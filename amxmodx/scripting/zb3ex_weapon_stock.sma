#include <amxmodx>
#include <reapi>
#include <zombie_thehero2>

#define PLUGIN "[ZB3EX] Stock Weapons"
#define VERSION "1.0"
#define AUTHOR ""

// Primary and Secondary Weapon Names
new const WEAPONNAMES[][] = { "", "P228 Compact", "", "Schmidt Scout", "HE Grenade", "XM1014 M4", "", "Ingram MAC-10", "Steyr AUG A1",
	"Smoke Grenade", "Dual Elite Berettas", "FiveseveN", "UMP 45", "SG-550 Auto-Sniper", "IMI Galil", "Famas",
	"USP .45 ACP Tactical", "Glock 18C", "AWP Magnum Sniper", "MP5 Navy", "M249 Para Machinegun",
	"M3 Super 90", "M4A1 Carbine", "Schmidt TMP", "G3SG1 Auto-Sniper", "Flashbang", "Desert Eagle .50 AE",
	"SG-552 Commando", "AK-47 Kalashnikov", "Seal Knife", "ES P90" }

new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10", "weapon_aug",
	"weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas",
	"weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
	"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle",
	"weapon_sg552", "weapon_ak47", "weapon_knife", "weapon_p90" }

new const WEAPONTYPE[] = { 0, WPN_SECONDARY, 0, WPN_PRIMARY, WPN_GRENADE, WPN_PRIMARY, 0, WPN_PRIMARY, WPN_PRIMARY,
	WPN_GRENADE, WPN_SECONDARY, WPN_SECONDARY, WPN_PRIMARY, WPN_PRIMARY, WPN_PRIMARY, WPN_PRIMARY,
	WPN_SECONDARY, WPN_SECONDARY, WPN_PRIMARY, WPN_PRIMARY, WPN_PRIMARY,
	WPN_PRIMARY, WPN_PRIMARY, WPN_PRIMARY, WPN_PRIMARY, WPN_GRENADE, WPN_SECONDARY,
	WPN_PRIMARY, WPN_PRIMARY, WPN_MELEE, WPN_PRIMARY }

new Array:weapon_list_num

new g_weapon[ sizeof(WEAPONENTNAMES) ];

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_precache()
{
	weapon_list_num = ArrayCreate(1, 1) // weapon id to be listed in weaponmenu

	ListWeapon()
}

public ListWeapon()
{
	for ( new i = 0 ; i < sizeof( g_weapon ); i++ )
	{
		if( WEAPONNAMES[i][0] == 0 || WEAPONTYPE[i] == 0 )
			continue

		g_weapon[i] = zb3_register_weapon( WEAPONNAMES[i], WEAPONTYPE[i], 0 )
		ArrayPushCell( weapon_list_num, g_weapon[i] )
	}

}
public zb3_weapon_selected_post(id, wpnid)
{
	for ( new i = 0 ; i < sizeof( g_weapon ); i++ )
	{
		if( WEAPONTYPE[i] == 0 )
			continue

		if( wpnid == ArrayGetCell( weapon_list_num, g_weapon[i]) )
			get_weapon( id, i )
	}
}

public get_weapon(id, wpnid)
{
	new ammo_name[32]
	new ammo_count

	rg_give_item(id, WEAPONENTNAMES[wpnid] )
	rg_get_weapon_info( wpnid, WI_AMMO_NAME, ammo_name, sizeof(ammo_name) )

	for( new i = 0; i < 6; i++)
	{
		rg_give_item(id, ammo_name )
	}

	ammo_count = clamp( rg_get_weapon_info( wpnid, WI_MAX_ROUNDS ) * ( WEAPONTYPE[wpnid] == WPN_GRENADE ? 1 : 2 ), 0, 240 )
	rg_set_user_bpammo(id, WeaponIdType:wpnid, ammo_count )
}
