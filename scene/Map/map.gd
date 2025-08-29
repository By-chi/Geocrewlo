extends TileMapLayer
var astar:=AStarGrid2D.new()
var empty_tiles:PackedVector2Array
func _ready() -> void:
	scale=Vector2(48,48)
	astar.region=get_used_rect()
	astar.cell_size=tile_set.tile_size
	astar.default_compute_heuristic=AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic=AStarGrid2D.HEURISTIC_OCTILE
	astar.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ALWAYS
	
	astar.update()
	for x in get_used_rect().size.x:
		for y in get_used_rect().size.y:
			var tile_data = get_cell_tile_data(Vector2i(x,y))
			if tile_data!=null:
				astar.set_point_solid(Vector2i(x,y))
			else:
				astar.set_point_solid(Vector2i(x,y),false)
				empty_tiles.append(Vector2i(x,y))
