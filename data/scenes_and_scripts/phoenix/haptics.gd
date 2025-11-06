extends Node

func triple_quick_hard():
	Input.vibrate_handheld(20, 1.0)
	await get_tree().create_timer(0.1).timeout
	Input.vibrate_handheld(20, 1.0)
	await get_tree().create_timer(0.1).timeout
	Input.vibrate_handheld(20, 1.0)

func triple_quick_medium():
	Input.vibrate_handheld(20, 0.65)
	await get_tree().create_timer(0.1).timeout
	Input.vibrate_handheld(20, 0.65)
	await get_tree().create_timer(0.1).timeout
	Input.vibrate_handheld(20, 0.65)

func triple_quick_soft():
	Input.vibrate_handheld(20, 0.3)
	await get_tree().create_timer(0.1).timeout
	Input.vibrate_handheld(20, 0.3)
	await get_tree().create_timer(0.1).timeout
	Input.vibrate_handheld(20, 0.3)

func double_quick_hard():
	Input.vibrate_handheld(20, 1.0)
	await get_tree().create_timer(0.1).timeout
	Input.vibrate_handheld(20, 1.0)
	await get_tree().create_timer(0.1).timeout

func double_quick_medium():
	Input.vibrate_handheld(20, 0.65)
	await get_tree().create_timer(0.1).timeout
	Input.vibrate_handheld(20, 0.65)
	await get_tree().create_timer(0.1).timeout

func double_quick_soft():
	Input.vibrate_handheld(20, 0.3)
	await get_tree().create_timer(0.1).timeout
	Input.vibrate_handheld(20, 0.3)
	await get_tree().create_timer(0.1).timeout

func double_normal_hard():
	Input.vibrate_handheld(100, 1.0)
	await get_tree().create_timer(0.3).timeout
	Input.vibrate_handheld(100, 1.0)
	await get_tree().create_timer(0.3).timeout

func double_normal_soft():
	Input.vibrate_handheld(100, 0.5)
	await get_tree().create_timer(0.3).timeout
	Input.vibrate_handheld(100, 0.5)
	await get_tree().create_timer(0.3).timeout

func stacatto_singleton():
	Input.vibrate_handheld(10, 1)

func stacatto_singleton_longer():
	Input.vibrate_handheld(20, 1)

func stacatto_doublet():
	Input.vibrate_handheld(10, 1)
	await get_tree().create_timer(0.1).timeout
	Input.vibrate_handheld(10, 1)
	
func hard_half_second():
	Input.vibrate_handheld(500, 1)
	
func hard_quarter_second():
	Input.vibrate_handheld(250,1)
	
func hard_doublet():
	Input.vibrate_handheld(200,1)
	await get_tree().create_timer(0.35).timeout
	Input.vibrate_handheld(200,1)

func pitter_patter_heavy():
	Input.vibrate_handheld(20,1)
	await get_tree().create_timer(0.05).timeout
	Input.vibrate_handheld(20,1)
	await get_tree().create_timer(0.05).timeout
	Input.vibrate_handheld(20,1)
	await get_tree().create_timer(0.05).timeout
	Input.vibrate_handheld(20,1)
	await get_tree().create_timer(0.05).timeout
	Input.vibrate_handheld(20,1)
	await get_tree().create_timer(0.05).timeout
	Input.vibrate_handheld(20,1)
	await get_tree().create_timer(0.05).timeout
	Input.vibrate_handheld(20,1)
	await get_tree().create_timer(0.05).timeout
	Input.vibrate_handheld(20,1)
	await get_tree().create_timer(0.05).timeout
	Input.vibrate_handheld(20,1)
	await get_tree().create_timer(0.05).timeout
	Input.vibrate_handheld(20,1)
	await get_tree().create_timer(0.05).timeout

func pitter_patter_light():
	Input.vibrate_handheld(20,0.3)
	await get_tree().create_timer(0.05).timeout
	Input.vibrate_handheld(20,0.3)
	await get_tree().create_timer(0.05).timeout
	Input.vibrate_handheld(20,0.3)
	await get_tree().create_timer(0.05).timeout
	Input.vibrate_handheld(20,0.3)
	await get_tree().create_timer(0.05).timeout
	Input.vibrate_handheld(20,0.3)
	await get_tree().create_timer(0.05).timeout
	Input.vibrate_handheld(20,0.3)
	await get_tree().create_timer(0.05).timeout
	Input.vibrate_handheld(20,0.3)
	await get_tree().create_timer(0.05).timeout
	Input.vibrate_handheld(20,0.3)
	await get_tree().create_timer(0.05).timeout
	Input.vibrate_handheld(20,0.3)
	await get_tree().create_timer(0.05).timeout
	Input.vibrate_handheld(20,0.3)
	await get_tree().create_timer(0.05).timeout
