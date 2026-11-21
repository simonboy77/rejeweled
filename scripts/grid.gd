extends Node2D

var layout = Vector2(); var cellDim = Vector2()
var rect = Rect2()

func arrange(gridLayout, screenSize):
	layout = gridLayout
	cellDim = Globals.CELL_DIM
	
	var dim = layout * cellDim
	var pos = (screenSize - dim) / 2
	rect = Rect2(pos, dim)

func coor_from_index(index):
	var row = floor(index / layout.x)
	var col = index - (row * layout.x)
	
	return Vector2(col, row)

func index_from_coor(coor):
	var index = (coor.y * layout.x) + coor.x
	return index

func coor_from_screen_pos(pos):
	var coor = floor((pos - rect.position) / cellDim)
	return coor

func index_from_screen_pos(pos):
	var coor = coor_from_screen_pos(pos)
	return index_from_coor(coor)

func screen_pos_from_coor(coor):
	return (rect.position + (coor * cellDim))

func center_screen_pos_from_coor(coor):
	var screenPos = screen_pos_from_coor(coor)
	screenPos += cellDim / 2
	return screenPos

func screen_pos_from_index(index):
	var coor = coor_from_index(index)
	return screen_pos_from_coor(coor)

func center_screen_pos_from_index(index):
	var screenPos = screen_pos_from_index(index)
	screenPos += cellDim / 2
	return screenPos

func contains_pos(pos):
	return rect.has_point(pos)

func get_cols():
	return layout.x

func get_rows():
	return layout.y

func get_cell_dim():
	return cellDim

func get_size():
	return rect.size

func get_top_left():
	return rect.position

func get_center():
	return rect.get_center()

func get_count():
	return (layout.x * layout.y)

func get_left_coor(coor): # Does not respect layout
	return Vector2(coor.x - 1, coor.y)

func get_above_coor(coor): # Does not respect layout
	return Vector2(coor.x, coor.y - 1)

func get_right_coor(coor): # Does not respect layout
	return Vector2(coor.x + 1, coor.y)

func get_below_coor(coor): # Does not respect layout
	return Vector2(coor.x, coor.y + 1)

func get_left_index(index): # Does not respect layout
	return index - 1

func get_above_index(index): # Does not respect layout
	return index - layout.x

func get_right_index(index): # Does not respect layout
	return index + 1

func get_below_index(index): # Does not respect layout
	return index + layout.x

func has_left_coor(coor):
	return (coor.x > 0)

func has_above_coor(coor):
	return (coor.y > 0)

func has_right_coor(coor):
	return (coor.x < (layout.x - 1))

func has_below_coor(coor):
	return (coor.y < (layout.y - 1))

func has_coor(coor):
	var hasCol = ((coor.x >= 0) && (coor.x < layout.x))
	var hasRow = ((coor.y >= 0) && (coor.y < layout.y))
	return (hasCol && hasRow)

func has_left_index(index):
	return has_left_coor(coor_from_index(index))

func has_above_index(index):
	return has_above_coor(coor_from_index(index))

func has_right_index(index):
	return has_right_coor(coor_from_index(index))

func has_below_index(index):
	return has_below_coor(coor_from_index(index))

func has_index(index):
	return ((index >= 0) && (index < get_count()))

func next_coor(coor):
	coor.x += 1
	if coor.x >= layout.x:
		coor.x = 0
		coor.y += 1
	
	return coor

func get_next_index(index, direction):
	match direction:
		Globals.DIR_LEFT:  return get_left_index(index)
		Globals.DIR_ABOVE: return get_above_index(index)
		Globals.DIR_RIGHT: return get_right_index(index)
		Globals.DIR_BELOW: return get_below_index(index)
	
	return index

func has_next_index(index, direction):
	match direction:
		Globals.DIR_LEFT:  return has_left_index(index)
		Globals.DIR_ABOVE: return has_above_index(index)
		Globals.DIR_RIGHT: return has_right_index(index)
		Globals.DIR_BELOW: return has_below_index(index)
	
	return has_index(index)

func dir_to_coor(fromCoor, toCoor):
	var xDiff = toCoor.x - fromCoor.x
	var yDiff = toCoor.y - fromCoor.y
	
	if abs(xDiff) > abs(yDiff):
		if xDiff > 0:
			return Globals.DIR_RIGHT
		else: # if xDiff < 0
			return Globals.DIR_LEFT
	elif abs(xDiff) < abs(yDiff):
		if yDiff > 0:
			return Globals.DIR_BELOW
		else: # if yDiff < 0
			return Globals.DIR_ABOVE
	elif xDiff != 0: # && yDiff != 0
		var horzDir = Globals.DIR_LEFT  if (xDiff < 0) else Globals.DIR_RIGHT
		var vertDir = Globals.DIR_ABOVE if (yDiff < 0) else Globals.DIR_BELOW
		
		#TODO: what about diagonalsss??
		if vertDir == Globals.DIR_BELOW:
			return Globals.DIR_BELOW
		else:
			return horzDir
	
	return Globals.DIR_NONE
