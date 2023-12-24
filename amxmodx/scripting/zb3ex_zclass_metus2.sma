#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_thehero2>

#define PLUGIN "[ZB3] Zombie Class: Regular"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const LANG_FILE[] = "zombie_thehero2.txt"

// Zombie Configs
new const zclass_name[] = "Metus"
new const zclass_desc[] = "Rush"
new const zclass_sex = SEX_MALE
new const zclass_lockcost = 7000
new const zclass_hostmodel[] = "deimos_zombi_host"
new const zclass_originmodel[] = "deimos2_zombi_origin"
new const zclass_clawsmodelhost[] = "v_knife_deimos_zombi_host.mdl"
new const zclass_clawsmodelorigin[] = "v_knife_deimos2_zombi.mdl"
new const zombiegrenade_modelhost[] = "models/zombie_thehero/v_zombibomb_deimos_zombi_host.mdl"
new const zombiegrenade_modelorigin[] = "models/zombie_thehero/v_zombibomb_deimos2_zombi_origin.mdl"
new const Float:zclass_gravity = 0.8
new const Float:zclass_speedhost = 280.0
new const Float:zclass_speedorigin = 280.0
new const Float:zclass_knockback = 0.4
new const Float:zclass_painshock = 0.5
new const Float:zclass_dmgmulti = 0.9
new const DeathSound[2][] =
{
	"zombie_thehero/zombi_death_1.wav",
	"zombie_thehero/zombi_death_2.wav"
}
new const HurtSound[2][] = 
{
	"zombie_thehero/zombi_hurt_01.wav",
	"zombie_thehero/zombi_hurt_02.wav"	
}
new const AttackSound[] = "zombie_thehero/zombi_attack_1.wav"
new const SwingSound[] = "zombie_thehero/zombi_swing_1.wav"
new const HitWallSound[] = "zombie_thehero/zombi_wall_1.wav"

new const HealSound[] = "zombie_thehero/zombi_heal.wav"
new const EvolSound[] = "zombie_thehero/zombi_evolution.wav"
new const Float:ClawsDistance1 = 1.0
new const Float:ClawsDistance2 = 1.1

new g_zombie_classid, g_can_charge[33], g_charging[33], g_current_time[33]
new const berserk_startsound[] = "zombie_thehero/zombi_pressure.wav"


#define LANG_OFFICIAL LANG_PLAYER

#define CHARGE_COLOR_R 255
#define CHARGE_COLOR_G 3
#define CHARGE_COLOR_B 0

#define FASTRUN_FOV 105
#define CHARGE_SPEED 400
#define CHARGE_GRAVITY 0.7

#define CHARGE_TIME_HOST 7
#define CHARGE_TIME_ORIGIN 15
#define CHARGE_COOLDOWN_HOST (2 * CHARGE_TIME_HOST)
#define CHARGE_COOLDOWN_ORIGIN (2 * CHARGE_TIME_ORIGIN)

#define TASK_CHARGING 13025
#define TASK_COOLDOWN 13026

const OFFSET_PAINSHOCK = 108

new g_Msg_Fov, g_synchud1

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary(LANG_FILE)

	RegisterHam(Ham_TakeDamage, "player", "fw_takedamage", false);

	register_clcmd("drop", "cmd_drop")
	//RegisterHam(Ham_TakeDamage, "player", "fw_PlayerTakeDamage_Post", 1)
	g_Msg_Fov = get_user_msgid("SetFOV")
	g_synchud1 = zb3_get_synchud_id(SYNCHUD_ZBHM_SKILL1)
}

public plugin_precache()
{
	// Register Zombie Class
	g_zombie_classid = zb3_register_zombie_class(zclass_name, zclass_desc, zclass_sex, zclass_lockcost, 
	zclass_gravity, zclass_speedhost, zclass_speedorigin, zclass_knockback, zclass_painshock, zclass_dmgmulti,
	ClawsDistance1, ClawsDistance2)
	
	zb3_set_zombie_class_data(zclass_hostmodel, zclass_originmodel, zclass_clawsmodelhost, zclass_clawsmodelorigin, 
	DeathSound[0], DeathSound[1], HurtSound[0], HurtSound[1], HealSound, EvolSound,
	AttackSound,SwingSound, HitWallSound, AttackSound )
	
	zb3_register_zbgre_model(zombiegrenade_modelhost, zombiegrenade_modelorigin)
	
	// Precache Class Resource
	engfunc(EngFunc_PrecacheSound, berserk_startsound)
	
}

public zb3_user_infected(id, infector, infect_flag)
{
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return;

	switch(infect_flag)
	{
		case INFECT_VICTIM: reset_skill(id, true) 
		case INFECT_CHANGECLASS:
		{
			if(g_charging[id]) {
				zb3_set_user_speed(id, CHARGE_SPEED)
				zb3_set_user_gravity(id, CHARGE_GRAVITY) 
			}
		} 
	}
}
public zb3_user_change_class(id, oldclass, newclass)
{
	if(newclass == g_zombie_classid && oldclass != newclass)
		reset_skill(id, true)
}

public reset_skill(id, bool:reset_time)
{
	if( reset_time ) 
		g_current_time[id] = zb3_get_user_level(id) > 1 ? CHARGE_COOLDOWN_ORIGIN : CHARGE_COOLDOWN_HOST

	g_can_charge[id] = reset_time ? 1 : 0
	g_charging[id] = 0

	if(task_exists(id+TASK_CHARGING)) remove_task(id+TASK_CHARGING)
	
	if(is_user_connected(id)) set_fov(id)
}

public zb3_user_spawned(id) 
{
	if(!zb3_get_user_zombie(id))
		reset_skill(id, false)
}

public zb3_user_dead(id) 
{
	if(!zb3_get_user_zombie(id))
		return;
	if( zb3_get_user_zombie_class(id) != g_zombie_classid)
		return;

	reset_skill(id, false)
}

public fw_takedamage(victim, inflictor, attacker, Float: damage)
{
	if(!is_user_alive(victim))
		return HAM_IGNORED;
	if(!zb3_get_user_zombie(victim))
		return HAM_IGNORED;
	if( zb3_get_user_zombie_class(victim) != g_zombie_classid)
		return HAM_IGNORED;
	if(!g_charging[victim])
		return HAM_IGNORED;
	
	damage *= 2.0;
	SetHamParamFloat(4, damage);
	
	return HAM_HANDLED;
}
public bot_use_skill(id)
{
	if(!is_user_alive(id) || !zb3_get_user_zombie(id))
		return PLUGIN_CONTINUE
		
	cmd_drop(id)
	set_task(zb3_get_user_level(id) > 1 ? float(CHARGE_COOLDOWN_ORIGIN) : float(CHARGE_COOLDOWN_HOST),"bot_use_skill",id)
	return PLUGIN_HANDLED
}
public cmd_drop(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	if(!zb3_get_user_zombie(id))
		return PLUGIN_CONTINUE
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return PLUGIN_CONTINUE
	if(!g_can_charge[id] || g_charging[id])
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZOMBIE_SKILL_NOT_READY", zclass_desc , get_cooldowntime(id) - g_current_time[id])
		return PLUGIN_HANDLED
	}
		
	Do_Charge(id)

	return PLUGIN_HANDLED
}

public Do_Charge(id)
{
	zb3_reset_user_speed(id)
		
	// Set Vars
	g_charging[id] = 1
	g_can_charge[id] = 0
	g_current_time[id] = 0
		
	// Decrease Health
	//zb3_set_user_health(id, get_user_health(id) - HEALTH_DECREASE)
		
	// Set Render Red
	zb3_set_user_rendering(id, kRenderFxGlowShell, CHARGE_COLOR_R, CHARGE_COLOR_G, CHARGE_COLOR_B, kRenderNormal, 0)
	
	// Set Fov
	set_fov(id, FASTRUN_FOV)
		
	// Set MaxSpeed & Gravity
	zb3_set_user_speed(id, CHARGE_SPEED)
	zb3_set_user_gravity(id, CHARGE_GRAVITY)
	//set_pev(id, pev_gravity, CHARGE_GRAVITY)	
	// Play Berserk Sound
	EmitSound(id, CHAN_VOICE, berserk_startsound)
		
	// Set Task
	//set_task(2.0, "Berserk_HeartBeat", id+TASK_BERSERK_SOUND)
		
	static Float:SkillTime
	SkillTime = zb3_get_user_level(id) > 1 ? float(CHARGE_TIME_ORIGIN) : float(CHARGE_TIME_HOST)
	if(task_exists(id+TASK_CHARGING)) remove_task(id+TASK_CHARGING)	
	set_task(SkillTime, "Remove_Charge", id+TASK_CHARGING)
	
}

public Remove_Charge(id)
{
	id -= TASK_CHARGING

	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 
	if(!g_charging[id])
		return	

	// Set Vars
	g_charging[id] = 0
	//g_can_charge[id] = 0	
	
	// Reset Rendering
	zb3_set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
	zb3_reset_user_gravity(id)
	// Reset FOV
	set_fov(id)
	
	// Reset Speed
	static Float:DefaultSpeed
	DefaultSpeed = zb3_get_user_level(id) > 1 ? zclass_speedorigin : zclass_speedhost
	
	zb3_set_user_speed(id, floatround(DefaultSpeed))
}

public zb3_skill_show(id)
{
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 	
		
	if(g_current_time[id] < (zb3_get_user_level(id) > 1 ? (CHARGE_COOLDOWN_ORIGIN): (CHARGE_COOLDOWN_HOST )))
		g_current_time[id]++
	
	static percent
	static timewait
	
	timewait = zb3_get_user_level(id) > 1 ? (CHARGE_COOLDOWN_ORIGIN): (CHARGE_COOLDOWN_HOST )
	percent = floatround((float(g_current_time[id]) / float(timewait)) * 100.0)
	
	set_hudmessage(255, 255, 255, -1.0, 0.10, 0, 3.0, 3.0)
	//ShowSyncHudMsg(id, g_synchud1, "[G] %s %i%%", zclass_desc, percent)
	ShowSyncHudMsg(id, g_synchud1, "%L", LANG_PLAYER, "ZOMBIE_SKILL_SINGLE", zclass_desc, percent)	
	if(percent > 99 && !g_can_charge[id]) 
		g_can_charge[id] = 1
		
}

stock set_fov(id, num = 90)
{
	if(!is_user_connected(id))
		return
	
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_Fov, {0,0,0}, id)
	write_byte(num)
	message_end()
}

stock EmitSound(id, chan, const file_sound[])
{
	if(!is_user_connected(id))
		return
		
	emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
stock get_cooldowntime(id)
{
	if(!zb3_get_user_zombie(id))
		return 0
	//return zb3_get_user_level(id) > 1 ? BERSERK_COOLDOWN_ORIGIN + BERSERK_TIME_ORIGIN : BERSERK_COOLDOWN_HOST + BERSERK_TIME_HOST
	return zb3_get_user_level(id) > 1 ? CHARGE_COOLDOWN_ORIGIN : CHARGE_COOLDOWN_HOST
}