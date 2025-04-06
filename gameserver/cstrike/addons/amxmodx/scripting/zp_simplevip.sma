#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fun>
#include <fakemeta>
#include <cstrike>
#include <esf>


/*
Player should have flag Q in users.ini for vip 1
Player should have flag R in users.ini for vip 2

Each VIP 1 player will receive on each round:

500 hp
150 armour
1/2 gravity
semi-visibility
Huge light aura
Word BOMB next to name in scoreboard

--------------------------------------------

Each VIP 2 player will receive on each round:

400 hp
120 armour
70% of gravity
*/

#define VIP1_FLAG ADMIN_LEVEL_E
#define VIP2_FLAG ADMIN_LEVEL_F


public plugin_init() 
{
	register_plugin( "[ZP] Addon: VIP1&2", "1.0", "fiendshard" );	
	RegisterHam( Ham_Spawn, "player", "fwdPlayerSpawn", 1 );
}

public fwdPlayerSpawn(id)
{
	if (is_user_alive(id) && (get_user_flags(id) & VIP1_FLAG))
		{
		set_user_health(id, 500) // hp
		set_user_armor(id, 150) // armour
		set_user_gravity(id, 0.50) // gravity
		set_user_rendering(id,kRenderFxNone,0,0,0,kRenderTransAlpha,127) // semi-visibility
		set_pev(id, pev_effects, pev(id, pev_effects) | EF_BRIGHTLIGHT) // light aura
		}
	if (is_user_alive(id) && (get_user_flags(id) & VIP2_FLAG))
		{
		set_user_health(id, 400) // hp
		set_user_armor(id, 120) // armour
		set_user_gravity(id, 0.20) // gravity
		cs_set_user_vip(id);
		}
	return HAM_IGNORED
}


public unlimitedAmmo(id){


	if(!is_user_alive(id)){
		return;
	}


}

