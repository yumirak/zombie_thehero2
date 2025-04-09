#include <amxmodx>
#include <reapi>
#include <zombie_thehero2>

#define PLUGIN "[ZB3] Addon: Weapon"
#define VERSION "1.0"
#define AUTHOR "Dias Pendragon"

#define LANG_FILE "zombie_thehero2.txt"
#define GAME_LANG LANG_SERVER

#define MAX_WEAPON 46
#define MAX_TYPE 4
#define MAX_FORWARD 4

new g_Forwards[MAX_FORWARD], g_GotWeapon[33]
new g_WeaponList[5][MAX_WEAPON], g_WeaponListCount[5]
new g_WeaponCount[5], g_PreWeapon[33][5], g_FirstWeapon[5], g_TotalWeaponCount, g_UnlockedWeapon[33][MAX_WEAPON]
new Array:ArWeaponName, Array:ArWeaponType, Array:ArWeaponCost
new g_RegWeaponCount
new g_MaxPlayers, g_fwResult, g_MsgSayText

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary(LANG_FILE)

	g_Forwards[WPN_PRE_BOUGHT] = CreateMultiForward("zb3_weapon_selected_pre", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[WPN_BOUGHT] = CreateMultiForward("zb3_weapon_selected_post", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[WPN_REMOVE] = CreateMultiForward("zb3_remove_weapon", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[WPN_ADDAMMO] = CreateMultiForward("Mileage_WeaponRefillAmmo", ET_IGNORE, FP_CELL, FP_CELL)
	
	g_MsgSayText = get_user_msgid("SayText")
	g_MaxPlayers = get_maxplayers()
	
	register_clcmd("buyammo1", "Native_OpenWeapon")
	
}

public plugin_precache()
{
	ArWeaponName = ArrayCreate(64, 1)
	ArWeaponType = ArrayCreate(1, 1)
	ArWeaponCost = ArrayCreate(1, 1)
	
	// Initialize
	g_FirstWeapon[WPN_PRIMARY] = -1
	g_FirstWeapon[WPN_SECONDARY] = -1
	g_FirstWeapon[WPN_MELEE] = -1
	g_FirstWeapon[WPN_GRENADE] = -1
	
	// Read Data
	//Mileage_ReadWeapon()
}

public plugin_cfg()
{
	// Initialize 2
	static Type
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		g_PreWeapon[i][WPN_PRIMARY] = g_FirstWeapon[WPN_PRIMARY]
		g_PreWeapon[i][WPN_SECONDARY] = g_FirstWeapon[WPN_SECONDARY]
		g_PreWeapon[i][WPN_MELEE] = g_FirstWeapon[WPN_MELEE]
		g_PreWeapon[i][WPN_GRENADE] = g_FirstWeapon[WPN_GRENADE]
	}
	
	// Handle WeaponList
	g_WeaponListCount[WPN_PRIMARY] = 0
	g_WeaponListCount[WPN_SECONDARY] = 0
	g_WeaponListCount[WPN_MELEE] = 0
	g_WeaponListCount[WPN_GRENADE] = 0
	
	for(new i = 0; i < g_TotalWeaponCount; i++)
	{
		Type = ArrayGetCell(ArWeaponType, i)
		g_WeaponList[Type][g_WeaponListCount[Type]] = i
		g_WeaponListCount[Type]++
	}
}

public plugin_natives()
{
	register_native("zb3_register_weapon","Native_RegisterWeapon", 1)
	// NYI
	register_native("Mileage_OpenWeapon", "Native_OpenWeapon", 1)
	register_native("Mileage_GiveRandomWeapon", "Native_GiveRandomWeapon", 1)
	
	register_native("Mileage_RemoveWeapon", "Native_RemoveWeapon", 1)
	register_native("Mileage_ResetWeapon", "Native_ResetWeapon", 1)
	register_native("Mileage_Weapon_RefillAmmo", "Native_RefillAmmo", 1)
	
	register_native("Mileage_WeaponAllow_Set", "Native_SetUseWeapon", 1)
	register_native("Mileage_WeaponAllow_Get", "Native_GetUseWeapon", 1)
}
	
public Native_RegisterWeapon(const Name[], weapon_type, unlock_cost)
{
	param_convert(1)

	ArrayPushString(ArWeaponName, Name)
	ArrayPushCell(ArWeaponType, weapon_type)
	ArrayPushCell(ArWeaponCost, unlock_cost)
	
	if(g_FirstWeapon[weapon_type] == -1) 
		g_FirstWeapon[weapon_type] = g_TotalWeaponCount
	
	g_WeaponCount[weapon_type]++
	g_TotalWeaponCount++
	
	g_RegWeaponCount++
	return g_RegWeaponCount - 1
}

public Native_GiveRandomWeapon(id)
{
	/*
	new ListPri[64], ListSec[64], g_Count[2]
	
	for(new i = 0; i < g_WeaponListCount[WPN_PRIMARY]; i++)
	{
		ListPri[g_Count[0]] = i 
		g_Count[0]++
	}
	
	for(new i = 0; i < g_WeaponListCount[WPN_SECONDARY]; i++)
	{
		ListSec[g_Count[1]] = i 
		g_Count[1]++
	}	
	*/
	new Pri, Sec
	
	Pri = random(g_WeaponListCount[WPN_PRIMARY])  //ListPri[random(g_Count[0])]
	Sec = random(g_WeaponListCount[WPN_SECONDARY]) //ListSec[random(g_Count[1])]
	
	switch(random_num(0, 100))
	{
		case 0..70:
		{
			rg_drop_items_by_slot(id, PRIMARY_WEAPON_SLOT)
			ExecuteForward(g_Forwards[WPN_BOUGHT], g_fwResult, id,  Pri)

			if(!g_UnlockedWeapon[id][Pri]) 
				g_UnlockedWeapon[id][Pri] = 1
		}
		case 71..100:
		{
			rg_drop_items_by_slot(id, PISTOL_SLOT)
			ExecuteForward(g_Forwards[WPN_BOUGHT], g_fwResult, id,  Sec)
			if(!g_UnlockedWeapon[id][Sec]) 
				g_UnlockedWeapon[id][Sec] = 1
		}
	}
}

public Native_OpenWeapon(id) 
{
	if(!(0 <= id <= 32))
		return
		
	Show_MainEquipMenu(id)
}

public Native_RemoveWeapon(id)
{
	if(!(0 <= id <= 32))
		return
		
	Remove_PlayerWeapon(id)
}

public Native_ResetWeapon(id, NewPlayer)
{
	if(!(0 <= id <= 32))
		return
		
	Reset_PlayerWeapon(id, NewPlayer)
}

public Native_RefillAmmo(id)
{
	if(!(0 <= id <= 32))
		return
		
	Refill_PlayerWeapon(id)
}

public Native_SetUseWeapon(id, Allow)
{
	if(!(0 <= id <= 32))
		return
	g_GotWeapon[id] = Allow ? 0 : 1
}

public Native_GetUseWeapon(id)
{
	if(!(0 <= id <= 32))
		return 0
		
	return g_GotWeapon[id]
}

public client_putinserver(id)
{
	Reset_PlayerWeapon(id, 1)
}

public client_disconnected(id)
{
	Reset_PlayerWeapon(id, 1)
}

public zb3_user_spawned(id)
{
	if(zb3_get_user_zombie(id)) return

	// Reset
	Native_ResetWeapon(id, 0)
	Native_RemoveWeapon(id)
	Native_SetUseWeapon(id, 1)
	
	// Open
	Player_Equipment(id)
}

public zb3_user_dead(id, Attacker, Headshot)
{
	if(zb3_get_user_zombie(id))
		return 
		
	Native_SetUseWeapon(id, 0)
}

public zb3_user_infected(id, Attacker, ClassID)
{
	Native_SetUseWeapon(id, 0)
}

public zevo_equipment_menu(id) Show_MainEquipMenu(id)
/*
public zevo_supplybox_pickup(id, Special)
{
	if(Special == HUMAN_HERO) return
	
	if(!is_user_bot(id))
	{
		Refill_PlayerWeapon(id)
		
		// Ask
		static LangText[64]; formatex(LangText, 63, "%L", GAME_LANG, "SHOP_ASK")
		static Menu; Menu = menu_create(LangText, "MenuHandle_MileageAsk")
		
		// Yes
		formatex(LangText, 63, "%L", GAME_LANG, "SHOP_YES")
		menu_additem(Menu, LangText, "yes")
		
		// No
		formatex(LangText, 63, "%L", GAME_LANG, "SHOP_NO")
		menu_additem(Menu, LangText, "no")
		
		// Dis
		menu_display(id, Menu)
	} else {
		// Reset
		Native_ResetWeapon(id, 0)
		Native_RemoveWeapon(id)
		Native_SetUseWeapon(id, 1)
		
		// Strip
		strip_user_weapons(id)
		give_item(id, "weapon_knife")
		
		// Open
		Player_Equipment(id)
	}
}

public MenuHandle_MileageAsk(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}
	if(!is_user_alive(id))
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}
	if(zevo_is_zombie(id))
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}

	new Name[64], Data[16], ItemAccess, ItemCallback
	menu_item_getinfo(Menu, Item, ItemAccess, Data, charsmax(Data), Name, charsmax(Name), ItemCallback)

	if(equal(Data, "yes"))
	{
		// Reset
		Native_ResetWeapon(id, 0)
		Native_RemoveWeapon(id)
		Native_SetUseWeapon(id, 1)
		
		// Strip
		strip_user_weapons(id)
		give_item(id, "weapon_knife")
		
		// Open
		Player_Equipment(id)
	} 
	
	menu_destroy(Menu)
	return PLUGIN_HANDLED
}
*/
// End of Zombie Evolution - Sync

public Remove_PlayerWeapon(id)
{
	if(g_PreWeapon[id][WPN_PRIMARY] != 1) ExecuteForward(g_Forwards[WPN_REMOVE], g_fwResult, id, g_PreWeapon[id][WPN_PRIMARY])
	if(g_PreWeapon[id][WPN_SECONDARY] != 1) ExecuteForward(g_Forwards[WPN_REMOVE], g_fwResult, id, g_PreWeapon[id][WPN_SECONDARY])
	if(g_PreWeapon[id][WPN_MELEE] != 1) ExecuteForward(g_Forwards[WPN_REMOVE], g_fwResult, id, g_PreWeapon[id][WPN_MELEE])
	if(g_PreWeapon[id][WPN_GRENADE] != 1) ExecuteForward(g_Forwards[WPN_REMOVE], g_fwResult, id, g_PreWeapon[id][WPN_GRENADE])
}

public Refill_PlayerWeapon(id)
{
	if(g_PreWeapon[id][WPN_PRIMARY] != 1) ExecuteForward(g_Forwards[WPN_ADDAMMO], g_fwResult, id, g_PreWeapon[id][WPN_PRIMARY])
	if(g_PreWeapon[id][WPN_SECONDARY] != 1) ExecuteForward(g_Forwards[WPN_ADDAMMO], g_fwResult, id, g_PreWeapon[id][WPN_SECONDARY])
	if(g_PreWeapon[id][WPN_MELEE] != 1) ExecuteForward(g_Forwards[WPN_ADDAMMO], g_fwResult, id, g_PreWeapon[id][WPN_MELEE])
	if(g_PreWeapon[id][WPN_GRENADE] != 1) ExecuteForward(g_Forwards[WPN_ADDAMMO], g_fwResult, id, g_PreWeapon[id][WPN_GRENADE])
}

public Reset_PlayerWeapon(id, NewPlayer)
{
	if(NewPlayer)
	{
		g_PreWeapon[id][WPN_PRIMARY] = g_FirstWeapon[WPN_PRIMARY]
		g_PreWeapon[id][WPN_SECONDARY] = g_FirstWeapon[WPN_SECONDARY]
		g_PreWeapon[id][WPN_MELEE] = g_FirstWeapon[WPN_MELEE]
		g_PreWeapon[id][WPN_GRENADE] = g_FirstWeapon[WPN_GRENADE]
		
		for(new i = 0; i < MAX_WEAPON; i++)
			g_UnlockedWeapon[id][i] = 0
	}
	
	g_GotWeapon[id] = 0
}

public Player_Equipment(id)
{
	if(!is_user_bot(id)) Show_MainEquipMenu(id)
	else set_task(random_float(0.25, 1.0), "Bot_RandomWeapon", id)
}

public Show_MainEquipMenu(id)
{
	if(!is_user_alive(id) || g_GotWeapon[id])
		return
	
	static Menu, WeaponName[64], LangText[64], SystemName[64]; 
	formatex(SystemName, 39, "%L", GAME_LANG, "SHOP_WEAPON")
	Menu = menu_create(SystemName, "MenuHandle_MainEquip")
	
	if(g_PreWeapon[id][WPN_PRIMARY] != -1)
	{
		ArrayGetString(ArWeaponName, g_PreWeapon[id][WPN_PRIMARY], WeaponName, sizeof(WeaponName))
		formatex(LangText, sizeof(LangText), "%L \y%s\w", GAME_LANG, "SHOP_PRIMARY", WeaponName)
	} else {
		formatex(LangText, sizeof(LangText), "%L \d N/A \w", GAME_LANG, "SHOP_PRIMARY")
	}
	menu_additem(Menu, LangText, "wpn_pri")
	
	if(g_PreWeapon[id][WPN_SECONDARY] != -1)
	{
		ArrayGetString(ArWeaponName, g_PreWeapon[id][WPN_SECONDARY], WeaponName, sizeof(WeaponName))
		formatex(LangText, sizeof(LangText), "%L \y%s\w", GAME_LANG, "SHOP_SECONDARY", WeaponName)
	} else {
		formatex(LangText, sizeof(LangText), "%L \d N/A \w", GAME_LANG, "SHOP_SECONDARY")
	}
	menu_additem(Menu, LangText, "wpn_sec")
	
	if(g_PreWeapon[id][WPN_MELEE] != -1)
	{
		ArrayGetString(ArWeaponName, g_PreWeapon[id][WPN_MELEE], WeaponName, sizeof(WeaponName))
		formatex(LangText, sizeof(LangText), "%L \y%s\w", GAME_LANG, "SHOP_MELEE", WeaponName)
	} else {
		formatex(LangText, sizeof(LangText), "%L \d N/A \w", GAME_LANG, "SHOP_MELEE")
	}
	menu_additem(Menu, LangText, "wpn_melee")
	
	if(g_PreWeapon[id][WPN_GRENADE] != -1)
	{
		ArrayGetString(ArWeaponName, g_PreWeapon[id][WPN_GRENADE], WeaponName, sizeof(WeaponName))
		formatex(LangText, sizeof(LangText), "%L \y%s\w^n", GAME_LANG, "SHOP_GRENADE", WeaponName)
	} else {
		formatex(LangText, sizeof(LangText), "%L \d N/A \w^n", GAME_LANG, "SHOP_GRENADE")
	}
	menu_additem(Menu, LangText, "wpn_grenade")
   
	formatex(LangText, sizeof(LangText), "\y%L", GAME_LANG, "SHOP_GET")
	menu_additem(Menu, LangText, "get_wpn")
   
	menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, Menu, 0)
}

public Bot_RandomWeapon(id)
{
	//if(g_PreWeapon[id][WPN_GRENADE] != -1) 
	g_PreWeapon[id][WPN_PRIMARY] = g_WeaponList[WPN_PRIMARY][random_num(0, g_WeaponListCount[WPN_PRIMARY])]
	//if(g_PreWeapon[id][WPN_SECONDARY] != -1) 
	g_PreWeapon[id][WPN_SECONDARY] = g_WeaponList[WPN_SECONDARY][random_num(0, g_WeaponListCount[WPN_SECONDARY])]
	//if(g_PreWeapon[id][WPN_MELEE] != -1)
	g_PreWeapon[id][WPN_MELEE] = g_WeaponList[WPN_MELEE][random_num(0, g_WeaponListCount[WPN_MELEE])]
	//if(g_PreWeapon[id][WPN_GRENADE] != -1)
	g_PreWeapon[id][WPN_GRENADE] = g_WeaponList[WPN_GRENADE][random_num(0, g_WeaponListCount[WPN_GRENADE])]
	
	Equip_Weapon(id)
}

public MenuHandle_MainEquip(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}
	if(!is_user_alive(id) || zb3_get_user_zombie(id))
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}

	new Name[64], Data[16], ItemAccess, ItemCallback
	menu_item_getinfo(Menu, Item, ItemAccess, Data, charsmax(Data), Name, charsmax(Name), ItemCallback)

	if(equal(Data, "wpn_pri"))
	{
		if(g_WeaponCount[WPN_PRIMARY]) Show_WpnSubMenu(id, WPN_PRIMARY, 0)
		else Show_MainEquipMenu(id)
	} else if(equal(Data, "wpn_sec")) {
		if(g_WeaponCount[WPN_SECONDARY]) Show_WpnSubMenu(id, WPN_SECONDARY, 0)
		else Show_MainEquipMenu(id)
	} else if(equal(Data, "wpn_melee")) {
		if(g_WeaponCount[WPN_MELEE]) Show_WpnSubMenu(id, WPN_MELEE, 0)
		else Show_MainEquipMenu(id)
	} else if(equal(Data, "wpn_grenade")) {
		if(g_WeaponCount[WPN_GRENADE]) Show_WpnSubMenu(id, WPN_GRENADE, 0)
		else Show_MainEquipMenu(id)
	} else if(equal(Data, "get_wpn")) {
		Equip_Weapon(id)
	}
	
	menu_destroy(Menu)
	return PLUGIN_CONTINUE
}

public Show_WpnSubMenu(id, WpnType, Page)
{
	static MenuName[64]
	switch(WpnType)
	{
		case WPN_PRIMARY: formatex(MenuName, sizeof(MenuName), "%L", GAME_LANG, "SHOP_PRIMARY")
		case WPN_SECONDARY: formatex(MenuName, sizeof(MenuName), "%L", GAME_LANG, "SHOP_SECONDARY")
		case WPN_MELEE: formatex(MenuName, sizeof(MenuName), "%L", GAME_LANG, "SHOP_MELEE")
		case WPN_GRENADE: formatex(MenuName, sizeof(MenuName), "%L", GAME_LANG, "SHOP_GRENADE")
	}

	new Menu = menu_create(MenuName, "MenuHandle_WpnSubMenu")

	static WeaponType, WeaponName[32], MenuItem[64], MenuItemID[4]
	static WeaponPrice, Money; Money = get_member(id, m_iAccount); // cs_get_user_money(id)
	
	for(new i = 0; i < g_TotalWeaponCount; i++)
	{
		WeaponType = ArrayGetCell(ArWeaponType, i)
		if(WpnType != WeaponType)
			continue
		
		ArrayGetString(ArWeaponName, i, WeaponName, sizeof(WeaponName))
		WeaponPrice = zb3_get_freeitem_status() ? 0 : ArrayGetCell(ArWeaponCost, i)

		ExecuteForward(g_Forwards[WPN_PRE_BOUGHT], g_fwResult, id, g_PreWeapon[id][WeaponType])
		if(WeaponPrice > 0)
		{
			if(g_UnlockedWeapon[id][i]) 
				formatex(MenuItem, sizeof(MenuItem), "%s", WeaponName)
			else {
				if(Money >= WeaponPrice) formatex(MenuItem, sizeof(MenuItem), "%s \y($%i)\w", WeaponName, WeaponPrice)
				else formatex(MenuItem, sizeof(MenuItem), "\d%s \r($%i)\w", WeaponName, WeaponPrice)
			}
		} else {
			formatex(MenuItem, sizeof(MenuItem), "%s", WeaponName)
		}
		
		num_to_str(i, MenuItemID, sizeof(MenuItemID))
		menu_additem(Menu, MenuItem, MenuItemID)
	}
   
	menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, Menu, Page)
}

public MenuHandle_WpnSubMenu(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		Show_MainEquipMenu(id)
		
		return PLUGIN_HANDLED
	}
	if(!is_user_alive(id) || zb3_get_user_zombie(id))
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}

	new Name[64], Data[16], ItemAccess, ItemCallback
	menu_item_getinfo(Menu, Item, ItemAccess, Data, charsmax(Data), Name, charsmax(Name), ItemCallback)

	new ItemId = str_to_num(Data)
	new WeaponType, WeaponPrice, WeaponName[32]
	
	WeaponType = ArrayGetCell(ArWeaponType, ItemId)
	WeaponPrice = zb3_get_freeitem_status() ? 0 : ArrayGetCell(ArWeaponCost, ItemId)
	ArrayGetString(ArWeaponName, ItemId, WeaponName, sizeof(WeaponName))

	new Money = get_member(id, m_iAccount);
	new OutputInfo[80]
	
	if(WeaponPrice > 0)
	{
		if(g_UnlockedWeapon[id][ItemId]) 
		{
			g_PreWeapon[id][WeaponType] = ItemId
			Show_MainEquipMenu(id)
		} else {
			if(Money >= WeaponPrice) 
			{
				g_UnlockedWeapon[id][ItemId] = 1
				g_PreWeapon[id][WeaponType] = ItemId

				formatex(OutputInfo, sizeof(OutputInfo), "%L", GAME_LANG, "SHOP_BUY", WeaponName, WeaponPrice)
				client_printc(id, OutputInfo)
									
				// cs_set_user_money(id, Money - WeaponPrice, 1)
				rg_add_account(id, Money - WeaponPrice, AS_SET, true)
				Show_MainEquipMenu(id)
			} else {
				formatex(OutputInfo, sizeof(OutputInfo), "%L", GAME_LANG, "SHOP_NOT_ENOUGH_MONEY", WeaponName ,WeaponPrice)
				client_printc(id, OutputInfo)
				Show_MainEquipMenu(id)	
			}
		}
	} else {
		if(!g_UnlockedWeapon[id][ItemId]) 
			g_UnlockedWeapon[id][ItemId] = 1
								
		g_PreWeapon[id][WeaponType] = ItemId
		Show_MainEquipMenu(id)
	}

	menu_destroy(Menu)
	return PLUGIN_CONTINUE
}

public Equip_Weapon(id)
{
	if(!is_user_alive(id) || zb3_get_user_zombie(id) || zb3_get_user_hero(id))
		return;

	// Equip: Melee
	if(g_PreWeapon[id][WPN_MELEE] != -1)
		ExecuteForward(g_Forwards[WPN_BOUGHT], g_fwResult, id, g_PreWeapon[id][WPN_MELEE])
		
	// Equip: Grenade
	if(g_PreWeapon[id][WPN_GRENADE] != -1)
		ExecuteForward(g_Forwards[WPN_BOUGHT], g_fwResult, id, g_PreWeapon[id][WPN_GRENADE])
		
	// Equip: Secondary
	if(g_PreWeapon[id][WPN_SECONDARY] != -1)
	{
		rg_drop_items_by_slot(id, PISTOL_SLOT)
		ExecuteForward(g_Forwards[WPN_BOUGHT], g_fwResult, id, g_PreWeapon[id][WPN_SECONDARY])
	}
		
	// Equip: Primary
	if(g_PreWeapon[id][WPN_PRIMARY] != -1)
	{
		rg_drop_items_by_slot(id, PRIMARY_WEAPON_SLOT)
		ExecuteForward(g_Forwards[WPN_BOUGHT], g_fwResult, id, g_PreWeapon[id][WPN_PRIMARY])
	}
	
	g_GotWeapon[id] = 1
}

stock client_printc(index, const text[], any:...)
{
	static szMsg[128]; vformat(szMsg, sizeof(szMsg) - 1, text, 3)

	replace_all(szMsg, sizeof(szMsg) - 1, "!g", "^x04")
	replace_all(szMsg, sizeof(szMsg) - 1, "!n", "^x01")
	replace_all(szMsg, sizeof(szMsg) - 1, "!t", "^x03")

	if(index)
	{
		message_begin(MSG_ONE_UNRELIABLE, g_MsgSayText, _, index);
		write_byte(index);
		write_string(szMsg);
		message_end();
	}
} 

