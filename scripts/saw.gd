extends Node2D

signal hit_block(coor, dir)
signal stopped()

var sprite = null

var moving:bool; var moveSpeed:int; var moveDirection:int
var moveTargets:Array

func _ready():
	sprite = $Sprite
	sprite.set_texture(Globals.block_texture_from_type(Globals.BLOCK_SAW))

func set_grid_position(gridIndex):
	set_global_position(Grid.screen_pos_from_index(gridIndex))
	sprite.position = Grid.get_cell_dim() / 2

func stop():
	stopped.emit()
	queue_free()

func launch(direction, speed):
	moveTargets.clear()
	var gridIndex = Grid.index_from_screen_pos(position)
	
	match direction:
		Globals.DIR_LEFT:
			while Grid.has_left_index(gridIndex):
				gridIndex = Grid.get_left_index(gridIndex)
				moveTargets.push_back(Grid.screen_pos_from_index(gridIndex))
		
		Globals.DIR_ABOVE:
			while Grid.has_above_index(gridIndex):
				gridIndex = Grid.get_above_index(gridIndex)
				moveTargets.push_back(Grid.screen_pos_from_index(gridIndex))
		
		Globals.DIR_RIGHT:
			while Grid.has_right_index(gridIndex):
				gridIndex = Grid.get_right_index(gridIndex)
				moveTargets.push_back(Grid.screen_pos_from_index(gridIndex))
		
		Globals.DIR_BELOW:
			while Grid.has_below_index(gridIndex):
				gridIndex = Grid.get_below_index(gridIndex)
				moveTargets.push_back(Grid.screen_pos_from_index(gridIndex))
	
	if moveTargets.size() != 0:
		moveDirection = direction
		moveSpeed = speed
		moving = true
	else:
		stop()

func _physics_process(delta):
	if moving:
		sprite.rotate(delta * 10)
		position = position.move_toward(moveTargets[0], moveSpeed * delta)
		if position == moveTargets[0]:
			hit_block.emit(Grid.coor_from_screen_pos(moveTargets[0]), moveDirection)
			moveTargets.remove_at(0)
			
			if moveTargets.size() == 0:
				stop()
