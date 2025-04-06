#include <amxmodx>
#include <zp50_ammopacks>
#include <zp50_colorchat>


public plugin_init()
{
    register_plugin("[ZP] Donate Ammo", "1.0", "YourName");

    register_clcmd("say", "HookPlayerChat");
    register_clcmd("say_team", "HookPlayerChat");
}

public HookPlayerChat(id)
{
    if (!is_user_connected(id))
        return PLUGIN_CONTINUE;

    new szText[192];
    read_args(szText, charsmax(szText));
    remove_quotes(szText);  

    if (!equal(szText, "/donate", 7))
        return PLUGIN_CONTINUE;

    new szAmount[8], szTargetName[32];
    new iCount = parse(szText[8], szAmount, charsmax(szAmount), szTargetName, charsmax(szTargetName));

    if (iCount < 2)
    {
        client_print(id, print_chat, "[ZP Donate] Usage: /donate <amount> <player_name>");
        return PLUGIN_HANDLED;
    }

    new iAmount = str_to_num(szAmount);
    if (iAmount <= 0)
    {
        client_print(id, print_chat, "[ZP Donate] Please specify a positive integer amount!");
        return PLUGIN_HANDLED;
    }

    new iTarget = find_player("b", szTargetName);
    if (!iTarget || !is_user_connected(iTarget))
    {
        client_print(id, print_chat, "[ZP Donate] Could not find a player named '%s'.", szTargetName);
        return PLUGIN_HANDLED;
    }

    if (iTarget == id)
    {
        client_print(id, print_chat, "[ZP Donate] You cannot donate to yourself!");
        return PLUGIN_HANDLED;
    }

    new iDonorAmmo = zp_ammopacks_get(id);
    if (iAmount > iDonorAmmo)
    {
        client_print(id, print_chat, "[ZP Donate] You only have %d ammo packs!", iDonorAmmo);
        return PLUGIN_HANDLED;
    }

    zp_ammopacks_set(id, iDonorAmmo - iAmount);

    new iTargetAmmo = zp_ammopacks_get(iTarget);
    zp_ammopacks_set(iTarget, iTargetAmmo + iAmount);

    new szDonorName[32], szReceiverName[32];
    get_user_name(id,       szDonorName,    charsmax(szDonorName));
    get_user_name(iTarget,  szReceiverName, charsmax(szReceiverName));

    zp_colored_print(id, "^3You donated %d ammo packs to '%s'.", iAmount, szReceiverName)
    zp_colored_print(iTarget,"^3You received %d ammo packs from '%s'.", iAmount, szDonorName)
    
    
    return PLUGIN_HANDLED;
}
