//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_CoordinatedTakedowns.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_CoordinatedTakedowns 
						extends X2DownloadableContentInfo 
						config(CoordinatedTakedowns);

var config array<name> CAPABLE_WEAPONS_PRIMARY;
var config array<name> CAPABLE_WEAPONS_PISTOL;
var config array<name> CAPABLE_WEAPONS_SNIPER;

/// <summary>
/// Called after the Templates have been created (but before they are validated) while this DLC / Mod is installed.
/// </summary>
static event OnPostTemplatesCreated()
{
	AddAbilitiesToPrimaries();
	AddAbilitiesToPistols();
	AddAbilitiesToSnipers();
}

static function AddAbilitiesToPrimaries(){
	local X2ItemTemplateManager				ItemManager;
	local X2WeaponTemplate					WeaponTemplate;
	local name								WeaponName;
	ItemManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach default.CAPABLE_WEAPONS_PRIMARY(WeaponName){
		WeaponTemplate = X2WeaponTemplate( ItemManager.FindItemTemplate( WeaponName ) ); 

		if( none == WeaponTemplate){
			`Log("CoordinatedTakedowns: MISSING WEAPON " $ WeaponName $ ", skipping");
		}else{
			`Log("CoordinatedTakedowns: Added abilities to " $ string(WeaponName));
			WeaponTemplate.Abilities.AddItem( 'MarkForTakedown' );
			WeaponTemplate.Abilities.AddItem( 'TakedownShot' );
		}
	}
}

static function AddAbilitiesToPistols(){
	local X2ItemTemplateManager				ItemManager;
	local X2WeaponTemplate					WeaponTemplate;
	local name								WeaponName;
	ItemManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach default.CAPABLE_WEAPONS_PISTOL(WeaponName){
		WeaponTemplate = X2WeaponTemplate( ItemManager.FindItemTemplate( WeaponName ) ); 
		if( none == WeaponTemplate){
			`Log("CoordinatedTakedowns: MISSING WEAPON " $ string(WeaponName) $ ", skipping");
		}else{
			`Log("CoordinatedTakedowns: Added abilities to " $ string(WeaponName));
			WeaponTemplate.Abilities.AddItem( 'MarkForTakedownPistol' );
			WeaponTemplate.Abilities.AddItem( 'TakedownShotPistol' );
		}
	}
}

static function AddAbilitiesToSnipers(){
	local X2ItemTemplateManager				ItemManager;
	local X2WeaponTemplate					WeaponTemplate;
	local name								WeaponName;
	ItemManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach default.CAPABLE_WEAPONS_SNIPER(WeaponName){
		WeaponTemplate = X2WeaponTemplate( ItemManager.FindItemTemplate( WeaponName ) );

		if( none == WeaponTemplate){
			`Log("CoordinatedTakedowns: MISSING WEAPON " $ WeaponName $ ", skipping");
		}else{
			`Log("CoordinatedTakedowns: Added abilities to " $ string(WeaponName));
			WeaponTemplate.Abilities.AddItem( 'MarkForTakedownSniper' );
			WeaponTemplate.Abilities.AddItem( 'TakedownShot' );
		}
	}
}

//------------------------------------------------------------------------------------------------------------------
//********************************************DEFAULT INHERITED FUNCTIONS*******************************************
//------------------------------------------------------------------------------------------------------------------

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{}

/// <summary>
/// This method is run when the player loads a saved game directly into Strategy while this DLC is installed
/// </summary>
static event OnLoadedSavedGameToStrategy()
{}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{}

/// <summary>
/// Called just before the player launches into a tactical a mission while this DLC / Mod is installed.
/// Allows dlcs/mods to modify the start state before launching into the mission
/// </summary>
static event OnPreMission(XComGameState StartGameState, XComGameState_MissionSite MissionState)
{}

/// <summary>
/// Called when the player completes a mission while this DLC / Mod is installed.
/// </summary>
static event OnPostMission()
{}

/// <summary>
/// Called when the player is doing a direct tactical->tactical mission transfer. Allows mods to modify the
/// start state of the new transfer mission if needed
/// </summary>
static event ModifyTacticalTransferStartState(XComGameState TransferStartState)
{}

/// <summary>
/// Called after the player exits the post-mission sequence while this DLC / Mod is installed.
/// </summary>
static event OnExitPostMissionSequence()
{}

/// <summary>
/// Called when the difficulty changes and this DLC is active
/// </summary>
static event OnDifficultyChanged()
{}

/// <summary>
/// A dialogue popup used for players to confirm or deny whether new gameplay content should be installed for this DLC / Mod.
/// </summary>
static function EnableDLCContentPopup()
{}

simulated function EnableDLCContentPopupCallback(eUIAction eAction)
{}

/// <summary>
/// Called when viewing mission blades with the Shadow Chamber panel, used primarily to modify tactical tags for spawning
/// Returns true when the mission's spawning info needs to be updated
/// </summary>
static function bool UpdateShadowChamberMissionInfo(StateObjectReference MissionRef)
{
	return false;
}

/// <summary>
/// Called from X2AbilityTag:ExpandHandler after processing the base game tags. Return true (and fill OutString correctly)
/// to indicate the tag has been expanded properly and no further processing is needed.
/// </summary>
static function bool AbilityTagExpandHandler(string InString, out string OutString)
{
	return false;
}
/// <summary>
/// Called from XComGameState_Unit:GatherUnitAbilitiesForInit after the game has built what it believes is the full list of
/// abilities for the unit based on character, class, equipment, et cetera. You can add or remove abilities in SetupData.
/// </summary>
static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{}

defaultProperties
{

}
