extends Node2D

var screenSize = Vector2(0, 0)
var scoreLabel = null; var refreshLabel = null
var refreshAnim = false; var refreshAnimTime = 0.0

func load_level(level):
	Board.load_level(level, screenSize, (z_index + 1))

func _ready():
	randomize();
	scoreLabel = $Lbl_Score; refreshLabel = $Lbl_Refresh
	
	screenSize = get_viewport().get_visible_rect().size
	$Background.set_size(screenSize)
	
	Board.score_changed.connect(_on_score_changed)
	Board.move_count_changed.connect(_on_move_count_changed)
	Board.refreshing_board.connect(_on_refreshing_board)
	
	load_level(LevelList.level_10)
	
	var spaceLeft = screenSize.y - Grid.get_size().y
	scoreLabel.set_size(Vector2(screenSize.x, spaceLeft / 2))
	scoreLabel.set_position(Vector2(0, 0))
	
	refreshLabel.set_visible(false)
	refreshLabel.set_size(Vector2(screenSize.x, Grid.get_size().y))
	refreshLabel.set_position(Vector2(0, Grid.get_top_left().y))
	refreshLabel.set_pivot_offset(refreshLabel.get_rect().size / 2)
	refreshLabel.set_z_index(z_index + 5)

func _input(event):
	Board.handle_input(event)

func _process(delta):
	progress_refresh_anim(delta)

func start_refresh_anim():
	refreshLabel.set_scale(Vector2(0.0, 0.0))
	refreshLabel.set_rotation(0); refreshLabel.set_visible(true)
	refreshAnim = true; refreshAnimTime = 0.0

func progress_refresh_anim(delta):
	if refreshAnim:
		refreshAnimTime = clamp(refreshAnimTime + delta, 0.0, Globals.REFRESH_ANIM_TIME)
		refreshLabel.set_rotation(sin(refreshAnimTime * 30.0) / 6.0)
		
		var halfwayTime = Globals.REFRESH_ANIM_TIME / 2.0
		if refreshAnimTime < halfwayTime:
			var t = refreshAnimTime / halfwayTime
			refreshLabel.set_scale(Vector2(0, 0).lerp(Vector2(1, 1), t))
		elif refreshAnimTime < Globals.REFRESH_ANIM_TIME:
			var t = (refreshAnimTime - halfwayTime) / halfwayTime
			refreshLabel.set_scale(Vector2(1, 1).lerp(Vector2(0, 0), t))
		else:
			refreshLabel.set_visible(false)
			refreshAnim = false

func _on_score_changed(oldScore, newScore):
	scoreLabel.set_text("%d" % newScore)

func _on_move_count_changed(oldMoveCount, newMoveCount):
	print("moves: %d" % newMoveCount)

func _on_refreshing_board():
	start_refresh_anim()

func _on_btn_clear_pressed():
	load_level(LevelList.level_5)
	#Board.soft_clear()

func _on_btn_shuffle_pressed():
	load_level(LevelList.level_6)
	#Board.shuffle()
	#get_tree().paused = true
