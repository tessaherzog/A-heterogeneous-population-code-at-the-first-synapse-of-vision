#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Window MixedOffStepAnal() : Panel 
	PauseUpdate; Silent 1 // building GUI
	NewPanel/k=1 /W=(610,80,1000,250) as "Mixed off-step analysis"
	ModifyPanel cbRGB=(65535,49151,55704)
	SetDrawLayer UserBack
	Button button0,pos={130,10},size={127,20},proc=Button_Deconvolve,title="Deconvolve trace"
	Button button0,fSize=14,fStyle=1,fColor=(32768,32770,65535)
	Button button1,pos={12,40},size={175,20},proc=Button_PickNameofRec,title="Trace to analyse"
	Button button1,fSize=14,fStyle=1,fColor=(32768,32770,65535)
	Button button2,pos={200,40},size={175,20},proc=Button_PickFirstStim,title="Pick first resp. to use"
	Button button2,fSize=14,fStyle=1,fColor=(32768,32770,65535)
	Button button3,pos={12,70},size={175,20},proc=Button_DetectResponses,title="Detect responses"
	Button button3,fSize=14,fStyle=1,fColor=(32768,32770,65535)
	Button button4,pos={200,70},size={175,20},proc=Button_ThresholdResps,title="Threshold responses"
	Button button4,fSize=14,fStyle=1,fColor=(32768,32770,65535)
	Button button5,pos={12,100},size={175,20},proc=Button_CalcMeanAmps,title="Calc ave resp amp."
	Button button5,fSize=14,fStyle=1,fColor=(32768,32770,65535)
	Button button6,pos={200,100},size={175,20},proc=Button_PlotMeanAmps,title="Plot mean amp"
	Button button6,fSize=14,fStyle=1,fColor=(32768,32770,65535)
	Button button7,pos={12,130},size={175,20},proc=Button_CalcTemporalJitter,title="Calc temporal jitter"
	Button button7,fSize=14,fStyle=1,fColor=(32768,32770,65535)
	Button button8,pos={200,130},size={175,20},proc=Button_PlotTemporalJitter,title="Plot temporal jitter"
	Button button8,fSize=14,fStyle=1,fColor=(32768,32770,65535)

endmacro

end

Function Button_Deconvolve(ba) : buttonControl
	Struct WMButtonAction &ba
	switch(ba.eventCode)
		case 2: 
			string list=wavelist("*",";","DIMS:2")
			string movieName
			prompt movieName, "Trace to analyse", popup,list
			doprompt "Pick your trace", MovieName
			print "selected: " + moviename
			if(V_flag==1)
					Abort
			endif
			DeconvolveT2($moviename, 0, 0.06)
//			duplicate/o $moviename, trace
			break
		case -1:
			break
		endswitch
		return 0
end

Function Button_PickNameofRec(ba) : buttonControl
	Struct WMButtonAction &ba
	switch(ba.eventCode)
		case 2: 
			string list=wavelist("*",";","DIMS:2")
			string movieName
			prompt movieName, "Trace to analyse", popup,list
			doprompt "Pick your trace", MovieName
			print "selected: " + moviename
			if(V_flag==1)
					Abort
			endif
			duplicate/o $moviename, SelecTrace
			break
		case -1:
			break
		endswitch
		return 0
end

Function Button_PickFirstStim(ba) : buttonControl // cursor placement to select first response to use
	Struct WMButtonAction &ba
	switch(ba.eventCode)
		case 2:
			wave SelecTrace, Stim_5to100
			display/k=1/N=TraceAndStim SelecTrace // display SelecTrace and stimulus
			SetAxis/A/N=1 left;DelayUpdate
			ModifyGraph lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
			Label left "F'S\\S-1";DelayUpdate
			Label bottom "Time (s)"
			modifygraph rgb=(0,0,0)
			appendtograph Stim_5to100
			ModifyGraph offset(Stim_5to100)={0,-1.5}
			DrawText 0.0831265508684863,0.0824742268041237,"Place cursor at first response to use"
			ShowInfo
//			break
//		case -1:
//			break
//		endswitch
//		return 0
			
			// cursor input from user to pick first response to use
			variable autoAbortSecs = 0
			if (UserCursorAdjust("TraceAndStim",autoAbortSecs)!=0)
				return -1
			endif
			variable firstTimePoint
   			firstTimePoint = pcsr(A)
   			firstTimePoint/=1000 // convert from points to seconds
   			print "analyse responses from " + num2str(firstTimePoint) + " s onwards"
			make/o/n=(1) FirstTmPnt = firstTimePoint
			killwindow TraceAndStim
			break
		endswitch
		return 0
end

Function Button_DetectResponses(ba) : buttonControl
	Struct WMButtonAction &ba
	switch(ba.eventCode)
		case 2: 
			wave order, FirstTmPnt
			MakeRespMatrices_mixedOffStep_v2(order, "SelecTrace", FirstTmPnt[0])
			break
		case -1:
			break
		endswitch
		return 0
end

Function Button_ThresholdResps(ba) : buttonControl
	Struct WMButtonAction &ba
	switch(ba.eventCode)
		case 2:
			wave RespSnips
			PullPeakAmpsXlocs(RespSnips)
			wave SelecTrace
			Thresholding(SelecTrace)
			CheckOutlierResps()
			PercMissedRespsPerCond()
		case -1:
			break
		endswitch
		return 0
end

Function Button_CalcMeanAmps(ba) : buttonControl
	Struct WMButtonAction &ba
	switch(ba.eventCode)
		case 2:
			wave RespPeakAmps_Ex_Thresh
			CalcMeanPeakAmp(RespPeakAmps_Ex_Thresh)
			print "Calculated mean response amplitudes"
			break
		case -1:
			break
		endswitch
		return 0
end

Function Button_PlotMeanAmps(ba) : buttonControl
	Struct WMButtonAction &ba
	switch(ba.eventCode)
		case 2:
			wave RespPeakAmps_Ex_Thresh_Mean, RespPeakAmps_Ex_Thresh_SD, RespPeakAmps_Ex_Thresh_Var
			DisplayRespAmpMean(RespPeakAmps_Ex_Thresh_Mean, RespPeakAmps_Ex_Thresh_SD)
			PlotVarVsMean(RespPeakAmps_Ex_Thresh_Mean, RespPeakAmps_Ex_Thresh_Var)
			break
		case -1:
			break
		endswitch
		return 0
end

Function Button_CalcTemporalJitter(ba) : buttonControl
	Struct WMButtonAction &ba
	switch(ba.eventCode)
		case 2:
			wave RespPeakxLocs_Ex_Thresh
			PullHalfPeakXloc(RespPeakxLocs_Ex_Thresh)
			wave HalfPeakXlocs
			CalcTempJitter(HalfPeakXlocs)
			break
		case -1:
			break
		endswitch
		return 0
end

Function Button_PlotTemporalJitter(ba) : buttonControl
	Struct WMButtonAction &ba
	switch(ba.eventCode)
		case 2:
			DisplayTempJitter()
			break
		case -1:
			break
		endswitch
		return 0
end




