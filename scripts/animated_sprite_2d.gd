extends AnimatedSprite2D

const SPEED = 300.0
# Identifiant du joueur (1 = clavier, 2 = manette)
@export var player_id: int = 1;

func _ready() -> void:
	# Ce noeud fait partie du groupe Player quand la scène est prête
	add_to_group("player")
	
func _process(_delta : float) -> void:
	# Obtenir les entrées spécifiques au joueur p1 ou p2
	var input_prefix = "p%d" % player_id

	var direction_x = 0
	# Animation par défaut
	var current_animation = "idle"
	
	# Jouer les animations
	if Input.is_action_pressed(input_prefix + "_right"):
		direction_x += 1
		current_animation = input_prefix + "_run"
		#current_animation.flip_h = false
		
	if Input.is_action_pressed(input_prefix + "_left"):
		direction_x -= 1
		current_animation = input_prefix + "_run"
		#current_animation.flip_h = false
	
	if Input.is_action_pressed(input_prefix + "_jump"):
		current_animation = input_prefix + "_jump"

	#velocity.x = direction_x * SPEED
	
	#animated_sprite.play(current_animation)
	
	
