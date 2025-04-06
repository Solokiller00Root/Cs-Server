public native_get_user_frozen(id)
{
	if(!g_pluginenabled)
		return -1
		
	return g_frozen[id]
}

public native_set_user_frozen(id, bool:IsFrozen, Float:duration)
{
	if(!g_pluginenabled)
		return
		
	g_frozen[id] = true
	
	if(IsFrozen)
	{
		if (get_pcvar_num(cvar_hudicons))
		{
			message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, _, id)
			write_byte(0) // damage save
			write_byte(0) // damage take
			write_long(DMG_DROWN) // damage type - DMG_FREEZE
			write_coord(0) // x
			write_coord(0) // y
			write_coord(0) // z
			message_end()
		}
		
		if (g_handle_models_on_separate_ent)
			fm_set_rendering(g_ent_playermodel[id], kRenderFxGlowShell, 0, 100, 200, kRenderNormal, 25)
		else
			fm_set_rendering(id, kRenderFxGlowShell, 0, 100, 200, kRenderNormal, 25)
		
		static sound[64]
		ArrayGetString(grenade_frost_player, random_num(0, ArraySize(grenade_frost_player) - 1), sound, charsmax(sound))
		emit_sound(id, CHAN_BODY, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		message_begin(MSG_ONE, g_msgScreenFade, _, id)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(FFADE_STAYOUT) // fade type
		write_byte(0) // red
		write_byte(50) // green
		write_byte(200) // blue
		write_byte(100) // alpha
		message_end()
		
		g_frozen[id] = true
		
		pev(id, pev_gravity, g_frozen_gravity[id])
		
		if (pev(id, pev_flags) & FL_ONGROUND)
			set_pev(id, pev_gravity, 999999.9) // set really high
		else
			set_pev(id, pev_gravity, 0.000001) // no gravity
		
		ExecuteHamB(Ham_Player_ResetMaxSpeed, id)
		
		if(duration > 0.0)
			set_task(duration, "remove_freeze", id)
		else
			set_task(get_pcvar_float(cvar_freezeduration), "remove_freeze", id)
	}
	else
	{
		g_frozen[id] = false
		
		set_pev(id, pev_gravity, g_frozen_gravity[id])
		ExecuteHamB(Ham_Player_ResetMaxSpeed, id)
		
		if (g_handle_models_on_separate_ent)
		{
			if (g_nemesis[id] && get_pcvar_num(cvar_nemglow))
				fm_set_rendering(g_ent_playermodel[id], kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 25)
			else if (g_survivor[id] && get_pcvar_num(cvar_survglow))
				fm_set_rendering(g_ent_playermodel[id], kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 25)
			else
				fm_set_rendering(g_ent_playermodel[id])
		}
		else
		{
			if (g_nemesis[id] && get_pcvar_num(cvar_nemglow))
				fm_set_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 25)
			else if (g_survivor[id] && get_pcvar_num(cvar_survglow))
				fm_set_rendering(id, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 25)
			else
				fm_set_rendering(id)
		}
		
		message_begin(MSG_ONE, g_msgScreenFade, _, id)
		write_short(UNIT_SECOND) // duration
		write_short(0) // hold time
		write_short(FFADE_IN) // fade type
		write_byte(0) // red
		write_byte(50) // green
		write_byte(200) // blue
		write_byte(100) // alpha
		message_end()
		
		static sound[64]
		ArrayGetString(grenade_frost_break, random_num(0, ArraySize(grenade_frost_break) - 1), sound, charsmax(sound))
		emit_sound(id, CHAN_BODY, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		static origin2[3]
		get_user_origin(id, origin2)
		
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin2)
		write_byte(TE_BREAKMODEL) // TE id
		write_coord(origin2[0]) // x
		write_coord(origin2[1]) // y
		write_coord(origin2[2]+24) // z
		write_coord(16) // size x
		write_coord(16) // size y
		write_coord(16) // size z
		write_coord(random_num(-50, 50)) // velocity x
		write_coord(random_num(-50, 50)) // velocity y
		write_coord(25) // velocity z
		write_byte(10) // random velocity
		write_short(g_glassSpr) // model
		write_byte(10) // count
		write_byte(25) // life
		write_byte(BREAK_GLASS) // flags
		message_end()
		
		ExecuteForward(g_fwUserUnfrozen, g_fwDummyResult, id)
	}
}

public native_user_has_infect_nade(id)
{
	if(!g_pluginenabled)
		return -1
		
	return g_infectnade[id]
}

public native_get_user_burning(id)
{
	if(!g_pluginenabled)
		return -1
		
	if(g_burning_duration[id] <= 0)
		return false
	
	return true
}

public native_set_user_burning(id, bool:IsBurning)
{
	if(!g_pluginenabled)
		return

	if(IsBurning)
	{
		if(!task_exists(id+TASK_BURN))
		{
			set_task(0.2, "burning_flame", id+TASK_BURN, _, _, "b")
		}
		else
		{
			g_burning_duration[id]--
		}
	}
	else
	{
		if(task_exists(id+TASK_BURN))
		{
			static origin[3]
			get_user_origin(id, origin)
			
			message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
			write_byte(TE_SMOKE) // TE id
			write_coord(origin[0]) // x
			write_coord(origin[1]) // y
			write_coord(origin[2]-50) // z
			write_short(g_smokeSpr) // sprite
			write_byte(random_num(15, 20)) // scale
			write_byte(random_num(10, 20)) // framerate
			message_end()
			
			remove_task(id+TASK_BURN)
			g_burning_duration[id] = 0
		}
	}
}

public native_get_user_unlimited_clip(id)
{
	if(!g_pluginenabled)
		return -1
		
	return g_unlimited_clip[id]
}

public native_set_user_unlimited_clip(id, bool:IsUnlimitedClip)
{
	if(!g_pluginenabled)
		return -1
		
	if(IsUnlimitedClip)
	{
		g_unlimited_clip[id] = true
	}
	else
	{
		g_unlimited_clip[id] = false
	}
	return 1
}

public native_get_user_painshockfree(id)
{
	if(!g_pluginenabled)
		return -1
		
	return g_painshockfree[id]
}

public native_set_user_painshockfree(id, bool:IsPainShockFree)
{
	if(!g_pluginenabled)
		return -1
	
	if(IsPainShockFree)
	{
		g_painshockfree[id] = true
	}
	else
	{
		g_painshockfree[id] = false
	}
	return 1
}

public native_zp_set_gamemode(gamemode)
{
	if(!g_pluginenabled)
		return -1
	
	if(g_modestarted)
		return 0
		
	remove_task(TASK_MAKEZOMBIE)
	
	switch(gamemode)
	{
		case MODE_SWARM:
		{
			make_a_zombie(MODE_SWARM, 0)
		}
		case MODE_MULTI:
		{
			make_a_zombie(MODE_MULTI, 0)
		}
		case MODE_PLAGUE:
		{
			make_a_zombie(MODE_PLAGUE, 0)
		}
	}
	return 1
}