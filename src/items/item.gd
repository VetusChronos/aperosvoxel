extends Node

class BaseInfo:
	var id : float = 0
	var name : String = ""
	var sprite : Texture

var base_info : BaseInfo = BaseInfo.new()


func use(_trans: Transform3D):
	pass
