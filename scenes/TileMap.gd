extends TileMap

func get_layer_by_name(name:String) -> int:
	for i in get_layers_count():
		if get_layer_name(i) == name:
			return i
	return -1

func get_tile_position_under_mouse() -> Vector2i:
	var mouse_global = get_global_mouse_position()
	var mouse_local = self.to_local(mouse_global)
	return self.local_to_map(mouse_local)

func get_local_rect_position() -> Vector2:
	var rect:Rect2i = get_used_rect()
	return (map_to_local(rect.position) + map_to_local(rect.position - Vector2i(1, 1))) * 0.5

func get_local_rect_size() -> Vector2:
	var rect:Rect2i = get_used_rect()
	var end:Vector2 = (map_to_local(rect.end) + map_to_local(rect.end - Vector2i(1, 1))) * 0.5
	return end - get_local_rect_position()

func get_local_rect() -> Rect2:
	return Rect2(get_local_rect_position(), get_local_rect_size())

func get_global_rect() -> Rect2:
	return Rect2(to_global(get_local_rect_position()), to_global(get_local_rect_size()))

func get_global_center() -> Vector2:
	return get_global_rect().get_center()
