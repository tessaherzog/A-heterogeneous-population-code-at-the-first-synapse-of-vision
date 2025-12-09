#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Window TrainStimAnal() : Panel 
	PauseUpdate; Silent 1 // building GUI
	NewPanel/k=1 /W=(600,100,800,300) as "Train stimulus analysis"
	ModifyPanel cbRGB=(65535,49151,55704)
	SetDrawLayer UserBack
	Button button1,pos={12,10},size={175,20},proc=Button_deconwave,title="Deconvolve trace?"
	Button button1,fSize=14,fStyle=1,fColor=(32768,32770,65535)
	
	Button button2,pos={12,40},size={175,20},proc=Button_NameofRec,title="Trace to analyse"
	Button button2,fSize=14,fStyle=1,fColor=(32768,32770,65535)
	Button button3,pos={12,70},size={175,20},proc=Button_OffStep,title="OffStep Dur?"
	Button button3,fSize=14,fStyle=1,fColor=(32768,32770,65535)
	Button button4,pos={12,100},size={175,20},proc=Button_DisplayHeatMap,title="Pick first resp to use"
	Button button4,fSize=14,fStyle=1,fColor=(32768,32770,65535)
	Button button5,pos={12,130},size={175,20},proc=Button_DefineFirstIt,title="Enter first stim to use"
	Button button5,fSize=14,fStyle=1,fColor=(32768,32770,65535)
	Button button6,pos={12,160},size={175,20},proc=Button_Analyse,title="Analyse"
	Button button6,fSize=14,fStyle=1,fColor=(32768,32770,65535)
endmacro

end

Function Button_deconwave(ba) : buttonControl
	Struct WMButtonAction &ba
	switch(ba.eventCode)
		case 2: 
			string list=wavelist("*",";","DIMS:2")
			string movieName
			prompt movieName, "Trace to deconvolve", popup,list
			doprompt "Pick your trace", movieName
			wave TraceName = $movieName
			DeconvolveT2(TraceName,0,0.06)
			
			print "Deconvolved trace " + moviename
			if(V_flag==1)
					Abort
			endif
			break
		case -1:
			break
		endswitch
		return 0
end

Function Button_NameofRec(ba) : buttonControl
	Struct WMButtonAction &ba
	switch(ba.eventCode)
		case 2: 
			string list=wavelist("*",";","DIMS:2")
			string movieName
			prompt movieName, "Trace to analyse", popup,list
			doprompt "Pick your trace", MovieName
			print "Trace to be analysed = " + moviename
			if(V_flag==1)
					Abort
			endif
			break
		case -1:
			break
		endswitch
		return 0
end

Function Button_OffStep(ba) : buttonControl
	Struct WMButtonAction &ba
	switch(ba.eventCode)
		case 2:
			Variable offStepDur // offstep duration in ms
			offStepDur = 40
			prompt offStepDur, "Enter off-step duration (ms)"
			doprompt "Off-step duration", offStepDur
			if(V_flag==1)
					Abort
			endif
			case -1: // control being killed
			
			variable/G offStep = offStepDur
			make/o/n=(1) OffStepDuration
			OffStepDuration = offstep
			break
		endswitch
		return 0
end

Function Button_DisplayHeatMap(ba) : buttonControl
	Struct WMButtonAction &ba
	switch(ba.eventCode)
		case 2: 
			wave OffStepDuration
			variable offstep = OffStepDuration[0]
			DisplayHeatMap(offStep)
			DrawText 0.331818181818182,0.130841121495327,"Place cursor on first response to use"
			break
		case -1:
			break
		endswitch
		return 0
end

Function Button_DefineFirstIt(ba) : buttonControl
	Struct WMButtonAction &ba
	switch(ba.eventCode)
		case 2:
			DoWindow/F Responses // bring heatmap window to the front
			
			if (V_Flag == 0) // if heatmap not loaded, give error message
				Abort "Graph does not exist, click Disp Response heatmap button again"
				return -1
			endif
			
			DrawText 0.331818181818182,0.130841121495327,"Place cursor on first response to use"
			variable x= vcsr(a,"Responses")
			Prompt x, "Enter first stim to use: "
			DoPrompt "Enter first stim to use", x
			if (v_flag)
				return -1
			endif
			Print "First stim to use = ", x
			variable/G FirstStimToUse = x
			make/o/n=(1) FirstStimItToUse
			FirstStimItToUse = x
			
//			NewPanel /N=UserPlaceCursor /K=1 /W=(187,368,437,531) as "Place cursor"
//			AutoPositionWindow/E/M=1/R=Responses // Put panel near the heatmap
//			DrawText 21,20,"Place cursor (A) on the first response"
//			DrawText 21,40,"to use and then click on continue"
//			Button buttonCont,pos={80,65},size={92,20},proc=TestTest,title="Continue"
//
//			
			
//			variable x=FirstStimToUse = vcsr(a,"Responses")
//			Prompt x, "Enter first stim to use: " // set first stim to use
//			DoPrompt "Enter first stim to use", x
//			if (v_flag)
//				return -1
//			endif
//			Print "First stim to use = ", x
//			variable/G FirstStimToUse = x
//			make/o/n=(1) FirstStimItToUse
//			FirstStimItToUse = x

		
			break
		case -1:
			break
		endswitch
		return 0
end

Function Button_Analyse(ba) : buttonControl
	Struct WMButtonAction &ba
	switch(ba.eventCode)
		case 2:
		wave OffStepDuration
		variable offstep = OffStepDuration[0]
		//variable firstStimToUse
		wave FirstStimItToUse
		variable FirstStim = FirstStimItToUse[0]
			TrainStim_MakeRespMatrices(offstep, FirstStim) // create matrices of response snippets
			PullPeakAmps_Train(FirstStim)
			Trainstim_TemporalJitter()
					break
				case -1:
					break
				endswitch
				return 0
end




