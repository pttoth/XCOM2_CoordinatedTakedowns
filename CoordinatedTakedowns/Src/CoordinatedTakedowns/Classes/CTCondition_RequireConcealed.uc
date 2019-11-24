//--------------------------------------------------------------------------------------- 
//  FILE:    CTCondition_RequireConcealed.uc
//  AUTHOR:  JL (Pavonis Interactive)
//  PURPOSE: Allows ability activition only when concealed
//	NOTE:	 Tapir:
//				Copied this from LW_PerkPack_Integrated and renamed it to avoid conflict.
//				Tried putting it to a separate 'LW_PerkPack_Integrated' package
//					(like LW_Tuple), but it messed up LW_Overhaul's perk trees.
//---------------------------------------------------------------------------------------
class CTCondition_RequireConcealed extends X2Condition;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit (kTarget);
	if (UnitState == none)
		return 'AA_UnitAlreadySpotted';

	if (UnitState.IsConcealed())
	    return 'AA_Success';

	return 'AA_UnitAlreadySpotted';

}