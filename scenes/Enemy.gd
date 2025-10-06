extends CharacterBody2D

# Enemy movement speed
@export var movement_speed = 150.0

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
var target_position: Vector2 = Vector2.ZERO


@export var Goal: Node = null

func _ready() -> void:
	$NavigationAgent2D.target_position = Goal.global_position
	
	await get_tree().physics_frame
	
	# Initialise la cible sur le premier point
	set_new_target(WAYPOINTS[current_waypoint_index])
	
func _physics_process(delta: float) -> void:
	# Vérifie si l'ennemi a atteint sa navigation
	if navigation_agent.is_navigation_finished():
		# Passe au point de cheminement suivant :
		current_waypoint_index = (current_waypoint_index + 1) % WAYPOINTS.size()
		# Définit la nouvelle cible
		set_new_target(WAYPOINTS[current_waypoint_index])
	
	# Calcule la direction de mouvement
	var next_point: Vector2 = navigation_agent.get_next_path_position()
	var direction: Vector2 = global_position.direction_to(next_point)
	
	if !$NavigationAgent2D.is_target_reached():
		var nav_point_direction = to_local($NavigationAgent2D.get_next_path_position()).normalized()
		velocity = nav_point_direction * movement_speed * delta	
		move_and_slide()

func _on_timer_timeout():
	if $NavigationAgent2D.target_position != Goal.global_position:
		$NavigationAgent2D.target_position = Goal.global_position
	$PathfindingUpdateTimer.start()
	
func set_new_target(target: Vector2):
	target_position = target
	
# Fonction pour que les ennemis s'effacent lorsqu'ils quittent l'écran
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
