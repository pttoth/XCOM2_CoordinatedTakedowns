class X2Effect_MarkForTakedown
		extends X2Effect_Persistent
		dependson(CTUtilities);

`include (CoordinatedTakedowns/Src/CoordinatedTakedowns/Classes/CTGlobals.uci)

var bool bPreEmptiveFire;		//	controls whether the marking soldier should fire before the triggering soldier

//---------------------------------------------------------------------------
function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager						EventMgr;
	local Object								EffectObj;
	local XComGameState_Effect_MarkForTakedown	TakedownState; //TODO: rewrite the class type to your own, if you are solving a mod conflict

	EventMgr = `XEVENTMGR;
	TakedownState = XComGameState_Effect_MarkForTakedown(EffectGameState); //TODO: rewrite the class type to your own, if you are solving a mod conflict
	EffectObj = TakedownState;
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', TakedownState.TakedownTriggerCheck, ELD_OnStateSubmitted);
	`CTUDEB("RegisterForEvents(): Registered for 'AbilityActivated' event");
}

DefaultProperties
{
	bPreEmptiveFire = false	//better on false, because you can manually select a unit with shredder or holo target to definitely fire first
	//inherited
	iNumTurns = 1
	EffectName = "MarkedForTakedownEffect"	// Used to identify the effect for purposes of stacking with other effects.
	bDupeForSameSourceOnly = true		// when adding the effect to a target, any similar effects coming from a different source are ignored when checking for a pre-existing effect
	DuplicateResponse = eDupe_Ignore
	//DuplicateResponse = eDupe_Allow
	bApplyOnHit = true
	bApplyOnMiss = true
	bRemoveWhenSourceDies = true
    bRemoveWhenTargetDies = true
	bRemoveWhenSourceDamaged = true
	bUniqueTarget = true				// for a given source, this effect may only apply to one target. any pre-existing effect on another target is removed in HandleApplyEffect
}

//if very, very bored - check them
/*
var string VFXTemplateName;						// Name of a particle system to play on the unit while this persistent effect is active
var name VFXSocket;								// The name of a socket to which the particle system component should be attached. (optional)
var name VFXSocketsArrayName;                   // Name associated with an array of sockets the particle system will attach to. (optional)
var float VisionArcDegreesOverride;				// This will limit the sight arc of the character.  If 2 effects have this it chooses the smaller arc.

var delegate<AddEffectVisualization> VisualizationFn;
var delegate<AddEffectVisualization> CleansedVisualizationFn;
var delegate<AddEffectVisualization> EffectTickedVisualizationFn;
var delegate<AddEffectVisualization> EffectRemovedVisualizationFn;
var delegate<AddEffectVisualization> EffectRemovedSourceVisualizationFn;
var delegate<AddEffectVisualization_Death> DeathVisualizationFn;
var delegate<AddEffectVisualization> ModifyTracksFn;
var delegate<EffectRemoved> EffectRemovedFn;
var delegate<EffectAdded> EffectAddedFn;
var delegate<EffectTicked> EffectTickedFn;

delegate AddEffectVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult);
delegate EffectRemoved(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed);
delegate EffectAdded(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState);
delegate bool EffectTicked(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication);
delegate X2Action AddEffectVisualization_Death(out VisualizationTrack BuildTrack, XComGameStateContext Context);
*/
