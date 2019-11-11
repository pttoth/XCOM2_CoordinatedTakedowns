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

simulated function name
GetReserveType(const out EffectAppliedData	ApplyEffectParameters,
							XComGameState	NewGameState)
{
	local XComGameState_Item		ItemState;
	local X2WeaponTemplate			WeaponTemplate;
	local name						OverwatchReserve;
	local name						PistolOverwatchReserve;

	if (ApplyEffectParameters.ItemStateObjectRef.ObjectID > 0){
		ItemState = XComGameState_Item(
							NewGameState.GetGameStateForObjectID(
									ApplyEffectParameters.ItemStateObjectRef.ObjectID ) );
		if (ItemState == none){
			ItemState = XComGameState_Item(
								`XCOMHISTORY.GetGameStateForObjectID(
										ApplyEffectParameters.ItemStateObjectRef.ObjectID ) );
		}
		if (ItemState != none){
			`CTUERR("Could not acquire item gamestate for item in 'ApplyEffectParameters'");
		}else{
			WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
			if( none == WeaponTemplate ){
				`CTUERR("Could not acquire weapon template for item:" $ ItemState.GetMyTemplateName());
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

					//if the weapon uses standard overwatch
					if( WeaponTemplate.OverwatchActionPoint == OverwatchReserve ){
						`CTUDEB("Weapon uses standard overwatch, allocating TakedownActionPoint");
						return TakedownActionPoint;
					}
					//if the weapon uses pistol overwatch
					if( WeaponTemplate.OverwatchActionPoint == PistolOverwatchReserve ){
						`CTUDEB("Weapon uses pistol overwatch, allocating TakedownPistolActionPoint");
						return TakedownPistolActionPoint;
					}

					return WeaponTemplate.OverwatchActionPoint;
				}
			}
		}
	}
	`CTUWARN("Allocated default Actionpoint Reserve Type, this may indicate an error!");
	return default.ReserveType;
}

DefaultProperties
{
	TakedownActionPoint			= "ReserveActionPointTakedown"
	TakedownPistolActionPoint	= "ReserveActionPointTakedownPistol"
	ReserveType = TakedownActionPoint
	NumPoints = 1
}
