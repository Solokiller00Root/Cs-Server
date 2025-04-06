#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <cs_teams_api>
#include <cs_ham_bots_api>
#include <zp50_gamemodes>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#define TE_BEAMFOLLOW 22

new beamsprite;

new g_sprite_grenade_ring[64] = "sprites/shockwave.spr"

new g_exploSpr

public plugin_init() {
    register_plugin("SpawnEntTEst", "1.0", "Test to spawn entities");

    RegisterHam(Ham_Killed, "player","fw_PlayerKilled");
}



public plugin_precache()  
{
    beamsprite = precache_model("sprites/beam.spr");
    g_exploSpr = precache_model(g_sprite_grenade_ring)

} 





public fw_PlayerKilled(victim, attacker, shouldgib) {
    // Begin the user message; the origin is set to {0, 0, 0} (you may adjust this if needed)
    // message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    //     write_byte(TE_BEAMFOLLOW);  // Tell client which TE to spawn
    //     write_short(id);            // The entity (or attachment) that the beam will follow
    //     write_short(beamsprite);    // Sprite index for the beam
    //     write_byte(2*10)             // Life of the beam in 0.1's (here: 0.1 second)
    //     write_byte(10);             // Beam width in 0.1's (here: 1.0 unit)
    //     write_byte(255);            // Red component
    //     write_byte(0);              // Green component
    //     write_byte(0);              // Blue component
    //     write_byte(255);            // Brightness
    // message_end();


    if(zp_core_is_zombie(victim)){
         static Float:origin[3]
	pev(victim, pev_origin, origin)

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_EXPLOSION)
    engfunc(EngFunc_WriteCoord, origin[0]) 
    engfunc(EngFunc_WriteCoord, origin[1]) 
    engfunc(EngFunc_WriteCoord, origin[2]) 
    write_short(beamsprite)
    write_byte(5)
    write_byte(0)   
    write_byte(4)
    message_end();


    	// Smallest ring    
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+200.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(5) // life
	write_byte(20) // width
	write_byte(0) // noise
	write_byte(0) // red
	write_byte(200) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
    }
   
}
