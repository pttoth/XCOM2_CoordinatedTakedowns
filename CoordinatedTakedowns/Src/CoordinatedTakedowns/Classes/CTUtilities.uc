//---------------------------------------------------------------------------------------
//  FILE:    CTUtilities.uc
//  AUTHOR:  Tapir
//  PURPOSE: Some common utility functions to make life easier
//---------------------------------------------------------------------------------------

class CTUtilities extends Object
	config(CoordinatedTakedowns);

`include (CoordinatedTakedowns/Src/CoordinatedTakedowns/Classes/CTGlobals.uci)
	
var config bool CT_ALLOW_REDSCREENS;
	
var config bool CT_DEBUG_ENABLE_PRINT;
var config bool CT_DEBUG_ENABLE_REDSCREEN;

var config bool CT_LOG_ENABLE_PRINT;
var config bool CT_LOG_ENABLE_REDSCREEN;

var config bool CT_WARNING_ENABLE_PRINT;
var config bool CT_WARNING_ENABLE_REDSCREEN;

var config bool CT_ERROR_ENABLE_PRINT;
var config bool CT_ERROR_ENABLE_REDSCREEN;

static function
Debug(string message)
{
	local string txt;
	txt = "CoordinatedTakedowns Debug:  " $ message;
	if(default.CT_DEBUG_ENABLE_PRINT){
		`Log(txt);
	}
	if(default.CT_DEBUG_ENABLE_REDSCREEN){
		PrintRS(txt);
	}
}
	
static function
Log(string message)
{
	local string txt;
	txt = "CoordinatedTakedowns Log:  " $ message;
	if(default.CT_LOG_ENABLE_PRINT){
		`Log(txt);
	}
	if(default.CT_LOG_ENABLE_REDSCREEN){
		PrintRS(txt);
	}
}

static function
Warning(string message)
{
	local string txt;
	txt = "CoordinatedTakedowns WARNING:  " $ message;
	if(default.CT_WARNING_ENABLE_PRINT){
		`Log(txt);
	}
	if(default.CT_WARNING_ENABLE_REDSCREEN){
		PrintRS(txt);
	}
}

static function
Error(string message)
{
	local string txt;
	txt = "CoordinatedTakedowns ERROR:  " $ message;
	if(default.CT_ERROR_ENABLE_PRINT){
		`Log(txt);
	}
	if(default.CT_ERROR_ENABLE_REDSCREEN){
		PrintRS(txt);
	}
}

//------//------//------//------//------//------

static function
PrintRS(string message)
{
	if(default.CT_ALLOW_REDSCREENS){
		`RedScreen(message);
	}
}
