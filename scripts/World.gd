extends Node2D

# Script world.gd

# Charger le script de la scène du joueur
const PLAYER_SCENE = preload("res://scenes/Player.tscn")
# Charger les scripts des ennemis
const GROUNDED_ENEMY_SCENE = preload("res://scenes/GroundedEnemy.tscn")
const FLYING_ENEMY_SCENE = preload("res://scenes/FlyingEnemy.tscn")

# Hauteur maximale de saut
const MAX_JUMP_HEIGHT = 4
# Distance horizontale maximale de saut
const MAX_JUMP_DISTANCE = 4

# Variables pour suivre quels joueurs ont été spawnés
var player1_spawned = false
var player2_spawned = false

# Points de spawn (voir éditeur)
@export var spawn_point_1: Marker2D
@export var spawn_point_2: Marker2D

var astar_grid = AStarGrid2D.new()
var path: PackedVector2Array = []
var path_index: int = 0
var grid_origin = Vector2i(0, 0)

@onready var tilemap_layer: TileMapLayer = $"TileMapLayer"
const TILEMAP_LAYER = 0

func _ready() -> void:
	if tilemap_layer == null:
		push_error("TileMap introuvable ! Vérifie le chemin.")
		return
	
	config_astar_grid()
	calculate_path(global_position, grid_to_world(Vector2i(66, 10)))
	
	# Spawn du Grounded Enemy
	# Le Grounded Enemy aura besoin de l'AStar Grid
	if spawn_point_1 != null:
		spawn_entity(GROUNDED_ENEMY_SCENE, spawn_point_1.position)
	
	# Spawn du Flying Enemy
	# Le Flying Enemy n'aura pas besoin de l'Astar Grid
	if spawn_point_2 != null:
		# Décaler légèrement la position
		var flying_spawn_pos = spawn_point_2.position + Vector2(0, -100)
		spawn_entity(FLYING_ENEMY_SCENE, flying_spawn_pos)

func _unhandled_input(event: InputEvent) -> void:
	# Spawn du Joueur 1 (par exemple avec la touche 'Enter')
	if event.is_action_pressed("ui_accept") and not player1_spawned:
		#spawn_player(1, spawn_point_1.position)
		spawn_entity(PLAYER_SCENE, spawn_point_1.position, 1)
		player1_spawned = true

	# Spawn du Joueur 2 (par exemple avec la touche 'Space')
	# Assure-toi que "p2_spawn" est configurée dans Project Settings -> Input Map
	if event.is_action_pressed("p2_spawn") and not player2_spawned:
		#spawn_player(2, spawn_point_2.position)
		spawn_entity(PLAYER_SCENE, spawn_point_2.position, 2)
		player2_spawned = true
		
# --- Fonction pour instancier et ajouter le joueur ---
#func spawn_player(id: int, position: Vector2) -> void:
	# Instanciation
	#var new_player = PLAYER_SCENE.instantiate()

	# Configuration du joueur (très important !)
	# Variable 'player_id' définie dans ton script de joueur
	#new_player.player_id = id 

	# Définir la position
	#new_player.position = position
	
	#add_child(new_player)
	
	#print("Joueur %d a été spawné à la position %s" % [id, position])	

# -- Fonction générique pour spawner les entités Player ou Enemy --
func spawn_entity(scene: PackedScene, position: Vector2, id: int = 0) -> void:
	var new_entity = scene.instantiate()
	
	# Si l'entité a besoin de la logique de pathfinding
	if new_entity.has_method("set_astar_dependencies"):
		new_entity.set_astar_dependencies(astar_grid, grid_origin)
		
	# Si c'est un joueur, affecter son ID
	if id != 0:
		if new_entity.has_method("set_player_id"):
			new_entity.set_player_id(id)
		elif "player_id" in new_entity:
			new_entity.player_id = id
			
	
	# Définir la position et ajouter à la scène
	new_entity.position = position
	add_child(new_entity) # L'ennemi est dans le World et peut trouver la TileMap
	
	print("Entité '%s' a été spawné à la position %s" % [scene.resource_path.get_file(), position])


func config_astar_grid() -> void:
	var used_rect = tilemap_layer.get_used_rect()
	
	# Récupère le point de départ réel de la TileMap
	grid_origin = used_rect.position
	# Définir la région de la grille AStar
	astar_grid.region = Rect2i(0, 0, used_rect.size.x, used_rect.size.y)	
	# Définir la taille de chaque cellule
	astar_grid.cell_size = tilemap_layer.tile_set.tile_size
	# Mettre à jour la grille pour appliquer les paramètres
	astar_grid.update()
	
	# Marquer les obstacles (sols)
	for x in range(used_rect.position.x, used_rect.end.x):
		for y in range(used_rect.position.y, used_rect.end.y):
			var cell = Vector2i(x, y)
			# Conversion : La position dans l'AStarGrid est (cell - origin)
			var astar_cell = cell - grid_origin
			
			# Vérifier si la cellule a une tuile dessinée (dans le monde)
			if tilemap_layer.get_cell_source_id(cell) != -1:
				# Utiliser la coordonnée convertie pour l'AStarGrid
				astar_grid.set_point_solid(astar_cell, true)
			else:
				# Si le point est vide, on s'assure qu'il n'est pas solide
				astar_grid.set_point_solid(astar_cell, false)
			
			# Vérifier si la cellule a une tuile dessinée
			#if tilemap_layer.get_cell_source_id(cell) != -1:
				#astar_grid.set_point_solid(cell, true)
	# Créer les connexions de saut
	for x in range(used_rect.position.y, used_rect.end.x):
		for y in range(used_rect.position.y, used_rect.end.y):
			var current_cell = Vector2i(x, y)
			var astar_current_cell = current_cell - grid_origin
			
			# On cherche la tuile sous la position actuelle
			var ground_cell = current_cell + Vector2i(0, 1)
			var astar_ground_cell = ground_cell - grid_origin
			
			# Si le point actuel (astar_current_cell) est déjà solide ou n'a pas de sol en dessous
			if astar_grid.is_point_solid(astar_current_cell) or \
				not astar_grid.is_in_bounds(astar_ground_cell.x, astar_ground_cell.y) or \
				not astar_grid.is_point_solid(astar_ground_cell):
					continue
			
			# Créer les connexions de Marche et de Saut
			
			# MARCHE : Connexion aux voisins immédiats
			for dx in [-1, 1]:
				var walk_end_cell = current_cell + Vector2i(dx, 0)
				var astar_walk_end_cell = walk_end_cell - grid_origin
				
				# Vérifier si le point cible est valide
				if astar_grid.is_in_bounds(astar_walk_end_cell.x, astar_walk_end_cell.y) and \
					not astar_grid.is_point_solid(astar_walk_end_cell):
						
						# Vérifier qu'il y a un sol sous le point
						var walk_end_ground_cell = walk_end_cell + Vector2i(0,1)
						var astar_walk_end_ground_cell = walk_end_ground_cell - grid_origin
						
						if astar_grid.is_in_bounds(astar_walk_end_ground_cell.x, astar_walk_end_ground_cell.y) and \
					   		astar_grid.is_point_solid(astar_walk_end_ground_cell):
							# Connexion de marche (poids 1.0 par défaut)
							astar_grid.connect_points(astar_current_cell, astar_walk_end_cell, true)
			# SAUT : Connexions sur la portée de saut
			for dx in range(-MAX_JUMP_DISTANCE, MAX_JUMP_DISTANCE + 1):
				if dx == 0: continue
					
				for dy in range(-MAX_JUMP_HEIGHT, 2): # 2 car l'ennemi peut tomber (dy=1)
					# Pas besoin de vérifier (0, 0)
					if dx == 0 and dy == 0: continue
					
					var end_cell = current_cell + Vector2i(dx, dy)
					var astar_end_cell = end_cell - grid_origin # Point AStar END
					
					if not astar_grid.is_in_bounds(astar_end_cell.x, astar_end_cell.y):
						continue
					if astar_grid.is_point_solid(astar_end_cell):
						continue
					
					# Vérifier s'il y a un sol sous la cellule cible
					var end_ground_cell = end_cell + Vector2i(0, 1)
					var astar_end_ground_cell = end_ground_cell - grid_origin
					
					if astar_grid.is_in_bounds(astar_end_ground_cell.x, astar_end_ground_cell.y) and \
					   astar_grid.is_point_solid(astar_end_ground_cell): # CORRECTION: Utiliser astar_end_ground_cell
						
							# Connexion de saut/chute (poids plus élevé)
							astar_grid.connect_points(astar_current_cell, astar_end_cell, true, JUMP_EXTRA_WEIGHT)
						
	print("Configuration AStarGrid2D terminée. Région:", astar_grid.region)
	
	# ---- Fin des modifications ----
	
					
	# Coût supplémentaire pour un saut
	const JUMP_EXTRA_WEIGHT = 5.0
	for x in range(used_rect.position.x, used_rect.end.x):
		for y in range(used_rect.position.y, used_rect.end.y):
			var current_cell = Vector2i(x, y)
			
			# Conversion du point de la TileMpa au point de l'AstarGrid
			var astar_current_cell = current_cell - grid_origin
			
			# Ajout de connexion uniquement depuis un point de départ solide
			if astar_grid.is_point_solid(astar_current_cell):
				continue
				
			# On cherche la tuile sous la position actuelle
			var ground_cell = current_cell + Vector2i(0,1)
			
			# Conversion du point du sol au point de l'AStarGrid
			var astar_ground_cell = ground_cell - grid_origin
			
			# Vérifier si la tuile en dessous est un solide
			if not astar_grid.is_in_bounds(astar_ground_cell.x, astar_ground_cell.y) or not astar_grid.is_point_solid(astar_ground_cell):
				continue
				
			# La cellule de départ est le haut de la plateforme
			# C'est là que l'ennemi se tient
			var astar_start_cell = current_cell
			
			# On parcourt les cellules devant (à gauche et à droite)
			for dx in range(-MAX_JUMP_DISTANCE, MAX_JUMP_DISTANCE + 1):
				if dx == 0:
					continue
					
				# On parcourt les cellules en hauteur (vers le haut)
				for dy in range(-MAX_JUMP_HEIGHT, 2):
					if dx == 0 and dy == 0:
						continue
					var end_cell = Vector2i(x + dx, y + dy)
				
					# Conversion du point de fin au 
					var astar_end_cell = end_cell - grid_origin
					
					# Vérifie si la cellule cible est dans la grille
					if not astar_grid.is_in_bounds(astar_end_cell.x, astar_end_cell.y):
						continue
					
					# Vérifie si la cellule cible n'est pas un obstacle
					if astar_grid.is_point_solid(astar_end_cell):
						continue
					
					# Vérifie s'il y a un sol sous la cellule cible
					var end_ground_cell = end_cell + Vector2i(0, 1)
				
					var astar_end_ground_cell = end_ground_cell - grid_origin
					
					if astar_grid.is_in_bounds(astar_end_ground_cell.x, astar_end_ground_cell.y) and astar_grid.is_point_solid(end_ground_cell):
						# Si on arrive ici, c'est un point d'atterrissage valide
						astar_grid.connect_points(astar_start_cell, astar_end_cell, true, JUMP_EXTRA_WEIGHT)
				
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
	return tilemap_layer.local_to_map(tilemap_layer.to_local(pos)) - grid_origin

func grid_to_world(cell: Vector2i) -> Vector2:
	var tilemap_cell = cell + grid_origin
	return tilemap_layer.to_global(tilemap_layer.map_to_local(tilemap_cell))

func calculate_path(from_world: Vector2, to_world: Vector2) -> void:
	var from_cell := world_to_grid(from_world)
	var to_cell := world_to_grid(to_world)
	path = astar_grid.get_point_path(from_cell, to_cell)
	path_index = 0
