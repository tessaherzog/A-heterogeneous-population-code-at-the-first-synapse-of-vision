#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function DetectTruePeak(w) // pull peaks in window after detected rise in PeakRise_xloc_PerStim
wave w

variable peakdetecwin = 20 // ms after detected rise for peak detection

wave PeakRise_xLocPnt_PerStim
variable nStimIts = dimsize(PeakRise_xLocPnt_PerStim,0)
make/o/n=(nStimIts) Peak_Amp_PerStim
make/o/n=(nStimIts) Peak_xLoc_PerStim
variable i

for (i=0;i<nStimIts;i+=1)
	if (numtype(PeakRise_xLocPnt_PerStim[i]) == 2) // if no response detected in that stim it, skip
		Peak_Amp_PerStim[i] = NaN
		Peak_xLoc_PerStim[i] = NaN
	endif
	if (numtype(PeakRise_xLocPnt_PerStim[i]) == 0)
		duplicate/o/r=[PeakRise_xLocPnt_PerStim[i],PeakRise_xLocPnt_PerStim[i]+peakDetecwin] w, tempsnip
		wavestats/q tempsnip
		Peak_Amp_PerStim[i] = v_max
		Peak_xLoc_PerStim[i] = v_maxloc
	endif
endfor

killwaves tempsnip

//// Calculate mean response amplitude
//make/o/n=(1) Peak_Amp_Mean
//make/o/n=(1) Peak_Amp_SD
//wavestats/q Peak_Amp
//Peak_Amp_Mean = v_avg
//Peak_Amp_SD = v_sdev
//
//// convert to time to peak
//wave StimBaseTimes
//duplicate/o Peak_xLoc, Peak_TimeToPeak
//Peak_TimeToPeak-=StimBaseTimes
//Peak_TimeToPeak*=1000
//
//// calculate temporal jitter as SD of time to peak
//make/o/n=(1) Peak_TimeToPeak_Mean
//make/o/n=(1) Peak_TimeToPeak_SD
//wavestats/q Peak_TimeToPeak
//Peak_TimeToPeak_Mean=v_avg
//Peak_TimeToPeak_SD=v_sdev

END