#include <amxmodx>
#include <sqlx>
#include <hamsandwich>


new Handle:g_SqlConnection;
new g_Error[512];
new errcode; 

new host[] = "127.0.0.1";
new username[] = "root"; 
new password[] = "";
new database[] = "cs16test";


public plugin_init()
{
    register_plugin("Solo", "1.0", "kappakippo");

    
    RegisterHam(Ham_Spawn,"player","swn")
    mysql_init();
}


public mysql_init(){
    
    new Handle:SqlConnection = SQL_MakeDbTuple(host, username, password, database);
    
    g_SqlConnection = SQL_Connect(SqlConnection, errcode, g_Error, charsmax(g_Error));


    server_print("THIS IS GSQL CONNECTION %", g_SqlConnection);

    if (g_SqlConnection)
    {
        server_print("][][][][ ITS WORKING ][][][][]^n[][][][][][][][][]");
    }
    else
    {
        server_print("ERROR: %s (Code: %d)", g_Error, errcode);
    }
}


public client_putinserver(id){
    if(is_User_Valid(id)){
        return PLUGIN_HANDLED;
    }

    if(is_user_alive(id) && is_user_connected(id)){
        set_task(1.0,"showcoins", id);
    }


    register_user(id);
    return PLUGIN_HANDLED;
}


public register_user(id){
    if (!is_user_connected(id))
        return;
    

    new username[32], query[128];
    new authid[32];    
    new Handle:Query;

    get_user_name(id, username, charsmax(username));
    get_user_authid(id,authid, charsmax(authid));

    
    formatex(query, charsmax(query), "INSERT INTO users (name, steamid) VALUES ('%s', '%s')", username, authid);

    Query = SQL_PrepareQuery(g_SqlConnection, query);

    if (!SQL_Execute(Query))
    {
        SQL_QueryError(Query, g_Error, charsmax(g_Error));
        server_print("ERROR SQL EXECUTE: %s", g_Error);
    }

    SQL_FreeHandle(Query); 
}



public is_User_Valid(id)
{
    new Handle:Query;
    new query[128];
    new authid[32];  
    get_user_authid(id, authid, charsmax(authid));

    formatex(query, charsmax(query), "SELECT * FROM users WHERE steamid = '%s'", authid);  

    Query = SQL_PrepareQuery(g_SqlConnection, query);

    if (SQL_Execute(Query))  
    {
        new rows = SQL_NumRows(Query);
        if (rows > 0)
        {
            SQL_FreeHandle(Query); 
            server_print("user found");
            return true; 
        }
        else
        {
            SQL_FreeHandle(Query); 
            return false;  
        }
    }
    else
    {
        SQL_QueryError(Query, g_Error, charsmax(g_Error));
        server_print("ERROR SQL EXECUTE: %s", g_Error);
        SQL_FreeHandle(Query); 
        return false;
    }
}

public fetchcoins(id){

    new Handle:Query;
    new query[128];
    new authid[32];  
    new coins = 0;


    get_user_authid(id, authid, charsmax(authid));

    formatex(query, charsmax(query), "SELECT coins FROM users WHERE steamid = '%s'", authid);  

    Query = SQL_PrepareQuery(g_SqlConnection, query);

    if (SQL_Execute(Query)){
        coins = SQL_ReadResult(Query, 0);  
        server_print("HELLO WORLD %d", coins);
        
    }else{
        SQL_QueryError(Query, g_Error, charsmax(g_Error));
        server_print("ERROR SQL EXECUTE: %s", g_Error);
        SQL_FreeHandle(Query); 
    }

    return coins;  
}



public showcoins(id)
{
    new Message[64];
    if (is_user_connected(id) && is_user_alive(id))
        {
            set_hudmessage(255, 0, 0, 0.28, 0.31, 0, 6.0, 12.0);
            formatex(Message, charsmax(Message), "P: %d", fetchcoins(id));
            show_hudmessage(id, Message);
        }
    return PLUGIN_HANDLED;
}

public swn(id){
    set_task(0.6,"showcoins",id,_,_,"b");
    return PLUGIN_HANDLED;
}





public plugin_end()
{
    if (g_SqlConnection)
    {
        SQL_FreeHandle(g_SqlConnection);  
    }
}
