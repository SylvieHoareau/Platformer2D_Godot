extends Node2D

# Charger le script de la scène du joueur
const PLAYER_SCENE = preload("res://scenes/Player.tscn")

# Variables pour suivre quels joueurs ont été spawnés
var player1_spawned = false
var player2_spawned = false

# Points de spawn (voir éditeur)
@export var spawn_point_1: Marker2D
@export var spawn_point_2: Marker2D

var astar_grid = AStarGrid2D.new()
var path: PackedVector2Array = []
var path_index: int = 0

@onready var tilemap: TileMap = $"NavigationRegion2D/TileMap"
const TILEMAP_LAYER = 0

func _ready() -> void:
	if tilemap == null:
		push_error("TileMap introuvable ! Vérifie le chemin.")
		
	# Récupère la grid depuis le parent
	var world_node = get_parent().get_parent()
	if world_node.has_method("get_astar_grid"):
		astar_grid = world_node.get_astar_grid()
	else:
		astar_grid = world_node.astar_grid

	astar_grid = get_parent().get("astar_grid")	
	config_astar_grid()
	calculate_path(global_position, grid_to_world(Vector2i(66, 10)))

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
	
func config_astar_grid() -> void:
	var used_rect = tilemap.get_used_rect()
	# Définir la région de la grille
	astar_grid.region = Rect2i(0, 0, tilemap.get_used_rect().size.x, tilemap.get_used_rect().size.y)	
	# Définir la taille de chaque cellule
	astar_grid.cell_size = tilemap.tile_set.tile_size
	
	# Mettre à jour la grille pour appliquer les paramètres
	astar_grid.update()
	
	# Marquer les obstacles
	for x in range(used_rect.position.x, used_rect.end.x):
		for y in range(used_rect.position.y, used_rect.end.y):
			var cell = Vector2i(x, y)
			# Vérifier si la cellule a une tuile dessinée
			if tilemap.get_cell_source_id(TILEMAP_LAYER, cell) != -1:
				astar_grid.set_point_solid(cell, true)
	
	# Coordonnées de grille
	print("Coordonnées de grille :", astar_grid.get_id_path(Vector2i(0, 0), Vector2i(3, 4))) # Prints [(0, 0), (1, 1), (2, 2), (3, 3), (3, 4)]
	# Coordonnées du monde
	print("Coordonnées du monde :", astar_grid.get_point_path(Vector2i(0, 0), Vector2i(3, 4))) # Prints [(0, 0), (16, 16), (32, 32), (48, 48), (48, 64)]
	# Définir les paramétres spécifiques pour marquer les points
	astar_grid.set_point_solid(Vector2i(44, 20), false)
	astar_grid.set_point_weight_scale(Vector2i(53, 17), 2.5) # Coût le plus élevé
	astar_grid.set_point_weight_scale(Vector2i(53, 17), 2.5)
	astar_grid.set_point_weight_scale(Vector2i(60, 14), 2.5)
	
	print("Configuration AStarGrid2D terminée. Région:", astar_grid.region)

func get_astar_grid() -> AStarGrid2D:
	return astar_grid

func world_to_grid(pos: Vector2) -> Vector2i:
	return tilemap.local_to_map(tilemap.to_local(pos))

func grid_to_world(cell: Vector2i) -> Vector2:
	return tilemap.to_global(tilemap.map_to_local(cell))

func calculate_path(from_world: Vector2, to_world: Vector2) -> void:
	var from_cell := world_to_grid(from_world)
	var to_cell := world_to_grid(to_world)
	path = astar_grid.get_point_path(from_cell, to_cell)
	path_index = 0
