extends CharacterBody2D

# Script : grounded_enemy.gd

# --- VARIABLES
@export var SPEED: float = 150.0
@export var JUMP_FORCE: float = - 450.0
@export var GRAVITY: float = 900.0
@export var NEXT_POINT_DISTANCE: float = 50.0
@export var JUMP_HEIGHT_THRESHOLD: float = -50.0

# Dépendances (Injectées par le World)
var astar_grid: AStarGrid2D # à initialisation dans la scène principale
var path: PackedVector2Array = []
var path_index: int = 0
var grid_origin = Vector2i(0, 0)
#var WAYPOINTS: Array[Vector2] = []

#var tilemap_node: TileMap
@onready var tilemap_layer: TileMapLayer = $"TileMapLayer"
#@onready var astar_grid: AStarGrid2D = get_node("/root/World").get("astar_grid")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Référence au noeud Navigation Agent 2D
#@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

func _ready() -> void:
	# Attendre de charger les frames
	await get_tree().physics_frame
	
	#var parent_node = get_parent()
	#if parent_node:
		#tilemap_node = parent_node.get_node("TileMapLayer")
	
	if tilemap_layer == null:
		push_error("TileMap introuvable. Vérifie le chemin")
		return
	
	# Vérifier les dépendances AStar doivent être injectées par le World
	if astar_grid == null:
		push_error("AStarGrid2D introuvable. Vérifie le chemin")
		return
	
	# Début du calcul de chemin
	
	# Définit les points de départ et d'arrivée
	# Point de départ
	var start_cell: Vector2i = world_to_grid(global_position)
	
	# Point d'arrivée
	var end_cell: Vector2i = Vector2i(66,10)
	
	# Calcul de chemin en coordonnées
	path = astar_grid.get_point_path(start_cell, end_cell)
	path_index = 0

# LOGIQUE DE MOUVEMENT AUTONOME
func physics_process(delta: float) -> void:
	# Appliquer la gravité
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Vérification de fin de chemin
	if path.is_empty() or path_index >= path.size():
		velocity.x = 0
		move_and_slide()
		return
		
	# Définir le prochain point (du chemin A*)
	var target := path[path_index]
	
	# Vérifier si l'ennemi a atteint le point actuel
	if global_position.distance_to(target) < NEXT_POINT_DISTANCE:
		# Passer au point suivant
		path_index += 1
		# Si on arrive à la fin du chemin, sortir.
		if path_index >= path.size():
			velocity.x = 0
			move_and_slide()
			return
		target = path[path_index] # Mise à jour vers la nouvelle cible
	
	# Calculer la direction vers le prochain point
	var direction := (target - global_position).normalized()
	
	# DÉCISION DE SAUT 
	if is_on_floor():
		# Taille d'une tuile pour la référence
		var tile_size = tilemap_layer.tile_set.tile_size.y
		var next_point_dist_x = abs(target.x - global_position.x)
	
		# Condition 1 : Sauter si la cible est significativement plus haute (si y est plus petit)
		if target.y < global_position.y - (tile_size * JUMP_HEIGHT_THRESHOLD):
			velocity.y = JUMP_FORCE
			# On met la vélocité horizontale ici
			velocity.x = direction.x * SPEED # Maintien de la vélocité horizontale pendant le saut
			move_and_slide()
			return # Sortir pour ne pas écraser la vélocité verticale
		
		# Condition 2 : Sauter si la cible est trop loin horizontalement
		elif next_point_dist_x > tile_size + 1.0:
			# Si la cible n'est pas trop basse (ex: moins d'une tuile de différence en Y)
			if target.y > global_position.y - tile_size: 
				velocity.y = JUMP_FORCE
				# On met la vélocité horizontale ici pour le saut
				velocity.x = direction.x * SPEED 
				move_and_slide()
				return
	
	# Mouvement horizontal Si on marche ou si on est en l'air sans sauter
	velocity.x = direction.x * SPEED # Maintien de la vélocité horizontale pendant le saut

	# Appliquer le mouvement
	move_and_slide()
	
	# Lire les animations
	if not is_on_floor():
		sprite.play("jump")
	elif abs(velocity.x > 10.0):
		sprite.play("walk")
	else:
		sprite.play("idle")
		
	sprite.flip_h = velocity.x <0

# FONCTIONS DE DEPENDANCE ET DE CONVERSION

# Injection de dépendance AStar
func set_astar_dependencies(astar: AStarGrid2D, origin: Vector2i) -> void:
	astar_grid = astar
	grid_origin = origin
	
#func get_astar_grid() -> AStarGrid2D:
	#return astar_grid

# Convertit une position du monde (Vector2) en coordonnées Astar (Vector2i)
func world_to_grid(pos: Vector2) -> Vector2i:
	# Convertir World -> TileMap (absolu)
	return tilemap_layer.local_to_map(tilemap_layer.to_local(pos))

# Convertit une coordonnées AStar (Vector2i) en position du monde (Vector2)
func grid_to_world(cell: Vector2i) -> Vector2:
	# Converir AStar (relative) -> TileMap
	var tilemap_cell = cell + grid_origin
	return tilemap_layer.to_global(tilemap_layer.map_to_local(cell))

# Fonction de recalcul du chemin
func calculate_path(from_world: Vector2, to_world: Vector2) -> void:
	var from_cell := world_to_grid(from_world)
	var to_cell := world_to_grid(to_world)
	if astar_grid:
		path = astar_grid.get_point_path(from_cell, to_cell)
		path_index = 0

	
