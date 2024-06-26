extends Node

const Blocks = preload("./blocks/blocks.gd")

const MAX_UPDATES_PER_FRAME = 64
const INTERVAL_SECONDS = 0.2
const MAX_SPREAD_DISTANCE = 8

const _spread_directions = [
	Vector3(-1, 0, 0),
	Vector3(1, 0, 0),
	Vector3(0, 0, -1),
	Vector3(0, 0, 1)
]

@onready var _terrain : VoxelTerrain = get_node("../VoxelTerrain")
@onready var _terrain_tool := _terrain.get_voxel_tool()
@onready var _blocks : Blocks = get_node("../Blocks")

class Queue:
	var _queue := []
	var _front := 0

	func push_back(item):
		_queue.append(item)

	func pop_front():
		if size() > 0:
			var item = _queue[_front]
			_front += 1
			return item
		return null

	func size():
		return len(_queue) - _front

var _update_queue := Queue.new()
var _process_queue := Queue.new()
var _scheduled_positions := {}
var _water_id : int = -1
var _water_top : int = -1
var _water_full : int = -1
var _time_before_next_process : float = 0.0


func _ready():
	_terrain_tool.set_channel(VoxelBuffer.CHANNEL_TYPE)
	var water = _blocks.get_block_by_name("water").base_info
	_water_id = water.id
	_water_full = water.voxels[0]
	_water_top = water.voxels[1]


func schedule(pos: Vector3, distance: int = 0):
	if _scheduled_positions.has(pos):
		return
	_scheduled_positions[pos] = true
	_update_queue.push_back({"position": pos, "distance": distance})


func _process(delta: float):
	_time_before_next_process -= delta
	if _time_before_next_process <= 0.0:
		_time_before_next_process += INTERVAL_SECONDS
		_do_process_queue()


func _do_process_queue():
	var update_count = 0

	while update_count < MAX_UPDATES_PER_FRAME and _process_queue.size() > 0:
		var item = _process_queue.pop_front()
		var pos = item["position"]
		var distance = item["distance"]
		_process_cell(pos, distance)
		_scheduled_positions.erase(pos)

		update_count += 1

	if _process_queue.size() == 0:
		_swap_queues()


func _swap_queues():
	var tmp := _update_queue
	_update_queue = _process_queue
	_process_queue = tmp


func _process_cell(pos: Vector3, distance: int):
	var v = _terrain_tool.get_voxel(pos)
	var rm = _blocks.get_raw_mapping(v)

	if rm.block_id != _water_id:
		return

	if v == _water_full:
		_fill_with_water(pos)

	if distance < MAX_SPREAD_DISTANCE:
		for di in _spread_directions:
			var npos = pos + di
			var nv = _terrain_tool.get_voxel(npos)
			if nv == Blocks.AIR_ID:
				_fill_with_water(npos)
				schedule(npos, distance + 1)


func _fill_with_water(pos: Vector3):
	var above = pos + Vector3(0, 1, 0)
	var below = pos - Vector3(0, 1, 0)
	var above_v = _terrain_tool.get_voxel(above)
	var below_v = _terrain_tool.get_voxel(below)
	var above_rm = _blocks.get_raw_mapping(above_v)

	if above_rm.block_id == _water_id:
		_terrain_tool.set_voxel(pos, _water_full)
	else:
		_terrain_tool.set_voxel(pos, _water_top)
	if below_v == Blocks.AIR_ID:
		_terrain_tool.set_voxel(below, _water_top)
	elif below_v != _water_full:
		var dir = Vector3.ZERO
		if _terrain_tool.get_voxel(pos + Vector3(-1, 0, 0)) == _water_full:
			dir = Vector3(-1, 0, 0)
		elif _terrain_tool.get_voxel(pos + Vector3(1, 0, 0)) == _water_full:
			dir = Vector3(1, 0, 0)
		elif _terrain_tool.get_voxel(pos + Vector3(0, 0, -1)) == _water_full:
			dir = Vector3(0, 0, -1)
		elif _terrain_tool.get_voxel(pos + Vector3(0, 0, 1)) == _water_full:
			dir = Vector3(0, 0, 1)

		if dir != Vector3.ZERO:
			_terrain_tool.set_voxel(below + dir, _water_top)

	schedule(pos)
