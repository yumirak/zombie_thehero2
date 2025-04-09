#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombie_thehero2>
#include <reapi>
#include <xs>

#define NAME		"Nata Knife"
#define VERSION		"2.0"
#define AUTHOR		"m4m3ts"

#define WEAPON_NAME 			"weapon_natakinfe" // not typo
#define WEAPON_REFERANCE 		"weapon_knife"
#define V_MODEL "models/zombie_thehero/wpn/melee/v_strong_knife.mdl"
#define P_MODEL "models/zombie_thehero/wpn/melee/p_strong_knife.mdl"

new Float:knife_swing_scalar = 1.0, Float:knife_stab_scalar = 2.0
new g_iszWeaponKey;

static const SoundList[][] =
{
	"weapons/strong_knife_draw.wav",
	"weapons/nata_wall.wav",
	"weapons/nata_slash.wav",
	"weapons/nata_stab.wav",
	"weapons/nata_hit_1.wav",
	"weapons/nata_hit_1.wav"
}

#define ANIM_EXTENSION "knife"
#define IsValidPev(%0) (pev_valid(%0) == 2)
#define IsCustomItem(%0) (pev(%0, pev_impulse) == g_iszWeaponKey)

/*
enum
{
	ATTACK_SLASH = 1,
	ATTACK_STAB,
}
*/
enum
{
	KNIFE_ANIM_IDLE = 0,
	KNIFE_ANIM_SLASH1,
	KNIFE_ANIM_SLASH2,
	KNIFE_ANIM_DRAW,
	KNIFE_ANIM_STAB_HIT,
	KNIFE_ANIM_STAB_MISS,
	KNIFE_ANIM_MIDSLASH1,
	KNIFE_ANIM_MIDSLASH2
}

new g_nata

public plugin_init()
{
	register_plugin(NAME, VERSION, AUTHOR)	

	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "HamHook_Item_Deploy_Post",	true);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife" , "HamHook_Item_PrimaryAttack",	false);
	RegisterHam(Ham_Weapon_SecondaryAttack,	"weapon_knife", "HamHook_Item_SecondaryAttack",	false);

	register_forward(FM_TraceLine, "fwTraceline")
	register_forward(FM_TraceHull, "fwTracehull", 1)
	register_forward(FM_EmitSound, "KnifeSound")

	g_iszWeaponKey = engfunc(EngFunc_AllocString, WEAPON_NAME);
	g_nata = zb3_register_weapon("Nata Knife", WPN_MELEE, 0)
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	
	static i
	for(i = 0; i <= charsmax(SoundList); i++)
		precache_sound(SoundList[i])
}


public zb3_weapon_selected_post(id, weaponid)
	if(weaponid == g_nata) give_nata(id)

public fw_TraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], TraceHandle, DamageBit)
{
	new iItem = fm_find_ent_by_owner( -1, WEAPON_REFERANCE, Attacker);

	if(!is_user_alive(Attacker))
		return 
	if( get_user_weapon(Attacker) != CSW_KNIFE || !IsCustomItem(iItem))
		return

	Damage *= 15.0 // DON'T SET TO FIXED VALUE IF WANT TO MAINTAIN BACKSTAB DAMAGE

	SetHamParamFloat(3, Damage)
}

public give_nata(id)
{
	new iWeapon;
	iWeapon = rg_give_item(id, WEAPON_REFERANCE, GT_REPLACE)

	if (!IsValidPev(iWeapon))
	{
		return FM_NULLENT;
	}

	set_pev(iWeapon, pev_impulse, g_iszWeaponKey);
	return iWeapon
}

public KnifeSound(id, channel, sample[], Float:volume, Float:attn, flags, pitch)
{
	new iItem = fm_find_ent_by_owner( -1, WEAPON_REFERANCE, id);

	if(!equal(sample, "weapons/knife_", 14) || !IsValidPev(id) || !IsCustomItem(iItem))
		return FMRES_IGNORED

	if(equal(sample[8], "knife_hitwall", 13)) PlaySound(id, 1)	
	else if(equal(sample[8], "knife_hit", 9)) PlaySound(id, random_num(4,5))	
	if(equal(sample[8], "knife_slash", 11)) PlaySound(id, 2)
	if(equal(sample[8], "knife_stab", 10)) PlaySound(id, 3)
	//if(equal(sample[8], "knife_deploy", 12)) PlaySound(id, 0)
	return FMRES_SUPERCEDE
}

public fwTraceline(Float:fStart[3], Float:fEnd[3], conditions, id, ptr)
	return vTrace(id, ptr,fStart,fEnd,conditions)


public fwTracehull(Float:fStart[3], Float:fEnd[3], conditions, hull, id, ptr)
	return vTrace(id, ptr,fStart,fEnd,conditions,true,hull)


vTrace(id, ptr, Float:fStart[3], Float:fEnd[3], iNoMonsters, bool:hull = false, iHull = 0)
{	
	static buttons
	new Float:scalar

	new iItem = fm_find_ent_by_owner( -1, WEAPON_REFERANCE, id);

	if(is_user_alive(id) && !zb3_get_user_zombie(id) && get_user_weapon(id) == CSW_KNIFE && IsValidPev(id) && IsCustomItem(iItem))
	{
		buttons = pev(id, pev_button)
		
		if(buttons & IN_ATTACK) scalar = knife_swing_scalar
		else if(buttons & IN_ATTACK2) scalar = knife_stab_scalar

		xs_vec_sub(fEnd,fStart,fEnd)
		xs_vec_mul_scalar(fEnd,scalar,fEnd);
		xs_vec_add(fEnd,fStart,fEnd);
		
		hull ? engfunc(EngFunc_TraceHull, fStart, fEnd, iNoMonsters, iHull, id, ptr) : engfunc(EngFunc_TraceLine, fStart, fEnd, iNoMonsters, id, ptr)
	}
	
	return FMRES_IGNORED;
}
public HamHook_Item_Deploy_Post(const iItem)
{
	static iPlayer
	iPlayer = get_member(iItem, m_pPlayer)

	if (!pev_valid(iItem) || !IsCustomItem(iItem))
		return HAM_IGNORED;

	static iViewModel;
	if (iViewModel || (iViewModel = engfunc(EngFunc_AllocString, V_MODEL)))
	{
		set_pev_string(iPlayer, pev_viewmodel2, iViewModel);
	}
	
	static iPlayerModel;
	if (iPlayerModel || (iPlayerModel = engfunc(EngFunc_AllocString, P_MODEL)))
	{
		set_pev_string(iPlayer, pev_weaponmodel2, iPlayerModel);
	}

	set_member( iPlayer, m_szAnimExtention, ANIM_EXTENSION)
	PlayPlayerAnim(iPlayer)
	Weapon_SendAnim(iPlayer, KNIFE_ANIM_DRAW)
	return HAM_SUPERCEDE;
}
public HamHook_Item_PrimaryAttack(const iItem)
{
	static iPlayer
	iPlayer = get_member(iItem, m_pPlayer)

	if (!pev_valid(iItem) || !IsCustomItem(iItem))
		return HAM_IGNORED;

	PlayPlayerAnim(iPlayer)
	ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);
	set_member( iItem, m_Weapon_flNextPrimaryAttack, 2.0 );

	return HAM_SUPERCEDE;
}
public HamHook_Item_SecondaryAttack(const iItem)
{
	static iPlayer
	iPlayer = get_member(iItem, m_pPlayer)

	if (!pev_valid(iItem) || !IsCustomItem(iItem))
		return HAM_IGNORED;

	PlayPlayerAnim(iPlayer)
	ExecuteHam(Ham_Weapon_SecondaryAttack, iItem);
	set_member( iItem, m_Weapon_flNextSecondaryAttack, 2.0 );
	return HAM_SUPERCEDE;
}
stock PlaySound(Ent, Sound)
	engfunc(EngFunc_EmitSound, Ent, CHAN_WEAPON, SoundList[_:Sound], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

stock PlayPlayerAnim(iPlayer)
{
	static iFlags, AnimDesired, Animation[64]; 
	iFlags = pev(iPlayer, pev_flags);

	formatex(Animation, charsmax(Animation), iFlags & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", ANIM_EXTENSION);
	
	if ((AnimDesired = lookup_sequence(iPlayer, Animation)) == -1)
	{
		AnimDesired = 0;
	}
	set_pev(iPlayer, pev_sequence, AnimDesired);
}
Weapon_SendAnim(const iPlayer, const iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	engfunc(EngFunc_MessageBegin,MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, iPlayer);
	write_byte(iAnim);
	write_byte(0);
	message_end();
}
