extends Node2D

# Charger le script de la scène du joueur
const PLAYER_SCENE = preload("res://scenes/Player.tscn")

# Variables pour suivre quels joueurs ont été spawnés
var player1_spawned = false
var player2_spawned = false

# Points de spawn (voir éditeur)
@export var spawn_point_1: Marker2D
@export var spawn_point_2: Marker2D

func _unhandled_input(event: InputEvent) -> void:
	# Spawn du Joueur 1 (par exemple avec la touche 'Enter')
	if event.is_action_pressed("ui_accept") and not player1_spawned:
		spawn_player(1, spawn_point_1.position)
		player1_spawned = true

	# Spawn du Joueur 2 (par exemple avec la touche 'Space')
	# Assure-toi que "p2_spawn" est configurée dans Project Settings -> Input Map
	if event.is_action_pressed("p2_spawn") and not player2_spawned:
		spawn_player(2, spawn_point_2.position)
		player2_spawned = true
		
# --- Fonction pour instancier et ajouter le joueur ---
func spawn_player(id: int, position: Vector2) -> void:
	# Instanciation
	var new_player = PLAYER_SCENE.instantiate()

	# Configuration du joueur (très important !)
	# Variable 'player_id' définie dans ton script de joueur
	new_player.player_id = id 

	# Définir la position
	new_player.position = position
	
	add_child(new_player)
	
	print("Joueur %d a été spawné à la position %s" % [id, position])	
