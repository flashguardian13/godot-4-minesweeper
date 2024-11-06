extends MarginContainer

const ATLAS_POS_NUMERIC:Array = [
	Vector2i(1, 2),
	Vector2i(0, 0),
	Vector2i(1, 0),
	Vector2i(2, 0),
	Vector2i(3, 0),
	Vector2i(0, 1),
	Vector2i(1, 1),
	Vector2i(2, 1),
	Vector2i(3, 1)
]
const ATLAS_POS_SKULL:Vector2i = Vector2i(0, 2)
const ATLAS_POS_TREASURE:Vector2i = Vector2i(2, 2)
const ATLAS_POS_COVERED:Vector2i = Vector2i(3, 2)

const CELL_NEIGHBORS:Array = [
	TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,     # (-1, -1)
	TileSet.CELL_NEIGHBOR_TOP_SIDE,            # (0, -1)
	TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,    # (1, -1)
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE,          # (1, 0)
	TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, # (1, 1)
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,         # (0, 1)
	TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,  # (-1, 1)
	TileSet.CELL_NEIGHBOR_LEFT_SIDE            # (-1, 0)
]

var tileset_source_id:int = 0

var mine_positions:Array = []
var revealed_positions:Array = []
var flagged_positions:Array = []
var is_game_over:bool = true

func _ready():
	update_flagged_label()
	var popup:Popup = $GameSetupPopup
	popup.popup_centered()

func _input(event):
	if is_game_over:
		return
	if is_instance_of(event, InputEventMouseButton):
		var mouse_button_event:InputEventMouseButton = event
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button_event.pressed:
				_on_left_mouse_pressed_input_event()
		elif mouse_button_event.button_index == MOUSE_BUTTON_RIGHT:
			if mouse_button_event.pressed:
				_on_right_mouse_pressed_input_event()

func _on_left_mouse_pressed_input_event() -> void:
	var tile_map:TileMap = $VBoxContainer/SubViewportContainer/SubViewport/TileMap
	var tile_pos:Vector2i = tile_map.get_tile_position_under_mouse()
	# Stop if out-of-bounds
	if !tile_map.get_used_rect().has_point(tile_pos):
		return
	reveal_cell(tile_pos)

func _on_right_mouse_pressed_input_event() -> void:
	# Get the tile position which was clicked
	var tile_map:TileMap = $VBoxContainer/SubViewportContainer/SubViewport/TileMap
	var tile_pos:Vector2i = tile_map.get_tile_position_under_mouse()
	# Stop if out-of-bounds
	if !tile_map.get_used_rect().has_point(tile_pos):
		return
	if revealed_positions.has(tile_pos):
		# Auto-reveal unflagged neighbors if neighboring mine count == neighboring flags
		var mine_count:int = count_neighboring_mines(tile_pos)
		var flag_count:int = count_neighboring_flags(tile_pos)
		if flag_count == mine_count:
			for side in CELL_NEIGHBORS:
				var neighbor_pos:Vector2i = tile_map.get_neighbor_cell(tile_pos, side)
				if tile_map.get_used_rect().has_point(neighbor_pos) && !flagged_positions.has(neighbor_pos):
					reveal_cell(neighbor_pos)
	else:
		if flagged_positions.has(tile_pos):
			# Unflag the cell
			tile_map.set_cell(0, tile_pos, tileset_source_id, ATLAS_POS_COVERED)
			flagged_positions.erase(tile_pos)
			update_flagged_label()
		else:
			# Flag the cell
			tile_map.set_cell(0, tile_pos, tileset_source_id, ATLAS_POS_TREASURE)
			flagged_positions.push_back(tile_pos)
			update_flagged_label()

func count_neighboring_mines(tile_pos:Vector2i) -> int:
	var tile_map:TileMap = $VBoxContainer/SubViewportContainer/SubViewport/TileMap
	var mine_count:int = 0
	for side in CELL_NEIGHBORS:
		var neighbor_pos:Vector2i = tile_map.get_neighbor_cell(tile_pos, side)
		if tile_map.get_used_rect().has_point(neighbor_pos) && mine_positions.has(neighbor_pos):
			mine_count += 1
	return mine_count

func count_neighboring_flags(tile_pos:Vector2i) -> int:
	var tile_map:TileMap = $VBoxContainer/SubViewportContainer/SubViewport/TileMap
	var flag_count:int = 0
	for side in CELL_NEIGHBORS:
		var neighbor_pos:Vector2i = tile_map.get_neighbor_cell(tile_pos, side)
		if tile_map.get_used_rect().has_point(neighbor_pos) && flagged_positions.has(neighbor_pos):
			flag_count += 1
	return flag_count

func reveal_cell(tile_pos:Vector2i) -> void:
	# Stop if already revealed
	if revealed_positions.has(tile_pos):
		return
	# Stop if flagged
	if flagged_positions.has(tile_pos):
		return
	# Reveal the cell contents
	var tile_map:TileMap = $VBoxContainer/SubViewportContainer/SubViewport/TileMap
	if mine_positions.has(tile_pos):
		tile_map.set_cell(0, tile_pos, tileset_source_id, ATLAS_POS_SKULL)
		revealed_positions.push_back(tile_pos)
		# Reveal all remaining mines
		for pos in mine_positions:
			if !flagged_positions.has(pos):
				tile_map.set_cell(0, pos, tileset_source_id, ATLAS_POS_SKULL)
				revealed_positions.push_back(pos)
		is_game_over = true
		var lbl:Label = $CanvasLayer/CenterContainer/GameOverLabel
		lbl.text = "Lose!"
		lbl.visible = true
	else:
		# Count nearby mines
		var mine_count:int = count_neighboring_mines(tile_pos)
		# Reveal neighboring mine count
		tile_map.set_cell(0, tile_pos, tileset_source_id, ATLAS_POS_NUMERIC[mine_count])
		revealed_positions.push_back(tile_pos)
		# If the flagged/covered cell count equals the number of mines,
		# we can be certain of the mines' positions and have won!
		if mine_positions.size() == tile_map.get_used_rect().get_area() - revealed_positions.size():
			# Flag all remaining mines
			for pos in mine_positions:
				if !flagged_positions.has(pos):
					tile_map.set_cell(0, pos, tileset_source_id, ATLAS_POS_TREASURE)
					flagged_positions.push_back(pos)
			update_flagged_label()
			is_game_over = true
			var lbl:Label = $CanvasLayer/CenterContainer/GameOverLabel
			lbl.text = "Win!"
			lbl.visible = true
			$CanvasLayer/CPUParticles2D.emitting = true
		# If our mine count is zero, reveal neighboring cells
		if mine_count <= 0:
			for side in CELL_NEIGHBORS:
				var neighbor_pos:Vector2i = tile_map.get_neighbor_cell(tile_pos, side)
				if tile_map.get_used_rect().has_point(neighbor_pos):
					reveal_cell(neighbor_pos)

func update_flagged_label() -> void:
	var lbl:Label = $VBoxContainer/PanelContainer/MarginContainer/FlaggedLabel
	lbl.text = "Mines Flagged: %d of %d" % [flagged_positions.size(), mine_positions.size()]

func _on_new_game_button_pressed():
	var popup:Popup = $GameSetupPopup
	popup.popup_centered()

func create_new_game(rows:int, columns:int, mines:int) -> void:
	# Sanitize
	rows = clampi(rows, 1, rows)
	columns = clampi(columns, 1, columns)
	mines = clampi(mines, 1, rows * columns - 1)
	# Reset State
	mine_positions.clear()
	revealed_positions.clear()
	flagged_positions.clear()
	# Cover all tiles
	var tile_map:TileMap = $VBoxContainer/SubViewportContainer/SubViewport/TileMap
	tile_map.clear()
	for ty in range(0, rows):
		for tx in range(0, columns):
			tile_map.set_cell(0, Vector2i(tx, ty), tileset_source_id, ATLAS_POS_COVERED)
	# Center the camera on the board
	tile_map.scale = Vector2(1, 1)
	var cam:Camera2D = $VBoxContainer/SubViewportContainer/SubViewport/TileMap/Camera2D
	cam.global_position = tile_map.get_global_center()
	# Scale the board to fit on screen
	while true:
		var board_rect:Rect2 = tile_map.get_global_rect()
		var screen_rect:Rect2 = $VBoxContainer/SubViewportContainer/SubViewport.get_visible_rect()
		if screen_rect.encloses(board_rect):
			break
		else:
			tile_map.apply_scale(Vector2(0.9, 0.9))
			cam.global_position = tile_map.get_global_center()
	# Determine mine positions
	mine_positions = tile_map.get_used_cells(0)
	mine_positions.shuffle()
	mine_positions.resize(mines)
	# Update UI
	update_flagged_label()
	# Play!
	is_game_over = false
	var lbl:Label = $CanvasLayer/CenterContainer/GameOverLabel
	lbl.visible = false
	$CanvasLayer/CPUParticles2D.emitting = false

func _on_play_button_pressed():
	var popup:Popup = $GameSetupPopup
	popup.hide()
	var gc:GridContainer = popup.get_node("MarginContainer/VBoxContainer/GridContainer")
	var rows:int = int(gc.get_node("RowsLineEdit").text)
	var columns:int = int(gc.get_node("ColumnsLineEdit").text)
	var mines:int = int(gc.get_node("MinesLineEdit").text)
	create_new_game(rows, columns, mines)

func _on_theme_option_button_item_selected(index):
	tileset_source_id = index
