#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <cstrike>
#include <hamsandwich>
#include <fun>
#include <zombieplague>

#define PLUGIN "[ZP] Extra Item: Quad Barrel"
#define VERSION "1.5"
#define AUTHOR "Dias/Arwel/heka/DimoK" // Thank for the help of RedPlane

#define m_pPlayer				41
#define m_flNextPrimaryAttack		46
#define m_flNextSecondaryAttack	47
#define m_flTimeWeaponIdle		48
#define m_iClip				51
#define m_fInReload				54
#define m_fInSpecialReload		55

#define XTRA_OFS_WEAPON			4
#define XTRA_OFS_PLAYER		5
#define m_flNextAttack		83
#define m_rgAmmo_player_Slot0	376

#define WEAP_LINUX_XTRA_OFF		4
#define PLAYER_LINUX_XTRA_OFF	5

#define qb_reload_time 3.0
#define qb_RELOAD 3
#define qb_DRAW 4
#define qb_IDLE 0

new const v_model[] = "models/zombie_plague/v_qbarrel.mdl"
new const p_model[] = "models/zombie_plague/p_qbarrel.mdl"
new const w_model[] = "models/zombie_plague/w_qbarrel.mdl"

const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)

new const qb_sound[5][] = {
	"weapons/qbarrel_clipin1.wav",
	"weapons/qbarrel_clipin2.wav",
	"weapons/qbarrel_clipout1.wav",
	"weapons/qbarrel_draw.wav",
	"weapons/qbarrel_shoot.wav"
}

#define CSW_QB CSW_XM1014

new g_had_qb[33], Float:g_last_fire[33], Float:g_last_fire2[33], g_bloodspray, g_blood
new cvar_default_clip, cvar_delayattack, cvar_randmg_start, cvar_randmg_end , cvar_qb_ammo , cvar_spd_qb
new g_quad_barrel , g_qb_TmpClip[33] , oldweap[33]

new g_orig_event

new gmsgWeaponList

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
	
	register_forward(FM_CmdStart, "fm_cmdstart")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_SetModel, "fw_SetModel")	
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")  
	
	RegisterHam(Ham_TakeDamage, "player", "fw_takedmg")
	RegisterHam(Ham_TraceAttack, "worldspawn", "TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "player", "TraceAttack", 1)	
	
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	
	RegisterHam(Ham_Weapon_Reload, "weapon_xm1014", "qb_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_xm1014", "qb_Reload_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_xm1014", "ham_priattack", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_xm1014", "ham_postframe")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_xm1014", "fw_item_addtoplayer", 1)
	RegisterHam(Ham_Item_Deploy, "weapon_xm1014", "fw_item_deploy", 1)
	
	cvar_default_clip = register_cvar("zp_qbarrel_default_clip", "4")
	cvar_delayattack = register_cvar("zp_qbarrel_delay_attack", "0.35")
	cvar_qb_ammo = register_cvar("zp_qb_ammo", "40")
	cvar_spd_qb = register_cvar("zp_speed_qb", "1.4")
	
	cvar_randmg_start = register_cvar("zp_qbarrel_randomdmg_start", "400.0")
	cvar_randmg_end = register_cvar("zp_qbarrel_randomdmg_end", "600.0")
	
	g_quad_barrel = zp_register_extra_item("Quad Barrel", 1, ZP_TEAM_HUMAN)
	gmsgWeaponList = get_user_msgid("WeaponList")
}

public plugin_precache()
{
	g_blood = precache_model("sprites/blood.spr")
	g_bloodspray = precache_model("sprites/bloodspray.spr")		
	
	precache_model(v_model)
	precache_model(p_model)
	precache_model(w_model)
	
	precache_generic("sprites/qb_sh.txt")
    precache_generic("sprites/sh/640hud60.spr")
      precache_generic("sprites/640hud7.spr")

      register_clcmd("qb_sh", "weapon_hook")
	
	for(new i = 0; i < sizeof(qb_sound); i++)
		precache_sound(qb_sound[i])
		
	register_forward(FM_PrecacheEvent, "fwPrecachePost", 1)	
}

public weapon_hook(id)
{
	engclient_cmd(id, "weapon_xm1014")
	return PLUGIN_HANDLED
}

public fwPrecachePost(type, const name[])
{
	if (equal("events/xm1014.sc", name))
	{
		g_orig_event=get_orig_retval()
		
		return FMRES_HANDLED
	}
	
	return FMRES_IGNORED
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event))
		return FMRES_IGNORED
	
	if (!g_had_qb[invoker])
		return FMRES_IGNORED
	
	fm_playback_event(flags|FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	return FMRES_SUPERCEDE
}

public event_newround()
{
	new iPlayers[32], iNumber
	get_players(iPlayers, iNumber)
	
	for(new i = 0; i < iNumber; i++)
	{
		new id = iPlayers[i]
		
		if(is_user_alive(id) && is_user_connected(id))
			g_had_qb[i] = 0
	}
}

public CurrentWeapon(id)
{
     replace_weapon_models(id, read_data(2))

     if(read_data(2) != CSW_XM1014|| !g_had_qb[id])
          return   
     
	 static Float:iSpeed
     if(g_had_qb[id])
          iSpeed = get_pcvar_float(cvar_spd_qb)
		  
     static weapon[32],Ent
     get_weaponname(read_data(2),weapon,31)
     Ent = find_ent_by_owner(-1,weapon,id)
     if(Ent)
     {
          static Float:Delay
          Delay = get_pdata_float( Ent, 46, 4) * iSpeed
          if (Delay > 0.0)
          {
               set_pdata_float(Ent, 46, Delay, 4)
          }
     }
}

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_XM1014:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return
			
			if(g_had_qb[id])
			{
				set_pev(id, pev_viewmodel2, v_model)
				set_pev(id, pev_weaponmodel2, p_model)
				if(oldweap[id] != CSW_XM1014) 
				{
					UTIL_PlayWeaponAnimation(id, qb_DRAW)
					set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
					
							message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
		write_string("qb_sh")
		write_byte(5)
		write_byte(32)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(12)
		write_byte(CSW_XM1014)
		message_end()
				}
			}
		}
	}
	oldweap[id] = weaponid
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid != g_quad_barrel)
		return 
	
    give_qb(id)
}

public give_qb(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id))
		return;
		
		
	drop_weapons(id, 1)
	new iWep2 = give_item(id,"weapon_xm1014")
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_default_clip))
		cs_set_user_bpammo (id, CSW_XM1014, get_pcvar_num(cvar_qb_ammo))	
		UTIL_PlayWeaponAnimation(id, qb_DRAW)
		set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
		
		message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
		write_string("qb_sh")
		write_byte(5)
		write_byte(32)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(12)
		write_byte(CSW_XM1014)
		message_end()
    }
	g_had_qb[id] = true
}

public zp_user_infected_post(id)
{
	g_had_qb[id] = 0
}

public zp_user_humanized_post(id)
{
	g_had_qb[id] = 0
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED
	if(zp_get_user_zombie(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) != CSW_QB || !g_had_qb[id])
		return FMRES_IGNORED
		
	set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001) 
	
	return FMRES_HANDLED
}

public TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker) || !is_user_connected(iAttacker))
		return HAM_IGNORED
	if(zp_get_user_zombie(iAttacker))
		return FMRES_IGNORED			
	if(get_user_weapon(iAttacker) != CSW_QB || !g_had_qb[iAttacker])
		return HAM_IGNORED
	
	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)

	make_bullet(iAttacker, flEnd)

	return HAM_HANDLED
}

public fw_takedmg(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(!is_user_alive(victim) || !is_user_alive(attacker))
		return HAM_IGNORED
	if(zp_get_user_zombie(attacker) || !zp_get_user_zombie(victim))
		return HAM_IGNORED

	if(get_user_weapon(attacker) == CSW_QB && g_had_qb[attacker])
	{
		static Float:random_start, Float:random_end
	
		random_start = get_pcvar_float(cvar_randmg_start)
		random_end = get_pcvar_float(cvar_randmg_end)
	
		SetHamParamFloat(4, random_float(random_start, random_end))
	}
	
	return HAM_HANDLED
}

public fw_item_deploy(ent)
{
	
	new id=get_pdata_cbase(ent, 41, 4)
	
	if(is_user_alive(id)&&g_had_qb[id])
	{
		
		set_pev(id, pev_viewmodel2, v_model)
		set_pev(id, pev_weaponmodel2, p_model)
	
		set_weapon_anim(id, 4)
		
	}
	
}

public make_bullet(id, Float:Origin[3])
{
	// Find target
	new target, body
	get_user_aiming(id, target, body, 999999)
	
	if(target > 0 && target <= get_maxplayers())
	{
		new Float:fStart[3], Float:fEnd[3], Float:fRes[3], Float:fVel[3]
		pev(id, pev_origin, fStart)
		
		// Get ids view direction
		velocity_by_aim(id, 64, fVel)
		
		// Calculate position where blood should be displayed
		fStart[0] = Origin[0]
		fStart[1] = Origin[1]
		fStart[2] = Origin[2]
		fEnd[0] = fStart[0]+fVel[0]
		fEnd[1] = fStart[1]+fVel[1]
		fEnd[2] = fStart[2]+fVel[2]
		
		// Draw traceline from victims origin into ids view direction to find
		// the location on the wall to put some blood on there
		new res
		engfunc(EngFunc_TraceLine, fStart, fEnd, 0, target, res)
		get_tr2(res, TR_vecEndPos, fRes)
		
		// Show some blood :)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
		write_byte(TE_BLOODSPRITE)
		write_coord(floatround(fStart[0])) 
		write_coord(floatround(fStart[1])) 
		write_coord(floatround(fStart[2])) 
		write_short(g_bloodspray)
		write_short(g_blood)
		write_byte(70)
		write_byte(random_num(1,2))
		message_end()
		
		
		} else {
		new decal = 41
		
		// Check if the wall hit is an entity
		if(target)
		{
			// Put decal on an entity
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_DECAL)
			write_coord(floatround(Origin[0]))
			write_coord(floatround(Origin[1]))
			write_coord(floatround(Origin[2]))
			write_byte(decal)
			write_short(target)
			message_end()
			} else {
			// Put decal on "world" (a wall)
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_WORLDDECAL)
			write_coord(floatround(Origin[0]))
			write_coord(floatround(Origin[1]))
			write_coord(floatround(Origin[2]))
			write_byte(decal)
			message_end()
		}
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		write_coord(floatround(Origin[0]))
		write_coord(floatround(Origin[1]))
		write_coord(floatround(Origin[2]))
		write_short(id)
		write_byte(decal)
		message_end()
	}
}

public fm_cmdstart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return
	if(zp_get_user_zombie(id))
		return
	if(get_user_weapon(id) != CSW_QB || !g_had_qb[id])
		return 

	new CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if(CurButton & IN_ATTACK2)
	{
		static Float:CurTime
		CurTime = get_gametime()
		
		if(CurTime - 4.0 > g_last_fire[id])
		{
			static ent, ammo
			ent = find_ent_by_owner(-1, "weapon_xm1014", id)
			ammo = cs_get_weapon_ammo(ent)
			
			if(cs_get_weapon_ammo(ent) <= 0)
				return			
			
			for(new i = 0; i < ammo; i++)
			{
				ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
			}
			
			emit_sound(id, CHAN_WEAPON, qb_sound[4], 1.0, ATTN_NORM, 0, PITCH_NORM)
			set_weapon_anim(id, random_num(1, 2))
			
			g_last_fire[id] = CurTime
		}
	}
	
	if(CurButton & IN_ATTACK)
	{
		static Float:CurTime
		CurTime = get_gametime()
		
		CurButton &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, CurButton)
		
		static ent
		ent = find_ent_by_owner(-1, "weapon_xm1014", id)
		
		if(cs_get_weapon_ammo(ent) <= 0 || get_pdata_int(ent, m_fInReload, XTRA_OFS_WEAPON))
			return
		
		if(CurTime - get_pcvar_float(cvar_delayattack) > g_last_fire2[id])
		{
			emit_sound(id, CHAN_WEAPON, qb_sound[4], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
			ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
			set_weapon_anim(id, random_num(1, 2))
			
			g_last_fire2[id] = CurTime
		}
		
	}	
	
	return 
}

public qb_Reload(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_had_qb[id])
          return HAM_IGNORED

     static iClipExtra

     if(g_had_qb[id])
          iClipExtra = get_pcvar_num(cvar_default_clip)

     g_qb_TmpClip[id] = -1

     new iBpAmmo = cs_get_user_bpammo(id, CSW_XM1014)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     if (iBpAmmo <= 0)
          return HAM_SUPERCEDE

     if (iClip >= iClipExtra)
          return HAM_SUPERCEDE

     g_qb_TmpClip[id] = iClip

     return HAM_IGNORED
}

public qb_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_had_qb[id])
		return HAM_IGNORED

	if (g_qb_TmpClip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(weapon_entity, m_iClip, g_qb_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, qb_reload_time, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, qb_reload_time, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	UTIL_PlayWeaponAnimation(id, qb_RELOAD)

	return HAM_IGNORED
}

public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED;
	
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
	
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED;
	
	static iOwner
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	if(equal(model, "models/w_xm1014.mdl"))
	{
		static weapon
		weapon = find_ent_by_owner(-1, "weapon_xm1014", entity)
		
		if(!is_valid_ent(weapon))
			return FMRES_IGNORED;
		
		if(g_had_qb[iOwner])
		{
			entity_set_int(weapon, EV_INT_impulse, 120)
			g_had_qb[iOwner] = 0
			set_pev(weapon, pev_iuser3, cs_get_weapon_ammo(weapon))
			entity_set_model(entity, w_model)
			
			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED;
}

public fw_item_addtoplayer(ent, id)
{
	if(!is_valid_ent(ent))
		return HAM_IGNORED
		
	if(zp_get_user_zombie(id))
		return HAM_IGNORED
			
	if(entity_get_int(ent, EV_INT_impulse) == 120)
	{
		g_had_qb[id] = 1
		cs_set_weapon_ammo(ent, pev(ent, pev_iuser3))
		
		entity_set_int(id, EV_INT_impulse, 0)
				
		message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
		write_string("qb_sh")
		write_byte(5)
		write_byte(32)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(12)
		write_byte(CSW_XM1014)
		message_end()
		
		return HAM_HANDLED
	}
	else
	{
		message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
		write_string("weapon_m3")
		write_byte(5)
		write_byte(32)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(12)
		write_byte(CSW_XM1014)
		message_end()
	}
	return HAM_IGNORED
}

public ham_priattack(ent)
{
	static id
	id = pev(ent, pev_owner)
	
	if(!zp_get_user_zombie(id) && g_had_qb[id])
	{
		if(cs_get_weapon_ammo(ent) > 0)
		{
			emit_sound(id, CHAN_WEAPON, qb_sound[4], 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		
		set_pdata_float(id, 83, 0.3, 4)
	}
}

public ham_postframe(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_had_qb[id])
          return HAM_IGNORED

     static iAnim; iAnim = pev(id, pev_weaponanim)
     if(iAnim == qb_DRAW && g_had_qb[id])
     UTIL_PlayWeaponAnimation(id, qb_IDLE)

     static iClipExtra
     
     iClipExtra = get_pcvar_num(cvar_default_clip)
     new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

     new iBpAmmo = cs_get_user_bpammo(id, CSW_XM1014)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

     if( fInReload && flNextAttack <= 0.0 )
     {
	     new j = min(iClipExtra - iClip, iBpAmmo)
	
	     set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
	     cs_set_user_bpammo(id, CSW_XM1014, iBpAmmo-j)
		
	     set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
	     fInReload = 0
     }
     return HAM_IGNORED
}

stock set_weapon_anim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)

	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(pev(id,pev_body))
	message_end()
}

stock drop_weapons(id, dropwhat)
{
     static weapons[32], num, i, weaponid
     num = 0
     get_user_weapons(id, weapons, num)
     
     for (i = 0; i < num; i++)
     {
          weaponid = weapons[i]
          
          if (dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
          {
               static wname[32]
               get_weaponname(weaponid, wname, sizeof wname - 1)
               engclient_cmd(id, "drop", wname)
          }
     }
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}
