//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_Effect_MarkForTakedown.uc
//  AUTHOR:  Tapir
//  PURPOSE: Overrides the XComGameState_Effect, adding the TakedownCheck function to it
//				TakedownCheck watches the onAbilityActivated event and triggers the takedown if conditions are met
//---------------------------------------------------------------------------------------

class XComGameState_Effect_MarkForTakedown
	extends XComGameState_Effect
	//native(Core) 
	dependson(X2Effect, CTUtilities);

`include (CoordinatedTakedowns/Src/CoordinatedTakedowns/Classes/CTGlobals.uci)


function string
IdentifyUnit(XComGameState_Unit Unit)
{
	local string UnitName;
	UnitName = Unit.GetNickName();
	if("" == UnitName){
		UnitName = Unit.GetFullName();
	}
	return UnitName;
}

function
PrintTakedownActors(XComGameState_Unit Attacker,
					XComGameState_Unit Marker,
					XComGameState_Unit MarkedVictim)
{
	if(none == Attacker){	`CTUERR("Attacker: Could not acquire unit reference");
	}else{					`CTUDEB("Attacker: '" $ IdentifyUnit(Attacker) $ "'");
	}
	if(none == Marker){		`CTUERR("Marker: Could not acquire unit reference");
	}else{					`CTUDEB("Marker: '" $ IdentifyUnit(Marker) $ "'");
	}
	if(none == MarkedVictim){	`CTUERR("MarkedVictim: Could not acquire unit reference");
	}else{						`CTUDEB("MarkedVictim: '" $ IdentifyUnit(MarkedVictim) $ "'");
	}
}

function
PrintInterruptionStatus(EInterruptionStatus status)
{
	if(status == eInterruptionStatus_None){				`CTUDEB("InterruptionStatus: eInterruptionStatus_None");
	}else if(status == eInterruptionStatus_Interrupt){	`CTUDEB("InterruptionStatus: eInterruptionStatus_Interrupt");
	}else if(status == eInterruptionStatus_Resume){		`CTUDEB("InterruptionStatus: eInterruptionStatus_Resume");
	}else{												`CTUWARN("InterruptionStatus: UNKNOWN");
	}
}

//in case of override conflict with your own mod, copy this function into your own overriding class
function EventListenerReturn
TakedownTriggerCheck(Object			EventData,
					 Object			EventSource,
					 XComGameState	GameState,
					 Name			EventID)
{
/*
	local XComGameStateContext_Ability		AbilityContext;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());

	if(none == AbilityContext){
		`CTUERR("TakedownTriggerCheck couldn't cast GameState param to AbilityContext");
	}

	return ELR_NoInterrupt;
*/
//--------------------------------------------------

	local XComGameState_Unit				AttackingUnit; // needed for checking whether the triggering action is offensive
	local XComGameState_Unit				MarkingUnit, MarkedUnit; // the shooter and the target
	local XComGameStateHistory				History;
	local X2Effect_MarkForTakedown			MarkEffect;
	local StateObjectReference				AbilityRef, EmptyRef;		//TODO: check what ObjectID EmptyRef has
	local XComGameState_Ability				TriggeringAbilityState;
	local XComGameState_Ability				AbilityState;
	local XComGameStateContext_Ability		AbilityContext;
	local int 								MarkingUnitOwnerID, MarkedUnitOwnerID, PlayerID;
	local name								AbilityCanActivateResult;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (none == AbilityContext){
		`CTUERR("TakedownTriggerCheck(): Could not acquire AbilityContext!");
		return ELR_NoInterrupt;
	}
	History = `XCOMHISTORY;
	TriggeringAbilityState = XComGameState_Ability(
									History.GetGameStateForObjectID(
											AbilityContext.InputContext.AbilityRef.ObjectID));
	if(TriggeringAbilityState == none){
		`CTUDEB("TakedownTriggerCheck(): Could not acquire TriggeringAbilityState ref, skipping");
		return ELR_NoInterrupt;
	}
	`CTUDEB("TakedownTriggerCheck(): Checking current ability: '" $ TriggeringAbilityState.GetMyTemplateName() $"'");

	AttackingUnit = class'X2TacticalGameRulesetDataStructures'.static.GetAttackingUnitState(GameState); //this checks whether the activated ability is offensive
	if(none == AttackingUnit){
		`CTUDEB("TakedownTriggerCheck(): Could not acquire 'AttackingUnit' ref, the ability in action is not offensive, skipping");
		return ELR_NoInterrupt;
	}

	MarkingUnit = XComGameState_Unit(
						History.GetGameStateForObjectID(
								ApplyEffectParameters.SourceStateObjectRef.ObjectID ) );
	MarkedUnit = XComGameState_Unit(
						History.GetGameStateForObjectID(
								ApplyEffectParameters.TargetStateObjectRef.ObjectID ) );

	PrintTakedownActors(AttackingUnit, MarkingUnit, MarkedUnit);

	if( (none == MarkingUnit)
		|| (none == MarkedUnit) )
	{
		`CTUERR("TakedownTriggerCheck(): Could not acquire all of the units during TakedownTriggerCheck, skipping");
		return ELR_NoInterrupt;
	}

	if (AttackingUnit.IsFriendlyUnit(MarkingUnit)){
		`CTUDEB("TakedownTriggerCheck(): Attacking unit is friendly to Marking unit");
		MarkEffect = X2Effect_MarkForTakedown(GetX2Effect());
		if( MarkEffect == none ){
			`CTUERR("TakedownTriggerCheck(): Could not acquire 'X2Effect_MarkForTakedown' reference from 'XComGameState_Effect_MarkForTakedown'");
			return ELR_NoInterrupt;
		}

		PrintInterruptionStatus(AbilityContext.InterruptionStatus);

		if (MarkEffect.bPreEmptiveFire){
			//  for pre emptive fire, only process during the interrupt step
			if (AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt){
				`CTUDEB("TakedownTriggerCheck(): 'bPreEmptiveFire' is on, Status: NOT Interrupt, skipping");
				return ELR_NoInterrupt;
			}
		}else{
			//  for non-pre emptive fire, don't process during the interrupt step
			if (AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt){
				`CTUDEB("TakedownTriggerCheck(): 'bPreEmptiveFire' is off, Status: Interrupt, skipping");
				return ELR_NoInterrupt;
			}
		}

		MarkingUnitOwnerID		= MarkingUnit.ControllingPlayer.ObjectID;
		MarkedUnitOwnerID		= MarkedUnit.ControllingPlayer.ObjectID;
		//AttackingUnitOwnerID	= MarkedUnit.ControllingPlayer.ObjectID;
		PlayerID				= `TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID;
		//source unit owner			MarkingUnit.ControllingPlayer.ObjectID
		//attacking unit owner		MarkedUnit.ControllingPlayer.ObjectID
		//current player			`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID

		//only against enemy units
		if(MarkingUnit.ControllingPlayer.ObjectID == MarkedUnit.ControllingPlayer.ObjectID ){
			`CTUDEB("TakedownTriggerCheck(): Marking Unit is on the same team as Marked Unit, skipping");
			return ELR_NoInterrupt;
		}

		//only on player turn
		if( MarkingUnit.ControllingPlayer.ObjectID != `TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID ) {
			`CTUDEB("TakedownTriggerCheck(): Marking Unit is NOT a player unit, skipping");
			return ELR_NoInterrupt;
		}

		AbilityRef = MarkingUnit.FindAbility('TakedownShot');
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));

		if(EmptyRef == AbilityRef){
			`CTUERR("TakedownTriggerCheck(): Could not acquire AbilityRef from MarkingUnit");
		}
		if(none == AbilityState){
			`CTUERR("TakedownTriggerCheck(): Could not acquire AbilityState based on ObjectID");
		}

		if (AbilityState != none){
			AbilityCanActivateResult = AbilityState.CanActivateAbilityForObserverEvent(MarkedUnit);
			`CTUDEB("TakedownTriggerCheck(): AbilityCanActivateResult: " $ AbilityCanActivateResult);
			if (AbilityCanActivateResult == 'AA_Success'){
				`CTUDEB("TakedownTriggerCheck(): AbilityState activation condition check PASSED");	//TODO: should this new context be for the Marked unit ????

				AbilityContext = class'XComGameStateContext_Ability'.static.
										BuildContextFromAbility(AbilityState, MarkedUnit.ObjectID ); //TODO: check this function!


				if( AbilityContext.Validate() ){
					`TACTICALRULES.SubmitGameStateContext(AbilityContext);
				}else{
					`CTUERR("TakedownTriggerCheck(): Failed to validate AbilityContext for Marked unit");
				}
			}else{
				`CTUDEB("TakedownTriggerCheck(): AbilityState activation condition check FAILED");
			}
		}
	}
	return ELR_NoInterrupt;

}
