extends Node2D

signal score_changed(oldScore, newScore)
signal move_count_changed(oldMoveCount, newMoveCount)
signal refreshing_board()

var score = 0
var moveCount = 0

var blockScene = preload("res://scenes/block.tscn")
var blocks = []; var selectedBlock = -1; var blockSpeed = 0
var blocksSettled = [] # bool for each block that says whether it can still move on its own

var sawScene = preload("res://scenes/saw.tscn")
var sawCount = 0; var sawSpeed = 0

var explosionScene = preload("res://scenes/explosion.tscn")
var starCount = 0

# pre-calc beauties
var blockPaths:Array[Array] # contains the shortest path to the top of the board for each block
var blocksByPathLength = [] # contains blockIndexes sorted from longest path to shortest path

# TODO: add fillableBlocks array that contains the indexes of every block that isnt a gap

var touchPos = 0
var checkBoard = false

func reset():
	set_score(0)
	set_move_count(0)
	
	blocks.clear()
	sawCount = 0
	
	for n in get_children():
		remove_child(n)
		n.queue_free()

func _init():
	reset()

func load_level(level, screenSize, atZ):
	reset()
	Grid.arrange(level.dim, screenSize)
	
	blockSpeed = Grid.get_cell_dim().x * Globals.BLOCK_TILES_PER_SECOND
	sawSpeed = Grid.get_cell_dim().x * Globals.SAW_TILES_PER_SECOND
	
	for gridIndex in Grid.get_count():
		var blockType = level.blocks[gridIndex]
		if !Globals.block_is_gap(blockType):
			var tile = Sprite2D.new();
			add_child(tile);
			
			var tilePos = Grid.screen_pos_from_index(gridIndex) + (Grid.get_cell_dim() / 2)
			tile.set_global_position(tilePos); tile.set_centered(true)
			tile.set_z_index(atZ); tile.set_texture(Globals.backTileTexture)
			
			var block = blockScene.instantiate()
			blocks.append(block); block.set_visible(false)
			
			add_child(block)
			block.set_grid_position(gridIndex)
			
			block.cleared.connect(_on_block_cleared)
			block.moved.connect(_on_block_moved)
			
			if Globals.block_is_random(blockType):
				fill_block_smart(gridIndex)
			else:
				block.set_type(blockType)
			
			block.z_index = atZ + 1
			block.set_visible(true)
		else:
			var block = blockScene.instantiate()
			add_child(block)
			block.set_type(blockType)
			blocks.append(block)
	
	blocksSettled.clear()
	for block in blocks:
		blocksSettled.push_back(block.is_settled())
	
	calc_block_paths()
	calc_sorted_path_lengths()
	checkBoard = true

func set_score(newScore):
	var oldScore = score
	score = newScore
	
	if oldScore != newScore:
		score_changed.emit(oldScore, newScore)

func increase_score(increase):
	set_score(score + increase)

func set_move_count(newMoveCount):
	var oldMoveCount = moveCount
	moveCount = newMoveCount
	move_count_changed.emit(oldMoveCount, newMoveCount)

func increase_move_count(increase):
	set_move_count(moveCount + increase)

func get_blocks_overview():
	var blocksOverview = []
	for blockIndex in blocks.size():
		if blocksSettled[blockIndex]:
			blocksOverview.append(blocks[blockIndex].get_type())
		else:
			blocksOverview.append(Globals.BLOCK_EMPTY)

	return blocksOverview

func are_blocks_moving():
	for block in blocks:
		if block.is_moving():
			return true
	
	return false

func are_blocks_busy():
	for block in blocks:
		if block.is_busy():
			return true
	
	return false

func is_full():
	for block in blocks:
		if block.is_empty():
			return false
	
	return true

func are_blocks_settled():
	for settled in blocksSettled:
		if !settled: return false
	
	return true

func clear():
	set_score(0)
	set_move_count(0)
	
	for gridIndex in Grid.get_count():
		blocks[gridIndex].clear()

func soft_clear():
	for gridIndex in Grid.get_count():
		blocks[gridIndex].start_clear()

func shuffle():
	blocks.shuffle()
	for blockIndex in blocks.size():
		var blockPosition = Grid.screen_pos_from_index(blockIndex)
		blocks[blockIndex].start_move(blockPosition, blocks[blockIndex].z_index, blockSpeed)

func fill_random():
	clear()
	for block in blocks:
		block.random_type()
	
	checkBoard = true

func fill_block_smart(blockIndex):
	# This makes sure a new block is different from its left and above block
	# maybe try alternating? odd blocks check above and even blocks check left?
	var allowedTypes = Globals.basicBlockTypes.duplicate()

	if Grid.has_left_index(blockIndex):
		var leftBlock = blocks[Grid.get_left_index(blockIndex)]
		allowedTypes.erase(leftBlock.get_type())
	
	if Grid.has_above_index(blockIndex):
		var aboveBlock = blocks[Grid.get_above_index(blockIndex)]
		allowedTypes.erase(aboveBlock.get_type())
	
	blocks[blockIndex].random_type(false, allowedTypes)

func fill_smart():
	clear()
	for blockIndex in blocks.size():
		fill_block_smart(blockIndex)
	
	checkBoard = true

func fill_debug():
	clear()
	
	var blockIndex = 0
	
	# row 1
	blocks[blockIndex].set_type(Globals.BLOCK_RED); blockIndex += 1
	blocks[blockIndex].set_type(Globals.BLOCK_BLUE); blockIndex += 1
	blocks[blockIndex].set_type(Globals.BLOCK_GREEN); blockIndex += 1
	blocks[blockIndex].set_type(Globals.BLOCK_RED); blockIndex += 1
	blocks[blockIndex].set_type(Globals.BLOCK_GAP); blockIndex += 1
	blocks[blockIndex].set_type(Globals.BLOCK_PINK); blockIndex += 1
	blocks[blockIndex].set_type(Globals.BLOCK_PINK); blockIndex += 1
	blocks[blockIndex].set_type(Globals.BLOCK_GAP); blockIndex += 1
	blocks[blockIndex].set_type(Globals.BLOCK_PINK); blockIndex += 1
	blocks[blockIndex].set_type(Globals.BLOCK_RED); blockIndex += 1
	blocks[blockIndex].set_type(Globals.BLOCK_RED); blockIndex += 1
	blocks[blockIndex].set_type(Globals.BLOCK_ORANGE); blockIndex += 1
	
	checkBoard = true

func spawn_block(blockIndex):
	var abovePos = Grid.screen_pos_from_index(Grid.get_above_index(blockIndex))
	var goalPos = Grid.screen_pos_from_index(blockIndex)
	
	var block = blocks[blockIndex]
	block.set_global_position(abovePos)
	block.random_type()
	block.start_move(goalPos, block.z_index, blockSpeed)

func path_block(blockIndex):
	var pathLength = blockPaths[blockIndex].size()
	var block = blocks[blockIndex]
	if block.can_swap() && !block.is_busy():
		# below has priority
		if Grid.has_below_index(blockIndex):
			var belowIndex = Grid.get_below_index(blockIndex)
			var belowPathLength = blockPaths[belowIndex].size()
			if blocks[belowIndex].is_empty() && (belowPathLength >= pathLength):
				swap_blocks(blockIndex, belowIndex)
				return
				
		var hasLeft  = Grid.has_left_index(blockIndex)
		var hasRight = Grid.has_right_index(blockIndex)
		
		if hasLeft && hasRight:
			var leftIndex = Grid.get_left_index(blockIndex)
			var leftEmpty = blocks[leftIndex].is_empty()
			var leftPathLength = blockPaths[leftIndex].size()
			
			var rightIndex = Grid.get_right_index(blockIndex)
			var rightEmpty = blocks[rightIndex].is_empty()
			var rightPathLength = blockPaths[rightIndex].size()
			
			var dir = Globals.DIR_LEFT if (leftPathLength >= rightPathLength) else Globals.DIR_RIGHT
			
			if leftEmpty && rightEmpty:
				if leftPathLength == rightPathLength:
					dir = randi_range(Globals.DIR_LEFT, Globals.DIR_RIGHT)
				
				if dir == Globals.DIR_LEFT && (leftPathLength >= pathLength):
					swap_blocks(blockIndex, leftIndex)
				elif dir == Globals.DIR_RIGHT && (rightPathLength >= pathLength):
					swap_blocks(blockIndex, rightIndex)
			elif leftEmpty && (leftPathLength >= pathLength):
				swap_blocks(blockIndex, leftIndex)
			elif rightEmpty && (rightPathLength >= pathLength):
				swap_blocks(blockIndex, rightIndex)
		elif hasLeft:
			var leftIndex = Grid.get_left_index(blockIndex)
			var leftPathLength = blockPaths[leftIndex].size()
			if blocks[leftIndex].is_empty() && (leftPathLength >= pathLength):
				swap_blocks(blockIndex, leftIndex)
		elif hasRight:
			var rightIndex = Grid.get_right_index(blockIndex)
			var rightPathLength = blockPaths[rightIndex].size()
			if blocks[rightIndex].is_empty() && (rightPathLength >= pathLength):
				swap_blocks(blockIndex, rightIndex)
		
		if Grid.has_above_index(blockIndex):
			var aboveIndex = Grid.get_above_index(blockIndex)
			var abovePathLength = blockPaths[aboveIndex].size()
			if blocks[aboveIndex].is_empty() && (abovePathLength >= pathLength):
				swap_blocks(blockIndex, aboveIndex)

func fill_empty_slots():
	for blockIndex in blocksByPathLength:
		var block = blocks[blockIndex]
		
		if block.is_empty():
			var direction = blockPaths[blockIndex][0]
			if (direction == Globals.DIR_ABOVE) && !Grid.has_above_index(blockIndex):
				spawn_block(blockIndex)
			else:
				path_block(Grid.get_next_index(blockIndex, direction))

func calc_blocks_settled():
	# sets the global blocksSettled array to the correct values
	var blocksChecked = []
	blocksChecked.resize(blocks.size()); blocksChecked.fill(false)
	
	for blockIndex in blocksByPathLength:
		if !blocksChecked[blockIndex]:
			var settled = blocks[blockIndex].is_settled()
			blocksSettled[blockIndex] = settled
			blocksChecked[blockIndex] = true
			
			var path = blockPaths[blockIndex]; var nextIndex = blockIndex
			for stepIndex in (path.size() - 1): # last step is to the top
				nextIndex = Grid.get_next_index(nextIndex, path[stepIndex])
				
				if !blocksChecked[nextIndex]:
					settled = (settled && blocks[nextIndex].is_settled())
					blocksSettled[nextIndex] = settled
					blocksChecked[nextIndex] = true
				else:
					break

func calc_block_paths():
	# TODO: this has be optimizable
	blockPaths.clear()
	blockPaths.resize(Grid.get_count())
	
	for col in Grid.get_cols():
		var blockIndex = Grid.index_from_coor(Vector2(col, 0))
		if !blocks[blockIndex].is_gap():
			blockPaths[blockIndex].push_front(Globals.DIR_ABOVE)
	
	var allPathed = false
	var pathDepth = 1
	
	while(!allPathed):
		allPathed = true
		
		for pathIndex in blockPaths.size():
			var path = blockPaths[pathIndex]
			if path.size() == pathDepth:
				for dir in Globals.dirRange:
					if Grid.has_next_index(pathIndex, dir):
						var nextIndex = Grid.get_next_index(pathIndex, dir)
						if blockPaths[nextIndex].size() == 0 && !blocks[nextIndex].is_gap():
							allPathed = false
							blockPaths[nextIndex] = path.duplicate()
							blockPaths[nextIndex].push_front(Globals.opposite_direction(dir))
		
		pathDepth += 1

func calc_sorted_path_lengths():
	blocksByPathLength.clear()
	
	var pathLengths = []
	for pathIndex in blockPaths.size():
		pathLengths.push_back(blockPaths[pathIndex].size())
	
	var stillPaths = true
	while(stillPaths):
		var longestPath = 0
		var longestPathIndex = 0
		for pathIndex in pathLengths.size():
			if pathLengths[pathIndex] > longestPath:
				longestPath = pathLengths[pathIndex]
				longestPathIndex = pathIndex
		
		if longestPath > 0:
			blocksByPathLength.push_back(longestPathIndex)
			pathLengths[longestPathIndex] = 0
		else:
			stillPaths = false

func get_all_combos():
	var comboList = []; var blockInCombo = []
	blockInCombo.resize(blocks.size()); blockInCombo.fill(false)
	
	for row in Grid.get_rows():
		for col in Grid.get_cols():
			var blockIndex = Grid.index_from_coor(Vector2(col, row))
			if !blockInCombo[blockIndex] && blocks[blockIndex].can_swap():
				var comboBlocks = [] # stores indexes of all blocks in combo
				if find_combo_at_index(blockIndex, comboBlocks):
					comboList.append(comboBlocks)
					for comboBlockIndex in comboBlocks:
						blockInCombo[comboBlockIndex] = true
	
	return comboList

func process_combo(comboBlocks):
	increase_score(comboBlocks.size())
	print("increase score by %d" % comboBlocks.size())
	
	if comboBlocks.size() == 4:
		blocks[comboBlocks.pop_at(0)].start_clear(Globals.BLOCK_SAW)
	elif comboBlocks.size() == 5:
		blocks[comboBlocks.pop_at(0)].start_clear(Globals.BLOCK_BOMB)
	elif comboBlocks.size() > 5:
		blocks[comboBlocks.pop_at(0)].start_clear(Globals.BLOCK_STAR)
	
	for comboIndex in comboBlocks.size():
		blocks[comboBlocks[comboIndex]].start_clear()

func process_board():
	calc_blocks_settled()
	
	# Clear all combo's
	var comboList = get_all_combos()
	for comboBlocks in comboList:
		process_combo(comboBlocks)
	
	if !is_full():
		fill_empty_slots()
	elif are_blocks_settled() && (comboList.size() == 0):
		restart_check_for_combos()

func find_combo_at_index(blockIndex, comboBlocks := []):
	var blocksOverview = get_blocks_overview()
	return BoardLogic.find_combo_at_index_in_overview(blockIndex, blocksOverview, comboBlocks)

func swap_overview_blocks(blocksOverview, blockIndex, swapIndex):
	var blockType = blocksOverview[blockIndex]
	blocksOverview[blockIndex] = blocksOverview[swapIndex]
	blocksOverview[swapIndex]  = blockType

func stop_check_for_combos():
	BoardLogic.stop_check_for_combos()

func restart_check_for_combos():
	var blocksOverview = get_blocks_overview()
	BoardLogic.restart_check_for_combos(blocksOverview)

func start_check_for_combos():
	restart_check_for_combos()

func move_block(blockIndex, direction):
	if Grid.has_next_index(blockIndex, direction):
		var nextIndex = Grid.get_next_index(blockIndex, direction)
		var nextBlock = blocks[nextIndex]
		if !nextBlock.is_gap():
			var block = blocks[blockIndex]
			block.start_move(nextBlock.position, block.z_index, blockSpeed)

func move_bomb(blockIndex, direction):
	var targetIndex = Grid.get_next_index(blockIndex, direction)
	blocks[blockIndex].moved.connect(_on_bomb_moved.bind(blockIndex, targetIndex))
	blocks[blockIndex].moved.disconnect(_on_block_moved)
	
	move_block(blockIndex, direction)

func swap_blocks(aIndex, bIndex):
	var aPos = Grid.screen_pos_from_index(aIndex)
	var aZ   = blocks[aIndex].z_index
	
	var bPos = Grid.screen_pos_from_index(bIndex)
	var bZ   = blocks[bIndex].z_index

	if !blocks[aIndex].is_empty():
		blocks[aIndex].start_move(bPos, bZ, blockSpeed)
		blocks[aIndex].z_index += 2
	else:
		blocks[aIndex].position = bPos
		blocks[aIndex].z_index =  bZ
	
	if !blocks[bIndex].is_empty():
		blocks[bIndex].start_move(aPos, aZ,blockSpeed)
		blocks[bIndex].z_index += 1
	else:
		blocks[bIndex].position = aPos
		blocks[bIndex].z_index =  aZ
	
	var aBlock = blocks[aIndex]
	blocks[aIndex] = blocks[bIndex]
	blocks[bIndex] = aBlock

func spawn_saw(gridIndex, direction):
	if direction != Globals.DIR_NONE:
		var saw = sawScene.instantiate()
		add_child(saw); sawCount += 1
		
		saw.hit_block.connect(_on_saw_hit_block)
		saw.stopped.connect(_on_saw_stopped)
		
		saw.set_grid_position(gridIndex)
		saw.set_z_index(100)
		saw.launch(direction, sawSpeed)
		
		return true
	return false

func destroy_area(gridCoor, width, height):
	var startCoor = gridCoor - Vector2(floor(width / 2.0), floor(height / 2.0))
	
	for row in height:
		for col in width:
			var blockCoor = startCoor + Vector2(col, row)
			if Grid.has_coor(blockCoor):
				var blockIndex = Grid.index_from_coor(blockCoor)
				var block = blocks[blockIndex]
				
				if block.can_swap() && !block.is_clearing():
					if block.is_special():
						use_special_block(blockIndex, Grid.dir_to_coor(gridCoor, blockCoor))
					else:
						increase_score(block.get_score())
						block.start_clear()

func explode_bomb(gridIndex, width := 3, height := 3):
	var bomb = blocks[gridIndex]; bomb.clear()
	
	if  bomb.moved.is_connected(_on_bomb_moved):  bomb.moved.disconnect(_on_bomb_moved)
	if !bomb.moved.is_connected(_on_block_moved): bomb.moved.connect(_on_block_moved)
	
	var explosionCoor = Grid.coor_from_screen_pos(bomb.get_position())
	destroy_area(explosionCoor, width, height)
	
	var explosionCenter = Grid.center_screen_pos_from_coor(explosionCoor)
	var explosionAnim = explosionScene.instantiate()
	
	add_child(explosionAnim)
	
	explosionAnim.scale = Vector2(width / 3.0, height / 3.0)
	explosionAnim.z_index = 1000; explosionAnim.position = explosionCenter
	explosionAnim.play()

func add_star_target(starTargets, blockIndex, sec):
	starTargets.push_back(blockIndex)
	blocks[blockIndex].start_spin()
	await Globals.async_wait(sec)

func activate_star(gridIndex, targetType, starTargets := []):
	starCount += 1
	var star = blocks[gridIndex]; star.start_spin()
	var clearType = Globals.BLOCK_EMPTY
	
	var selectTime = Globals.STAR_SELECT_TIME
	var selectSpeedup = Globals.STAR_SELECT_SPEEDUP
	
	if Globals.block_is_rainbow(targetType):
		for blockIndex in blocks.size():
			if blocks[blockIndex].can_combo():
				await add_star_target(starTargets, blockIndex, selectTime)
				selectTime /= selectSpeedup
	elif Globals.block_is_basic(targetType):
		for blockIndex in blocks.size():
			if blocks[blockIndex].get_type() == targetType:
				await add_star_target(starTargets, blockIndex, selectTime)
				selectTime /= selectSpeedup
	elif Globals.block_is_special(targetType):
		var targets = []
		for blockIndex in blocks.size():
			if blocks[blockIndex].can_combo():
				targets.push_back(blockIndex)
		
		var targetCount = ceil(targets.size() * Globals.STAR_TRANSFORM_RATE)
		targets.shuffle(); targets.resize(targetCount)
		
		for blockIndex in targets:
			await add_star_target(starTargets, blockIndex, selectTime)
			selectTime /= selectSpeedup
		
		clearType = targetType
	
	await Globals.async_wait(Globals.STAR_POST_SELECT_TIME)
	
	for blockIndex in starTargets:
		increase_score(blocks[blockIndex].get_score())
		blocks[blockIndex].start_clear(clearType)
	
	star.start_clear(clearType); starCount -= 1
	print("done")

func activate_star_from_index(gridIndex, targetIndex):
	var targetType = blocks[targetIndex].get_type()
	var starTargets = []; add_star_target(starTargets, targetIndex, Globals.STAR_SELECT_TIME)
	activate_star(gridIndex, targetType, starTargets)

func use_special_block(blockIndex, direction):
	match blocks[blockIndex].get_type():
		Globals.BLOCK_SAW:
			if spawn_saw(blockIndex, direction):
				var block = blocks[blockIndex]
				if block.can_swap():
					block.clear()
					increase_move_count(1)
			else:
				blocks[blockIndex].start_shake()
		Globals.BLOCK_BOMB:
			if !Grid.has_next_index(blockIndex, direction) || direction == Globals.DIR_NONE:
				explode_bomb(blockIndex)
			else:
				move_bomb(blockIndex, direction)
		Globals.BLOCK_STAR:
			if Grid.has_next_index(blockIndex, direction) && direction != Globals.DIR_NONE:
				activate_star_from_index(blockIndex, Grid.get_next_index(blockIndex, direction))
			else:
				blocks[blockIndex].start_shake()

func can_manually_swap(aIndex, bIndex):
	var aBlock = blocks[aIndex]; var bBlock = blocks[bIndex]
	var aValidType = Globals.block_can_swap(aBlock.get_type())
	var bValidType = Globals.block_can_swap(bBlock.get_type())
	
	var settled = (blocksSettled[aIndex] && blocksSettled[bIndex])
	return (aValidType && bValidType && settled)

func try_block_move(blockIndex, direction):
	if blocks[blockIndex].is_special():
		use_special_block(blockIndex, direction)
		return
	
	var swapIndex = blockIndex
	if Grid.has_next_index(blockIndex, direction): swapIndex = Grid.get_next_index(blockIndex, direction)

	if (swapIndex != blockIndex) && can_manually_swap(blockIndex, swapIndex):
		var blocksOverview = get_blocks_overview()
		swap_overview_blocks(blocksOverview, blockIndex, swapIndex)
		
		var comboAfterSwap = BoardLogic.find_combo_at_index_in_overview(blockIndex, blocksOverview)
		if !comboAfterSwap:
			comboAfterSwap = BoardLogic.find_combo_at_index_in_overview(swapIndex, blocksOverview)
		
		if comboAfterSwap:
			swap_blocks(blockIndex, swapIndex)
			increase_move_count(1)
		else: # fake move attempt
			var block = blocks[blockIndex]; var blockPos = block.position
			var swapBlock = blocks[swapIndex]; var swapBlockPos = swapBlock.position
			
			block.start_moves([swapBlockPos, blockPos], block.z_index, blockSpeed)
			swapBlock.start_moves([blockPos, swapBlockPos], swapBlock.z_index, blockSpeed)
		
		blocksSettled[blockIndex] = false; blocksSettled[swapIndex] = false

func select_block(blockIndex):
	selectedBlock = blockIndex

func deselect_block():
	selectedBlock = -1

func is_block_selected():
	return ((selectedBlock > -1) && (selectedBlock < blocks.size()))

func handle_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if Grid.contains_pos(event.position):
				var gridIndex = Grid.index_from_screen_pos(event.position)
				if !blocks[gridIndex].is_empty():
					select_block(gridIndex)
		elif is_block_selected():
			if blocks[selectedBlock].is_special():
				print("used special block on click")
				use_special_block(selectedBlock, Globals.DIR_NONE)
				increase_move_count(1)
			elif blocks[selectedBlock].can_swap():
				blocks[selectedBlock].start_shake()
			
			deselect_block()

	if is_block_selected():
		touchPos = event.position

func board_paused():
	return (sawCount > 0) || (starCount > 0)

func _process(delta):
	if !board_paused():
		if is_block_selected():
			var centerPos = Grid.center_screen_pos_from_index(selectedBlock)
			var posDiff = touchPos - centerPos
			
			if posDiff.x < (-Grid.get_cell_dim().x * 0.75):
				try_block_move(selectedBlock, Globals.DIR_LEFT); deselect_block()
			elif posDiff.x > (Grid.get_cell_dim().x * 0.75):
				try_block_move(selectedBlock, Globals.DIR_RIGHT); deselect_block()
			elif posDiff.y < (-Grid.get_cell_dim().y * 0.75):
				try_block_move(selectedBlock, Globals.DIR_ABOVE); deselect_block()
			elif posDiff.y > (Grid.get_cell_dim().y * 0.75):
				try_block_move(selectedBlock, Globals.DIR_BELOW); deselect_block()
		
		if checkBoard:
			process_board()
			checkBoard = false
		elif BoardLogic.should_refresh() && are_blocks_settled():
			refreshing_board.emit(); soft_clear()
			BoardLogic.refresh_executed()

func _on_block_cleared():
	#print("cleared block!")
	checkBoard = true

func _on_block_moved():
	#print("moved block!")
	checkBoard = true
	#checkBoard = (checkBoard || !are_blocks_moving())

func _on_saw_hit_block(coor, dir):
	var blockIndex = Grid.index_from_coor(coor)
	var block = blocks[blockIndex]
	
	if block.can_swap():
		if block.get_type() == Globals.BLOCK_SAW:
			if ((dir == Globals.DIR_LEFT) || (dir == Globals.DIR_RIGHT)):
				spawn_saw(blockIndex, Globals.DIR_ABOVE)
				spawn_saw(blockIndex, Globals.DIR_BELOW)
			elif ((dir == Globals.DIR_ABOVE) || (dir == Globals.DIR_BELOW)):
				spawn_saw(blockIndex, Globals.DIR_LEFT)
				spawn_saw(blockIndex, Globals.DIR_RIGHT)
			
			block.clear()
		elif block.get_type() == Globals.BLOCK_BOMB:
			explode_bomb(blockIndex)
		elif block.get_type() == Globals.BLOCK_STAR:
			activate_star(blockIndex, Globals.BLOCK_SAW)
		else:
			increase_score(blocks[blockIndex].get_score())
			blocks[blockIndex].start_clear()

func _on_saw_stopped():
	sawCount -= 1
	checkBoard = checkBoard || (sawCount == 0)

func _on_bomb_moved(bombIndex, targetIndex):
	if blocks[targetIndex].get_type() == Globals.BLOCK_SAW:
		blocks[targetIndex].clear()
		explode_bomb(bombIndex)
		
		for dir in Globals.dirRange:
			spawn_saw(targetIndex, dir)
	elif blocks[targetIndex].get_type() == Globals.BLOCK_BOMB:
		blocks[targetIndex].clear()
		explode_bomb(bombIndex, 5, 5)
	elif blocks[targetIndex].get_type() == Globals.BLOCK_STAR:
		blocks[targetIndex].clear()
		explode_bomb(bombIndex)
		activate_star(targetIndex, Globals.BLOCK_BOMB)
	else:
		explode_bomb(bombIndex)
