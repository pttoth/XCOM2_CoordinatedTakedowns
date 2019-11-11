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
	local StateObjectReference				AbilityRef;
	local XComGameState_Ability				AbilityState;
	local XComGameStateContext_Ability		AbilityContext;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != none){
		History = `XCOMHISTORY;
		AttackingUnit = class'X2TacticalGameRulesetDataStructures'.static.GetAttackingUnitState(GameState); //this checks whether the activated ability is offensive
		MarkingUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		MarkedUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		if (AttackingUnit != none && AttackingUnit.IsFriendlyUnit(MarkingUnit)){
			MarkEffect = X2Effect_MarkForTakedown(GetX2Effect());
			if( MarkEffect == none ){
				`RedScreen("XComGamestate_MarkForTakedown: on acquision of MarkEffect, GetX2Effect returned 'none' ");
				return ELR_NoInterrupt;
			}
			//source unit owner			MarkingUnit.ControllingPlayer.ObjectID
			//attacking unit owner		MarkedUnit.ControllingPlayer.ObjectID
			//current player			`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID

			//only on player turn
			if( (MarkingUnit.ControllingPlayer.ObjectID != MarkedUnit.ControllingPlayer.ObjectID)
					&&(MarkingUnit.ControllingPlayer.ObjectID != `TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID) ) {
				return ELR_NoInterrupt;
			}

			if (MarkEffect.bPreEmptiveFire){
				//  for pre emptive fire, only process during the interrupt step
				if (AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt){
					return ELR_NoInterrupt;
				}
			}else{
				//  for non-pre emptive fire, don't process during the interrupt step
				if (AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt){
					return ELR_NoInterrupt;
				}
			}

			AbilityRef = MarkingUnit.FindAbility('TakedownShot');
			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
			if (AbilityState != none){
				if (AbilityState.CanActivateAbilityForObserverEvent(MarkedUnit) == 'AA_Success'){
					AbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility( AbilityState, MarkedUnit.ObjectID);
					if( AbilityContext.Validate() ){
						`TACTICALRULES.SubmitGameStateContext(AbilityContext);
					}
				}
			}
		}
	}
	return ELR_NoInterrupt;
}
