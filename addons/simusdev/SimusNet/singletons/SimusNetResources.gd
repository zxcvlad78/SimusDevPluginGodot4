extends SimusNetSingletonChild
class_name SimusNetResources

static var _instance: SimusNetResources

var _hash: SimusNetHashedValues = SimusNetHashedValues.new()

static func get_hash() -> SimusNetHashedValues:
	return _instance._hash

static func get_cached() -> PackedStringArray:
	return SimusNetCache.data_get_or_add("r", PackedStringArray())

func initialize() -> void:
	_instance = self
	SimusNetEvents.event_connected_pre.listen(_on_connected_pre)
	SimusNetEvents.event_disconnected.listen(_on_disconnected)

func _on_disconnected() -> void:
	_hash.clear()

func _on_connected_pre() -> void:
	var folders_to_hash: PackedStringArray = singleton.settings.hashing_resource_folders_to_hash
	var hashed_files: int = 0
	
	for folder: String in folders_to_hash:
		var files: Array[String] = SimusNetFileSystem.get_all_files(folder)
		for file in files:
			hashed_files += 1
			_hash.put_string(file)
	
	if hashed_files > 0:
		logger.debug("Hashed %s resources." % hashed_files)

static func get_unique_path(resource: Resource) -> String:
	var uuid: String = ""
	if !resource.resource_path.is_empty():
		uuid = resource.resource_path
		#uuid = ResourceUID.path_to_uid(resource.resource_path)
	if uuid.is_empty():
		_instance.logger.push_error("failed get unique path: %s, %s" % [resource, resource.resource_path])
	return uuid

static func get_unique_id(resource: Resource) -> int:
	var uuid: String = get_unique_path(resource)
	var id: int = get_cached().find(uuid)
	#if id < 0:
		#_instance.logger.push_warning("cached unique id was not found: %s" % resource)
	return id

static func get_unique_id_by_path(path: String) -> int:
	var id: int = get_cached().find(path)
	return id

static func get_path_by_unique_id(id: int) -> String:
	var result: String = get_cached().get(id)
	return result

static func get_path_by_unique_id_async(id: int, timeout_ms: int = 5000) -> String:
	var start_time: int = Time.get_ticks_msec()
	var result: String = get_cached().get(id)
	
	while result.is_empty() and Time.get_ticks_msec() - start_time < timeout_ms:
		await _instance.get_tree().physics_frame
		result = get_cached().get(id)
	
	return result 

static func get_unique_id_by_path_async(path: String, timeout_ms: int = 5000) -> int:
	var start_time: int = Time.get_ticks_msec()
	var id: int = get_cached().find(path)
	while id < 0 and Time.get_ticks_msec() - start_time < timeout_ms:
		await _instance.get_tree().physics_frame
		id = get_cached().find(path)
	return id
