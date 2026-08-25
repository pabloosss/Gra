extends Node

var player_name := "Wędrowiec"
var class_id := "wojownik"
var class_name := "Wojownik"
var max_hp := 26
var hp := 26
var charisma := 1
var perception := 1
var description := "Twardy wojownik, który przeżyje tam, gdzie inni padną."

func set_character(data: Dictionary, new_name: String) -> void:
	player_name = new_name.strip_edges() if not new_name.strip_edges().is_empty() else "Wędrowiec"
	class_id = data.get("id", "wojownik")
	class_name = data.get("name", "Wojownik")
	max_hp = data.get("hp", 20)
	hp = max_hp
	charisma = data.get("cha", 0)
	perception = data.get("per", 0)
	description = data.get("description", "")
