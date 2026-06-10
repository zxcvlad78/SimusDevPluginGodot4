@static_unload
class_name SimusNetHash
extends RefCounted

static func hash64(input: String) -> int:
	var h1 = input.hash()
	var h2 = (input + "_" + str(input.length())).hash()
	
	return (h1 & 0xFFFFFFFF) | ((h2 & 0xFFFFFFFF) << 32)

static func hash64_salted(input: String, salt: String = "SimusNet") -> int:
	var salted = input + "_" + salt
	return hash64(salted)

static func hash32(input: String) -> int:
	return input.hash()
