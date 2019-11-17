//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityToHitCalc_MarkForTakedown.uc
//  AUTHOR:  Tapir
//  PURPOSE: This Hit Calculation shows the normal shot chance to the user,
//			   but will always be hit
//---------------------------------------------------------------------------------------

class X2AbilityToHitCalc_MarkForTakedown
		extends X2AbilityToHitCalc_StandardAim;

function
RollForAbilityHit(XComGameState_Ability		kAbility,
				  AvailableTarget			kTarget,
				  out AbilityResultContext	ResultContext)
{
	ResultContext.HitResult = eHit_Success;
}
