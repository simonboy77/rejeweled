extends Node2D

var thread: Thread
var stopThread = false; var shouldRefresh = false

func _init():
	thread = Thread.new()

func should_refresh():
	return (shouldRefresh && !thread.is_alive())

func refresh_executed():
	shouldRefresh = false

func find_combo_at_index_in_overview_full(blockIndex, blocksOverview, blocksChecked, comboBlocks := []):
	var partOfCombo = false
	if !blocksChecked[blockIndex]:
		blocksChecked[blockIndex] = true
		var matchType = blocksOverview[blockIndex]
		
		# these are leading if any hasX is false, the type and index vars associated with that position are garbage
		var hasLeft  = Grid.has_left_index( blockIndex); var hasAbove = Grid.has_above_index(blockIndex)
		var hasRight = Grid.has_right_index(blockIndex); var hasBelow = Grid.has_below_index(blockIndex)
		var hasLeftAbove = (hasLeft && hasAbove); var hasRightAbove = (hasRight && hasAbove)
		var hasLeftBelow = (hasLeft && hasBelow); var hasRightBelow = (hasRight && hasBelow)
		
		# indexes could be garbage, always check hasX bools first!
		var leftIndex      = Grid.get_left_index( blockIndex); var aboveIndex      = Grid.get_above_index(blockIndex)
		var rightIndex     = Grid.get_right_index(blockIndex); var belowIndex      = Grid.get_below_index(blockIndex)
		var leftAboveIndex = Grid.get_left_index( aboveIndex); var rightAboveIndex = Grid.get_right_index(aboveIndex)
		var leftBelowIndex = Grid.get_left_index( belowIndex); var rightBelowIndex = Grid.get_right_index(belowIndex)
		
		# types could be garbage, always check hasX bools first! has_index is only used so we stay in array bounds
		var leftType  = blocksOverview[ leftIndex] if Grid.has_index( leftIndex) else Globals.BLOCK_EMPTY
		var aboveType = blocksOverview[aboveIndex] if Grid.has_index(aboveIndex) else Globals.BLOCK_EMPTY
		var rightType = blocksOverview[rightIndex] if Grid.has_index(rightIndex) else Globals.BLOCK_EMPTY
		var belowType = blocksOverview[belowIndex] if Grid.has_index(belowIndex) else Globals.BLOCK_EMPTY
		
		var leftAboveType  = blocksOverview[ leftAboveIndex] if Grid.has_index( leftAboveIndex) else Globals.BLOCK_EMPTY
		var leftBelowType  = blocksOverview[ leftBelowIndex] if Grid.has_index( leftBelowIndex) else Globals.BLOCK_EMPTY
		var rightAboveType = blocksOverview[rightAboveIndex] if Grid.has_index(rightAboveIndex) else Globals.BLOCK_EMPTY
		var rightBelowType = blocksOverview[rightBelowIndex] if Grid.has_index(rightBelowIndex) else Globals.BLOCK_EMPTY
		
		# check left row
		if hasLeft && Grid.has_left_index(leftIndex):
			var farLeftIndex = Grid.get_left_index(leftIndex)
			if Globals.blocks_match_3(matchType, leftType, blocksOverview[farLeftIndex]):
				find_combo_at_index_in_overview_full(   leftIndex, blocksOverview, blocksChecked, comboBlocks)
				find_combo_at_index_in_overview_full(farLeftIndex, blocksOverview, blocksChecked, comboBlocks)
				partOfCombo = true
		
		# check above column
		if hasAbove && Grid.has_above_index(aboveIndex):
			var farAboveIndex = Grid.get_above_index(aboveIndex)
			if Globals.blocks_match_3(matchType, aboveType, blocksOverview[farAboveIndex]):
				find_combo_at_index_in_overview_full(   aboveIndex, blocksOverview, blocksChecked, comboBlocks)
				find_combo_at_index_in_overview_full(farAboveIndex, blocksOverview, blocksChecked, comboBlocks)
				partOfCombo = true
		
		# check right row
		if hasRight && Grid.has_right_index(rightIndex):
			var farRightIndex = Grid.get_right_index(rightIndex)
			if Globals.blocks_match_3(matchType, rightType, blocksOverview[farRightIndex]):
				find_combo_at_index_in_overview_full(   rightIndex, blocksOverview, blocksChecked, comboBlocks)
				find_combo_at_index_in_overview_full(farRightIndex, blocksOverview, blocksChecked, comboBlocks)
				partOfCombo = true
		
		# check below column
		if hasBelow && Grid.has_below_index(belowIndex):
			var farBelowIndex = Grid.get_below_index(belowIndex)
			if Globals.blocks_match_3(matchType, belowType, blocksOverview[farBelowIndex]):
				find_combo_at_index_in_overview_full(   belowIndex, blocksOverview, blocksChecked, comboBlocks)
				find_combo_at_index_in_overview_full(farBelowIndex, blocksOverview, blocksChecked, comboBlocks)
				partOfCombo = true
		
		# check plus rows from middle
		if hasLeft && hasRight && Globals.blocks_match_3(matchType, leftType, rightType):
			find_combo_at_index_in_overview_full( leftIndex, blocksOverview, blocksChecked, comboBlocks)
			find_combo_at_index_in_overview_full(rightIndex, blocksOverview, blocksChecked, comboBlocks)
			partOfCombo = true
		
		if hasAbove && hasBelow && Globals.blocks_match_3(matchType, aboveType, belowType):
			find_combo_at_index_in_overview_full(aboveIndex, blocksOverview, blocksChecked, comboBlocks)
			find_combo_at_index_in_overview_full(belowIndex, blocksOverview, blocksChecked, comboBlocks)
			partOfCombo = true
		
		# check 2x2 areas
		if hasLeftAbove && Globals.blocks_match_4(matchType,  leftType, aboveType,  leftAboveType):
			find_combo_at_index_in_overview_full(     leftIndex, blocksOverview, blocksChecked, comboBlocks)
			find_combo_at_index_in_overview_full(    aboveIndex, blocksOverview, blocksChecked, comboBlocks)
			find_combo_at_index_in_overview_full(leftAboveIndex, blocksOverview, blocksChecked, comboBlocks)
			partOfCombo = true
		
		if hasLeftBelow && Globals.blocks_match_4(matchType,  leftType, belowType,  leftBelowType):
			find_combo_at_index_in_overview_full(     leftIndex, blocksOverview, blocksChecked, comboBlocks)
			find_combo_at_index_in_overview_full(    belowIndex, blocksOverview, blocksChecked, comboBlocks)
			find_combo_at_index_in_overview_full(leftBelowIndex, blocksOverview, blocksChecked, comboBlocks)
			partOfCombo = true
		
		if hasRightAbove && Globals.blocks_match_4(matchType, rightType, aboveType, rightAboveType):
			find_combo_at_index_in_overview_full(     rightIndex, blocksOverview, blocksChecked, comboBlocks)
			find_combo_at_index_in_overview_full(     aboveIndex, blocksOverview, blocksChecked, comboBlocks)
			find_combo_at_index_in_overview_full(rightAboveIndex, blocksOverview, blocksChecked, comboBlocks)
			partOfCombo = true
		
		if hasRightBelow && Globals.blocks_match_4(matchType, rightType, belowType, rightBelowType):
			find_combo_at_index_in_overview_full(     rightIndex, blocksOverview, blocksChecked, comboBlocks)
			find_combo_at_index_in_overview_full(     belowIndex, blocksOverview, blocksChecked, comboBlocks)
			find_combo_at_index_in_overview_full(rightBelowIndex, blocksOverview, blocksChecked, comboBlocks)
			partOfCombo = true

		# mark block
		if partOfCombo: comboBlocks.append(blockIndex)
	
	return partOfCombo

func find_combo_at_index_in_overview(blockIndex, blocksOverview, comboBlocks := []):
	var blocksChecked = []
	blocksChecked.resize(blocksOverview.size()); blocksChecked.fill(false)
	
	return find_combo_at_index_in_overview_full(blockIndex, blocksOverview, blocksChecked, comboBlocks)

func swap_overview_blocks(blocksOverview, blockIndex, swapIndex):
	var blockType = blocksOverview[blockIndex]
	blocksOverview[blockIndex] = blocksOverview[swapIndex]
	blocksOverview[swapIndex]  = blockType

func check_for_swap_combos(blocksOverview):
	for blockType in blocksOverview:
		if Globals.block_is_special(blockType):
			return
	
	var coor = Vector2(0, 0); var swapComboFound = false
	while !stopThread && !swapComboFound:
		var blockIndex = Grid.index_from_coor(coor)
		for dir in Globals.dirRange:
			if Grid.has_next_index(blockIndex, dir):
				var nextIndex = Grid.get_next_index(blockIndex, dir)
				swap_overview_blocks(blocksOverview, blockIndex, nextIndex)
				
				if find_combo_at_index_in_overview(blockIndex, blocksOverview):
					swapComboFound = true; break
				else:
					swap_overview_blocks(blocksOverview, blockIndex, nextIndex)
		
		if !swapComboFound:
			coor = Grid.next_coor(coor)
			if !Grid.has_coor(coor):
				shouldRefresh = true; break

func stop_check_for_combos():
	if thread.is_alive() || thread.is_started():
		stopThread = true
		thread.wait_to_finish()

func restart_check_for_combos(blocksOverview):
	stop_check_for_combos()
	
	stopThread = false; shouldRefresh = false
	thread.start(check_for_swap_combos.bind(blocksOverview))

func start_check_for_combos(blocksOverview):
	restart_check_for_combos(blocksOverview)
