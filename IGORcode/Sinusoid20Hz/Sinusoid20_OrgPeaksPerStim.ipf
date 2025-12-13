#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function RespRise_OrgPerStim(DiffTrace_Peak_xLoc_stim) // use DiffTrace_Peak_xLoc_stim
wave DiffTrace_Peak_xLoc_stim
wave DiffTrace_Peak_Amp_Stim

variable StimHz = 20 // frequency of stimulus in hz
variable PhaseDur = 1/StimHz // duration of one phase of the stimulus in ms
wave StimStartTimes
variable nStimIts = dimsize(StimStartTimes,0)

duplicate/o StimStartTimes, StimPeakTimes
duplicate/o StimStartTimes, StimHalfTimes
duplicate/o StimStartTimes, StimBaseTimes
StimPeakTimes/=1000
StimHalfTimes/=1000
StimBaseTimes/=1000
StimPeakTimes+=PhaseDur*0.25
StimHalfTimes+=PhaseDur*0.5
StimBaseTimes+=PhaseDur*0.75

variable PeakWin = 20 // in ms, window for detection of response peak after stim. 

make/o/n=(nStimIts) DiffTrace_Peak_xLoc_Perstim // make matrix to put PeakTime values (1 per stim iteration)
make/o/n=(nStimIts) DiffTrace_Peak_Amp_PerStim
// diregarding final stimulus phase as the glutamate response occurs during "grey light" and therefore under a different condition 
DiffTrace_Peak_xLoc_Perstim=NaN
variable i,j
for (j=0;j<nStimIts;j+=1) // for each stimulus phase
	for (i=0;i<dimsize(DiffTrace_Peak_xLoc_stim,0);i+=1) // in the list of detected peak times, check if it falls into the stim window
		if (numtype(DiffTrace_Peak_xLoc_Perstim[j]) == 2) // if space for stim window is empty i.e. is a NaN
			if (DiffTrace_Peak_xLoc_stim[i]>StimHalfTimes[j] && DiffTrace_Peak_xLoc_stim[i]<StimHalfTimes[j+1]) // only use first peak in response window, do not enter more values if space already filled
				DiffTrace_Peak_xLoc_Perstim[j]=DiffTrace_Peak_xLoc_stim[i] // put in peak timing for each stimulus window
				DiffTrace_Peak_Amp_PerStim[j]=DiffTrace_Peak_Amp_Stim[i] // put amp in for each stimulus window
			endif
		endif
	endfor
endfor

DeletePoints 599,1, DiffTrace_Peak_xLoc_Perstim //disregard final response phase as response occurs during "grey" light conditions
DeletePoints 599,1, DiffTrace_Peak_Amp_PerStim
end