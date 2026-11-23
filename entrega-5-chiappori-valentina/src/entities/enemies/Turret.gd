extends CharacterBody2D
class_name EnemyTurret

@onready var fire_position: Node2D = $FirePosition
@onready var fire_timer: Timer = $FireTimer
@onready var raycast: RayCast2D = $RayCast2D
@onready var body_anim: AnimatedSprite2D = $Body

@export var projectile_scene: PackedScene
@export var pathfinding: PathfindAstar

@export_group("Movimiento")
@export var speed: float = 60.0
@export var wander_radius: float = 120.0
@export var wander_wait: Vector2 = Vector2(1.5, 3.5)
@export var arrive_distance: float = 4.0
@export var chase_repath_time: float = 0.5

var target: Node2D
var projectile_container: Node

## Flag de ayuda para saber identificar el estado de actividad
var dead: bool = false

var path: PackedVector2Array = PackedVector2Array()

var _wander_time_left: float = 0.0
var _repath_time_left: float = 0.0
var _stuck_time: float = 0.0

const TRANSITION_ANIMATIONS: Array[StringName] = [
	&"alert", &"go_normal", &"attack", &"die", &"die_alert"
]


func _ready() -> void:
	fire_timer.timeout.connect(fire)
	_wander_time_left = randf_range(wander_wait.x, wander_wait.y)

	_play_animation(&"idle")


func initialize(turret_pos: Vector2, _projectile_container: Node) -> void:
	global_position = turret_pos
	self.projectile_container = _projectile_container


func fire() -> void:
	if target != null:
		var proj_instance: Node = projectile_scene.instantiate()
		if projectile_container == null:
			projectile_container = get_parent()
		projectile_container.add_child(proj_instance)
		proj_instance.initialize(
			fire_position.global_position,
			fire_position.global_position.direction_to(target.global_position)
		)
		fire_timer.start()
		_play_animation(&"attack")


func _physics_process(delta: float) -> void:
	if target != null:
		_process_alert(delta)
	else:
		_process_wander(delta)

	_follow_path()
	_update_movement_animation()
	move_and_slide()
	_check_stuck(delta)


func _process_alert(delta: float) -> void:
	raycast.set_target_position(raycast.to_local(target.global_position))
	var can_see_target: bool = raycast.is_colliding() && raycast.get_collider() == target

	if can_see_target:
		path.clear()
		if fire_timer.is_stopped():
			fire_timer.start()
		body_anim.flip_h = raycast.target_position.x < 0
	else:
		if !fire_timer.is_stopped():
			fire_timer.stop()
		_repath_time_left -= delta
		if _repath_time_left <= 0.0:
			_repath_time_left = chase_repath_time
			_set_path_to(target.global_position)


func _process_wander(delta: float) -> void:
	if !path.is_empty():
		return
	_wander_time_left -= delta
	if _wander_time_left <= 0.0:
		_wander_time_left = randf_range(wander_wait.x, wander_wait.y)
		var random_point: Vector2 = global_position + Vector2(
			randf_range(-wander_radius, wander_radius),
			randf_range(-wander_radius, wander_radius)
		)
		_set_path_to(random_point)


func _set_path_to(point: Vector2) -> void:
	if pathfinding == null:
		path.clear()
		return
	path = pathfinding.get_simple_path(global_position, point)


func _follow_path() -> void:
	while !path.is_empty() && global_position.distance_to(path[0]) < arrive_distance:
		path.remove_at(0)

	if path.is_empty():
		velocity = Vector2.ZERO
		return

	velocity = global_position.direction_to(path[0]) * speed
	if abs(velocity.x) > 1.0:
		body_anim.flip_h = velocity.x < 0



func _check_stuck(delta: float) -> void:
	if !path.is_empty() && get_real_velocity().length() < speed * 0.1:
		_stuck_time += delta
		if _stuck_time > 1.0:
			path.clear()
			_stuck_time = 0.0
	else:
		_stuck_time = 0.0


func _update_movement_animation() -> void:
	if body_anim.animation in TRANSITION_ANIMATIONS:
		return
	var moving: bool = velocity.length() > 1.0
	if target != null:
		_play_animation(&"walk_alert" if moving else &"idle_alert")
	else:
		_play_animation(&"walk" if moving else &"idle")


func notify_hit() -> void:
	if dead:
		return
	print("I'm turret and imma die")
	dead = true
	set_physics_process(false)
	fire_timer.stop()
	path.clear()
	velocity = Vector2.ZERO
	set_deferred(&"collision_layer", 0)
	if target != null:
		_play_animation(&"die_alert")
	else:
		_play_animation(&"die")
	target = null


func _remove() -> void:
	get_parent().remove_child(self)
	queue_free()


func _on_detection_area_body_entered(body: Node2D) -> void:
	if target == null && !dead:
		target = body
		path.clear()
		_repath_time_left = 0.0

		_play_animation(&"alert")


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == target && !dead:
		target = null
		path.clear()
		fire_timer.stop()

		_play_animation(&"go_normal")


func _on_animation_finished() -> void:
	match body_anim.animation:
		&"alert":
			_play_animation(&"idle_alert")
		&"go_normal":
			_play_animation(&"idle")
		&"fire", &"attack":
			_play_animation(&"idle_alert" if target != null else &"idle")
		&"die", &"die_alert":
			call_deferred(&"_remove")


func _play_animation(animation: StringName) -> void:
	if body_anim.sprite_frames.has_animation(animation):
		body_anim.play(animation)
