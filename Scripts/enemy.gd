# enemy.gd
extends CharacterBody2D

const BASE_SPEED = 150.0
const BASE_MAX_HEALTH = 50.0
const BASE_DAMAGE = 10.0
const XP_REWARD = 10

var current_speed: float
var current_health: float
var damage: float
var player: Node2D = null

func _ready():
	add_to_group("enemies")
	StatsManager.stats_updated.connect(update_stats_from_manager)
	update_stats_from_manager()
	current_health = BASE_MAX_HEALTH * StatsManager.get_stat("enemy_max_health")

func _physics_process(delta: float):
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * current_speed
		move_and_slide()

func update_stats_from_manager():
	current_speed = BASE_SPEED * StatsManager.get_stat("enemy_speed")
	damage = BASE_DAMAGE * StatsManager.get_stat("enemy_damage")
	var old_max_health = BASE_MAX_HEALTH * StatsManager.get_stat("enemy_max_health")
	var health_ratio = current_health / old_max_health if old_max_health > 0 else 1.0
	var new_max_health = BASE_MAX_HEALTH * StatsManager.get_stat("enemy_max_health")
	current_health = new_max_health * health_ratio

func take_damage(amount: float):
	current_health -= amount
	if current_health <= 0:
		die()

func die():
	StatsManager.add_xp(XP_REWARD)
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node and player_node.has_method("on_enemy_killed"):
		player_node.on_enemy_killed()
	queue_free()

# Note: You need a way to set the 'player' variable,
# for example by using an Area2D to detect when the player is near.
