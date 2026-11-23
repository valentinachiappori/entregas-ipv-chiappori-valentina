extends PlayerState


func enter() -> void:
	character._play_animation(&"walk")


func exit() -> void:
	return


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"jump") && character.is_on_floor_raycasted():
		finished.emit(&"jump")


func update(delta: float) -> void:
	character._handle_weapon_actions()
	
	character._handle_move_input(delta)
	character._apply_movement(delta)
	
	if character.h_movement_direction == 0:
		finished.emit(&"idle")
	else:
		if character.is_on_floor():
			character._play_animation(&"walk")
		else:
			if character.velocity.y > 0:
				character._play_animation(&"fall")
			else:
				character._play_animation(&"jump")


func _on_animation_finished(_anim_name: StringName) -> void:
	return


func handle_event(event: StringName, value = null) -> void:
	match event:
		&"hit":
			character._handle_hit(value)
			if character.dead:
				finished.emit(&"dead")
