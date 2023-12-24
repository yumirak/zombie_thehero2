#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <zombie_thehero2>

#define PLUGIN "[ZB3EX] ExtraItem Human"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define DELAY_TIME 2.0
#define ITEM_FILE "zombie_thehero_item.ini"

// Configs
const g_wb_cost = 3000
const Float:g_wb_gravity = 0.75

const g_dg_cost = 2000
const g_p30_cost = 5000
	
const g_sprint_cost = 5000
const Float:fastrun_time = 10.0
const Float:fastrun_speed = 340.0
const Float:slowrun_time = 5.0
const Float:slowrun_speed = 140.0
new const sound_fastrun_start[] = "zombie_thehero/speedup.wav"
new const sound_fastrun_heartbeat[] = "zombie_thehero/speedup_heartbeat.wav"
new const sound_breath_male[] = "zombie_thehero/human_breath_male.wav"
new const sound_breath_female[] = "zombie_thehero/human_breath_female.wav"

const g_deadlyshot_cost = 7000
const Float:g_deadlyshot_time = 5.0
new const g_deadlyshot_icon[] = "sprites/zombie_thehero/zb_skill_headshot.spr"
	
const g_bloodyblade_cost = 7000
const Float:g_bloodyblade_damage = 2.0	
const Float:g_bloodyblade_time = 5.0
new const g_bloodyblade_icon[] = "sprites/zombie_thehero/zb_meleeup.spr"
/// ===== Configs

new g_sync_hud1, g_sync_hud2
new Float:g_hud_delay[33]
new g_register, g_zombie_appear

// Wing Boot
new g_wing_boot, g_had_wing_boot[33]

// Double Grenade
new g_double_grenade, g_had_double_grenade[33], g_doubled_grenade[33]

// Sprint
new g_sprint
new g_had_sprint[33], g_can_use_sprint[33], g_using_sprint[33], g_sprint_status[33]

#define TASK_REMOVE_FASTRUN 59384543
#define TASK_REMOVE_SLOWRUN 5893485
#define TASK_HUMAN_SOUND 53450834

// +30% Damage
new g_p30_damage, g_had_p30_damage[33]

// Deadly Shot
new g_deadlyshot, g_had_deadlyshot[33], g_can_use_deadlyshot[33], g_using_deadlyshot[33]

#define TASK_REMOVE_DEADLYSHOT 839483

// Bloody Blade
new g_bloodyblade, g_had_bloodyblade[33], g_can_use_bloodyblade[33], g_using_bloodyblade[33]

#define TASK_REMOVE_BLOODYBLADE 839485

new g_Msg_ScreenFade

// NightVision
new g_nightvision, g_had_nvg[33]
const g_nightvision_cost = 1000

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_sync_hud1 = zb3_get_synchud_id(SYNCHUD_HUMANZOMBIE_ITEM)
	g_sync_hud2 = zb3_get_synchud_id(SYNCHUD_ZBHM_SKILL1)
	
	RegisterHam(Ham_Item_AddToPlayer, "weapon_hegrenade", "fw_Add_Hegrenade_Post", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")

	//register_forward(FM_ClientConnect, "fw_client_connect" );
	
	g_Msg_ScreenFade = get_user_msgid("ScreenFade")
	
	register_clcmd("sprint", "do_fastrun")
	register_clcmd("deadlyshot", "do_deadlyshot")
	register_clcmd("bloodyblade", "do_bloodyblade")
}

public plugin_precache()
{
	precache_sound(sound_fastrun_start)
	precache_sound(sound_fastrun_heartbeat)
	precache_sound(sound_breath_male)
	precache_sound(sound_breath_female)
	
	precache_model(g_deadlyshot_icon)
	precache_model(g_bloodyblade_icon)
	
	g_wing_boot = zb3_register_item("Boot", "More High Jump", g_wb_cost, TEAM2_HUMAN, 1)
	g_double_grenade = zb3_register_item("x2 Grenade", "+1 More Grenade", g_dg_cost, TEAM2_HUMAN, 1)
	g_p30_damage = zb3_register_item("+30% Damage", "Start Damage is 130%", g_p30_cost, TEAM2_HUMAN, 1)
	g_sprint = zb3_register_item("Sprint", "Sprint for 10 Sec", g_sprint_cost, TEAM2_HUMAN, 1)
	g_deadlyshot = zb3_register_item("Deadly Shot", "Deal Headshot for 5 Sec", g_deadlyshot_cost, TEAM2_HUMAN, 1)
	g_bloodyblade = zb3_register_item("Bloody Blade", "Deal Double Melee Damage", g_bloodyblade_cost, TEAM2_HUMAN, 1)
	g_nightvision = zb3_register_item("NightVision", "See in Dark", g_nightvision_cost, TEAM2_HUMAN, 1)
}

public client_connect(id)
{
	g_had_wing_boot[id] = 0
	g_had_double_grenade[id] = 0
	g_had_p30_damage[id] = 0
	g_had_sprint[id] = 0
	g_can_use_sprint[id] = 0
	g_using_sprint[id] = 0
	g_sprint_status[id] = 0
	g_had_deadlyshot[id] = is_user_bot(id) ? 1 : 0
	g_can_use_deadlyshot[id] = is_user_bot(id) ? 1 : 0
	g_using_deadlyshot[id] = 0
	g_had_bloodyblade[id] = 0
	g_can_use_bloodyblade[id] = 0
	g_using_bloodyblade[id] = 0
	g_had_nvg[id] = 0
}

public client_putinserver(id)
{
	if(is_user_bot(id) && !g_register)
	{
		g_register = 1
		set_task(0.1, "do_register", id)
	}
}

public do_register(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
}

public zb3_item_selected_post(id, itemid)
{
	if(itemid == g_wing_boot){
		g_had_wing_boot[id] = 1
		set_wing_boot(id)
	} else if(itemid == g_double_grenade) {
		g_had_double_grenade[id] = 1
		set_double_grenade(id)
	} else if(itemid == g_p30_damage) {
		g_had_p30_damage[id] = 1
		set_p30_damage(id)
	} else if(itemid == g_sprint) {
		g_had_sprint[id] = 1
		set_user_item_sprint(id)
	} else if(itemid == g_deadlyshot) {
		g_had_deadlyshot[id] = 1
		set_user_deadlyshot(id)
	} else if(itemid == g_bloodyblade) {
		g_had_bloodyblade[id] = 1
		set_user_bloodyblade(id)
	} else if(itemid == g_nightvision) {
		g_had_nvg[id] = 1
		zb3_set_user_nvg(id, 0, 0, 1, 0)
	}
}

public zb3_game_start(start_type) 
{
	if(start_type == GAMESTART_NEWROUND) g_zombie_appear = 0
	else if(start_type == GAMESTART_ZOMBIEAPPEAR) g_zombie_appear = 1
}

public client_PostThink(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return
	
	static Float:CurTime, Float:SprintCurTime
	CurTime = get_gametime()
	
	if(CurTime - DELAY_TIME > g_hud_delay[id])
	{
		//sync_hud1_handle(id)
		sync_hud2_handle(id)
		
		g_hud_delay[id] = CurTime
	}
	
	if(g_had_sprint[id] && g_using_sprint[id] && CurTime - 0.5 > SprintCurTime)
	{
		static max_speed; max_speed = pev(id, pev_maxspeed)
		SprintCurTime = CurTime
		switch (g_sprint_status[id])
		{
			case 1: if(max_speed != fastrun_speed) zb3_set_user_speed(id, floatround(fastrun_speed))
			case 2: if(max_speed != slowrun_speed) zb3_set_user_speed(id, floatround(slowrun_speed))
		}
	}
	/*
	if(g_had_deadlyshot[id] && g_can_use_deadlyshot[id] && is_user_bot(id) && CurTime - 0.5 > BotCurTime) 
	{
		BotCurTime = CurTime
		
		static target, body;
 		new Float:Distance = get_user_aiming(id, target, body)
 		new CheckEnemy = is_user_alive(target) && cs_get_user_team(id) != cs_get_user_team(target)
 		
 		if( Distance > 1.0 && CheckEnemy )
 		{
 			do_deadlyshot(id)
 		} 
	}*/
}

public sync_hud1_handle(id)
{
	static Temp_String[128], Temp_String2[128], Temp_String3[128]
	formatex(Temp_String, sizeof(Temp_String), "[Items]^n")
	
	if(g_had_wing_boot[id])
	{
		formatex(Temp_String2, sizeof(Temp_String2), " Boot", Temp_String)
		formatex(Temp_String3, sizeof(Temp_String3), "%s^n%s", Temp_String, Temp_String2)
		formatex(Temp_String, sizeof(Temp_String), "%s", Temp_String3)
	}
	if(g_had_double_grenade[id])
	{
		formatex(Temp_String2, sizeof(Temp_String2), " Grenade", Temp_String)
		formatex(Temp_String3, sizeof(Temp_String3), "%s^n%s", Temp_String, Temp_String2)
		formatex(Temp_String, sizeof(Temp_String), "%s", Temp_String3)
	}
	if(g_had_p30_damage[id])
	{
		formatex(Temp_String2, sizeof(Temp_String2), " x1.3 DMG", Temp_String)
		formatex(Temp_String3, sizeof(Temp_String3), "%s^n%s", Temp_String, Temp_String2)
		formatex(Temp_String, sizeof(Temp_String), "%s", Temp_String3)
	}		
	if(g_had_nvg[id])
	{
		formatex(Temp_String2, sizeof(Temp_String2), " NVG", Temp_String)
		formatex(Temp_String3, sizeof(Temp_String3), "%s^n%s", Temp_String, Temp_String2)
		formatex(Temp_String, sizeof(Temp_String), "%s", Temp_String3)
	}		
	
	set_hudmessage(0, 255, 0, 0.015, 0.20, 0, 2.0, 2.0)
	ShowSyncHudMsg(id, g_sync_hud1, Temp_String3)	
}
public sync_hud2_handle(id)
{
	if(is_user_bot(id))
		return

	static Temp_String_Sprint[128], Temp_String_DeadlyShot[128], Temp_String_BloodyBlade[128]
	static Temp_String_Hud[128]
	
	if(g_had_sprint[id] && g_can_use_sprint[id])
		formatex(Temp_String_Sprint, sizeof(Temp_String_Sprint), "Sprint")
	else 
		formatex(Temp_String_Sprint, sizeof(Temp_String_Sprint), "")
	
	if(g_had_deadlyshot[id] && g_can_use_deadlyshot[id])
		formatex(Temp_String_DeadlyShot, sizeof(Temp_String_DeadlyShot), "^nDeadly Shot")
	else 
		formatex(Temp_String_DeadlyShot, sizeof(Temp_String_DeadlyShot), "^n")
	
	if(g_had_bloodyblade[id] && g_can_use_bloodyblade[id])
		formatex(Temp_String_BloodyBlade, sizeof(Temp_String_BloodyBlade), "^nBloody Blade")
	else
		formatex(Temp_String_BloodyBlade, sizeof(Temp_String_BloodyBlade), "^n")
		
	formatex(Temp_String_Hud, sizeof(Temp_String_Hud), "%s%s%s", Temp_String_Sprint, Temp_String_DeadlyShot, Temp_String_BloodyBlade)
	
	set_hudmessage(255, 255, 255, -1.0, 0.10, 0, 0.0, 2.1)
	ShowSyncHudMsg(id, g_sync_hud2, Temp_String_Hud)
}

public zb3_user_spawned(id)
{
	if(!is_user_connected(id))
		return HAM_IGNORED
		
	set_wing_boot(id)
	set_double_grenade(id)
	set_user_item_sprint(id)
	set_p30_damage(id)
	set_user_deadlyshot(id)
	set_user_bloodyblade(id)
	set_user_nightvision(id)
	
	return HAM_HANDLED
}

public zb3_user_infected(id)
{
	reset_all_item(id)
}

public reset_all_item(id)
{
	g_can_use_sprint[id] = 0
	g_using_sprint[id] = 0
	g_sprint_status[id] = 0
	g_can_use_deadlyshot[id] = 0
	g_using_deadlyshot[id] = 0	
	//zb3_reset_user_maxlevel(id)
}

// =========== Item: Wing Boot
public set_wing_boot(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!g_had_wing_boot[id])
		return
		
	set_pev(id, pev_gravity, g_wb_gravity)
}

// =========== Item: Double Grenade
public fw_Add_Hegrenade_Post(ent, id)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(zb3_get_user_zombie(id))
		return HAM_IGNORED			
		
	if(!g_doubled_grenade[id])
		set_double_grenade(id)
		
	return HAM_HANDLED
}

public set_double_grenade(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!g_had_double_grenade[id])
		return
		
	g_doubled_grenade[id] = 1
	give_item(id, "weapon_hegrenade")
	
	cs_set_user_bpammo(id, CSW_HEGRENADE, 2)
}

// ============ Item: Sprint
public set_user_item_sprint(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!g_had_sprint[id])
		return	
		
	g_can_use_sprint[id] = 1
	g_using_sprint[id] = 0
	g_sprint_status[id] = 0
	
	client_cmd(id, "bind F1 fastrun")
}

public do_fastrun(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return	
	if(!g_zombie_appear)
		return
	
	if(g_can_use_sprint[id] && !g_using_sprint[id])
	{
		g_can_use_sprint[id] = 0
		g_using_sprint[id] = 1
		g_sprint_status[id] = 1
		
		message_begin(MSG_ONE_UNRELIABLE, g_Msg_ScreenFade, _, id)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(0x0004) // fade type
		write_byte(255) // r
		write_byte(255) // g
		write_byte(255) // b
		write_byte(10) // alpha
		message_end()
		
		remove_task(id+TASK_REMOVE_FASTRUN)
		set_task(fastrun_time, "task_remove_fastrun", id+TASK_REMOVE_FASTRUN)
		
		zb3_set_user_speed(id, floatround(fastrun_speed))
		
		emit_sound(id, CHAN_AUTO, sound_fastrun_start, 1.0, ATTN_NORM, 0, PITCH_NORM)
		emit_sound(id, CHAN_AUTO, sound_fastrun_heartbeat, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		set_task(1.0, "task_human_sound", id+TASK_HUMAN_SOUND, _, _, "b")
	}
}

public task_human_sound(id)
{
	id -= TASK_HUMAN_SOUND
	
	if(!is_user_alive(id))
		return

	static Sex
	Sex = zb3_get_user_sex(id)

	if(zb3_get_user_zombie(id) || !g_had_sprint[id] || !g_using_sprint[id])
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return			
	}
	switch(g_sprint_status[id])
	{
		case 1: emit_sound(id, CHAN_VOICE, sound_fastrun_heartbeat, 1.0, ATTN_NORM, 0, PITCH_NORM)
		case 2: emit_sound(id, CHAN_VOICE, Sex == SEX_MALE ? sound_breath_male : sound_breath_female, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}

public task_remove_fastrun(id)
{
	id -= TASK_REMOVE_FASTRUN
	
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id) || !g_had_sprint[id] || !g_using_sprint[id])
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return			
	}

	message_begin(MSG_ONE_UNRELIABLE, g_Msg_ScreenFade, _, id)
	write_short(0) // duration
	write_short(0) // hold time
	write_short(0x0004) // fade type
	write_byte(255) // r
	write_byte(255) // g
	write_byte(255) // b
	write_byte(0) // alpha
	message_end()
	
	g_sprint_status[id] = 2
	
	remove_task(id+TASK_REMOVE_SLOWRUN)
	set_task(slowrun_time, "task_remove_slowrun", id+TASK_REMOVE_SLOWRUN)
	
	zb3_reset_user_speed(id)
	zb3_set_user_speed(id, floatround(slowrun_speed))
}

public task_remove_slowrun(id)
{
	id -= TASK_REMOVE_SLOWRUN
	
	if(!is_user_alive(id))
		return

	if(zb3_get_user_zombie(id) || !g_had_sprint[id] || !g_using_sprint[id])
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return			
	}	
	
	g_sprint_status[id] = 0
	g_using_sprint[id] = 0
	
	zb3_reset_user_speed(id)
}

// ============ Item: +30% Damage
public set_p30_damage(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!g_had_p30_damage[id])
		return	
		
	zb3_set_user_maxlevel(id, 13)
	zb3_set_user_level(id, zb3_get_user_level(id) + 3)
}

// =============== Item: Deadly Shot
public set_user_deadlyshot(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!g_had_deadlyshot[id])
		return	
		
	g_can_use_deadlyshot[id] = 1
	g_using_deadlyshot[id] = 0

	client_cmd(id, "bind F2 use_deadlyshot")	
}

public do_deadlyshot(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return	
	if(!g_zombie_appear)
		return		
	
	if(g_can_use_deadlyshot[id] && !g_using_deadlyshot[id])
	{
		g_can_use_deadlyshot[id] = 0
		g_using_deadlyshot[id] = 1
		
		//make_deadlyshoot_icon(id)
		zb3_showattachment(id, g_deadlyshot_icon, g_deadlyshot_time, 1.0, 1.0, 0)
		emit_sound(id, CHAN_AUTO, sound_fastrun_start, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		if(!zb3_get_user_nvg(id))
		{
			message_begin(MSG_ONE_UNRELIABLE, g_Msg_ScreenFade, _, id)
			write_short(0) // duration
			write_short(0) // hold time
			write_short(0x0004) // fade type
			write_byte(255) // r
			write_byte(255) // g
			write_byte(255) // b
			write_byte(10) // alpha
			message_end()
		}
		
		remove_task(id+TASK_REMOVE_DEADLYSHOT)
		set_task(g_deadlyshot_time, "task_remove_headshot", id+TASK_REMOVE_DEADLYSHOT)
	}
}

public task_remove_headshot(id)
{
	id -= TASK_REMOVE_DEADLYSHOT
	
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!g_had_deadlyshot[id])
		return		
		
	if(!zb3_get_user_nvg(id))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_Msg_ScreenFade, _, id)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(0x0004) // fade type
		write_byte(255) // r
		write_byte(255) // g
		write_byte(255) // b
		write_byte(0) // alpha
		message_end()
	}
	
	g_can_use_deadlyshot[id] = 0
	g_using_deadlyshot[id] = 0
}

// NightVision
public set_user_nightvision(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!g_had_nvg[id])
		return	
		
	zb3_set_user_nvg(id, 0, 0, 1, 0)
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (victim == attacker || !is_user_alive(attacker) || !is_user_alive(victim))
		return HAM_IGNORED;
	if (cs_get_user_team(victim) == cs_get_user_team(attacker))
		return HAM_IGNORED
		
	if(g_using_bloodyblade[attacker] && get_user_weapon(attacker) == CSW_KNIFE)
		SetHamParamFloat(3, damage * g_bloodyblade_damage)
	if(g_using_deadlyshot[attacker] && get_user_weapon(attacker) != CSW_KNIFE)
		set_tr2(tracehandle, TR_iHitgroup, HIT_HEAD)
	
	return HAM_IGNORED
}

// ================ Skill: Bloody Blade
public set_user_bloodyblade(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!g_had_bloodyblade[id])
		return	
		
	g_can_use_bloodyblade[id] = 1
	g_using_bloodyblade[id] = 0
	
	client_cmd(id, "bind F3 use_bloodyblade")		
}

public do_bloodyblade(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return	
	if(!g_zombie_appear)
		return		
	
	if(g_can_use_bloodyblade[id] && !g_using_bloodyblade[id])
	{
		g_can_use_bloodyblade[id] = 0
		g_using_bloodyblade[id] = 1
		//make_bloodblade_icon(id)

		zb3_showattachment(id, g_bloodyblade_icon, g_bloodyblade_time, 1.0, 1.0, 0)
		emit_sound(id, CHAN_AUTO, sound_fastrun_start, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		if(!zb3_get_user_nvg(id))
		{
			message_begin(MSG_ONE_UNRELIABLE, g_Msg_ScreenFade, _, id)
			write_short(0) // duration
			write_short(0) // hold time
			write_short(0x0004) // fade type
			write_byte(255) // r
			write_byte(255) // g
			write_byte(255) // b
			write_byte(10) // alpha
			message_end()
		}
		
		remove_task(id+TASK_REMOVE_BLOODYBLADE)
		set_task(g_bloodyblade_time, "task_remove_bloodyblade", id+TASK_REMOVE_BLOODYBLADE)
	}
}

public task_remove_bloodyblade(id)
{
	id -= TASK_REMOVE_BLOODYBLADE
	
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!g_had_bloodyblade[id])
		return		
		
	if(!zb3_get_user_nvg(id))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_Msg_ScreenFade, _, id)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(0x0004) // fade type
		write_byte(255) // r
		write_byte(255) // g
		write_byte(255) // b
		write_byte(0) // alpha
		message_end()
	}
	
	g_can_use_bloodyblade[id] = 0
	g_using_bloodyblade[id] = 0
}