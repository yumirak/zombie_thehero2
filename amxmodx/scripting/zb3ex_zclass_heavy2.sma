#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <xs>
#include <zombie_thehero2>

#define PLUGIN "[ZB3] Zombie Class: Regular"
#define VERSION "2.0"
#define AUTHOR "Dias"

#define IsValidPev(%0) (pev_valid(%0) == 2)

new const LANG_FILE[] = "zombie_thehero2.txt"

// Zombie Configs
new const zclass_name[] = "Heavy"
new const zclass_desc[] = "Trap"
new const zclass_sex = SEX_MALE
new const zclass_lockcost = 0
new const zclass_hostmodel[] = "heavy_zombi_host"
new const zclass_originmodel[] = "heavy_zombi_origin"
new const zclass_clawsmodelhost[] = "v_knife_heavy_zombi.mdl"
new const zclass_clawsmodelorigin[] = "v_knife_heavy_zombi.mdl"
new const zombiegrenade_modelhost[] = "models/zombie_thehero/v_zombibomb_heavy_zombi.mdl"
new const zombiegrenade_modelorigin[] = "models/zombie_thehero/v_zombibomb_heavy_zombi.mdl"
new const Float:zclass_gravity = 0.8
new const Float:zclass_speedhost = 270.0
new const Float:zclass_speedorigin = 270.0
new const Float:zclass_knockback = 0.3
new const Float:zclass_painshock = 0.5
new const Float:zclass_dmgmodifier = 0.8

new const AttackSound[] = "zombie_thehero/zombi_attack_1.wav"
new const SwingSound[] = "zombie_thehero/zombi_swing_1.wav"
new const HitWallSound[] = "zombie_thehero/zombi_wall_1.wav"
new const StabSound[] = "zombie_thehero/zombi_attack_1.wav"

new const DeathSound[2][] = 
{
	"zombie_thehero/zombi_death_heavy_1.wav",
	"zombie_thehero/zombi_death_heavy_2.wav"
}

new const HurtSound[2][] = {
	"zombie_thehero/zombi_hurt_heavy_1.wav",
	"zombie_thehero/zombi_hurt_heavy_2.wav"
}

new const HealSound[] = "zombie_thehero/zombi_heal_heavy.wav"
new const EvolSound[] = "zombie_thehero/zombi_evolution.wav"
new const Float:ClawsDistance1 = 1.0
new const Float:ClawsDistance2 = 1.1

new g_zombie_classid, g_can_set_trap[33], g_current_time[33]

#define LANG_OFFICIAL LANG_PLAYER

#define TRAP_SKILL_COOLDOWN_HOST 10
#define TRAP_SKILL_COOLDOWN_ORIGIN 15

#define TASK_COOLDOWN 12001

const MAX_TRAP = 30
new const trap_classname[] = "zb_trap"
new const TrapSlow[] = "sprites/zombie_thehero/zbt_slow.spr"
new const model_trap[] = "models/zombie_thehero/zombitrap.mdl"
new const sound_trapsetup[] = "zombie_thehero/zombi_trapsetup.wav"
new const sound_trapped[] = "zombie_thehero/zombi_trapped.wav"
// Vars
new g_total_traps[33], g_msgScreenShake, g_player_trapped[33]
new TrapOrigins[33][MAX_TRAP][4]

// Task offsets
enum (+= 100)
{
	TASK_REMOVETRAP = 2000
}

// IDs inside tasks
#define ID_REMOVETRAP (taskid - TASK_REMOVETRAP)
#define TRAP_TOTAL 4
#define TRAP_INVISIBLE 100
#define TRAP_TIME_EFFECT 8.0

new g_synchud1

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary(LANG_FILE)
	register_clcmd("drop", "cmd_drop")

	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")

	g_msgScreenShake = get_user_msgid("ScreenShake")
	g_synchud1 = zb3_get_synchud_id(SYNCHUD_ZBHM_SKILL1)
}

public plugin_precache()
{
	// Register Zombie Class
	g_zombie_classid = zb3_register_zombie_class(zclass_name, zclass_desc, zclass_sex, zclass_lockcost, 
	zclass_gravity, zclass_speedhost, zclass_speedorigin, zclass_knockback, zclass_painshock, zclass_dmgmodifier, 
	ClawsDistance1, ClawsDistance2)
	
	zb3_set_zombie_class_data(zclass_hostmodel, zclass_originmodel, zclass_clawsmodelhost, zclass_clawsmodelorigin, 
	DeathSound[0], DeathSound[1], HurtSound[0], HurtSound[1], HealSound, EvolSound,
	AttackSound,SwingSound, HitWallSound, StabSound)
	
	zb3_register_zbgre_model(zombiegrenade_modelhost, zombiegrenade_modelorigin)
	
	// Precache Class Resource
	engfunc(EngFunc_PrecacheModel, model_trap)
	engfunc(EngFunc_PrecacheSound, sound_trapsetup)
	engfunc(EngFunc_PrecacheSound, sound_trapped)
	engfunc(EngFunc_PrecacheModel, TrapSlow)
}

public zb3_user_infected(id, infector)
{
	if(zb3_get_user_zombie_class(id) == g_zombie_classid)
	{
		reset_skill(id)
		
		g_can_set_trap[id] = 1
		//g_total_traps[id] = 0
		g_current_time[id] = zb3_get_user_level(id) > 1 ? (TRAP_SKILL_COOLDOWN_ORIGIN) : (TRAP_SKILL_COOLDOWN_HOST)
	}
}

public reset_skill(id)
{
	if (task_exists(id+TASK_REMOVETRAP)) remove_task(id+TASK_REMOVETRAP)

	g_player_trapped[id] = 0
	g_can_set_trap[id] = 0
	//g_total_traps[id] = 0
	//remove_trap(id)
	//if(g_total_traps[id]) remove_traps_player(id)
	remove_traps_player(id) // g_total_traps[id] = 0
}
public zb3_user_dead(id) 
{
	reset_skill(id)
	//if(g_total_traps[id]) remove_traps_player(id)
}

public zb3_game_start(start_type)
{
	if(start_type == GAMESTART_NEWROUND) remove_traps()
}

public cmd_drop(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	if(!zb3_get_user_zombie(id))
		return PLUGIN_CONTINUE
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return PLUGIN_CONTINUE
	if(!g_can_set_trap[id])
		return PLUGIN_HANDLED

	if (g_total_traps[id] )
	{
		client_print(id, print_center,"Current trap deployed max : %i) ", g_total_traps[id])
		return PLUGIN_HANDLED
	}	

	Do_Trap(id)

	return PLUGIN_HANDLED
}

public Do_Trap(id)
{
	g_can_set_trap[id] = 0
	g_current_time[id] = 0
	
	// set trapping
	create_trap(id)

	// play sound
	EmitSound(id, sound_trapsetup)

	return PLUGIN_HANDLED
}
// don't move when traped (called per frame)

public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id) || !g_player_trapped[id])  // call only when someone got trapped
		return;

	new ent_trap = g_player_trapped[id]
	//static Float:vecVelocity[3]
	
	if(!pev_valid(ent_trap))
	{
		if (task_exists(id+TASK_REMOVETRAP)) remove_task(id+TASK_REMOVETRAP)
		RemoveTrap(id+TASK_REMOVETRAP)
		return;
	}
	
	if (ent_trap && pev_valid(ent_trap)) // player is trapped 
	{	
		if(zb3_get_user_zombie(id)) // release trapped player when infected
		{
			if (task_exists(id+TASK_REMOVETRAP)) remove_task(id+TASK_REMOVETRAP)
			RemoveTrap(id+TASK_REMOVETRAP)
			return;
		}
		//pev(id, pev_velocity, vecVelocity);
		//xs_vec_mul_scalar(vecVelocity, 0.1, vecVelocity);
		set_pev(id, pev_velocity, {0.0,0.0,0.0});
		//zb3_set_user_speed(id, 1) // set player speed

		switch(pev(ent_trap, pev_sequence)) // trap animation
		{
			case 1: 
			{ 
				switch(pev(ent_trap, pev_frame))
				{
					case 0..230: set_pev(ent_trap, pev_frame, pev(ent_trap, pev_frame) + 1.0)
					default: set_pev(ent_trap, pev_frame, 20.0)
				}
			}
			default: { set_pev(ent_trap, pev_sequence, 1); set_pev(ent_trap, pev_frame, 0.0); }
		}
	}
	
}
// touch trap (called per frame)
public pfn_touch(ptr, ptd)
{
	if(pev_valid(ptr) && !zb3_get_user_zombie(ptd)) // call only when human touches trap
	{
		static classname[32]
		pev(ptr, pev_classname, classname, charsmax(classname))
		
		if(equal(classname, trap_classname))
		{
			if (is_user_alive(ptd) && g_player_trapped[ptd] != ptr && pev(ptr, pev_sequence) != 1) // don't repeat trap a trapped player
			{
				Trapped(ptd, ptr)
			}
		}
	}
}

Trapped(id, ent_trap)
{
	// check trapped
	for (new i=1; i< get_maxplayers(); i++)
	{
		if (is_user_connected(i) && g_player_trapped[i]==ent_trap) return;
	}
	
	// set ent trapped of player
	g_player_trapped[id] = ent_trap
	
	// set screen shake
	user_screen_shake(id, 4, 2, 5)
			
	// play sound
	EmitSound(id, sound_trapped)

	// reset invisible model trapped
	fm_set_rendering(ent_trap)
	zb3_showattachment(id, TrapSlow, TRAP_TIME_EFFECT, 1.0, 1.0, 0)
	
	// set task remove trap
	if (task_exists(id+TASK_REMOVETRAP)) remove_task(id+TASK_REMOVETRAP)
	set_task(TRAP_TIME_EFFECT, "RemoveTrap", id+TASK_REMOVETRAP)
}
public RemoveTrap(taskid)
{
	new id = ID_REMOVETRAP
	
	// remove trap
	remove_trapped_when_infected(id)
	
	if (task_exists(taskid)) remove_task(taskid)
}
remove_trapped_when_infected(id)
{
	new p_trapped = g_player_trapped[id]
	if (p_trapped)
	{
		// remove trap
		//if (pev_valid(p_trapped)) engfunc(EngFunc_RemoveEntity, p_trapped)
		//zb3_reset_user_speed(id)
		// reset value of player
		g_player_trapped[id] = 0
		//g_total_traps[id] -= 1
		remove_traps_player(pev(p_trapped, pev_owner) )
	}
}
create_trap(id)
{
	if (!zb3_get_user_zombie(id)) return -1;
	
	// get origin
	new Float:origin[3]
	pev(id, pev_origin, origin)

	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if (!ent) return -1;
	
	// Set trap data
	set_pev(ent, pev_classname, trap_classname)
	set_pev(ent, pev_solid, SOLID_TRIGGER)
	set_pev(ent, pev_movetype, MOVETYPE_TOSS)
	set_pev(ent, pev_sequence, 0)
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_owner, id)
	//set_pev(ent, pev_iuser1, id)
	
	// Set trap size
	new Float:mins[3] = { -20.0, -20.0, 0.0 }
	new Float:maxs[3] = { 20.0, 20.0, 30.0 }
	engfunc(EngFunc_SetSize, ent, mins, maxs)
	
	// Set trap model
	engfunc(EngFunc_SetModel, ent, model_trap)

	// Set trap position
	set_pev(ent, pev_origin, origin)
	
	
	// set invisible
	fm_set_rendering(ent,kRenderFxNone,0,0,0,kRenderTransAlpha, TRAP_INVISIBLE)
	
	// trap counter
	g_total_traps[id] += 1
	TrapOrigins[id][g_total_traps[id]][0] = ent
	TrapOrigins[id][g_total_traps[id]][1] = FloatToNum(origin[0])
	TrapOrigins[id][g_total_traps[id]][2] = FloatToNum(origin[1])
	TrapOrigins[id][g_total_traps[id]][3] = FloatToNum(origin[2])
	
	return -1;
}

fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) 
{
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);

	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, RenderColor);
	set_pev(entity, pev_rendermode, render);
	set_pev(entity, pev_renderamt, float(amount));

	return 1;
}

FloatToNum(Float:floatn)
{
	new str[64], num
	float_to_str(floatn, str, 63)
	num = str_to_num(str)
	
	return num
}


remove_traps()
{
	// reset model
	new nextitem  = find_ent_by_class(-1, trap_classname)
	while(nextitem)
	{
		if (pev_valid(nextitem)) remove_entity(nextitem)
		nextitem = find_ent_by_class(-1, trap_classname)
	}
}

remove_traps_player(id)
{
	// remove model trap in map
	//for (new i = g_total_traps[id]; i <= MAX_TRAP; i++)
	//{
	new trap_ent = TrapOrigins[id][1][0]
	if (pev_valid(trap_ent)) engfunc(EngFunc_RemoveEntity, trap_ent)
	g_total_traps[id] = 0
	//}
	
}
/*
remove_traps_player(id)
{
	// remove model trap in map
	for (new i = 1; i <= g_total_traps[id]; i++)
	{
		new trap_ent = TrapOrigins[id][i][0]
		if (pev_valid(trap_ent)) engfunc(EngFunc_RemoveEntity, trap_ent)
	}
	
}*/
user_screen_shake(id, amplitude = 4, duration = 2, frequency = 10)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
	write_short((1<<12)*amplitude) // ??
	write_short((1<<12)*duration) // ??
	write_short((1<<12)*frequency) // ??
	message_end()
}

public zb3_skill_show(id)
{
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 	
		
	if(g_current_time[id] < (zb3_get_user_level(id) > 1 ? (TRAP_SKILL_COOLDOWN_ORIGIN): (TRAP_SKILL_COOLDOWN_HOST )))
		g_current_time[id]++
	
	static percent
	static timewait
	
	timewait = zb3_get_user_level(id) > 1 ? (TRAP_SKILL_COOLDOWN_ORIGIN): (TRAP_SKILL_COOLDOWN_HOST )
	percent = floatround((float(g_current_time[id]) / float(timewait)) * 100.0)
	
	set_hudmessage(255, 255, 255, -1.0, 0.10, 0, 3.0, 3.0)
	ShowSyncHudMsg(id, g_synchud1, "%L", LANG_PLAYER, "ZOMBIE_SKILL_SINGLE", zclass_desc, percent)
	if(percent >= 99) 
		g_can_set_trap[id] = 1
		
}

stock EmitSound(id, const file_sound[])
{
	if(!is_user_connected(id))
		return
		
	emit_sound(id, CHAN_VOICE, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
