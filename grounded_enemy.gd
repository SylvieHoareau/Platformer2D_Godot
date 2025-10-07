extends CharacterBody2D

# --- VARIABLES
@export var SPEED: float = 150.0
@export var JUMP_FORCE: float = - 450.0
@export var GRAVITY: float = 900.0
@export var jump_threshold: float = -50.0

var astar_grid: AStarGrid2D # à initialisation dans la scène principale
var path: PackedVector2Array = []
var path_index: int = 0
#var WAYPOINTS: Array[Vector2] = []
var velocity: Vector2 = Vector2.ZERO

# Référence au noeud Navigation Agent 2D
#@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

func _ready() -> void:
	# Attendre de charger les frames
	await get_tree().physics_frame
	
	# Récupère la grid depuis le parent
	astar_grid = get_parent().get("astar_grid")
	
	# Définit les points de départ et d'arrivée
	var start_cell := Vector2i(44, 20)
	var end_cell: Vector2i(66,10)
	
	#WAYPOINTS = [
		#astar_grid.get_point_position(Vector2i(44, 20)),
		#astar_grid.get_point_position(Vector2i(53, 17)),
		#astar_grid.get_point_position(Vector2i(60, 14)),
		#astar_grid.get_point_position(Vector2i(66, 10))
	#]
	path = astar_grid.get_point_path(start_cell, end_cell)
	path_index = 0

func physics_process(delta: float) -> void:
	if path.is_empty():
		return # Pas de chemin à suivre 

	# Appliquer la gravité
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		
	var target := path[path_index]
	var direction := (target - global.position).normalized
		
	var next_point_world_pos: Vector2 = path[path_index]
	# Convertit la position en pixels en une coordonnée de grille AstarGrid2D
	var next_point_grid_pos: Vector2i = astar_grid.world_to_map(next_point_world_pos)
	
	# Saut si le prochain point est plus haut
	if is_on_floor() and target.y < global_position.y + jump_threshold:
		velocity.y = JUMP_FORCE
		
	# Mouvement horizontal
	velocity.x = direction.x * SPEED
	
	# Récupère le coût de ce point 
	#var point_cost: float = astar_grid.get_point_weight_scale(next_point_grid_pos)
	#if navigation_agent.is_navigation_finished():
		# passe au waypoint suivant (boucle)
		#current_waypoint_index = (current_waypoint_index + 1) % WAYPOINTS.size()
		#navigation_agent.target_position = WAYPOINTS[current_waypoint_index]
		#return
	
	#if not navigation_agent.is_navigation_ready():
		#return
		
	# Obtenir le prochain point sur le chemin
	#var next_point: Vector2 = navigation_agent.get_next_path_position()
	# Calculer la direction horizontale vers ce point
	#var direction: Vector2 = global_position.direction_to(next_point)
	
	move_and_slide()
	
