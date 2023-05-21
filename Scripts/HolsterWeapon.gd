extends Position3D

var enabled = true setget set_enabled
var equipped_weapon = 0
var weapons
onready var is_network_master = is_network_master()

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process_input(is_network_master)
	weapons = get_children()
#	get_tree().connect("network_peer_connected",self,"_player_connected")
	if is_network_master:
		rpc("equip",equipped_weapon)


func _input(event):
	if not enabled: return
	
	if event is InputEventKey:
		equip_by_key([KEY_1,KEY_2,KEY_3,KEY_4].find(event.scancode))
	elif event is InputEventMouseButton and event.is_pressed():
		if event.button_index == BUTTON_WHEEL_UP:
			equip_by_mouse_wheel(1)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			equip_by_mouse_wheel(-1)


func equip_by_mouse_wheel(scroll_direction):
	var index = equipped_weapon
	for _i in range(weapons.size()):
		index += scroll_direction
		
		if index < 0:
			index = weapons.size()-1
		if index >= weapons.size():
			index = 0
		
		if weapons[index].equippable:
			rpc("equip",index)
			return


func equip_by_key(number:int):
	if number < 0 or number >= weapons.size() or number == equipped_weapon: return
	
	if weapons[number].equippable:
		rpc("equip",number)

func _player_connected(_id):
	if is_network_master:
		rpc("equip",equipped_weapon)


# equip weapon in index, if invalid index is passed, 
# all weapons are unequipped
puppetsync func equip(index:int):
	weapons[equipped_weapon].equipped = false
	if index >= 0 and index < weapons.size():
		weapons[index].equipped = true
		equipped_weapon = index
	else:
		equipped_weapon = -1

func receive_ammo(pickup_type,amount)->bool:
	var weapon = null
	match pickup_type:
		Global.PickupType.GUN_AMMO:
			weapon = weapons[0]
		Global.PickupType.BARRELGUN_AMMO:
			weapon = weapons[1]
		Global.PickupType.AK47_AMMO:
			weapon = weapons[2]
		Global.PickupType.SNIPER_AMMO:
			weapon = weapons[3]
	
	if weapon != null && weapon.pouch_amount < weapon.pouch_size:
		weapon.add_ammo(amount)
		return true
	return false

# resets player arsenal.
# if wpns_to_reset (array of indexes of weapons) is passed,
# specified weapons will be reset to original state with full ammo.
# if wpn_to_equip is specified, weapon with that index will be equipped
func reset_state(wpns_to_reset=[0],wpn_to_equip=0):
	var child_index = 0
	for w in weapons:
		if child_index in wpns_to_reset:
			w.force_state(w.clip_size,w.pouch_size)
		else:
			w.force_state(0,0)
		child_index += 1
	
	if is_network_master and wpn_to_equip != null:
		rpc("equip",wpn_to_equip)

# toggle arsenal
func set_enabled(val,equip_on_enable=0):
	if val:
		equip(equip_on_enable)
	else:
		equip(-1)
	
	enabled = val
