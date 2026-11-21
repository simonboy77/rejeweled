extends Node2D

const REFRESH_ANIM_TIME = 0.8
const CELL_DIM = Vector2(170, 170) # IMPORTANT

# if these are multiples of each other, shit lines up nice
const BLOCK_TILES_PER_SECOND = 10; const SAW_TILES_PER_SECOND = 12
const BLOCK_CLEAR_TIME = 0.2; const BLOCK_SPAWN_TIME = 0.1; const BLOCK_SHAKE_TIME = 0.2

const BLOCK_GAP = 0; const BLOCK_EMPTY  = 1; const BLOCK_RANDOM = 2

const BLOCK_RED  = 10; const BLOCK_GREEN  = 11; const BLOCK_BLUE = 12
const BLOCK_PINK = 13; const BLOCK_ORANGE = 14
const basicBlockTypes = [ BLOCK_RED, BLOCK_GREEN, BLOCK_BLUE, BLOCK_PINK, BLOCK_ORANGE ]

const BLOCK_RAINBOW = 20; const BLOCK_SAW = 21; const BLOCK_BOMB = 22; const BLOCK_STAR = 23
const RAINBOW_CHANCE = 0.01 # out of 1.0
const STAR_TRANSFORM_RATE = 0.1
const STAR_SELECT_TIME = 0.2; const STAR_SELECT_SPEEDUP = 1.2; const STAR_POST_SELECT_TIME = 0.7

const BLOCK_JOURNEY = 30
const BLOCK_BREAK_1 = 40; const BLOCK_BREAK_2 = 41; const BLOCK_BREAK_3 = 42

const blockTextureRed    = preload("res://sprites/blocks/basic/red.png")
const blockTextureGreen  = preload("res://sprites/blocks/basic/green.png")
const blockTextureBlue   = preload("res://sprites/blocks/basic/blue.png")
const blockTexturePink   = preload("res://sprites/blocks/basic/pink.png")
const blockTextureOrange = preload("res://sprites/blocks/basic/orange.png")

const blockTextureRainbow = preload("res://sprites/blocks/special/rainbow.png")
const blockTextureSaw     = preload("res://sprites/blocks/special/saw.png")
const blockTextureBomb    = preload("res://sprites/blocks/special/bomb.png")
const blockTextureStar    = preload("res://sprites/blocks/special/star.png")

const backTileTexture = preload("res://sprites/blocks/back-tile.png")

func block_texture_from_type(blockType):
	match blockType:
		BLOCK_RED:     return blockTextureRed
		BLOCK_GREEN:   return blockTextureGreen
		BLOCK_BLUE:    return blockTextureBlue
		BLOCK_PINK:    return blockTexturePink
		BLOCK_ORANGE:  return blockTextureOrange
		
		BLOCK_RAINBOW: return blockTextureRainbow
		BLOCK_SAW:     return blockTextureSaw
		BLOCK_BOMB:    return blockTextureBomb
		BLOCK_STAR:    return blockTextureStar
	
	return null # BLOCK_EMPTY also returns null

func block_is_gap(blockType):
	return (blockType == BLOCK_GAP)

func block_is_empty(blockType):
	return (blockType == BLOCK_EMPTY)

func block_is_random(blockType):
	return (blockType == BLOCK_RANDOM)

func block_is_basic(blockType):
	return basicBlockTypes.has(blockType)

func block_is_rainbow(blockType):
	return (blockType == BLOCK_RAINBOW)

func block_is_special(blockType):
	return ((blockType == BLOCK_SAW) || (blockType == BLOCK_BOMB) || (blockType == BLOCK_STAR))

func block_can_combo(blockType):
	return (block_is_basic(blockType) || block_is_rainbow(blockType))

func block_can_swap(blockType):
	return block_can_combo(blockType) || block_is_special(blockType)

func blocks_match(blockTypeA, blockTypeB):
	var aCanMatch = block_can_combo(blockTypeA)
	var bCanMatch = block_can_combo(blockTypeB)
	
	if aCanMatch && bCanMatch:
		var aIsBasic = block_is_basic(blockTypeA)
		var bIsBasic = block_is_basic(blockTypeB)

		if aIsBasic && bIsBasic:
			return (blockTypeA == blockTypeB)
		else:
			return true

	return false

func blocks_match_3(blockTypeA, blockTypeB, blockTypeC):
	var aCanMatch = block_can_combo(blockTypeA)
	var bCanMatch = block_can_combo(blockTypeB)
	var cCanMatch = block_can_combo(blockTypeC)
	
	if aCanMatch && bCanMatch && cCanMatch:
		var aIsBasic = block_is_basic(blockTypeA)
		var bIsBasic = block_is_basic(blockTypeB)
		var cIsBasic = block_is_basic(blockTypeC)
		
		if aIsBasic && bIsBasic && cIsBasic:
			return ((blockTypeA == blockTypeB) && (blockTypeB == blockTypeC))
		elif aIsBasic || bIsBasic || cIsBasic:
			var basicTypes = []
			if aIsBasic && !basicTypes.has(blockTypeA): basicTypes.append(blockTypeA)
			if bIsBasic && !basicTypes.has(blockTypeB): basicTypes.append(blockTypeB)
			if cIsBasic && !basicTypes.has(blockTypeC): basicTypes.append(blockTypeC)
			
			return (basicTypes.size() <= 1)
		else:
			return true # all rainbows baby
	
	return false

func blocks_match_4(blockTypeA, blockTypeB, blockTypeC, blockTypeD):
	var aCanMatch = block_can_combo(blockTypeA)
	var bCanMatch = block_can_combo(blockTypeB)
	var cCanMatch = block_can_combo(blockTypeC)
	var dCanMatch = block_can_combo(blockTypeD)
	
	if aCanMatch && bCanMatch && cCanMatch && dCanMatch:
		var aIsBasic = block_is_basic(blockTypeA); var bIsBasic = block_is_basic(blockTypeB)
		var cIsBasic = block_is_basic(blockTypeC); var dIsBasic = block_is_basic(blockTypeD)
		
		if aIsBasic && bIsBasic && cIsBasic && dIsBasic:
			var abMatch = (blockTypeA == blockTypeB)
			var cdMatch = (blockTypeC == blockTypeD)
			var adMatch = (blockTypeA == blockTypeD)
			
			return (abMatch && cdMatch && adMatch)
		elif aIsBasic || bIsBasic || cIsBasic || dIsBasic:
			var basicTypes = []
			if aIsBasic && !basicTypes.has(blockTypeA): basicTypes.append(blockTypeA)
			if bIsBasic && !basicTypes.has(blockTypeB): basicTypes.append(blockTypeB)
			if cIsBasic && !basicTypes.has(blockTypeC): basicTypes.append(blockTypeC)
			if dIsBasic && !basicTypes.has(blockTypeD): basicTypes.append(blockTypeD)
			
			return (basicTypes.size() <= 1)
		else:
			return true # all rainbows baby
	
	return false

const DIR_LEFT  = 0; const DIR_ABOVE = 1
const DIR_RIGHT = 2; const DIR_BELOW = 3
const DIR_NONE  = 4

var dirRange = range(DIR_LEFT, DIR_BELOW + 1)

func opposite_direction(dir):
	match(dir):
		DIR_LEFT:  return DIR_RIGHT
		DIR_ABOVE: return DIR_BELOW
		DIR_RIGHT: return DIR_LEFT
		DIR_BELOW: return DIR_ABOVE
	
	return DIR_NONE

func name_from_direction(direction):
	match direction:
		DIR_LEFT:  return "Left"
		DIR_ABOVE: return "Above"
		DIR_RIGHT: return "Right"
		DIR_BELOW: return "Below"
		DIR_NONE:  return "None"
	
	return "Unknown"

func async_wait(sec):
	await get_tree().create_timer(sec).timeout
