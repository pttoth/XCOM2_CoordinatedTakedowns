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
	local XComGameStateHistory				History;
	local XComGameState_Unit				AttackingUnit;
	local XComGameState_Unit				MarkingUnit, MarkedUnit;
	//local XComGameState_???				  MarkedProp;	//exploding barrels, etc.
	local int 								MarkingUnitOwnerID, MarkedUnitOwnerID, PlayerID;
	local X2Effect_MarkForTakedown			MarkEffect;
	local XComGameState_Ability				TriggeringAbilityState;
	local XComGameStateContext_Ability		TriggeringAbilityContext;
	local StateObjectReference				TakedownAbilityRef, EmptyRef;		//TODO: check what ObjectID EmptyRef has
	local XComGameState_Ability				TakedownAbilityState;
	local name								AbilityCanActivateResult;

	TriggeringAbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (none == TriggeringAbilityContext){
		`CTUERR("TakedownTriggerCheck(): Could not acquire TriggeringAbilityContext!");
		return ELR_NoInterrupt;
	}
	History = `XCOMHISTORY;
	TriggeringAbilityState = XComGameState_Ability(
									History.GetGameStateForObjectID(
											TriggeringAbilityContext.InputContext.AbilityRef.ObjectID));
	if(TriggeringAbilityState == none){
		`CTUDEB("TakedownTriggerCheck(): Could not acquire TriggeringAbilityState ref, skipping");
		return ELR_NoInterrupt;
	}
	`CTUDEB("TakedownTriggerCheck(): Checking current ability: '" $ TriggeringAbilityState.GetMyTemplateName() $"'");

	//check whether the activated ability is offensive
	AttackingUnit = class'X2TacticalGameRulesetDataStructures'.static.GetAttackingUnitState(GameState);
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

	//if could not acquire MarkedUnit, it may still be a targetable prop
	if(MarkedUnit == none){
		//TODO: acquire prop ref
	}

	PrintTakedownActors(AttackingUnit, MarkingUnit, MarkedUnit); //TODO: print prop ref too

	if( (none == MarkingUnit)
		|| (none == MarkedUnit) )		//TODO: update this condition with prop
	{
		`CTUERR("TakedownTriggerCheck(): Could not acquire all of the units during TakedownTriggerCheck, skipping");
		return ELR_NoInterrupt;
	}

	if (!AttackingUnit.IsFriendlyUnit(MarkingUnit)){
		`CTUDEB("TakedownTriggerCheck(): Attacking unit is not friendly to Marking unit, skipping");
		return ELR_NoInterrupt;
	}
	MarkEffect = X2Effect_MarkForTakedown(GetX2Effect());
	if( MarkEffect == none ){
		`CTUERR("TakedownTriggerCheck(): Could not acquire 'X2Effect_MarkForTakedown' reference from 'XComGameState_Effect_MarkForTakedown'");
		return ELR_NoInterrupt;
	}

	PrintInterruptionStatus(TriggeringAbilityContext.InterruptionStatus);
	MarkingUnitOwnerID	= MarkingUnit.ControllingPlayer.ObjectID;
	MarkedUnitOwnerID	= MarkedUnit.ControllingPlayer.ObjectID;
	PlayerID			= `TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID;	//TODO: check whether this is Player or current Player (should be Player)

	if (MarkEffect.bPreEmptiveFire){
		//  for pre emptive fire, only process during the interrupt step
		if (TriggeringAbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt){
			`CTUDEB("TakedownTriggerCheck(): 'bPreEmptiveFire' is on, Status: NOT Interrupt, skipping");
			return ELR_NoInterrupt;
		}
	}else{
		//  for non-pre emptive fire, don't process during the interrupt step
		if (TriggeringAbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt){
			`CTUDEB("TakedownTriggerCheck(): 'bPreEmptiveFire' is off, Status: Interrupt, skipping");
			return ELR_NoInterrupt;
		}
	}

	//only against enemy units
	if(MarkingUnitOwnerID == MarkedUnitOwnerID ){
		`CTUDEB("TakedownTriggerCheck(): Marking Unit is on the same team as Marked Unit, skipping");
		return ELR_NoInterrupt;
	}

	//only on player turn
	if( MarkingUnitOwnerID != `TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID ) {
		`CTUDEB("TakedownTriggerCheck(): Marking Unit is NOT a player unit, skipping");
		return ELR_NoInterrupt;
	}

	TakedownAbilityRef = MarkingUnit.FindAbility('TakedownShot');
	if(EmptyRef == TakedownAbilityRef){
		`CTUERR("TakedownTriggerCheck(): Could not acquire TakedownAbilityRef from MarkingUnit");
		return ELR_NoInterrupt;
	}

	TakedownAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(TakedownAbilityRef.ObjectID));
	if(none == TakedownAbilityState){
		`CTUERR("TakedownTriggerCheck(): Could not acquire TakedownAbilityState based on ObjectID");
		return ELR_NoInterrupt;
	}

	AbilityCanActivateResult = TakedownAbilityState.CanActivateAbilityForObserverEvent(MarkedUnit, MarkingUnit);
	`CTUDEB("TakedownTriggerCheck(): AbilityCanActivateResult: " $ AbilityCanActivateResult);
	if (AbilityCanActivateResult == 'AA_Success'){
		`CTUDEB("TakedownTriggerCheck(): TakedownAbilityState activation condition check PASSED");

		//update the GameStateContext of the Triggering ability with the changes
		TriggeringAbilityContext = class'XComGameStateContext_Ability'.static.
								BuildContextFromAbility(TakedownAbilityState, MarkedUnit.ObjectID );

		if( TriggeringAbilityContext.Validate() ){
			`TACTICALRULES.SubmitGameStateContext(TriggeringAbilityContext);
		}else{
			`CTUERR("TakedownTriggerCheck(): Failed to validate new TriggeringAbilityContext for Marked unit");
		}
	}else{
		`CTUDEB("TakedownTriggerCheck(): TakedownAbilityState activation condition check FAILED");
	}
	return ELR_NoInterrupt;
}
