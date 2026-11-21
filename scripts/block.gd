extends Node2D

signal cleared()
signal moved()

var sprite = null; var type = 0

var moving = false; var moveSpeed = 0
var moveTargets = []; var moveTargetZ = 0

var clearing = false; var clearTime = 0.0
var postClearType = Globals.BLOCK_EMPTY

var spawning = false; var spawnTime = 0.0
var shaking = false; var shakeTime = 0.0
var spinning = false

func is_moving():
	return moving

func is_clearing():
	return clearing

func is_spawning():
	return spawning

func is_busy():
	return (is_moving() || is_clearing() || is_spawning())

func is_gap():
	return Globals.block_is_gap(type)

func is_empty():
	return Globals.block_is_empty(type)

func is_special():
	return Globals.block_is_special(type)

func is_settled():
	return (is_gap() || (!is_empty() && !is_busy()))

func can_combo():
	return Globals.block_can_combo(type)

func can_swap():
	return Globals.block_can_swap(type)

func get_type():
	return type

func set_type(newType):
	type = newType
	sprite.set_texture(Globals.block_texture_from_type(type))

func get_score():
	if Globals.block_can_combo(type):
		return 1
	
	return 0

func set_grid_position(gridIndex):
	set_global_position(Grid.screen_pos_from_index(gridIndex))
	#set_pivot_offset(Grid.get_cell_dim() / 2.0)
	# refreshLabel.set_pivot_offset(refreshLabel.get_rect().size / 2)
	sprite.position = Grid.get_cell_dim() / 2.0

func random_type(allowSpecials := true, allowedBasics := []):
	var newType = Globals.BLOCK_EMPTY
	var specialChance = randf()
	
	if allowSpecials && (specialChance < Globals.RAINBOW_CHANCE):
		newType = Globals.BLOCK_RAINBOW
	else:
		if allowedBasics.size():
			newType = allowedBasics.pick_random()
		else:
			newType = Globals.basicBlockTypes.pick_random()
	
	set_type(newType)

func start_moves(targets, z, speed):
	moveTargets.clear()
	moveTargets = targets
	moveTargetZ = z
	moveSpeed = speed
	moving = true

func start_move(target, z, speed):
	var targets = []; targets.push_back(target)
	start_moves(targets, z, speed)

func start_clear(postType := Globals.BLOCK_EMPTY):
	clearing = true; clearTime = 0.0
	sprite.set_scale(Vector2(1.2, 1.2))
	start_spin()
	postClearType = postType

func clear(newType := Globals.BLOCK_EMPTY):
	set_type(newType)
	stop_spin()
	clearing = false
	
	if newType == Globals.BLOCK_EMPTY:
		sprite.set_scale(Vector2(1.0, 1.0))
	else:
		start_spawn()

func start_spawn():
	sprite.set_scale(Vector2(0.0, 0.0))
	spawning = true; spawnTime = 0.0

func start_shake():
	shaking = true; shakeTime = 0.0

func start_spin():
	spinning = true

func stop_spin():
	sprite.set_rotation(0)
	spinning = false

func _ready():
	sprite = $Sprite
	set_type(Globals.BLOCK_EMPTY)

func _physics_process(delta):
	progress_move(delta)
	progress_clear(delta)
	progress_spawn(delta)
	progress_shake(delta)
	progress_spin(delta)

func progress_move(delta):
	if moving:
		position = position.move_toward(moveTargets[0], moveSpeed * delta)
		if position == moveTargets[0]:
			moveTargets.remove_at(0)
			if moveTargets.size() == 0:
				z_index = moveTargetZ
				moving = false; moved.emit()

func progress_clear(delta):
	if clearing:
		clearTime = clamp(clearTime + delta, 0.0, Globals.BLOCK_CLEAR_TIME)
		sprite.set_scale(Vector2(1.2, 1.2).lerp(Vector2(0.0, 0.0), clearTime / Globals.BLOCK_CLEAR_TIME))
		if clearTime >= Globals.BLOCK_CLEAR_TIME:
			clear(postClearType)
			cleared.emit()

func progress_spawn(delta):
	if spawning:
		spawnTime = clamp(spawnTime + delta, 0.0, Globals.BLOCK_SPAWN_TIME)
		sprite.set_scale(Vector2(0.0, 0.0).lerp(Vector2(1.0, 1.0), spawnTime / Globals.BLOCK_SPAWN_TIME))
		if spawnTime >= Globals.BLOCK_SPAWN_TIME:
			spawning = false

func progress_shake(delta):
	if shaking:
		shakeTime = clamp(shakeTime + delta, 0.0, Globals.BLOCK_SHAKE_TIME)
		sprite.set_rotation(sin(shakeTime * 40.0) / 6.0)
		
		if shakeTime >= Globals.BLOCK_SHAKE_TIME:
			shaking = false; sprite.set_rotation(0)

func progress_spin(delta):
	if spinning:
		var radian = sprite.get_rotation()
		sprite.set_rotation(radian + (delta * 10.0))
