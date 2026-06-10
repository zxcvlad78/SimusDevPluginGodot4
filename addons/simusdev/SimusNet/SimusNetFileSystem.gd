@static_unload
class_name SimusNetFileSystem
extends RefCounted

# ============================================
# КОНСТАНТЫ
# ============================================

enum FileType {
	ALL,
	RESOURCE,      # .tres, .res
	SCENE,         # .tscn, .scn
	TEXTURE,       # .png, .jpg, .jpeg, .svg, .webp
	AUDIO,         # .ogg, .mp3, .wav
	SCRIPT,        # .gd, .cs
	MATERIAL,      # .tres (материалы), .res
	MESH,          # .obj, .gltf, .glb
	ANIMATION,     # .anim
	FONT,          # .ttf, .otf
	SHADER,        # .gdshader
	TRANSLATION,   # .po, .csv
	ANY            # Любой тип
}

# ============================================
# ОСНОВНЫЕ МЕТОДЫ
# ============================================

## Рекурсивно собирает все файлы в директории
static func get_all_files(directory: String, file_type: FileType = FileType.ALL, recursive: bool = true) -> Array[String]:
	var result: Array[String] = []
	var dir = DirAccess.open(directory)
	
	if dir == null:
		push_error("Failed to open directory: ", directory)
		return result
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = directory.path_join(file_name)
		
		if dir.current_is_dir() and recursive:
			# Рекурсивно обходим подпапку
			var sub_files = get_all_files(full_path, file_type, true)
			result.append_array(sub_files)
		elif not dir.current_is_dir():
			# Это файл, проверяем тип
			if _matches_file_type(full_path, file_type):
				result.append(full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return result

## Получить только файлы определенного расширения
static func get_files_by_extension(directory: String, extensions: Array[String], recursive: bool = true) -> Array[String]:
	var result: Array[String] = []
	var all_files = get_all_files(directory, FileType.ALL, recursive)
	
	for file in all_files:
		var ext = file.get_extension().to_lower()
		if extensions.has(ext):
			result.append(file)
	
	return result

## Получить все ресурсы (.tres, .res)
static func get_all_resources(directory: String, recursive: bool = true) -> Array[String]:
	return get_files_by_extension(directory, ["tres", "res"], recursive)

## Получить все сцены (.tscn, .scn)
static func get_all_scenes(directory: String, recursive: bool = true) -> Array[String]:
	return get_files_by_extension(directory, ["tscn", "scn"], recursive)

## Получить все текстуры (.png, .jpg, .jpeg, .svg, .webp)
static func get_all_textures(directory: String, recursive: bool = true) -> Array[String]:
	return get_files_by_extension(directory, ["png", "jpg", "jpeg", "svg", "webp"], recursive)

## Получить все скрипты (.gd, .cs)
static func get_all_scripts(directory: String, recursive: bool = true) -> Array[String]:
	return get_files_by_extension(directory, ["gd", "cs"], recursive)

# ============================================
# ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
# ============================================

static func _matches_file_type(file_path: String, file_type: FileType) -> bool:
	if file_type == FileType.ALL or file_type == FileType.ANY:
		return true
	
	var ext = file_path.get_extension().to_lower()
	
	match file_type:
		FileType.RESOURCE:
			return ext in ["tres", "res"]
		FileType.SCENE:
			return ext in ["tscn", "scn"]
		FileType.TEXTURE:
			return ext in ["png", "jpg", "jpeg", "svg", "webp"]
		FileType.AUDIO:
			return ext in ["ogg", "mp3", "wav"]
		FileType.SCRIPT:
			return ext in ["gd", "cs"]
		FileType.MATERIAL:
			return ext in ["tres", "res"]
		FileType.MESH:
			return ext in ["obj", "gltf", "glb"]
		FileType.ANIMATION:
			return ext == "anim"
		FileType.FONT:
			return ext in ["ttf", "otf"]
		FileType.SHADER:
			return ext == "gdshader"
		FileType.TRANSLATION:
			return ext in ["po", "csv"]
		_:
			return false

# ============================================
# КЭШИРОВАНИЕ (ДЛЯ БЫСТРОГО ДОСТУПА)
# ============================================

static var _cache: Dictionary = {}  # directory -> Array[String]

## Получить файлы с кэшированием (быстрее при повторных вызовах)
static func get_all_files_cached(directory: String, file_type: FileType = FileType.ALL, recursive: bool = true) -> Array[String]:
	var cache_key = directory + "_" + str(file_type) + "_" + str(recursive)
	
	if not _cache.has(cache_key):
		_cache[cache_key] = get_all_files(directory, file_type, recursive)
	
	return _cache[cache_key].duplicate()

## Очистить кэш
static func clear_cache():
	_cache.clear()

# ============================================
# СТАТИСТИКА
# ============================================

static func get_stats(directory: String, recursive: bool = true) -> Dictionary:
	var all_files = get_all_files(directory, FileType.ALL, recursive)
	var stats = {
		"total": all_files.size(),
		"resources": get_all_resources(directory, recursive).size(),
		"scenes": get_all_scenes(directory, recursive).size(),
		"textures": get_all_textures(directory, recursive).size(),
		"scripts": get_all_scripts(directory, recursive).size(),
		"other": 0
	}
	
	stats.other = stats.total - stats.resources - stats.scenes - stats.textures - stats.scripts
	return stats

# ============================================
# ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ
# ============================================

static func example():
	# Все файлы в папке res://assets/
	var all = get_all_files("res://assets/")
	print("All files: ", all.size())
	
	# Только ресурсы
	var resources = get_all_resources("res://assets/")
	print("Resources: ", resources.size())
	
	# Только текстуры
	var textures = get_all_textures("res://assets/")
	print("Textures: ", textures.size())
	
	# Файлы по расширениям
	var models = get_files_by_extension("res://assets/", ["obj", "gltf"])
	print("Models: ", models.size())
	
	# Статистика
	var stats = get_stats("res://assets/")
	print("Stats: ", stats)
