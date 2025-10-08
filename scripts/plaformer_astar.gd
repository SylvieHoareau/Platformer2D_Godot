extends AStarGrid2D

# Cette fonction est appelée par AStarGrid2D pour calculer le coût entre 
# deux points connectés (adjacents, gérés automatiquement).
# Pour un pathfinding de plateforme, nous allons également l'utiliser pour
# autoriser les connexions de saut/chute non adjacentes.

# Note : from_id et to_id sont les Vector2i de la grille AStar.

func _compute_cost(from_id: Vector2i, to_id: Vector2i) -> float:
	# Calcul de la distance de base
	var distance_sq = from_id.distance_squared_to(to_id)
	var cost = sqrt(distance_sq)
	
	# Logique pour le Saut/Chute (connexions non adjacentes)
	# L'AStarGrid2D n'appelle _compute_cost que sur des points ADJACENTS par défaut.
	# Pour le saut, vous DEVEZ utiliser 'connect_points' (AStar2D) ou overridez la connexion (trop complexe).

	# Alternative : Si vous utilisez jumping_enabled = true (qui est désactivé par défaut),
	# AStarGrid2D pourrait créer des connexions de saut automatiques, mais cela désactivera
	# la prise en compte du poids, ce qui n'est pas ce que vous voulez.

	# *** La meilleure solution est de revenir à AStar2D pour le Pathfinding de Plateforme ***
	
	# Si on utilise AStarGrid2D, la seule façon d'augmenter le coût est via set_point_weight_scale :
	var weight_scale = get_point_weight_scale(to_id)
	return cost * weight_scale
