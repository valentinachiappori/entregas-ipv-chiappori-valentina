extends StaticBody2D

@onready var fire_position: Node2D = $FirePosition
@onready var fire_timer: Timer = $FireTimer
@onready var raycast: RayCast2D = $RayCast2D
@onready var body: AnimatedSprite2D = $Body
@onready var detection_area: Area2D = $DetectionArea

@export var projectile_scene: PackedScene

const THROW_FRAME: int = 2

var target: Node2D
var projectile_container: Node

var dead: bool = false


func _ready() -> void:
	fire_timer.timeout.connect(fire)
	body.frame_changed.connect(_on_frame_changed)
	body.animation_finished.connect(_on_animation_finished)
	set_physics_process(false)
	_play_animation("idle")


func initialize(turret_pos: Vector2, container: Node) -> void:
	global_position = turret_pos
	projectile_container = container


func fire() -> void:
	if target == null || dead:
		return
	_play_animation("attack")
	fire_timer.start()


func _throw_projectile() -> void:
	if target == null:
		return
	var proj_instance: Node = projectile_scene.instantiate()
	if projectile_container == null:
		projectile_container = get_parent()
	projectile_container.add_child(proj_instance)
	proj_instance.initialize(
		fire_position.global_position,
		fire_position.global_position.direction_to(target.global_position)
	)


func _physics_process(_delta: float) -> void:
	raycast.set_target_position(raycast.to_local(target.global_position))
	if raycast.is_colliding() && raycast.get_collider() == target:
		if fire_timer.is_stopped():
			fire_timer.start()
	elif !fire_timer.is_stopped():
		fire_timer.stop()


func notify_hit() -> void:
	if dead:
		return
	print("I'm turret and imma die")
	dead = true
	fire_timer.stop()
	set_physics_process(false)
	detection_area.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	_play_animation("death")


func _remove() -> void:
	hide()
	get_parent().remove_child(self)
	queue_free()


func _on_detection_area_body_entered(entered_body: Node2D) -> void:
	if target == null:
		target = entered_body
		set_physics_process(true)


func _on_detection_area_body_exited(exited_body: Node2D) -> void:
	if exited_body == target:
		target = null
		set_physics_process(false)


func _on_frame_changed() -> void:
	if body.animation == "attack" && body.frame == THROW_FRAME:
		_throw_projectile()


func _on_animation_finished() -> void:
	match body.animation:
		"attack":
			_play_animation("idle")
		"death":
			_remove()


func _play_animation(animation: String) -> void:
	if body.sprite_frames.has_animation(animation):
		body.play(animation)
