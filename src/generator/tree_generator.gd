const Structure = preload("./structure.gd")

var trunk_len_min : int = 4
var trunk_len_max : int = 8
var log_type : int = 1
var leaves_type : int = 2
var channel : VoxelBuffer.ChannelId = VoxelBuffer.CHANNEL_TYPE

func generate() -> Structure:
	var voxels := {}
	# Trunk
	var trunk_len := int(randf_range(trunk_len_min, trunk_len_max))
	for y in range(trunk_len):
		voxels[Vector3(0, y, 0)] = log_type

	# Leaves
	var leaves_start := trunk_len - 3
	var leaves_end := trunk_len + 2
	for y in range(leaves_start, leaves_end):
		if y < leaves_start + 2:
			# Square layers at the bottom
			for x in range(-2, 3):
				for z in range(-2, 3):
					if not (x == 0 and y == trunk_len and z == 0):  # Skip trunk position
						voxels[Vector3(x, y, z)] = leaves_type
		else:
			# Rounded layers on top
			var radius = 1 - abs(y - trunk_len)
			for x in range(-radius, radius + 1):
				for z in range(-radius, radius + 1):
					if x * x + z * z <= radius * radius:
						if not (x == 0 and y == trunk_len and z == 0):  # Skip trunk position
							voxels[Vector3(x, y, z)] = leaves_type

	# Make structure
	var aabb := AABB()
	for pos in voxels:
		aabb = aabb.expand(pos)

	var structure := Structure.new()
	structure.offset = -aabb.position

	var buffer := structure.voxels
	buffer.create(int(aabb.size.x) + 1, int(aabb.size.y) + 1, int(aabb.size.z) + 1)

	for pos in voxels:
		var rpos = pos + structure.offset
		var v = voxels[pos]
		buffer.set_voxel(v, rpos.x, rpos.y, rpos.z, channel)

	return structure
