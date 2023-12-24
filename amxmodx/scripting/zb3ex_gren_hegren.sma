#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombie_thehero2>
#include <cstrike>

#define PLUGIN "[ZB3EX] He Gren"
#define VERSION "2.0"
#define AUTHOR "Dias"

new g_sealknife


public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_precache()
{
	g_sealknife = zb3_register_weapon("HE Grenade", WPN_GRENADE, 0)
}

public zb3_weapon_selected_post(id, wpnid)
{
	if(wpnid == g_sealknife) 
	{
		fm_give_item(id, "weapon_hegrenade")
		//give_item(id, "weapon_hegrenade")
	}
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1066\\ f0\\ fs16 \n\\ par }
*/
