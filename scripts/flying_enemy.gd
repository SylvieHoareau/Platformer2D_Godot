extends CharacterBody2D

# Enemy movement speed
@export var movement_speed: float = 150.0
#@export var movement_target_position: Vector2 = Vector2(60.0,180.0)

# Référence au noeud de l'agent de navigation
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

# Les points de patrouille (waypoints)
const WAYPOINTS: Array[Vector2] = [
	Vector2(100, 100),
	Vector2(500, 100),
	Vector2(500, 400),
	Vector2(100, 400),
]

# Index du point de cheminement actuel
var current_waypoint_index: int = 0
#var target_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0

	# Make sure to not await during _ready.
	start_patrol.call_deferred()
	
func start_patrol():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame

	# Initialise le premier objectif
	set_new_target(WAYPOINTS[current_waypoint_index])

func set_new_target(target: Vector2):
	navigation_agent.target_position = target
	
func _physics_process(delta: float) -> void:
	# Vérifie si l'ennemi a atteint sa navigation
	if navigation_agent.is_navigation_finished():
		# Passe au point de cheminement suivant
		current_waypoint_index = (current_waypoint_index + 1) % WAYPOINTS.size()
		set_new_target(WAYPOINTS[current_waypoint_index])
		return # Sortir de la boucle pour attendre le calcul du nouveau chemin
		
	# Calcul du mouvement
	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()

	# Calcul du vecteur de vitesse
	velocity = current_agent_position.direction_to(next_path_position) * movement_speed
	
	# Appliquer le mouvement
	move_and_slide()
