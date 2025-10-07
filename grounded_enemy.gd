extends CharacterBody2D

# --- VARIABLES
@export var SPEED: float = 150.0
@export var JUMP_FORCE: float = - 450.0
@export var GRAVITY: float = 900.0
@export var NEXT_POINT_DISTANCE: float = 50.0
@export var jump_threshold: float = -50.0

var astar_grid: AStarGrid2D # à initialisation dans la scène principale
var path: PackedVector2Array = []
var path_index: int = 0
#var WAYPOINTS: Array[Vector2] = []

@onready var tilemap: TileMap = $"NavigationRegion2D/TileMap"
#@onready var astar_grid: AStarGrid2D = get_node("/root/World").get("astar_grid")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Référence au noeud Navigation Agent 2D
#@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

func _ready() -> void:
	# Attendre de charger les frames
	await get_tree().physics_frame
	
	if tilemap == null:
		push_error("TileMap introuvable. Vérifie le chemin")
		return
		
	if astar_grid == null:
		push_error("AStarGrid2D introuvable. Vérifie le chemin")
		return
	
	# Récupère la grid depuis le parent
	var world_node = get_parent().get_parent()
	if world_node.has_method("get_astar_grid"):
		astar_grid = world_node.get_astar_grid()
	else:
		push_error("Impossible de trouver la référence AStarGrid2D sur le nœud parent.")
		return

	astar_grid = get_parent().get("astar_grid")
	
	# Définit les points de départ et d'arrivée
	var start_cell: Vector2i = world_to_grid(global_position)
	var end_cell: Vector2i = Vector2i(66,10)
	
	# Calcule de chemin en coordonnées
	path = astar_grid.get_point_path(start_cell, end_cell)
	path_index = 0

func physics_process(delta: float) -> void:

	# Vérification de fin de chemin
	if path.is_empty() or path_index >= path.size():
		velocity.x = 0
		move_and_slide()
		return
		
	# Appliquer la gravité
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		
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
	var target_cell := world_to_grid(target)
	var cost := astar_grid.get_point_weight_scale(target_cell)
	
	# Vérifie si le coût de ce point correspond au coût que vous avez défini pour le saut (ex: 2.5)
	if is_on_floor() and (cost > 1.0 or target.y < global_position.y + jump_threshold):
		# Déclencher le saut si le point A* est marqué comme un point de saut
		velocity.y = JUMP_FORCE
	
	# Mouvement horizontal
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
