extends Node2D

@onready var weapon_tip: Node2D = $WeaponTip
@onready var fx_anim: AnimationPlayer = $FXAnim

@export var projectile_scene: PackedScene

var projectile_container: Node


## Desacoplamos el manejo del arma para que maneje su propia lógica.
## El báculo apunta siempre hacia el mouse.
func process_input() -> void:
	look_at(get_global_mouse_position())


## Arranca la animación de disparo. El proyectil no sale acá: lo crea
## _fire(), que se llama desde la animación "fire" en el momento del destello.
func fire() -> void:
	fx_anim.stop()
	fx_anim.play("fire")


## Llamada desde la pista de método de la animación "fire"
func _fire() -> void:
	var projectile_instance: Node = projectile_scene.instantiate()
	projectile_container.add_child(projectile_instance)
	projectile_instance.initialize(
		weapon_tip.global_position,
		global_position.direction_to(weapon_tip.global_position)
	)
