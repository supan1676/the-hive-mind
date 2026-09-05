extends Node

# --- OPTIMIZATION: TOKEN SYSTEM ---
# Only 3 enemies can attack at once. Prevents "Kung Fu Circle" chaos and saves CPU.
const MAX_ATTACKERS = 3
var current_attackers = 0

# --- SHARED MEMORY ---
# 0.0 = Safe, 1.0 = Deadly. All enemies read this.
var tactical_memory = {
	"backstab": 0.0,
	"magic": 0.0,
	"heavy_attack": 0.0,
	"parry": 0.0
}

# Signal simulating a "Shout" or "Death Cry"
signal death_reported(position: Vector3, cause: String)

# --- TOKEN LOGIC ---
func request_attack_token() -> bool:
	if current_attackers < MAX_ATTACKERS:
		current_attackers += 1
		return true
	return false

func return_attack_token():
	if current_attackers > 0:
		current_attackers -= 1

# --- LEARNING LOGIC ---
func report_death(pos: Vector3, cause: String):
	# 1. Update Global Knowledge
	if cause in tactical_memory:
		# Increase fear of this tactic by 15%, max 1.0
		tactical_memory[cause] = clamp(tactical_memory[cause] + 0.15, 0.0, 1.0)
	
	print("Hive Mind Updated: ", tactical_memory)
	
	# 2. Tell nearby enemies (simulated hearing)
	emit_signal("death_reported", pos, cause)
