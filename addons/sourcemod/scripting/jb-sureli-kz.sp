#include <sourcemod>
#include <sdktools>
#include <warden>
#include <cstrike>
#include <devzones>
#include <emitsoundany>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "[JB] Süreli Kz", 
	author = "ByDexter - quantum.", 
	description = "", 
	version = "1.1", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

int skztime = 0, bunnytime = 0, finishpos = 0;
bool gonnaslay[MAXPLAYERS] = { false, ... };
bool Aktif = false;
float FinishTime[MAXPLAYERS] = { 0.0, ... }, LaneCoords[3] = { 0.0, ... }, OrtaCoords[3] = { 0.0, ... };
static char dosyayolu[PLATFORM_MAX_PATH];

Handle g_timer = null;

#define LoopAllTerroristPlayers(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsClientInGame(%1) && !IsFakeClient(%1) && GetClientTeam(%1) == CS_TEAM_T)

public void OnPluginStart()
{
	RegConsoleCmd("sm_skz", Cmd_Skz, "Main command");
	RegConsoleCmd("sm_skz0", Cmd_Skz0, "Stop command");
	RegAdminCmd("sm_skzayar", Command_SkzAyar, ADMFLAG_GENERIC, "Setting command");
	HookEvent("round_start", ElBasiSonu, EventHookMode_PostNoCopy);
	HookEvent("round_end", ElBasiSonu, EventHookMode_PostNoCopy);
	RegAdminCmd("skzstart_flag", Flag_SKZ, ADMFLAG_ROOT, "");
	RegAdminCmd("skzsettings_flag", Flag_SKZ, ADMFLAG_ROOT, "");
	BuildPath(Path_SM, dosyayolu, sizeof(dosyayolu), "configs/sureli_kz.kv");
}

public Action Flag_SKZ(int client, int args)
{
	return Plugin_Handled;
}

public void OnMapStart()
{
	char map[32];
	GetCurrentMap(map, sizeof(map));
	char Filename[256];
	GetPluginFilename(INVALID_HANDLE, Filename, 256);
	if (strncmp(map, "workshop/", 9, false) == 0)
	{
		if (StrContains(map, "/jb_", false) == -1 && StrContains(map, "/jail_", false) == -1 && StrContains(map, "/ba_jail", false) == -1)
			ServerCommand("sm plugins unload %s", Filename);
	}
	else if (strncmp(map, "jb_", 3, false) != 0 && strncmp(map, "jail_", 5, false) != 0 && strncmp(map, "ba_jail", 3, false) != 0)
		ServerCommand("sm plugins unload %s", Filename);
	
	KeyValues kv = new KeyValues("SKZ");
	kv.ImportFromFile(dosyayolu);
	if (kv.JumpToKey(map, true))
	{
		kv.GetVector("Kulvar", LaneCoords);
		kv.GetVector("Orta", OrtaCoords);
	}
	delete kv;
	AddFileToDownloadsTable("sound/bydexter/yaris/1.mp3");
	PrecacheSoundAny("bydexter/yaris/1.mp3");
	AddFileToDownloadsTable("sound/bydexter/yaris/2.mp3");
	PrecacheSoundAny("bydexter/yaris/2.mp3");
	AddFileToDownloadsTable("sound/bydexter/yaris/3.mp3");
	PrecacheSoundAny("bydexter/yaris/3.mp3");
	AddFileToDownloadsTable("sound/bydexter/yaris/gogo.mp3");
	PrecacheSoundAny("bydexter/yaris/gogo.mp3");
}

public Action Cmd_Skz0(int client, int args)
{
	if (!warden_iswarden(client) || !CheckCommandAccess(client, "skzstart_flag", ADMFLAG_ROOT))
	{
		ReplyToCommand(client, "[SM] Bu komuta erişiminiz yok.");
		return Plugin_Handled;
	}
	if (!Aktif)
	{
		ReplyToCommand(client, "[SM] Aktif bir skz bulunmamakta");
		return Plugin_Handled;
	}
	
	FinishGame();
	if (g_timer != null)
		delete g_timer;
	
	return Plugin_Handled;
}

public Action Cmd_Skz(int client, int args)
{
	if (!warden_iswarden(client) || !CheckCommandAccess(client, "skzstart_flag", ADMFLAG_ROOT))
	{
		ReplyToCommand(client, "[SM] Bu komuta erişiminiz yok.");
		return Plugin_Handled;
	}
	char time[20];
	GetCmdArg(1, time, 20);
	if (StringToInt(time) <= 0)
	{
		ReplyToCommand(client, "[SM] Sıfırdan büyük bir sayı girmelisin.");
		return Plugin_Handled;
	}
	skztime = StringToInt(time);
	StyleMenu().Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action Command_SkzAyar(int client, int args)
{
	SettingsMenu().Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

Menu SettingsMenu()
{
	Menu menu = new Menu(Settings_Handle);
	menu.SetTitle("SKZ Ayarlama\n ");
	menu.AddItem("lane", "Kulvar Konumu Ayarla");
	menu.AddItem("ortadan", "Orta Konumu Ayarla\n ");
	return menu;
}

public int Settings_Handle(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		switch (position)
		{
			case 0:
			{
				KeyValues kv = new KeyValues("SKZ");
				kv.ImportFromFile(dosyayolu);
				char map[64];
				GetCurrentMap(map, sizeof(map));
				if (kv.JumpToKey(map, true))
				{
					GetAimCoords(client, LaneCoords);
					kv.SetVector("Kulvar", LaneCoords);
					PrintCenterText(client, "Kulvar Ayarı başarı ile yapıldı.");
				}
				kv.Rewind();
				kv.ExportToFile(dosyayolu);
				delete kv;
				StyleMenu().Display(client, MENU_TIME_FOREVER);
			}
			case 1:
			{
				KeyValues kv = new KeyValues("SKZ");
				kv.ImportFromFile(dosyayolu);
				char map[64];
				GetCurrentMap(map, sizeof(map));
				if (kv.JumpToKey(map, true))
				{
					GetAimCoords(client, OrtaCoords);
					kv.SetVector("Orta", OrtaCoords);
					PrintCenterText(client, "Ortadan Ayarı başarı ile yapıldı.");
				}
				kv.Rewind();
				kv.ExportToFile(dosyayolu);
				delete kv;
				StyleMenu().Display(client, MENU_TIME_FOREVER);
			}
		}
	}
	else if (action == MenuAction_End)
		delete menu;
}

Menu StyleMenu()
{
	Menu menu = new Menu(Style_Handle);
	menu.SetTitle("SKZ Stilini Seç\nVerilen süre: %d\n ", skztime);
	menu.AddItem("orta", "Ortadan", skztime <= 0 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.AddItem("kulvar", "Kulvardan", skztime <= 0 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.AddItem("hucre", "Hücreden", skztime <= 0 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	menu.AddItem("bakis", "Baktığım Yerden\n ", skztime <= 0 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	return menu;
}

public int Style_Handle(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		switch (position)
		{
			case 0:
			{
				float checklocation[3] = { 0.0, 0.0, 0.0 };
				if (GetVectorDistance(OrtaCoords, checklocation) == 0.0)
				{
					if (CheckCommandAccess(client, "skzsettings_flag", ADMFLAG_ROOT))
						PrintCenterText(client, "Orta Ayarı yapılmamış !skzayar menüsünden ayar yapabilirsiniz.");
					else
						PrintCenterText(client, "Orta Ayarı yapılmamış lütfen yapılmasını isteyiniz.");
				}
				else
				{
					PrepareAndTeleport(OrtaCoords);
					PrintToChatAll("[SM] \x10%N tarafından \x04%d Saniyelik \x0ESKZ \x01başlatıldı!", client, skztime);
					EmitSoundToAllAny("bydexter/yaris/3.mp3", SOUND_FROM_PLAYER, 1, 50);
					PrintCenterTextAll("SKZ Başlamasına <font color='#34eb40'>3</font>");
					g_timer = CreateTimer(1.0, Go2, _, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			case 1:
			{
				float checklocation[3] = { 0.0, 0.0, 0.0 };
				if (GetVectorDistance(LaneCoords, checklocation) == 0.0)
				{
					if (CheckCommandAccess(client, "skzsettings_flag", ADMFLAG_ROOT))
						PrintCenterText(client, "Kulvar Ayarı yapılmamış !skzayar menüsünden ayar yapabilirsiniz.");
					else
						PrintCenterText(client, "Kulvar Ayarı yapılmamış lütfen yapılmasını isteyiniz.");
				}
				else
				{
					PrepareAndTeleport(LaneCoords);
					PrintToChatAll("[SM] \x10%N tarafından \x04%d Saniyelik \x0ESKZ \x01başlatıldı!", client, skztime);
					EmitSoundToAllAny("bydexter/yaris/3.mp3", SOUND_FROM_PLAYER, 1, 50);
					g_timer = CreateTimer(1.0, Go2, _, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			case 2:
			{
				RevConfirm().Display(client, MENU_TIME_FOREVER);
			}
			case 3:
			{
				float Coords[3] = { 0.0, ... };
				GetAimCoords(client, Coords);
				PrepareAndTeleport(Coords);
				PrintToChatAll("[SM] \x10%N tarafından \x04%d Saniyelik \x0ESKZ \x01başlatıldı!", client, skztime);
				EmitSoundToAllAny("bydexter/yaris/3.mp3", SOUND_FROM_PLAYER, 1, 50);
				g_timer = CreateTimer(1.0, Go2, _, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	else if (action == MenuAction_End)
		delete menu;
}

Menu RevConfirm()
{
	Menu menu = new Menu(RevConfirm_Handle);
	menu.SetTitle("SKZ için oyuncular revlensin mi?");
	menu.AddItem("0", "Revlensin");
	menu.AddItem("1", "Revlenmesin");
	menu.ExitBackButton = true;
	return menu;
}

public int RevConfirm_Handle(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		if (position == 0)
		{
			LoopAllTerroristPlayers(i)if (!IsPlayerAlive(i))
			{
				CS_RespawnPlayer(i);
			}
		}
		BunnyTimesMenu().Display(client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
	{
		if (position == MenuCancel_ExitBack)
		{
			StyleMenu().Display(client, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_End)
		delete menu;
}

Menu BunnyTimesMenu()
{
	Menu menu = new Menu(BunnyTimesMenu_Handle);
	menu.SetTitle("SKZ Bunny Süresini Seç");
	char info[8], display[64];
	for (int i = 0; i <= 61; i++)if (i % 10 == 0)
	{
		if (i == 0)continue;
		Format(info, sizeof(info), "%d", i / 10 - 1);
		Format(display, sizeof(display), "%d Saniye", i);
		menu.AddItem(info, display);
	}
	menu.ExitBackButton = true;
	return menu;
}

public int BunnyTimesMenu_Handle(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		bunnytime = (position + 1) * 10;
		LoopAllTerroristPlayers(i)if (IsPlayerAlive(i))
		{
			CS_RespawnPlayer(i);
			SetEntityRenderColor(i, 255, 0, 0, 255);
		}
		char classname[32];
		for (int j = MaxClients + 1; j <= 2048; j++)
		{
			if (!IsValidEntity(j))
				continue;
			GetEntityClassname(j, classname, 32);
			if (strcmp(classname, "func_door", false) == 0 || strcmp(classname, "func_movelinear", false) == 0)
				AcceptEntityInput(j, "Close");
		}
		PrintToChatAll("[SM] \x10%N tarafından \x04%d Bunny Süresi ile %d Saniyelik \x0EHücreden SKZ \x01başlatıldı!", client, bunnytime, skztime);
		Aktif = true;
		g_timer = CreateTimer(1.0, BunnyCountDown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (action == MenuAction_Cancel)
	{
		if (position == MenuCancel_ExitBack)
			RevConfirm().Display(client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public Action BunnyCountDown(Handle timer, any data)
{
	if (bunnytime <= 0)
	{
		char classname[32];
		for (int j = MaxClients + 1; j <= 2048; j++)
		{
			if (!IsValidEntity(j))
				continue;
			GetEntityClassname(j, classname, sizeof(classname));
			if (strcmp(classname, "func_door", false) == 0 || strcmp(classname, "func_movelinear", false) == 0)
				AcceptEntityInput(j, "Open");
		}
		LoopAllTerroristPlayers(i)
		{
			gonnaslay[i] = true;
			FinishTime[i] = GetEngineTime();
		}
		g_timer = CreateTimer(1.0, SlayNotInZone, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}
	PrintCenterTextAll("Kapıların Açılmasına <font color='#34eb40'>%d</font>", bunnytime);
	bunnytime--;
	return Plugin_Continue;
}

public Action CountDownTimer(Handle timer, any data)
{
	LoopAllTerroristPlayers(i)
	{
		SetEntityMoveType(i, MOVETYPE_WALK);
		FinishTime[i] = GetEngineTime();
	}
	EmitSoundToAllAny("bydexter/yaris/gogo.mp3", SOUND_FROM_PLAYER, 1, 50);
	PrintCenterTextAll("SKZ <font color='#34eb40'>Başladı</font>");
	g_timer = CreateTimer(1.0, SlayNotInZone, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Stop;
}

public Action Go2(Handle timer, any data)
{
	if (g_timer != null)
		g_timer = null;
	EmitSoundToAllAny("bydexter/yaris/2.mp3", SOUND_FROM_PLAYER, 1, 50);
	g_timer = CreateTimer(1.0, Go1, _, TIMER_FLAG_NO_MAPCHANGE);
	PrintCenterTextAll("SKZ Başlamasına <font color='#34eb40'>2</font>");
	return Plugin_Stop;
}

public Action Go1(Handle timer, any data)
{
	if (g_timer != null)
		g_timer = null;
	EmitSoundToAllAny("bydexter/yaris/1.mp3", SOUND_FROM_PLAYER, 1, 50);
	g_timer = CreateTimer(1.0, CountDownTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	PrintCenterTextAll("SKZ Başlamasına <font color='#34eb40'>1</font>");
	return Plugin_Stop;
}

public Action SlayNotInZone(Handle timer, any data)
{
	if (skztime <= 0)
	{
		if (finishpos == 0)
		{
			PrintToChatAll("[SM] Kimse yapamadı!");
		}
		else
		{
			LoopAllTerroristPlayers(i)if (gonnaslay[i])
				ForcePlayerSuicide(i);
		}
		FinishGame();
		return Plugin_Stop;
	}
	PrintCenterTextAll("Slay Atılmasına <font color='#34eb40'>%d</font>", skztime);
	skztime--;
	return Plugin_Continue;
}

void PrepareAndTeleport(float Teleport[3])
{
	LoopAllTerroristPlayers(i)
	{
		SetEntityMoveType(i, MOVETYPE_NONE);
		SetEntityRenderColor(i, 255, 0, 0, 255);
		gonnaslay[i] = true;
		TeleportEntity(i, Teleport, NULL_VECTOR, NULL_VECTOR);
	}
	Aktif = true;
}

void FinishGame()
{
	Aktif = false;
	skztime = 0;
	bunnytime = 0;
	finishpos = 0;
	PrintCenterTextAll("");
	LoopAllTerroristPlayers(i)
	{
		if (IsPlayerAlive(i))
			SetEntityRenderColor(i, 255, 255, 255, 255);
		if (GetEntityMoveType(i) == MOVETYPE_NONE)
			SetEntityMoveType(i, MOVETYPE_WALK);
		FinishTime[i] = 0.0;
	}
}

public void GetAimCoords(int client, float vector[3])
{
	float vAngles[3];
	float vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if (TR_DidHit(trace))
		TR_GetEndPosition(vector, trace);
	trace.Close();
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients;
}

void Ekran_Renk_Olustur(int client, int Renk[4])
{
	int clients[1];
	clients[0] = client;
	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1, 0);
	Protobuf pb = UserMessageToProtobuf(message);
	pb.SetInt("duration", 200);
	pb.SetInt("hold_time", 40);
	pb.SetInt("flags", 17);
	pb.SetColor("clr", Renk);
	EndMessage();
}

public void Zone_OnClientEntry(int client, const char[] zone)
{
	if (Aktif)
	{
		if (StrContains(zone, "SKZ", false) != -1 && GetClientTeam(client) == 2)
		{
			if (gonnaslay[client])
			{
				finishpos++;
				PrintToChatAll("[SM] \x0E%N \x01adlı oyuncu \x04SKZ'yi \x10%0.2f \x04Saniyede \x10%d. \x04Sırada \x01tamamladı!", client, GetEngineTime() - FinishTime[client], finishpos);
				gonnaslay[client] = false;
				Ekran_Renk_Olustur(client, { 0, 255, 0, 130 } );
				SetEntityRenderColor(client, 0, 255, 0, 255);
			}
		}
	}
}

public Action ElBasiSonu(Event event, const char[] name, bool dB)
{
	if (Aktif)
	{
		FinishGame();
		if (g_timer != null)
			delete g_timer;
	}
}
