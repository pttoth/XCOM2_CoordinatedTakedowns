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

//in case of override conflict with your own mod, copy this function into your own overriding class
function EventListenerReturn
TakedownTriggerCheck(Object			EventData,
					 Object			EventSource,
					 XComGameState	GameState,
					 Name			EventID)
{
	local XComGameState_Unit				AttackingUnit; // needed for checking whether the triggering action is offensive
	local XComGameState_Unit				MarkingUnit, MarkedUnit; // the shooter and the target
	local XComGameStateHistory				History;
	local X2Effect_MarkForTakedown			MarkEffect;
	local StateObjectReference				AbilityRef, EmptyRef;		//TODO: check what ObjectID EmptyRef has
	local XComGameState_Ability				AbilityState;
	local XComGameStateContext_Ability		AbilityContext;

	`CTUDEB("TakedownTriggerCheck running");
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != none){
		History = `XCOMHISTORY;
		AttackingUnit = class'X2TacticalGameRulesetDataStructures'.static.GetAttackingUnitState(GameState); //this checks whether the activated ability is offensive
		MarkingUnit = XComGameState_Unit(
							History.GetGameStateForObjectID(
									ApplyEffectParameters.SourceStateObjectRef.ObjectID ) );
		MarkedUnit = XComGameState_Unit(
							History.GetGameStateForObjectID(
									ApplyEffectParameters.TargetStateObjectRef.ObjectID ) );

		PrintTakedownActors(AttackingUnit, MarkingUnit, MarkedUnit);

		if( (none == AttackingUnit)
			|| (none == MarkingUnit)
			|| (none == MarkedUnit) )
		{
			`CTUERR("Could not acquire all of the units during TakedownTriggerCheck, skipping");
			return ELR_NoInterrupt;
		}

		if (AttackingUnit.IsFriendlyUnit(MarkingUnit)){
			`CTUDEB("Attacking unit is friendly to Marking unit");
			MarkEffect = X2Effect_MarkForTakedown(GetX2Effect());
			if( MarkEffect == none ){
				`CTUERR("Could not acquire 'X2Effect_MarkForTakedown' reference from 'XComGameState_Effect_MarkForTakedown'");
				return ELR_NoInterrupt;
			}
			//source unit owner			MarkingUnit.ControllingPlayer.ObjectID
			//attacking unit owner		MarkedUnit.ControllingPlayer.ObjectID
			//current player			`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID

			//only on player turn
			if( (MarkingUnit.ControllingPlayer.ObjectID != MarkedUnit.ControllingPlayer.ObjectID)
					&&(MarkingUnit.ControllingPlayer.ObjectID != `TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID) ) {
				`CTUDEB("Marking Unit is player unit, the Marked Target is not");
				return ELR_NoInterrupt;
			}

			if (MarkEffect.bPreEmptiveFire){
				`CTUDEB("'bPreEmptiveFire' is on");
				//  for pre emptive fire, only process during the interrupt step
				if (AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt){
					return ELR_NoInterrupt;
				}
			}else{
				`CTUDEB("'bPreEmptiveFire' is off");
				//  for non-pre emptive fire, don't process during the interrupt step
				if (AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt){
					return ELR_NoInterrupt;
				}
			}

			AbilityRef = MarkingUnit.FindAbility('TakedownShot');
			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));

			if(EmptyRef == AbilityRef){
				`CTUERR("Could not acquire AbilityRef from MarkingUnit");
			}
			if(none == AbilityState){
				`CTUERR("Could not acquire AbilityState based on ObjectID");
			}

			if (AbilityState != none){
				if (AbilityState.CanActivateAbilityForObserverEvent(MarkedUnit) == 'AA_Success'){
					`CTUDEB("AbilityState activation condition check PASSED");	//TODO: should this new context be for the Marked unit ????
					AbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility( AbilityState, MarkedUnit.ObjectID);
					if( AbilityContext.Validate() ){
						`TACTICALRULES.SubmitGameStateContext(AbilityContext);
					}else{
						`CTUERR("Failed to validate AbilityContext for Marked unit");
					}
				}else{
					`CTUDEB("AbilityState activation condition check FAILED");
				}
			}
		}
	}
	return ELR_NoInterrupt;
}
