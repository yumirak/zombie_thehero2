#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombie_thehero2>
#include <fun>

#define PLUGIN "[ZB3EX] SupplyBox Item"
#define VERSION "2.0"
#define AUTHOR "Dias"

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const NADE_WEAPONS_BIT_SUM = ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG))

new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

new g_wpn_i
new Array:Supply_Item_Name
new g_forward

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	g_forward = CreateMultiForward("zb3_supply_item_give", ET_IGNORE, FP_CELL, FP_CELL)
	register_dictionary("zombie_thehero2.txt")
	
}
public plugin_precache()
{
	Supply_Item_Name = ArrayCreate(64, 1)
}

public plugin_natives()
{
	//register_native("zb3_supplybox_random_getitem", "native_getitem", 1)
	register_native("zb3_register_supply_item", "native_register_supply_item", 1)
}

public native_register_supply_item(const Name[])
{
	param_convert(1)
	
	ArrayPushString(Supply_Item_Name, Name)
	
	g_wpn_i++
	return g_wpn_i - 1
}

public zb3_touch_supply(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_hero(id)) 
	{
		refill_ammo(id)
		return;
	}
	
	switch(random_num(0, 50))
	{
		// temporary get supply item
		case 0..20: refill_ammo(id)
		case 21..30: { zb3_set_user_nvg(id, 1, 1, 1, 0); notice_supply(id, "Nightvision Googles"); }
		case 31..50: get_registered_random_weapon(id)
	}
}

public get_registered_random_weapon(id)
{
	if(!is_user_alive(id))
		return
	
	static g_forward_dummy, wpn_id , Temp_String[64]
	
	wpn_id = random_num(0, g_wpn_i - 1)

	ExecuteForward(g_forward, g_forward_dummy, id, wpn_id)
	ArrayGetString(Supply_Item_Name, wpn_id, Temp_String, sizeof(Temp_String))
	notice_supply(id,Temp_String)
}

public refill_ammo(id)
{
	if(!is_user_alive(id))
		return
		
	give_nade(id, 1)
	give_ammo(id)
	notice_supply(id, "Grenades and Magazines Set")
}

stock SendCenterText(id, const message[])
{
	new dest
	if (id) dest = MSG_ONE_UNRELIABLE
	else dest = MSG_BROADCAST
	
	message_begin(dest, get_user_msgid("TextMsg"), {0,0,0}, id)
	write_byte(4)
	write_string(message)
	message_end()
}

stock notice_supply(id, const itemname[])
{
	new buffer[256], name[64]
	get_user_name(id, name, sizeof(name))
	
	format(buffer, charsmax(buffer), "%L", LANG_PLAYER, "NOTICE_ITEM_PICKUP_BROADCAST", name, itemname)
	
	for (new i = 1; i <= get_maxplayers(); i++)
	{
		 if (!is_user_connected(i) || i == id) continue;
		 
		 SendCenterText(i, buffer)
	}
	
	format(buffer, charsmax(buffer), "%L", LANG_PLAYER, "NOTICE_ITEM_PICKUP", itemname)
	SendCenterText(id, buffer)	
}
stock get_weapon_type(weaponid)
{
	new type_wpn = 0
	if ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM) type_wpn = 1
	else if ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM) type_wpn = 2
	else if ((1<<weaponid) & NADE_WEAPONS_BIT_SUM) type_wpn = 4
	return type_wpn
}

stock give_nade(id, type)
{
	if (!is_user_alive(id)) return
	
	new weapons[32], num, check_vl[3]
	num = 0
	get_user_weapons(id, weapons, num)
	
	for (new i = 0; i < num; i++)
	{
		if (weapons[i] == CSW_HEGRENADE) check_vl[0] = 1
		else if (weapons[i] == CSW_FLASHBANG) check_vl[1] = 1
		else if (weapons[i] == CSW_SMOKEGRENADE) check_vl[2] = 1
	}
	
	if (!check_vl[0]) give_item(id, WEAPONENTNAMES[CSW_HEGRENADE])
	
	if(type == 1)
	{
		if (!check_vl[1])
		{	
			give_item(id, WEAPONENTNAMES[CSW_FLASHBANG])
			give_item(id, WEAPONENTNAMES[CSW_FLASHBANG])
		}
	}
	if (!check_vl[2]) give_item(id, WEAPONENTNAMES[CSW_SMOKEGRENADE])
}
public give_ammo(id)
{
	if (!is_user_alive(id)) return
	
	// Get user weapons
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]
		
		if (get_weapon_type(weaponid) == 1 || get_weapon_type(weaponid) == 2)
			cs_set_user_bpammo(id, weaponid, 200)
	}	
}
