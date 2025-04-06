//#define engine

#include <amxmodx>
#include <amxmisc>
#include <fun>
#if defined engine
#include <engine>
#else
#include <fakemeta>
#endif

#define ADMIN_LEVEL_Q	ADMIN_LEVEL_C

new bool:hook[33]
new hook_to[33][3]
new hook_speed_cvar
new bool:has_hook[33]

new beamsprite

public plugin_init() 
{
	register_plugin("Hook","1.0","Future")
	register_concmd("+hook","hook_on",ADMIN_LEVEL_Q," - Use: bind key +hook")
	register_concmd("-hook","hook_off")
	
	
	hook_speed_cvar = register_cvar("hook_speed","5")
	
}


/**********************************
Register beam sprite + Hook Sound
**********************************/

public plugin_precache()
{
	beamsprite = precache_model("sprites/frostgib.spr")
	precache_sound("weapons/Hook.wav")
}



public client_putinserver(id)
{
	if(get_user_flags(id) && ADMIN_LEVEL_Q){
		has_hook[id] = true;
	}
}


/*****
Hook
*****/

public hook_on(id,level,cid)
{
	if(!has_hook[id] && !is_user_admin(id))
	{
		return PLUGIN_HANDLED
	}
	if(hook[id])
	{
		return PLUGIN_HANDLED
	}
	set_user_gravity(id,0.0)
	set_task(0.1,"hook_prethink",id+10000,"",0,"b")
	hook[id]=true
	hook_to[id][0]=999999
	hook_prethink(id+10000)
	emit_sound(id,CHAN_VOICE,"weapons/Hook.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	return PLUGIN_HANDLED
}

public hook_off(id)
{
	if(is_user_alive(id)) set_user_gravity(id)
	hook[id]=false
	return PLUGIN_HANDLED
}

public hook_prethink(id)
{
	id -= 10000
	if(!is_user_alive(id))
	{
		hook[id]=false
	}
	if(!hook[id])
	{
		remove_task(id+10000)
		return PLUGIN_HANDLED
	}
	
	//Get Id's origin
	static origin1[3]
	get_user_origin(id,origin1)
	

	if(hook_to[id][0]==999999)
	{
		static origin2[3]
		get_user_origin(id,origin2,3)
		hook_to[id][0]=origin2[0]
		hook_to[id][1]=origin2[1]
		hook_to[id][2]=origin2[2]
	}
	
	//Create blue beam
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(1)		//TE_BEAMENTPOINT
	write_short(id)		// start entity
	write_coord(hook_to[id][0])
	write_coord(hook_to[id][1])
	write_coord(hook_to[id][2])
	write_short(beamsprite)
	write_byte(1)		// framestart
	write_byte(1)		// framerate
	write_byte(2)		// life in 0.1's
	write_byte(10)		// width
	write_byte(0)		// noise
	write_byte(0)		// red
	write_byte(255)		// green
	write_byte(255)		// blue
	write_byte(255)		// brightness
	write_byte(0)		// speed
	message_end()
	
	//Calculate Velocity
	static Float:velocity[3]
	velocity[0] = (float(hook_to[id][0]) - float(origin1[0])) * 3.0
	velocity[1] = (float(hook_to[id][1]) - float(origin1[1])) * 3.0
	velocity[2] = (float(hook_to[id][2]) - float(origin1[2])) * 3.0
	
	static Float:y
	y = velocity[0]*velocity[0] + velocity[1]*velocity[1] + velocity[2]*velocity[2]
	

	static Float:x
	x = (get_pcvar_float(hook_speed_cvar) * 150.0) / floatsqroot(y)
	
	velocity[0] *= x
	velocity[1] *= x
	velocity[2] *= x
	
	set_velo(id,velocity)


	
	


	return PLUGIN_CONTINUE
}

public get_origin(ent,Float:origin[3])
{
	#if defined engine
	return entity_get_vector(id,EV_VEC_origin,origin)
	#else
	return pev(ent,pev_origin,origin)
	#endif
}

public set_velo(id,Float:velocity[3])
{
	#if defined engine
	return set_user_velocity(id,velocity)
	#else
	return set_pev(id,pev_velocity,velocity)
	#endif
}

public get_velo(id,Float:velocity[3])
{
	#if defined engine
	return get_user_velocity(id,velocity)
	#else
	return pev(id,pev_velocity,velocity)
	#endif
}

public is_valid_ent2(ent)
{
	#if defined engine
	return is_valid_ent(ent)
	#else
	return pev_valid(ent)
	#endif
}

public get_solidity(ent)
{
	#if defined engine
	return entity_get_int(ent,EV_INT_solid)
	#else
	return pev(ent,pev_solid)
	#endif
}

stock set_rendering2(index, fx=kRenderFxNone, r=255, g=255, b=255, render=kRenderNormal, amount=16)
{
	#if defined engine
	return set_rendering(index,fx,r,g,b,render,amount)
	#else
	set_pev(index, pev_renderfx, fx);
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);
	set_pev(index, pev_rendercolor, RenderColor);
	set_pev(index, pev_rendermode, render);
	set_pev(index, pev_renderamt, float(amount));
	return 1;
	#endif
}

