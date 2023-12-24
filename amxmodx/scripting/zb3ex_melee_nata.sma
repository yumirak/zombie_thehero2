#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_thehero2>
#include <xs>

#define NAME		"Nata Knife"
#define VERSION		"2.0"
#define AUTHOR		"m4m3ts"

#define V_MODEL "models/zombie_thehero/wpn/melee/v_strong_knife.mdl"
#define P_MODEL "models/zombie_thehero/wpn/melee/p_strong_knife.mdl"

new Float:knife_swing_scalar = 1.0, Float:knife_stab_scalar = 2.0

static const SoundList[][] =
{
	"weapons/strong_knife_draw.wav",
	"weapons/nata_wall.wav",
	"weapons/nata_slash.wav",
	"weapons/nata_stab.wav",
	"weapons/nata_hit_1.wav",
	"weapons/nata_hit_1.wav"
}

// Linux extra offsets
#define extra_offset_weapon		4
#define extra_offset_player		5

// CBasePlayerItem
#define m_pPlayer			41
#define m_pNext				42

// CBasePlayerWeapon
#define m_flNextPrimaryAttack		46
#define m_flNextSecondaryAttack		47
#define m_flTimeWeaponIdle			48

// CBaseMonster
#define m_flNextAttack			83

// CBasePlayer
#define m_szAnimExtention		492

#define ANIM_EXTENSION "knife"

//
static bool:Knife[33]
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
//new g_MaxPlayers, 
new g_nata

public plugin_init()
{
	register_plugin(NAME, VERSION, AUTHOR)	

	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn_Post", true)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "HamHook_Item_Deploy_Post",	true);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife" , "HamHook_Item_PrimaryAttack",	false);
	RegisterHam(Ham_Weapon_SecondaryAttack,	"weapon_knife", "HamHook_Item_SecondaryAttack",	false);

	register_forward(FM_TraceLine, "fwTraceline")
	register_forward(FM_TraceHull, "fwTracehull", 1)
	register_forward(FM_EmitSound, "KnifeSound")

	g_nata = zb3_register_weapon("Nata Knife", WPN_MELEE, 0)
	//g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	
	static i
	for(i = 0; i <= charsmax(SoundList); i++)
		precache_sound(SoundList[i])
}

public zb3_user_infected(id,infector,flag) 
	if(flag == INFECT_VICTIM) Knife[id] = false

public zb3_weapon_selected_post(id, weaponid)
	if(weaponid == g_nata) give_nata(id)

public remove_katana(id) Knife[id] = false

public fw_TraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], TraceHandle, DamageBit)
{
	if(!is_user_alive(Attacker))
		return 
	if(get_user_weapon(Attacker) != CSW_KNIFE || !Knife[Attacker])
		return

	Damage *= 15.0 // DON'T SET TO FIXED VALUE IF WANT TO MAINTAIN BACKSTAB DAMAGE

	SetHamParamFloat(3, Damage)
}

public Player_Spawn_Post(id)
	Knife[id] = false

public fw_PlayerKilled(id)
	Knife[id] = false

public give_nata(id)
	Knife[id] = true

public KnifeSound(id, channel, sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!equal(sample, "weapons/knife_", 14) || !Knife[id])
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
	if(is_user_alive(id) && !zb3_get_user_zombie(id) && get_user_weapon(id) == CSW_KNIFE && Knife[id])
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
	iPlayer = get_pdata_cbase(iItem, m_pPlayer, extra_offset_weapon);

	if (!pev_valid(iItem) || Knife[iPlayer] == false)
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

	set_pdata_string(iPlayer, m_szAnimExtention * 4, ANIM_EXTENSION, -1, extra_offset_player * 4);
	PlayPlayerAnim(iPlayer)
	Weapon_SendAnim(iPlayer, KNIFE_ANIM_DRAW)
	return HAM_SUPERCEDE;
}
public HamHook_Item_PrimaryAttack(const iItem)
{
	static iPlayer
	iPlayer = get_pdata_cbase(iItem, m_pPlayer, extra_offset_weapon);

	if (!pev_valid(iItem) || Knife[iPlayer] == false)
		return HAM_IGNORED;

	PlayPlayerAnim(iPlayer)
	ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);
	set_pdata_float(iItem, m_flNextPrimaryAttack, 2.0, extra_offset_weapon);

	return HAM_SUPERCEDE;
}
public HamHook_Item_SecondaryAttack(const iItem)
{
	static iPlayer
	iPlayer = get_pdata_cbase(iItem, m_pPlayer, extra_offset_weapon);

	if (!pev_valid(iItem) || Knife[iPlayer] == false)
		return HAM_IGNORED;

	PlayPlayerAnim(iPlayer)
	ExecuteHam(Ham_Weapon_SecondaryAttack, iItem);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 2.0, extra_offset_weapon);

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