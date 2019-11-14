//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_ReserveTakedownActionPoints.uc
//  AUTHOR:  Tapir (based on ReserveOverwatchPoints)
//  PURPOSE: Utility class for the MarkForTakedown ability
//				used to distinguish, whether the pistol or the primary weapon should be used for the takedown shot
//---------------------------------------------------------------------------------------
class X2Effect_ReserveTakedownActionPoints 
					extends X2Effect_ReserveActionPoints
					dependson(CTUtilities);

`include (CoordinatedTakedowns/Src/CoordinatedTakedowns/Classes/CTGlobals.uci)

var name TakedownActionPoint;
var name TakedownPistolActionPoint;


//this is called when the effect is placed (called from: X2Effect_ReserveActionPoints.OnEffectAdded() )
//determines which type of Takedown Action Point should be added to the soldier
//	based on the weapon used in the mark ability
//it checks which Overwatch Action Point would be used and returns its own instead
//	can use '' as error signaling ???
simulated function name
GetReserveType(const out EffectAppliedData	ApplyEffectParameters,
							XComGameState	NewGameState)
{
	local XComGameState_Item		ItemState;
	local X2WeaponTemplate			WeaponTemplate;
	local name						OverwatchReserve;
	local name						PistolOverwatchReserve;
	local string					WeaponName;

	`CTUDEB("GetReserveType() running");
	if (ApplyEffectParameters.ItemStateObjectRef.ObjectID > 0){
		ItemState = XComGameState_Item(
							NewGameState.GetGameStateForObjectID(
									ApplyEffectParameters.ItemStateObjectRef.ObjectID ) );
		if (ItemState == none){
			`CTUDEB("GetReserveType(): Could not get ItemState from ApplyEffectParameters");
			`CTUDEB("GetReserveType():   Trying from History...");
			ItemState = XComGameState_Item(
								`XCOMHISTORY.GetGameStateForObjectID(
										ApplyEffectParameters.ItemStateObjectRef.ObjectID ) );
		}
		if (ItemState == none){
			`CTUERR("GetReserveType(): Could not acquire item gamestate for item in 'ApplyEffectParameters'");
		}else{
			`CTUDEB("GetReserveType(): Acquired ItemState");
			WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
			if( WeaponTemplate == none){
				`CTUERR("GetReserveType(): Could not acquire weapon template for item:" $ ItemState.GetMyTemplateName());
			}else{
				if ( WeaponTemplate.OverwatchActionPoint != '' ){
					//workaround to save an X2CharacterTemplateManager override
					//	identifies the weapon the same way overwatch does
					//	based on that information returns Takedown's own reserve types
					//	will need to update if
					//	 - overwatch changes 
					//	 - a new weapon type becomes available simultaneously with primaries or pistols

					//get the overwatch identifier names
					OverwatchReserve = class'X2CharacterTemplateManager'.default.OverwatchReserveActionPoint;
					PistolOverwatchReserve = class'X2CharacterTemplateManager'.default.PistolOverwatchReserveActionPoint;

					WeaponName = WeaponTemplate.GetItemFriendlyName();
					if( WeaponTemplate.OverwatchActionPoint == OverwatchReserve ){
					//if the weapon uses standard overwatch
						`CTUDEB("GetReserveType(): Weapon uses standard overwatch, allocating TakedownActionPoint");
						return TakedownActionPoint;
					}else if( WeaponTemplate.OverwatchActionPoint == PistolOverwatchReserve ){
					//if the weapon uses pistol overwatch
						`CTUDEB("GetReserveType(): Weapon uses pistol overwatch, allocating TakedownPistolActionPoint");
						return TakedownPistolActionPoint;
					}else{
						`CTUERR("GetReserveType(): Could not determine the Takedown Action Point Reserve Type for weapon: " $ WeaponName);
						`CTUERR("GetReserveType():   The weapon '"$WeaponName$"' has 'MarkForTakedown' ability, but this mod cannot recognize an 'OverwatchActionPoint' Type for it!");
						`CTUERR("GetReserveType():   Modded weapon maybe?");
						return default.ReserveType;
					}
				}
			}
		}
	}else{
		`CTUDEB("GetReserveType(): ApplyEffectParameters.ItemStateObjectRef.ObjectID > 0   ==  FALSE");
	}
	`CTUERR("GetReserveType(): Could not determine the Takedown Actionpoint Reserve Type");
	`CTUERR("GetReserveType():   Returning default value instead");
	return default.ReserveType;
}


//This is called in parent's 'OnEffectAdded' function
//	the return value is used as an upper bound in a for-cycle in which
//	GetReserveType() is called each time (default = 1)
//Can it be used (with this parameter) for error-handling
//	to avoid having to return an ActionPoint type in a case of failure ???
simulated protected function int
GetNumPoints(XComGameState_Unit UnitState)
{
	return NumPoints;
}

DefaultProperties
{
	TakedownActionPoint			= "ReserveActionPointTakedown"
	TakedownPistolActionPoint	= "ReserveActionPointTakedownPistol"
	ReserveType = TakedownActionPoint
	//bApplyOnHit = true
	//bApplyOnMiss = true		TODO: try these
	NumPoints = 1
}
