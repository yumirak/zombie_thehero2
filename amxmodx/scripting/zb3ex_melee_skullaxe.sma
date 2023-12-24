#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombie_thehero2>
#include <cstrike>
#include <xs>

#define PLUGIN "[Zombie: The Hero] Melee Weapon: Skull-Axe (A.K.A: Skull-9)"
#define VERSION "2.0"
#define AUTHOR "Dias"

#define RADIUS_SLASH 110.0
#define RADIUS_STAB 80.0
#define DISTANCE_FROM_ATTACK 48.0

#define DAMAGE_SLASH 400.0
#define DAMAGE_STAB 800.0

new const v_model[] = "models/zombie_thehero/wpn/melee/v_skullaxe2.mdl"
new const p_model[] = "models/zombie_thehero/wpn/melee/p_skullaxe.mdl"

new const draw_sound[] = "weapons/skullaxe_draw.wav"
new const hit_sound[] = "weapons/skullaxe_hit.wav"
new const miss_sound[] = "weapons/skullaxe_slash1.wav"

new g_skullaxe
new g_had_skullaxe[33], g_can_attack
const m_szAnimExtention = 492

#define is_valid_entity(%0) (pev_valid(%0) == 2)

#define TASK_STARTSLASH 342423
#define TASK_SLASHING 423453
#define TASK_STABING 423423

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

enum
{
	SKULLAXE_ANIM_IDLE = 0,
	SKULLAXE_ANIM_DRAW,
	SKULLAXE_ANIM_STARTSLASH,
	SKULLAXE_ANIM_SLASHHIT,
	SKULLAXE_ANIM_SLASHMISS,
	SKULLAXE_ANIM_STAB
}

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")		
	
	RegisterHam(Ham_CS_Weapon_SendWeaponAnim, "weapon_knife", "fw_Knife_SendAnim", 1)
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, v_model)
	engfunc(EngFunc_PrecacheModel, p_model)
	
	engfunc(EngFunc_PrecacheSound, draw_sound)
	engfunc(EngFunc_PrecacheSound, hit_sound)
	engfunc(EngFunc_PrecacheSound, miss_sound)
	
	g_skullaxe = zb3_register_weapon("Skull-Axe (Skull-9)", WPN_MELEE, 10000)
}

public get_skullaxe(id)
{
	g_had_skullaxe[id] = 1
	
	if(get_user_weapon(id) == CSW_KNIFE) 
	{
		Event_CurWeapon(id)
		set_weapon_anim(id, SKULLAXE_ANIM_DRAW)
	}
}

public remove_skullaxe(id)
{
	g_had_skullaxe[id] = 0
	
	remove_task(id+TASK_STARTSLASH)
	remove_task(id+TASK_SLASHING)
	remove_task(id+TASK_STABING)
}

public zb3_user_dead(id) remove_skullaxe(id)
public zb3_user_spawned(id) remove_skullaxe(id)
public zb3_game_start(start_type) 
{
	if(start_type == 2) g_can_attack = 1
}
public zb3_game_end() g_can_attack = 0
public zb3_user_infected(id) remove_skullaxe(id)
public zb3_weapon_selected_post(id, wpnid)
{
	if(wpnid == g_skullaxe) get_skullaxe(id)
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return 1
	if(get_user_weapon(id) != CSW_KNIFE)
		return 1
	if(!g_had_skullaxe[id])
		return 1
		
	set_pev(id, pev_viewmodel2, v_model)
	set_pev(id, pev_weaponmodel2, p_model)
		
	return 0
}

public fw_Knife_SendAnim(ent, anim, skip_local)
{
	if(!is_valid_entity(ent))
		return HAM_IGNORED
		
	new id
	id = get_pdata_cbase(ent, 41 , 4)
	
	if(!g_had_skullaxe[id])
		return HAM_IGNORED
	
	set_pdata_string(id, m_szAnimExtention * 4, "skullaxe", -1 , 20)

	if(anim == KNIFE_ANIM_DRAW)
	{
		//set_weapons_timeidle(id, 0.5)
		//set_player_nextattack(id, 0.5)	
		
		set_weapon_anim(id, SKULLAXE_ANIM_DRAW)
	}
	
	return HAM_IGNORED
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!is_user_connected(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_KNIFE || !g_had_skullaxe[id])
		return FMRES_IGNORED
		
	if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
	{
		if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
			return FMRES_SUPERCEDE
		if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') // hit
		{
			if (sample[17] == 'w') // wall
				return FMRES_SUPERCEDE
			else
				return FMRES_SUPERCEDE
		}
		if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a') // stab
			return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id)) 
		return
	if(get_user_weapon(id) != CSW_KNIFE)
		return
	if(!g_had_skullaxe[id])
		return
	
	static ent
	ent = find_ent_by_owner(-1, "weapon_knife", id)
	
	if(!pev_valid(ent))
		return
	if(get_pdata_float(ent, 46, 4) > 0.0 || get_pdata_float(ent, 47, 4) > 0.0) 
		return
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if (CurButton & IN_ATTACK)
	{
		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK)
		
		ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
		
		set_weapons_timeidle(id, 1.7)
		set_player_nextattack(id, 1.7)
		
		set_weapon_anim(id, SKULLAXE_ANIM_STARTSLASH)
		set_task(1.0, "Start_SlashNow", id+TASK_STARTSLASH)
	} else if (CurButton & IN_ATTACK2) {
		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK2)
		
		ExecuteHamB(Ham_Weapon_SecondaryAttack, ent)
		
		set_weapons_timeidle(id, 1.7)
		set_player_nextattack(id, 1.7)
		
		set_weapon_anim(id, SKULLAXE_ANIM_STAB)
		set_task(1.0, "Start_StabNow", id+TASK_STABING)
	}
}

public fw_TraceLine(Float:vector_start[3], Float:vector_end[3], ignored_monster, id, handle)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED
	if(zb3_get_user_zombie(id))
		return FMRES_IGNORED		
	if (get_user_weapon(id) != CSW_KNIFE)
		return FMRES_IGNORED
	if(!g_had_skullaxe[id])
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)

	xs_vec_mul_scalar(v_forward, 0.0, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, ignored_monster, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_TraceHull(Float:vector_start[3], Float:vector_end[3], ignored_monster, hull, id, handle)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED
	if(zb3_get_user_zombie(id))
		return FMRES_IGNORED
	if (get_user_weapon(id) != CSW_KNIFE)
		return FMRES_IGNORED
	if(!g_had_skullaxe[id])
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)

	xs_vec_mul_scalar(v_forward, 0.0, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceHull, vecStart, vecEnd, ignored_monster, hull, id, handle)
	
	return FMRES_SUPERCEDE
}

public Start_SlashNow(id)
{
	id -= TASK_STARTSLASH
	
	if (!is_user_alive(id)) 
		return
	if(!g_had_skullaxe[id])
		return	
		
	if(!Check_Slash(id, 1))
	{
		set_weapon_anim(id, SKULLAXE_ANIM_SLASHMISS)
		EmitSound(id, CHAN_WEAPON, miss_sound)
		
		set_task(0.2, "Slash_Miss", id+TASK_SLASHING)
		
	} else {
		set_weapon_anim(id, SKULLAXE_ANIM_SLASHHIT)
		EmitSound(id, CHAN_WEAPON, hit_sound)
		
		set_task(0.2, "Slash_Hit", id+TASK_SLASHING)
	}
}

public Start_StabNow(id)
{
	id -= TASK_STABING
	
	if (!is_user_alive(id)) 
		return
	if(!g_had_skullaxe[id])
		return		
		
	if(get_user_weapon(id) != CSW_KNIFE)
	{
		set_weapons_timeidle(id, 0.0)
		set_player_nextattack(id, 0.0)
	} else {
		set_weapons_timeidle(id, 0.5)
		set_player_nextattack(id, 0.5)
	}		
		
	if(!Check_Stab(id, 1))
	{
		EmitSound(id, CHAN_WEAPON, miss_sound)
	} else {	
		EmitSound(id, CHAN_WEAPON, hit_sound)
		Check_Stab(id, 0)
	}
}

public Slash_Miss(id)
{
	id -= TASK_SLASHING
	
	if (!is_user_alive(id)) 
		return
	if(!g_had_skullaxe[id])
		return	
	
	if(get_user_weapon(id) != CSW_KNIFE)
	{
		set_weapons_timeidle(id, 0.0)
		set_player_nextattack(id, 0.0)
	} else {
		set_weapons_timeidle(id, 0.15)
		set_player_nextattack(id, 0.15)
	}
}

public Slash_Hit(id)
{
	id -= TASK_SLASHING
	
	if (!is_user_alive(id)) 
		return
	if(!g_had_skullaxe[id])
		return	
	
	if(get_user_weapon(id) != CSW_KNIFE)
	{
		set_weapons_timeidle(id, 0.0)
		set_player_nextattack(id, 0.0)
	} else {
		set_weapons_timeidle(id, 0.2)
		set_player_nextattack(id, 0.2)
	}

	Check_Slash(id, 0)
}

public Check_Slash(id, First_Check)
{
	#define MAX_POINT 4
	static Float:Max_Distance, Float:Point[MAX_POINT][3], Float:TB_Distance
	
	Max_Distance = RADIUS_SLASH
	TB_Distance = Max_Distance / float(MAX_POINT)
	
	static Float:VicOrigin[3], Float:MyOrigin[3]
	pev(id, pev_origin, MyOrigin)
	
	for(new i = 0; i < MAX_POINT; i++)
		get_position(id, TB_Distance * (i + 1), 0.0, 0.0, Point[i])
		
	static Have_Victim; Have_Victim = 0
	static ent
	ent = fm_get_user_weapon_entity(id, get_user_weapon(id))
		
	if(!pev_valid(ent))
		return 0
		
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		if(id == i)
			continue
		//if(zb3_get_user_zombie(i))
		//	continue
		if(entity_range(id, i) > Max_Distance)
			continue
	
		pev(i, pev_origin, VicOrigin)
		if(is_wall_between_points(MyOrigin, VicOrigin, id))
			continue
			
		if(get_distance_f(VicOrigin, Point[0]) <= DISTANCE_FROM_ATTACK
		|| get_distance_f(VicOrigin, Point[1]) <= DISTANCE_FROM_ATTACK
		|| get_distance_f(VicOrigin, Point[2]) <= DISTANCE_FROM_ATTACK
		|| get_distance_f(VicOrigin, Point[3]) <= DISTANCE_FROM_ATTACK)
		{
			if(!Have_Victim) Have_Victim = 1
			if(!First_Check && g_can_attack && cs_get_user_team(id) != cs_get_user_team(i)) do_attack(id, i, ent, DAMAGE_SLASH)
		}
	}	
	
	if(Have_Victim)
		return 1
	else
		return 0
}	

public Check_Stab(id, First_Check)
{
	#define MAX_POINT 4
	static Float:Max_Distance, Float:Point[MAX_POINT][3], Float:TB_Distance
	
	Max_Distance = RADIUS_STAB
	TB_Distance = Max_Distance / float(MAX_POINT)
	
	static Float:VicOrigin[3], Float:MyOrigin[3]
	pev(id, pev_origin, MyOrigin)
	
	for(new i = 0; i < MAX_POINT; i++)
		get_position(id, TB_Distance * (i + 1), 0.0, 0.0, Point[i])
		
	static Have_Victim; Have_Victim = 0
	static ent
	ent = fm_get_user_weapon_entity(id, get_user_weapon(id))
		
	if(!pev_valid(ent))
		return 0
		
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		if(id == i)
			continue
		if(entity_range(id, i) > Max_Distance)
			continue
	
		pev(i, pev_origin, VicOrigin)
		if(is_wall_between_points(MyOrigin, VicOrigin, id))
			continue
			
		if(get_distance_f(VicOrigin, Point[0]) <= (DISTANCE_FROM_ATTACK * 2.0)
		|| get_distance_f(VicOrigin, Point[1]) <= (DISTANCE_FROM_ATTACK * 2.0)
		|| get_distance_f(VicOrigin, Point[2]) <= (DISTANCE_FROM_ATTACK * 2.0)
		|| get_distance_f(VicOrigin, Point[3]) <= (DISTANCE_FROM_ATTACK * 2.0))
		{
			if(!Have_Victim) Have_Victim = 1
			if(!First_Check && g_can_attack && cs_get_user_team(id) != cs_get_user_team(i)) do_attack(id, i, ent, DAMAGE_STAB)
		}
	}	
	
	if(Have_Victim)
		return 1
	else
		return 0
}	

do_attack(Attacker, Victim, Inflictor, Float:fDamage)
{
	fake_player_trace_attack(Attacker, Victim, fDamage)
	fake_take_damage(Attacker, Victim, fDamage, Inflictor)
}

fake_player_trace_attack(iAttacker, iVictim, &Float:fDamage)
{
	// get fDirection
	new Float:fAngles[3], Float:fDirection[3]
	pev(iAttacker, pev_angles, fAngles)
	angle_vector(fAngles, ANGLEVECTOR_FORWARD, fDirection)
	
	// get fStart
	new Float:fStart[3], Float:fViewOfs[3]
	pev(iAttacker, pev_origin, fStart)
	pev(iAttacker, pev_view_ofs, fViewOfs)
	xs_vec_add(fViewOfs, fStart, fStart)
	
	// get aimOrigin
	new iAimOrigin[3], Float:fAimOrigin[3]
	get_user_origin(iAttacker, iAimOrigin, 3)
	IVecFVec(iAimOrigin, fAimOrigin)
	
	// TraceLine from fStart to AimOrigin
	new ptr = create_tr2() 
	engfunc(EngFunc_TraceLine, fStart, fAimOrigin, DONT_IGNORE_MONSTERS, iAttacker, ptr)
	new pHit = get_tr2(ptr, TR_pHit)
	new iHitgroup = get_tr2(ptr, TR_iHitgroup)
	new Float:fEndPos[3]
	get_tr2(ptr, TR_vecEndPos, fEndPos)

	// get target & body at aiming
	new iTarget, iBody
	get_user_aiming(iAttacker, iTarget, iBody)
	
	// if aiming find target is iVictim then update iHitgroup
	if (iTarget == iVictim)
	{
		iHitgroup = iBody
	}
	
	// if ptr find target not is iVictim
	else if (pHit != iVictim)
	{
		// get AimOrigin in iVictim
		new Float:fVicOrigin[3], Float:fVicViewOfs[3], Float:fAimInVictim[3]
		pev(iVictim, pev_origin, fVicOrigin)
		pev(iVictim, pev_view_ofs, fVicViewOfs) 
		xs_vec_add(fVicViewOfs, fVicOrigin, fAimInVictim)
		fAimInVictim[2] = fStart[2]
		fAimInVictim[2] += get_distance_f(fStart, fAimInVictim) * floattan( fAngles[0] * 2.0, degrees )
		
		// check aim in size of iVictim
		new iAngleToVictim = get_angle_to_target(iAttacker, fVicOrigin)
		iAngleToVictim = abs(iAngleToVictim)
		new Float:fDis = 2.0 * get_distance_f(fStart, fAimInVictim) * floatsin( float(iAngleToVictim) * 0.5, degrees )
		new Float:fVicSize[3]
		pev(iVictim, pev_size , fVicSize)
		if ( fDis <= fVicSize[0] * 0.5 )
		{
			// TraceLine from fStart to aimOrigin in iVictim
			new ptr2 = create_tr2() 
			engfunc(EngFunc_TraceLine, fStart, fAimInVictim, DONT_IGNORE_MONSTERS, iAttacker, ptr2)
			new pHit2 = get_tr2(ptr2, TR_pHit)
			new iHitgroup2 = get_tr2(ptr2, TR_iHitgroup)
			
			// if ptr2 find target is iVictim
			if ( pHit2 == iVictim && (iHitgroup2 != HIT_HEAD || fDis <= fVicSize[0] * 0.25) )
			{
				pHit = iVictim
				iHitgroup = iHitgroup2
				get_tr2(ptr2, TR_vecEndPos, fEndPos)
			}
			
			free_tr2(ptr2)
		}
		
		// if pHit still not is iVictim then set default HitGroup
		if (pHit != iVictim)
		{
			// set default iHitgroup
			iHitgroup = HIT_GENERIC
			
			new ptr3 = create_tr2() 
			engfunc(EngFunc_TraceLine, fStart, fVicOrigin, DONT_IGNORE_MONSTERS, iAttacker, ptr3)
			get_tr2(ptr3, TR_vecEndPos, fEndPos)
			
			// free ptr3
			free_tr2(ptr3)
		}
	}
	
	// set new Hit & Hitgroup & EndPos
	set_tr2(ptr, TR_pHit, iVictim)
	set_tr2(ptr, TR_iHitgroup, iHitgroup)
	set_tr2(ptr, TR_vecEndPos, fEndPos)
	
	// hitgroup multi fDamage
	new Float:fMultifDamage 
	switch(iHitgroup)
	{
		case HIT_HEAD: fMultifDamage  = 4.0
		case HIT_STOMACH: fMultifDamage  = 1.25
		case HIT_LEFTLEG: fMultifDamage  = 0.75
		case HIT_RIGHTLEG: fMultifDamage  = 0.75
		default: fMultifDamage  = 1.0
	}
	
	fDamage *= fMultifDamage
	
	// ExecuteHam
	fake_trake_attack(iAttacker, iVictim, fDamage, fDirection, ptr)
	
	// free ptr
	free_tr2(ptr)
}

stock fake_trake_attack(iAttacker, iVictim, Float:fDamage, Float:fDirection[3], iTraceHandle, iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
	ExecuteHamB(Ham_TraceAttack, iVictim, iAttacker, fDamage, fDirection, iTraceHandle, iDamageBit)
}

stock fake_take_damage(iAttacker, iVictim, Float:fDamage, iInflictor = 0, iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
	iInflictor = (!iInflictor) ? iAttacker : iInflictor
	ExecuteHamB(Ham_TakeDamage, iVictim, iInflictor, iAttacker, fDamage, iDamageBit)
}

stock get_angle_to_target(id, const Float:fTarget[3], Float:TargetSize = 0.0)
{
	new Float:fOrigin[3], iAimOrigin[3], Float:fAimOrigin[3], Float:fV1[3]
	pev(id, pev_origin, fOrigin)
	get_user_origin(id, iAimOrigin, 3) // end position from eyes
	IVecFVec(iAimOrigin, fAimOrigin)
	xs_vec_sub(fAimOrigin, fOrigin, fV1)
	
	new Float:fV2[3]
	xs_vec_sub(fTarget, fOrigin, fV2)
	
	new iResult = get_angle_between_vectors(fV1, fV2)
	
	if (TargetSize > 0.0)
	{
		new Float:fTan = TargetSize / get_distance_f(fOrigin, fTarget)
		new fAngleToTargetSize = floatround( floatatan(fTan, degrees) )
		iResult -= (iResult > 0) ? fAngleToTargetSize : -fAngleToTargetSize
	}
	
	return iResult
}

stock get_angle_between_vectors(const Float:fV1[3], const Float:fV2[3])
{
	new Float:fA1[3], Float:fA2[3]
	engfunc(EngFunc_VecToAngles, fV1, fA1)
	engfunc(EngFunc_VecToAngles, fV2, fA2)
	
	new iResult = floatround(fA1[1] - fA2[1])
	iResult = iResult % 360
	iResult = (iResult > 180) ? (iResult - 360) : iResult
	
	return iResult
}

stock EmitSound(id, chan, const file_sound[])
{
	if(!pev_valid(id))
		return
		
	emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
	
stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}
	
stock set_weapons_timeidle(id, Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	new entwpn = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if (pev_valid(entwpn)) 
	{
		set_pdata_float(entwpn, 46, TimeIdle, 4)
		set_pdata_float(entwpn, 47, TimeIdle, 4)
		set_pdata_float(entwpn, 48, TimeIdle + 1.0, 4)
	}
}

stock is_wall_between_points(Float:start[3], Float:end[3], ignore_ent)
{
	static ptr
	ptr = create_tr2()

	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ignore_ent, ptr)
	
	static Float:EndPos[3]
	get_tr2(ptr, TR_vecEndPos, EndPos)

	free_tr2(ptr)
	return floatround(get_distance_f(end, EndPos))
} 

stock set_player_nextattack(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	const m_flNextAttack = 83
	set_pdata_float(id, m_flNextAttack, nexttime, 5)
}

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
		
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(0)
	message_end()	
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1066\\ f0\\ fs16 \n\\ par }
*/
