extends CharacterBody2D

# --- Variables à ajuster depuis l'éditeur ---
@export var speed: float = 200.0 # vitesse de déplacement
@export var jump_force: float = -400.0 # force du saut
@export var gravity: float = 900.0 # gravité

# --- Variables pour le dash ---
const DASH_AMT: float = 120.0
const DASH_TIME: float = 0.16

var can_dash: bool = true
var is_dashing: bool = false
var dash_dir: Vector2 = Vector2.RIGHT
var dash_timer: float = 0.0

# Identifiant du joueur (1 = clavier, 2 = manette)
@export var player_id: int = 1;

# Raccourci pour accéder au sprite
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Charger les animations du joueur
# const PLAYER_ANIMATIONS = preload("res://scenes/Player.tscn")

func _ready() -> void:
	# Ce noeud fait partie du groupe Player quand la scène est prête
	add_to_group("player")

func _physics_process(delta: float) -> void:
	# Appliquer la gravité
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
		
	if is_on_floor():
		print("Le joueur touche le sol")
		if !is_dashing and !can_dash:
			can_dash = true
			_update_dash_visuals()
	else:
		print("En l'air")

	# Choisir les bons inputs
	var left_action = "p%d_left" %player_id
	var right_action = "p%d_right" %player_id
	var jump_action = "p%d_jump" %player_id
	var dash_action = "p%d_dash" % player_id
	
	# Récupérer l'input gauche/droite
	var direction = Input.get_action_strength(right_action) - Input.get_action_strength(left_action)
	if !is_dashing:
		velocity.x = direction * speed
	
	# Gérer le saut
	if Input.is_action_just_pressed(jump_action) and is_on_floor():		
		velocity.y = jump_force
	
	# Dash
	_dash_logic(delta, dash_action, left_action, right_action)
	
	_handle_animations(direction)
	
	# Déplacer le joueur
	move_and_slide()
		
func _handle_animations(direction: float):
	# Choisir les bonnes animations selon l'ID du Player
	var jump_anim = "p%d_jump" %player_id
	var run_anim = "p%d_run" %player_id
	var idle_anim = "p%d_idle" %player_id
	var dash_anim = "p%d_dash" %player_id
	# var snooze_anim = "p%d_snooze" % player_id
	
	# Priorité haute
	if (is_dashing):
		sprite.play(dash_anim)
		
	# Priorité moyenne
	if not is_on_floor():
		# Si le AnimatedSprite2D a cette animation :
		if sprite.sprite_frames.has_animation(jump_anim):
			sprite.play(jump_anim)
		else:
			# Si l'animation de saut n'existe pas, on revient à l'état de mouvement/arrêt
			
			# Ne rien faire, le sprite continue sur sa dernière animation
			#pass
			
			# Forcer l'animation 'run' ou 'idle' si le personnage n'a pas de saut
			if direction != 0:
				sprite.play(run_anim)
				sprite.flip_h = direction < 0
			else:
				sprite.play(idle_anim)
				
		# Une fois l'état d'Air géré, on sort de la fonction
		return 

	# Priorité basse
	if direction != 0:
		sprite.play(run_anim)
		sprite.flip_h = direction < 0 # retourne le sprite si gauche
	else:
		sprite.play(idle_anim)

func _dash_logic(delta: float, dash_action: String, left_action: String, right_action: String) -> void:
	var input_dir: Vector2 = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	).normalized()
	
	# Déclenchement du dash
	if can_dash and Input.is_action_just_pressed(dash_action):
		is_dashing = true
		can_dash = false
		dash_timer = DASH_TIME
		
		# Si pas de direction, dash dans la direction actuelle
		var final_dir = input_dir
		if final_dir == Vector2.ZERO:
			final_dir = Vector2.RIGHT * (-1 if sprite.flip_h else 1)
			
		velocity = final_dir * DASH_AMT
		_update_dash_visuals()

	# Timer du dash	
	if is_dashing:
		print("IsDashing")
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false

func _update_dash_visuals() -> void:
	if can_dash:
		modulate = Color("ffffff")
	else:
		modulate = Color("5d6060")
			
