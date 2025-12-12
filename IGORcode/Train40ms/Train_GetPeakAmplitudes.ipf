#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Train stimulus
// Pull the max response amplitude

Function PullPeakAmps_Train(FirstStimToUse)
variable FirstStimToUse
PullPeakAmpsXlocs(FirstStimToUse)
wave RespPeakAmps
NormaliseAmplitudes()
DisplayRespAmps_violin()
PlotSnippets()
end

//////////////////////////////////////////////////////
// Pull amplitude of peak for each response snippet into RespPeakAmps matrix
// Pull xLoc of peak into RespPeakxLocs matrix

Function PullPeakAmpsXlocs(FirstStimToUse)
variable FirstStimToUse
wave RespSnips, RespSnips_Decon

variable nStimReps = dimsize(RespSnips,1)
variable j

variable transientstart = 70
variable transientend = 120

make/o/n=(nStimReps) RespPeak_Amps // put peak amplitude and time of peak into waves
make/o/n=(nStimReps) RespPeak_xLocs
for (j=0;j<nStimReps;j+=1)
	duplicate/o/r=[transientstart,transientend][j] RespSnips, tempTrans
	Redimension/N=-1 temptrans
	SetScale/P y 0,1,"", tempTrans;DelayUpdate
	SetScale/P z 0,1,"", tempTrans
	wavestats/q tempTrans
	RespPeak_Amps[j] = v_max
	RespPeak_xLocs[j] = V_maxloc
	killwaves tempTrans
endfor
RespPeak_xLocs*=1000
RespPeak_xlocs[,FirstStimToUse] = NaN

make/o/n=(nStimReps) RespPeak_Amps_Decon // put peak amplitude and time of peak into waves
make/o/n=(nStimReps) RespPeak_xLocs_Decon
for (j=0;j<nStimReps;j+=1)
	duplicate/o/r=[transientstart,transientend][j] RespSnips_Decon, tempTrans
	Redimension/N=-1 temptrans
	SetScale/P y 0,1,"", tempTrans;DelayUpdate
	SetScale/P z 0,1,"", tempTrans
	wavestats/q tempTrans
	RespPeak_Amps_Decon[j] = v_max
	RespPeak_xLocs_Decon[j] = V_maxloc
	killwaves tempTrans
endfor
RespPeak_xLocs_Decon*=1000
RespPeak_xlocs_Decon[,FirstStimToUse] = NaN

// get summary stats on amplitude
make/o/n=(1) RespPeak_Amps_Mean, RespPeak_Amps_SD, RespPeak_Amps_Var
wavestats/q RespPeak_Amps
RespPeak_Amps_Mean = v_avg
RespPeak_Amps_SD = v_sdev
RespPeak_Amps_Var = v_sdev^2

make/o/n=(1) RespPeak_Amps_Mean_Decon, RespPeak_Amps_SD_Decon, RespPeak_Amps_Var_Decon
wavestats/q RespPeak_Amps_Decon
RespPeak_Amps_Mean_Decon = v_avg
RespPeak_Amps_SD_Decon = v_sdev
RespPeak_Amps_Var_Decon = v_sdev^2

end

//////////////////////////////////////////////////////
// Calculate the mean for the nomalised peak amplitude data

Function NormaliseAmplitudes() // scale them down so max amp is 1, 

wave RespPeak_Amps
duplicate/o RespPeak_Amps, RespPeak_Amps_Nrm
RespPeak_Amps_Nrm/=wavemax(RespPeak_Amps)

make/o/n=(1) RespPeak_Amps_Mean_Nrm, RespPeak_Amps_SD_Nrm, RespPeak_Amps_Var_Nrm
wavestats/q RespPeak_Amps_Nrm
RespPeak_Amps_Mean_Nrm = v_avg
RespPeak_Amps_SD_Nrm = v_sdev
RespPeak_Amps_Var_Nrm = v_sdev^2

wave RespPeak_Amps_Decon
duplicate/o RespPeak_Amps_Decon, RespPeak_Amps_Nrm_Decon
RespPeak_Amps_Nrm_Decon/=wavemax(RespPeak_Amps_Decon)

make/o/n=(1) RespPeak_Amps_Mean_Nrm_Decon, RespPeak_Amps_SD_Nrm_Decon, RespPeak_Amps_Var_Nrm_Decon
wavestats/q RespPeak_Amps_Nrm_Decon
RespPeak_Amps_Mean_Nrm_Decon = v_avg
RespPeak_Amps_SD_Nrm_Decon = v_sdev
RespPeak_Amps_Var_Nrm_Decon = v_sdev^2

end

//////////////////////////////////////////////////////
// Plot response amplitude as a function of off step duration

Function DisplayRespAmps_violin()
wave RespPeak_Amps, RespPeak_Amps_Decon

Display/k=1;AppendViolinPlot RespPeak_Amps
ModifyGraph lblMargin(left)=5;DelayUpdate
Label left "Peak response amplitude (DF/F)";DelayUpdate
SetAxis/A/N=1 left
ModifyViolinPlot trace=RespPeak_Amps,ShowMean,MeanMarker=19
SetAxis left 0,*

Display/k=1;AppendViolinPlot RespPeak_Amps_Decon
ModifyGraph lblMargin(left)=5;DelayUpdate
Label left "Peak response amplitude (F’ s-1)";DelayUpdate
SetAxis/A/N=1 left
ModifyViolinPlot trace=RespPeak_Amps_Decon,ShowMean,MeanMarker=19
SetAxis left 0,*

end

//////////////////////////////////////////////////////
// Plot overlay of response snippets plus peaks detected

Function PlotSnippets()
wave RespSnips_Decon

variable nResps = dimsize(RespSnips_Decon,1)
variable i

display/k=1 RespSnips_Decon[][0]
for (i=1;i<nResps-1;i+=1)
	appendtograph RespSnips_Decon[][i]
endfor
ModifyGraph rgb=(0,0,0,32767)

wave RespPeak_xLocs_Decon, RespPeak_Amps_Decon
duplicate/o RespPeak_xLocs_Decon, RespPeakxLocPnts
RespPeakxLocPnts/=1000
appendtograph RespPeak_Amps_Decon vs RespPeakxLocPnts
ModifyGraph mode(RespPeak_Amps_Decon)=2,lsize(RespPeak_Amps_Decon)=3
END
