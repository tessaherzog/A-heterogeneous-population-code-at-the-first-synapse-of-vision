#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// display heat maps of resp
//Snips to find which first stim to use

Function InputOffstepDur()
variable x=20
Prompt x, "Enter off-step duration (ms): " // set first stim to use
DoPrompt "Off-step duration?", x
if (v_flag)
	return -1
endif

Print "Off-step duration = ", x
variable/G OffStep = x

END

Function DisplayHeatMap(offstep)
variable offstep
TrainStim_MakeRespMatrices(offstep, 0) // create matrices of response snippets

wave RespSnips
Display/k=1/n=Responses // display heat map of RespSnips
AppendImage RespSnips
SetAxis left 98.5,0.5
ModifyImage RespSnips ctab= {*,*,Rainbow,0};delayupdate
ShowInfo
end

Function DefineFirstIt()

variable x=20
Prompt x, "Enter first stim to use: " // set first stim to use
DoPrompt "Enter first stim to use", x
if (v_flag)
	return -1
endif

Print "First stim to use = ", x

variable/G FirstStimToUse = x
//make/o/n=(1) FirstStim = x

end
