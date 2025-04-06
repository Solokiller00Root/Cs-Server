#include <amxmodx>
#include <hamsandwich>
#include <zp50_core>
#include <zp50_class_nemesis>
#include <fakemeta>
#include <float> 

#define PLUGIN_NAME "Hud Attack Damage"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "Hud for Attack Damage"

#define LIBRARY_NEMESIS "zp50_class_nemesis"
#define MAX_PLAYERS 32

new preHealth[MAX_PLAYERS+1];
new msgSync;



public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
    
    msgSync = CreateHudSyncObj();
    
    RegisterHam(Ham_TakeDamage, "player", "ham_PlayerTakeDamage_Pre", 0);
    RegisterHam(Ham_TakeDamage, "player", "Ham_PlayerTakeDamage_Post", 1);
}



public ham_PlayerTakeDamage_Pre(victim)
{
    if (!is_user_connected(victim))
        return PLUGIN_HANDLED;
    
    preHealth[victim] = get_user_health(victim);
    return PLUGIN_CONTINUE;
}

public Ham_PlayerTakeDamage_Post(victim, attacker, Float:damage, damagebits)
{
    if (!is_user_connected(attacker) || !is_user_connected(victim))
        return PLUGIN_HANDLED;

    if (damagebits & DMG_FALL)
        return HAM_IGNORED;

    new currentHealth = get_user_health(victim);
    new oldHealth = preHealth[victim];
    new damageCalc = oldHealth - currentHealth;

    if (damageCalc > 0)
    {
        ShowDamageHud(attacker, damageCalc, true);
        ShowDamageHud(victim, damageCalc, false);
    }
    
    preHealth[victim] = currentHealth;

    return PLUGIN_CONTINUE;
}

stock ShowDamageHud(id, damageValue, bool:dealt)
{
    if (!is_user_connected(id))
        return;
    
    new Float:centerX   = 0.5;
    new Float:centerY   = 0.5;
    new Float:minRadius = 0.05;
    new Float:maxRadius = 0.1;
    
    new Float:radius = random_float(minRadius, maxRadius);
    new Float:angle  = random_float(0.0, 2.0 * M_PI);
    new Float:posX = centerX + radius * floatcos(angle);
    new Float:posY = centerY + radius * floatsin(angle);

    if (dealt)
    {
        set_hudmessage(0, 128, 255, posX, posY, 0, 1.5, 1.0);
    }
    else
    {
        set_hudmessage(255, 0, 0, posX, posY, 0, 1.5, 1.0);
    }

    ShowSyncHudMsg(id, msgSync, "%i", damageValue);
}

