class X2Ability_CoordinatedTakedown
		extends X2Ability
		dependson(CTUtilities, X2AbilityToHitCalc_MarkForTakedown)
		config(CoordinatedTakedowns);

`include (CoordinatedTakedowns/Src/CoordinatedTakedowns/Classes/CTGlobals.uci)

enum eTakedownAnimSequence{
	eSequential,
	eSemiSequential,
	eParallel
};

var config 		bool 								bRemoveConcealmentRequirement;
var config		eTakedownAnimSequence				eVisualizationType;

//vars below should not be modified
var protected 	X2AbilityToHitCalc_MarkForTakedown	MarkForTakedownToHitCalc;

//------------------------------------------------------------------
//***********************CREATE TEMPLATES***************************
//------------------------------------------------------------------
static function array<X2DataTemplate>
CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	`CTUDEB("X2Ability_CoordinatedTakedown: CreateTemplates() called");
	Templates.AddItem(AddMarkForTakedownAbility());
	Templates.AddItem(AddMarkForTakedownSniperAbility());
	Templates.AddItem(AddMarkForTakedownPistolAbility());
	Templates.AddItem(AddTakedownShotAbility());
	Templates.AddItem(AddTakedownShotPistolAbility());
	return Templates;
}

static function
CreateMarkForTakedownCommonProperties(out X2AbilityTemplate Template)
{
//used variables	
	local X2AbilityCost_Ammo				AmmoCost;
	local X2Effect_MarkForTakedown			TakedownMarkEffect;		//shooting checks whether this effect is on the targets
	local X2Condition_UnitEffects			SuppressedCondition;
	local X2Condition_Visibility			VisibilityCondition;

//Icon Properties
	Template.bDontDisplayInAbilitySummary = true;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailableOrNoTargets;
	Template.DisplayTargetHitChance = true;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_standard";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.OVERWATCH_PRIORITY+1;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityConfirmSound = "Unreal2DSounds_OverWatch";

//Conditions:
//user alive
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
//user has ammo
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	AmmoCost.bFreeCost = true;			//  ammo is consumed by the shot, not by this, but this should verify ammo is available
	Template.AbilityCosts.AddItem(AmmoCost);
//user is not suppressed
	SuppressedCondition = new class'X2Condition_UnitEffects';
	SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
	Template.AbilityShooterConditions.AddItem(SuppressedCondition);
//target is visible
	VisibilityCondition = new class'X2Condition_Visibility';
	VisibilityCondition.bRequireGameplayVisible = true;
	Template.AbilityTargetConditions.AddItem(VisibilityCondition);
//target is a living enemy (or destructible prop)
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);

//add standard ability cancel behavior for impairing states (panicked, stunned, etc.)
	Template.AddShooterEffectExclusions();

//Additional behavior when selected
// Targeting Method
	Template.AbilityTargetStyle = default.SimpleSingleTarget; // Only at single targets that are in range.
	Template.TargetingMethod = class'X2TargetingMethod_OverTheShoulder';
	
//TODO: make some visual feedback, check how overwatch displays the popup text overhead
	//	Template.CinescriptCameraType = "StandardGunFiring"; 
	//note: X2Effect_MarkForTakedown takes care of effect application regardless of hit/miss
	
	//Has to display normal hit chance percentages during targeting,
	//  but the Mark ability itself always has to hit (it is the effect placement only)
	Template.AbilityToHitCalc = default.MarkForTakedownToHitCalc;

//add concealment requirement condition
	`CTUDEB("CreateTemplates(): bRemoveConcealmentRequirement: " $ default.bRemoveConcealmentRequirement);
	if(!default.bRemoveConcealmentRequirement){
		Template.AbilityShooterConditions.AddItem( new class'CTCondition_RequireConcealed' );
	}

//Ability gameplay effects
//doesn't reveal soldier(this is only mark, not shoot)
	Template.Hostility = eHostility_Neutral;
	//Template.bIsPassive = true; //why was this enabled?
	//bAllowedByDefault;		//  if true, this ability will be enabled by default. Otherwise the ability will have to be enabled before it is usable
	//AdditionalAbilities		//  when a unit is granted this ability, it will be granted all of these abilities as well
	//PostActivationEvents;     //  trigger these events after AbilityActivated is triggered (only when not interrupted) EventData=ability state, EventSource=owner unit state
//place the mark on the target
	TakedownMarkEffect = new class'X2Effect_MarkForTakedown';
	TakedownMarkEffect.BuildPersistentEffect(1, true, true,, eGameRule_TacticalGameStart);	//shouldn't be infinite
	//TakedownMarkEffect.BuildPersistentEffect(1, false, true,, eGameRule_TacticalGameStart);	//TODO: try this
	TakedownMarkEffect.SetDisplayInfo(ePerkBuff_Passive,
										Template.LocFriendlyName,
										Template.GetMyLongDescription(),
										Template.IconImage,
										true, , Template.AbilitySourceName);
	Template.AddTargetEffect(TakedownMarkEffect);

//Set it up in the game
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = MarkForTakedown_BuildVisualization;
//	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;	//uses a shot animation for marking, replace this
	//Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;	//TODO: needed?

	//Template.bSkipFireAction = true;	//TODO: see this
}


//------------------------------------------------------------------
//***********************STANDARD WEAPONS***************************
//------------------------------------------------------------------
static function X2AbilityTemplate
AddMarkForTakedownAbility()
{
//used variables
	local X2AbilityTemplate                 Template;
	local X2Effect_ReserveActionPoints      ReserveActionPointsEffect;	//this will give us the special action points the shot needs
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Condition_Visibility			VisibilityCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'MarkForTakedown');
	CreateMarkForTakedownCommonProperties(Template);

//allow squadsight usage
	VisibilityCondition = new class'X2Condition_Visibility';
	VisibilityCondition.bAllowSquadsight = true;
	Template.AbilityTargetConditions.AddItem(VisibilityCondition);

//reserve TakedownActionPoint to use when shooting
	ReserveActionPointsEffect = new class'X2Effect_ReserveTakedownActionPoints';
	ReserveActionPointsEffect.ReserveType = class'X2Effect_ReserveTakedownActionPoints'.default.TakedownActionPoint;
	Template.AddShooterEffect(ReserveActionPointsEffect);
//has ActionPoints
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bConsumeAllPoints = true;   //  this will guarantee the unit has at least 1 action point

	//If bFreeCost = true, then ApplyCost should do nothing, but CanAfford will still check the requirements.
	ActionPointCost.bFreeCost = true;	//  ReserveActionPoints effect will take all action points away instead

	ActionPointCost.DoNotConsumeAllEffects.Length = 0;
	ActionPointCost.DoNotConsumeAllSoldierAbilities.Length = 0;
	Template.AbilityCosts.AddItem(ActionPointCost);

	return Template;
}

//------------------------------------------------------------------
//*************************SNIPER WEAPONS***************************
//------------------------------------------------------------------

static function X2AbilityTemplate
AddMarkForTakedownSniperAbility()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints		ActionPointCost;
	local X2Effect_ReserveActionPoints      ReserveActionPointsEffect;	//this will give us the special action points the shot needs
	local X2Condition_Visibility			VisibilityCondition;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'MarkForTakedownSniper');
	CreateMarkForTakedownCommonProperties(Template);

//allow squadsight usage
	VisibilityCondition = new class'X2Condition_Visibility';
	VisibilityCondition.bAllowSquadsight = true;
	Template.AbilityTargetConditions.AddItem(VisibilityCondition);

//Icon Properties
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_snipershot";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.OVERWATCH_PRIORITY+1;

//Conditions:
//sniper fire conditions
	// Action Point (cannot use it after moving)
	ActionPointCost = new class 'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 2;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);
//currently doesn't support snap shot
	//...
//reserve TakedownActionPoint to use when shooting
	ReserveActionPointsEffect = new class'X2Effect_ReserveTakedownActionPoints';
	ReserveActionPointsEffect.ReserveType = class'X2Effect_ReserveTakedownActionPoints'.default.TakedownActionPoint;
	Template.AddShooterEffect(ReserveActionPointsEffect);

	return Template;
}

//------------------------------------------------------------------
//*************************PISTOL WEAPONS***************************
//------------------------------------------------------------------

static function X2AbilityTemplate
AddMarkForTakedownPistolAbility()
{
	local X2AbilityTemplate                 Template;
	local X2Effect_ReserveActionPoints      ReserveActionPointsEffect;	//this will give us the special action points the shot needs
	local X2AbilityCost_ActionPoints        ActionPointCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'MarkForTakedownPistol');
	CreateMarkForTakedownCommonProperties(Template);

	//Icon Properties
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_standardpistol";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.PISTOL_OVERWATCH_PRIORITY+1;

//reserve TakedownPistolActionPoint to use when shooting
	ReserveActionPointsEffect = new class'X2Effect_ReserveTakedownActionPoints';
	ReserveActionPointsEffect.ReserveType = class'X2Effect_ReserveTakedownActionPoints'.default.TakedownPistolActionPoint;
	Template.AddShooterEffect(ReserveActionPointsEffect);
//Conditions:
//has ActionPoints
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bConsumeAllPoints = true;   //  this will guarantee the unit has at least 1 action point
	ActionPointCost.bFreeCost = true;           //  ReserveActionPoints effect will take all action points away
	ActionPointCost.DoNotConsumeAllEffects.Length = 0;
	ActionPointCost.DoNotConsumeAllSoldierAbilities.Length = 0;
	Template.AbilityCosts.AddItem(ActionPointCost);

	return Template;
}


//------------------------------------------------------------------
//*************************TAKEDOWN SHOT****************************
//------------------------------------------------------------------



static function
CreateTakedownShotCommonProperties(out X2AbilityTemplate Template)
{
	local X2AbilityToHitCalc_StandardAim				StandardAim;
	local X2AbilityTarget_Single						SingleTarget;
	local X2Effect_Knockback							KnockbackEffect;
	local X2Condition_UnitEffectsWithAbilitySource		AbilitySourceCondition; //this check whether the target was marked by us

	//Icon Properties
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_overwatch";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.OVERWATCH_PRIORITY;

//Conditions:
//shooter is alive
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

//shooter is concealed (bug: this prevents Takedown Shots after the triggering unit exits concealment)
/*
	`CTUDEB("CreateTakedownShotCommonProperties(): bRemoveConcealmentRequirement: " $ default.bRemoveConcealmentRequirement);
	if(!default.bRemoveConcealmentRequirement){
		Template.AbilityShooterConditions.AddItem( new class'CTCondition_RequireConcealed' );
	}
*/

//target is already marked by this soldier
	AbilitySourceCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	AbilitySourceCondition.AddRequireEffect(class'X2Effect_MarkForTakedown'.default.EffectName, 'AA_UnitIsMarkedForTakedown');
	Template.AbilityTargetConditions.Additem(AbilitySourceCondition);
// Can't target dead; Can't target friendlies
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);
//may need to modify it to use with my mark
	//Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty); 

//add standard ability cancel behavior for impairing states (panicked, stunned, etc.)
	Template.AddShooterEffectExclusions();

//Ability gameplay effects
//Acquire target (only single target within weapon range)
	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.OnlyIncludeTargetsInsideWeaponRange = true;
	Template.AbilityTargetStyle = SingleTarget;
//calculate aim
	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	Template.AbilityToHitCalc = StandardAim;
	Template.AbilityToHitOwnerOnMissCalc = StandardAim;
//extra shot effects
//  Put holo target effect first because if the target dies from this shot, it will be too late to notify the effect.
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());
	Template.bAllowBonusWeaponEffects = true;
	Template.bAllowFreeFireWeaponUpgrade = false;	
	Template.bAllowAmmoEffects = true;
// Damage Effect
	//Template.AddTargetEffect(default.WeaponUpgradeMissDamage);
	Template.AssociatedPassives.AddItem('HoloTargeting'); // marks to gain the aim bonus?

//visuals (knockback)
	KnockbackEffect = new class'X2Effect_Knockback';
	KnockbackEffect.KnockbackDistance = 2;
	KnockbackEffect.bUseTargetLocation = true;
	Template.AddTargetEffect(KnockbackEffect);
//Set it up in the game
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TakedownShot_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
}



static function X2AbilityTemplate
AddTakedownShotAbility()
{
//used variables
	local X2AbilityTemplate								Template;
	local X2AbilityCost_Ammo							AmmoCost;
	local X2AbilityCost_ReserveActionPoints				ReserveActionPointCost;
	local X2Condition_Visibility						TargetVisibilityCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'TakedownShot');
	//set up common properties
	CreateTakedownShotCommonProperties(Template);

//Conditions:
//has ammo
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);
//has ReservedActionPoints (the shot is ready and waiting for a trigger event)
	ReserveActionPointCost = new class'X2AbilityCost_ReserveActionPoints';
	ReserveActionPointCost.iNumPoints = 1;
	ReserveActionPointCost.AllowedTypes.AddItem(class'X2Effect_ReserveTakedownActionPoints'.default.TakedownActionPoint);
	Template.AbilityCosts.AddItem(ReserveActionPointCost);
//target is visible
	TargetVisibilityCondition = new class'X2Condition_Visibility';
	TargetVisibilityCondition.bRequireBasicVisibility = true; //LOS + in range
	TargetVisibilityCondition.bRequireGameplayVisible = true; //LOS + in range + meets situational conditions in interface method UpdateGameplayVisibility
	TargetVisibilityCondition.bAllowSquadsight = true;        //LOS + any squadmate can see the target, if unit has Squadsight (overrides bRequireGameplayVisible)
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);

	return Template;	
}


//------------------------------------------------------------------
//****************************PISTOLS*******************************
//------------------------------------------------------------------

static function X2AbilityTemplate
AddTakedownShotPistolAbility()
{
	//used variables
	local X2AbilityTemplate						Template;
	local X2AbilityCost_ReserveActionPoints		ReserveActionPointCost;
	local X2Condition_Visibility				TargetVisibilityCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'TakedownShotPistol');
	//set up common properties
	CreateTakedownShotCommonProperties(Template);

	ReserveActionPointCost = new class'X2AbilityCost_ReserveActionPoints';
	ReserveActionPointCost.iNumPoints = 1;
	ReserveActionPointCost.AllowedTypes.AddItem(class'X2Effect_ReserveTakedownActionPoints'.default.TakedownPistolActionPoint);
	Template.AbilityCosts.AddItem(ReserveActionPointCost);

	TargetVisibilityCondition = new class'X2Condition_Visibility';
	TargetVisibilityCondition.bRequireBasicVisibility = true; //LOS + in range
	TargetVisibilityCondition.bRequireGameplayVisible = true; //LOS + in range + meets situational conditions in interface method UpdateGameplayVisibility
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);

	return Template;
}


//------------------------------------------------------------------
//****************************SNIPERS*******************************
//------------------------------------------------------------------

//------------------------------------------------------------------
//*************************VISUALIZATION****************************
//------------------------------------------------------------------
function
MarkForTakedown_BuildVisualization(XComGameState					VisualizeGameState,
									out array<VisualizationTrack>	OutVisualizationTracks)
{
	local XComGameStateContext_Ability		AbilityContext;
	local StateObjectReference				InteractingUnitRef;
	local XComGameStateHistory				History;
	local X2Action_PlaySoundAndFlyOver		SoundAndFlyOver;
	local VisualizationTrack				BuildTrack;
	local string							FlyOverText, FlyOverImage;
	local name								CharSpeechName;

	History = `XCOMHISTORY;

	FlyOverText = "Ready for Takedown";		//TODO: move this to Localization
	CharSpeechName = '';					//Name of the speech the character should bark on activation
	FlyOverImage = "";						//Mark for Takedown icon path here

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = AbilityContext.InputContext.SourceObject;

	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID( InteractingUnitRef.ObjectID,
																		eReturnType_Reference,
																		VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(
							class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(none, FlyOverText, CharSpeechName, eColor_Good, FlyOverImage);

	OutVisualizationTracks.AddItem(BuildTrack);
}

function
TakedownShot_BuildVisualization(XComGameState					VisualizeGameState,
								out array<VisualizationTrack>	OutVisualizationTracks)
{
	switch(default.eVisualizationType){
		case eSequential:
			`CTUDEB("Using 'eSequential' visualization");
			TypicalAbility_BuildVisualization(VisualizeGameState, OutVisualizationTracks);
			break;
		case eSemiSequential:
			`CTUDEB("Using 'eSemiSequential' visualization");
			TakedownShot_BuildVisualization_SemiSequential(VisualizeGameState, OutVisualizationTracks);
			break;
		case eParallel:
			`CTUDEB("Using 'eParallel' visualization");
			TakedownShot_BuildVisualization_Parallel(VisualizeGameState, OutVisualizationTracks);
			break;
		default:
			`CTUERR("Could not identify 'eVisualizationType' setting! Using fallback Visualization instead!");
			//use standard shot visuals (sequential)
			TypicalAbility_BuildVisualization(VisualizeGameState, OutVisualizationTracks);
			break;
	}
}

function
TakedownShot_BuildVisualization_DisplayFlyOver(XComGameState					VisualizeGameState,
												out array<VisualizationTrack>	OutVisualizationTracks)
{
	local XComGameStateContext_Ability		AbilityContext;
	local StateObjectReference				InteractingUnitRef;
	local XComGameStateHistory				History;

	local X2Action_PlaySoundAndFlyOver		SoundAndFlyOver;
	local VisualizationTrack				BuildTrack;
	local string							FlyOverText, FlyOverImage;
	local name								CharSpeechName;

	`CTUDEB("Visualization: building FlyOver text visualization");

//init local variables
	History = `XCOMHISTORY;

	FlyOverText = "Coordinated Takedown";	//TODO: move this to Localization
	CharSpeechName = '';					//Name of the speech the character should bark on activation
	FlyOverImage = "";						//Mark for Takedown icon path here

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = AbilityContext.InputContext.SourceObject;



	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID( InteractingUnitRef.ObjectID,
																		eReturnType_Reference,
																		VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);


//show flyover, play silently
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(
							class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(none, FlyOverText, CharSpeechName, eColor_Good, FlyOverImage);
	OutVisualizationTracks.AddItem(BuildTrack);
}

function
TakedownShot_BuildVisualization_SemiSequential(XComGameState					VisualizeGameState,
												out array<VisualizationTrack>	OutVisualizationTracks)
{


	local XComGameStateHistory					History;
	local XComGameStateVisualizationMgr			VisMgr;
	local X2AbilityTemplateManager				AbilityTemplateMgr;

	local XComGameStateContext_Ability			AbilityContext;
	local X2AbilityTemplate						AbilityTemplate;

	local Actor									ShooterVisualizer;
	local VisualizationTrackModInfo				CurrentInfo;
	local array<VisualizationTrackModInfo>		VisTrackModInfoArray;	//metainfo about visualization blocks we need
																		//	(read: info about any VisBlock where the TrackActor is doing a TakedownShot)
	local int									idx;
	local int									idx_action;
	local array<VisualizationTrack>				PendingTakedownVisTracks;
	local X2Action_EnterCover					EnterCoverAction;

	History 			= `XCOMHISTORY;
	VisMgr				= `XCOMVISUALIZATIONMGR;
	AbilityTemplateMgr	= class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	AbilityContext		= XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityTemplate		= AbilityTemplateMgr.FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
	ShooterVisualizer	= History.GetVisualizer(AbilityContext.InputContext.SourceObject.ObjectID);

	//-------------------------------------------------------
	//set up the TrackInfo start index to: right after any previous TakedownShot's shoot animation

	if(AbilityContext == none){
		`CTUERR("Visualization: Could not acquire 'AbilityContext' reference. Aborting");
		return;
	}

	if(AbilityTemplate == none){
		`CTUERR("Visualization: Could not acquire 'AbilityTemplate' reference. Aborting");
		return;
	}

	if(ShooterVisualizer == none){
		`CTUERR("Visualization: Could not acquire 'ShooterVisualizer' reference. Aborting");
		return;
	}

	`CTUDEB("Visualization: AbilityTemplate name: " $ AbilityTemplate.DataName);


	//fill VisTrackModInfoArray
	VisMgr.GetVisModInfoForTrackActor(AbilityTemplate.DataName,
									  ShooterVisualizer,
									  VisTrackModInfoArray);

	if(VisTrackModInfoArray.Length <= 0){
		`CTUDEB("Visualization: could not find VisTrackModInfo instances!");
	}else{
	//if(0 < VisTrackModInfoArray.Length){
		//find the latest valid instance
		`CTUDEB("Visualization: found VisTrackModInfo instances ("$ VisTrackModInfoArray.Length $")");
		for(idx = VisTrackModInfoArray.Length-1; idx >= 0; --idx){
			CurrentInfo = VisTrackModInfoArray[idx];
			`CTUDEB("Visualization: checking VisTrackModInfoArray["$idx$"]");
			`CTUDEB("Visualization:   AbilityContext: "$ "???");
			`CTUDEB("Visualization:   BlockIndex: "$ CurrentInfo.BlockIndex);
			`CTUDEB("Visualization:   TrackIndex: "$ CurrentInfo.TrackIndex);
			//Modify the VisualizationBlock so that we don't wait for the previous shooter to re-enter cover
			VisMgr.GetTrackActions(CurrentInfo.BlockIndex, PendingTakedownVisTracks);
			`CTUDEB("Visualization: found " $ PendingTakedownVisTracks.Length $ " Pending Takedown VisTracks");
			for(idx_action = PendingTakedownVisTracks[CurrentInfo.TrackIndex].TrackActions.Length-1;
				idx_action >= 0;
				--idx_action)
			{
				`CTUDEB("Visualization: checking PendingTakedownVisTracks["$CurrentInfo.TrackIndex$"].TrackActions["$idx_action$"]");
				//find an EnterCover action from the back
				EnterCoverAction = X2Action_EnterCover(PendingTakedownVisTracks[CurrentInfo.TrackIndex].TrackActions[idx_action]);
				if(EnterCoverAction != none){
					`CTUDEB("Visualization: found EnterCover action");
					//set the new shot to play during the previous shot's EnterCover animation
					AbilityContext.SetVisualizationStartIndex(EnterCoverAction.CurrentHistoryIndex);

					//TODO: remove this
					//Remove the EnterCover action. The last OverwatchShot will return the soldier to cover.
					VisMgr.RemovePendingTrackAction(CurrentInfo.BlockIndex, CurrentInfo.TrackIndex, idx_action);
					break;
				}
			}
		}
	}
	//-------------------------------------------------------
	//build the flyover text
	TakedownShot_BuildVisualization_DisplayFlyOver(VisualizeGameState, OutVisualizationTracks);
	//-------------------------------------------------------
	//build the rest of the shooting animation
	TypicalAbility_BuildVisualization(VisualizeGameState, OutVisualizationTracks);
}

function
TakedownShot_BuildVisualization_Parallel(XComGameState					VisualizeGameState,
										out array<VisualizationTrack>	OutVisualizationTracks)
{
	TypicalAbility_BuildVisualization(VisualizeGameState, OutVisualizationTracks);	//placeholder build fn
}

//--------------------------------------------------

function
OverwatchShot_BuildVisualization(XComGameState VisualizeGameState,
								out array<VisualizationTrack> OutVisualizationTracks)
{
	local X2AbilityTemplate					AbilityTemplate;
	local Actor								ShooterVisualizer;
	local XComGameStateContext_Ability		Context;
	local XComGameStateVisualizationMgr		VisManager;
	local array<VisualizationTrackModInfo>	InfoArray;
	local VisualizationTrackModInfo			CurrentInfo;
	local XComGameState_Unit				TargetUnitState;
	local XComGameState_AIGroup				AIGroup;
	local X2Action_EnterCover				EnterCoverAction;
	local int								InfoIndex, ActionIndex;
	local bool								bModifiedTrack;
	local array<VisualizationTrack>			LocalVisualizationTracks;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);
	ShooterVisualizer = `XCOMHISTORY.GetVisualizer(Context.InputContext.SourceObject.ObjectID);

	VisManager = `XCOMVISUALIZATIONMGR;

	//Find pending visualization blocks where the TrackActor is performing OverwatchShot
	VisManager.GetVisModInfoForTrackActor(AbilityTemplate.DataName, ShooterVisualizer, InfoArray);
	if (InfoArray.Length > 0)
	{
		//Iterate backwards to find the latest instance
		for (InfoIndex = InfoArray.Length - 1; InfoIndex >= 0 && !bModifiedTrack; --InfoIndex)
		{
			CurrentInfo = InfoArray[InfoIndex];
			TargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(CurrentInfo.Context.InputContext.PrimaryTarget.ObjectID));
			AIGroup = TargetUnitState.GetGroupMembership();
			//Modify the exiting visualization block if the TrackActor is firing at an enemy in the same UI group as the current target.
			if (AIGroup.m_arrMembers.Find('ObjectID', Context.InputContext.PrimaryTarget.ObjectID) != INDEX_NONE)
			{
				VisManager.GetTrackActions(CurrentInfo.BlockIndex, LocalVisualizationTracks);
				//Look for the EnterCover action of the previous OverwatchShot
				for (ActionIndex = LocalVisualizationTracks[CurrentInfo.TrackIndex].TrackActions.Length - 1; ActionIndex >= 0; --ActionIndex)
				{
					EnterCoverAction = X2Action_EnterCover(LocalVisualizationTracks[CurrentInfo.TrackIndex].TrackActions[ActionIndex]);
					if (EnterCoverAction != none)
					{
						//Set this new action to trigger after the previous overwatch
						Context.SetVisualizationStartIndex(EnterCoverAction.CurrentHistoryIndex);
						//Remove the EnterCover action. The last OverwatchShot will return the soldier to cover.
						VisManager.RemovePendingTrackAction(CurrentInfo.BlockIndex, CurrentInfo.TrackIndex, ActionIndex);
						bModifiedTrack = true;
						break;
					}
				}
			}
		}
	}
	//Continue building the OverwatchShot visualization as normal.
	TypicalAbility_BuildVisualization(VisualizeGameState, OutVisualizationTracks);
}


static simulated function
OverwatchAbility_BuildVisualization(XComGameState VisualizeGameState,
									out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory			History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference          InteractingUnitRef;

	local VisualizationTrack        EmptyTrack;
	local VisualizationTrack        BuildTrack;

	local X2Action_CameraFrameAbility FrameAction;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local UnitValue EverVigilantValue;
	local XComGameState_Unit UnitState;
	local X2AbilityTemplate AbilityTemplate;
	local string FlyOverText, FlyOverImage;
	local XGUnit UnitVisualizer;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter
	//****************************************************************************************
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	UnitState = XComGameState_Unit(BuildTrack.StateObject_NewState);

	// Only turn the camera on the overwatcher if it is visible to the local player.
	if( !`XENGINE.IsMultiPlayerGame() || class'X2TacticalVisibilityHelpers'.static.IsUnitVisibleToLocalPlayer(UnitState.ObjectID, VisualizeGameState.HistoryIndex) )
	{
		FrameAction = X2Action_CameraFrameAbility(class'X2Action_CameraFrameAbility'.static.AddToVisualizationTrack(BuildTrack, Context));
		FrameAction.AbilityToFrame = Context;
	}
					
	if (UnitState != none && UnitState.GetUnitValue(class'X2Ability_SpecialistAbilitySet'.default.EverVigilantEffectName, EverVigilantValue) && EverVigilantValue.fValue > 0)
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate('EverVigilant');
		if (UnitState.HasSoldierAbility('CoveringFire'))
			FlyOverText = class'XLocalizedData'.default.EverVigilantWithCoveringFire;
		else
			FlyOverText = AbilityTemplate.LocFlyOverText;
		FlyOverImage = AbilityTemplate.IconImage;
	}
	else if (UnitState != none && UnitState.HasSoldierAbility('CoveringFire'))
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate('CoveringFire');
		FlyOverText = AbilityTemplate.LocFlyOverText;
		FlyOverImage = AbilityTemplate.IconImage;
	}
	else
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);
		FlyOverText = AbilityTemplate.LocFlyOverText;
		FlyOverImage = AbilityTemplate.IconImage;
	}
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, Context));

	if (UnitState != none)
	{
		UnitVisualizer = XGUnit(UnitState.GetVisualizer());
		if( (UnitVisualizer != none) && !UnitVisualizer.IsMine())
		{
			SoundAndFlyOver.SetSoundAndFlyOverParameters(SoundCue'SoundUI.OverwatchCue', FlyOverText, 'Overwatch', eColor_Bad, FlyOverImage);
		}
		else
		{
			SoundAndFlyOver.SetSoundAndFlyOverParameters(none, FlyOverText, 'Overwatch', eColor_Good, FlyOverImage);
		}
	}
	OutVisualizationTracks.AddItem(BuildTrack);
	//****************************************************************************************
}

DefaultProperties
{
	//bRemoveConcealmentRequirement = false;

	Begin Object Class=X2AbilityToHitCalc_MarkForTakedown Name=DefaultMarkForTakedownToHitCalc
	End Object
	MarkForTakedownToHitCalc = DefaultMarkForTakedownToHitCalc;
}