#include <amxmodx>


#include <zp50_items>
#include <zp50_gamemodes>
#include <zp50_core>
#include <zp50_class_survivor>
#include <fun>
#include <zombieplague>

#define LIBRARY_SURVIVOR "zp50_class_survivor"


#define ITEM_NAME "Armor"
#define COST 5

new g_itemId
new cvar_armor_round_limit
new g_armorTaken


public plugin_init(){
    register_plugin("[ZP] Armor Extra Items", "1.0", "Buy armor 100")

	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
    g_itemId = zp_register_extra_item(ITEM_NAME, COST, ZP_TEAM_HUMAN);

    cvar_armor_round_limit = register_cvar("zp_armor_round_limit", "5"); 

}



public event_round_start(){

    g_armorTaken = 0

}


public zp_fw_items_select_pre(id, itemid, ignorecost){

    if(itemid != g_itemId)
        return ZP_ITEM_AVAILABLE;
	    

	static text[32]
	formatex(text, charsmax(text), "[%d/%d]", g_armorTaken, get_pcvar_num(cvar_armor_round_limit))
	zp_items_menu_text_add(text)
    

    // only for humans
    if(zp_core_is_zombie(id))
        return ZP_ITEM_DONT_SHOW;   

    // armor available for survivor?
    if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(id) )
		return ZP_ITEM_DONT_SHOW;
	
     
    if (g_armorTaken >= get_pcvar_num(cvar_armor_round_limit))
		return ZP_ITEM_NOT_AVAILABLE;
	


    new armor = get_user_armor(id);

    // Limit on how much armor a user can have
    if(armor >= 250){
        return ZP_ITEM_NOT_AVAILABLE;
    }

    return ZP_ITEM_AVAILABLE;
}


public zp_fw_items_select_post(id, itemid, ignorecost)
{
    if(itemid != g_itemId)
		return;

    
    new armor = get_user_armor(id);


    // if armor plus 100 is over 250 then leave it at 250, else add 100
    new newArmor = (armor + 100 > 250) ? 250 : armor + 100;
    set_user_armor(id, newArmor);
    
	g_armorTaken++
}


