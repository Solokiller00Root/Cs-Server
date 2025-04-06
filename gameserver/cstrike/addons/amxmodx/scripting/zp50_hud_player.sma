#include <amxmodx>
#include <fakemeta>
#include <cstrike>
#include <zp50_ammopacks>

new g_szSyncHud;
new g_iMaxPlayers;

public plugin_init()
{
    register_plugin("Target Info on HUD", "1.2", "Sylwester");


    g_szSyncHud    = CreateHudSyncObj();

    g_iMaxPlayers  = get_maxplayers();

    register_event("StatusValue", "fwdPlayerPreThink", "be", "1=2", "2!0")
}


public fwdPlayerPreThink(plr)
{
    if (!is_user_connected(plr) || !is_user_alive(plr))
        return;

    new iTarget, iBody;
    get_user_aiming(plr, iTarget, iBody, 512);

    // Must be a valid player and alive
    if (iTarget > 0 && iTarget <= g_iMaxPlayers && is_user_alive(iTarget))
    {
        new CsTeams:MyTeam     = cs_get_user_team(plr);
        new CsTeams:TargetTeam = cs_get_user_team(iTarget);

        new UserName[64], szMsg[128];
        get_user_name(iTarget, UserName, charsmax(UserName));

        if (TargetTeam == MyTeam)
        {
            formatex(szMsg, charsmax(szMsg),
                     "%s^nHealth: %i, Ammo: %i",
                     UserName, get_user_health(iTarget), zp_ammopacks_get(iTarget));
        }
        else
        {
            formatex(szMsg, charsmax(szMsg),
                     "%s", UserName);
        }

        switch (TargetTeam)
        {
            case CS_TEAM_CT:
            {
                set_hudmessage(0, 63, 127, -1.0, 0.60, 1, 0.01, 0.5, 0.01, 0.01, -1)
            }
            case CS_TEAM_T:
            {

                set_hudmessage(127, 0, 0, -1.0, 0.60, 1, 0.01, 0.5, 0.01, 0.01, -1)
                               
            }
            default:
            {
               set_hudmessage(127, 127, 127, -1.0, 0.60, 1, 0.01, 0.5, 0.01, 0.01, -1)

            }
        }

        ShowSyncHudMsg(plr, g_szSyncHud, szMsg);
    }
}
