extends Node

# 存储池：{ "资源路径": [Node, Node, ...] }
var _pools: Dictionary = {}

# 从池中提取对象
func get_object(scene: PackedScene) -> Node:
	var path = scene.resource_path
	
	if _pools.has(path) and _pools[path].size() > 0:
		var obj = _pools[path].pop_back()
		
		# 恢复节点的处理能力
		obj.process_mode = PROCESS_MODE_INHERIT 
		obj.show()
		return obj
	
	# 如果池子为空，创建新实例
	var new_obj = scene.instantiate()
	new_obj.set_meta("scene_path", path)
	return new_obj

# 将对象还回池子
func return_object(obj: Node) -> void:
	var path = obj.get_meta("scene_path", "")
	if path == "":
		obj.queue_free() # 如果不是通过池生成的，直接销毁
		return
		
	if not _pools.has(path):
		_pools[path] = []
		
	# 停止节点的所有处理（防止在池子里还会移动或攻击）
	obj.process_mode = PROCESS_MODE_DISABLED
	obj.hide()
	
	# 从当前的房间层级中移除，挂载到 PoolManager 下统一管理
	if obj.get_parent():
		obj.get_parent().remove_child(obj)
	
	_pools[path].append(obj)
