#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
// get peakrise on snip

Function GetRiseAmp(w)
wave w
wave DiffTrace_Peak_xLoc_Perstim

duplicate/o DiffTrace_Peak_xLoc_Perstim, PeakRise_xlocpnt_PerStim // get diff. peak xloc in pnts
PeakRise_xlocpnt_PerStim*=1000


duplicate/o DiffTrace_Peak_xLoc_Perstim, PeakRise_xLoc_PerStim, PeakRise_Amp_PerStim
PeakRise_Amp_PerStim=NaN
variable nStimIts = dimsize(DiffTrace_Peak_xLoc_Perstim,0)
variable i
for (i=0;i<nStimIts;i+=1)
	if (numtype(DiffTrace_Peak_xLoc_Perstim[i]) == 0)
		PeakRise_Amp_PerStim[i] = w[PeakRise_xlocpnt_PerStim[i]]
	endif
endfor

killwaves PeakRise_xlocpnt_PerStim

duplicate/o PeakRise_xLoc_PerStim, PeakRise_xLocPnt_PerStim
PeakRise_xLocPnt_PerStim*=1000
END