#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function PeaksInStim()

// get peaks during sinusoidal portion of stimulus only i.e. 8 - 38 s
wave DiffTrace_Peak_xLoc, DiffTrace_Peak_Amp
variable StimStart = 8
variable StimEnd = 38
duplicate/o DiffTrace_Peak_xLoc, DiffTrace_Peak_xLoc_stim
duplicate/o DiffTrace_Peak_Amp, DiffTrace_Peak_Amp_Stim
variable nPeaksDet = dimsize(DiffTrace_Peak_xLoc,0)
variable i

for (i=0;i<nPeaksDet;i+=1)
	if (DiffTrace_Peak_xLoc_Stim[i]<StimStart)
		DiffTrace_Peak_xLoc_Stim[i] = NaN
		DiffTrace_Peak_Amp_Stim[i] = NaN
	endif
	if (DiffTrace_Peak_xLoc_Stim[i]>StimEnd)
		DiffTrace_Peak_xLoc_Stim[i] = NaN
		DiffTrace_Peak_Amp_Stim[i] = NaN
	endif
endfor

//Differentiate DiffTrace_Peak_xLoc_stim/D=DiffTrace_Peak_xLoc_stim_DIF;DelayUpdate
//Make/N=100/O DiffTrace_Peak_xLoc_Stim_DIF_Hist;DelayUpdate
//Histogram/B=1 DiffTrace_Peak_xLoc_stim_DIF,DiffTrace_Peak_xLoc_stim_DIF_Hist;DelayUpdate

end