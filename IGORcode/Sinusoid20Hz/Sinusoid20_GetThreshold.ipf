#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function ThresholdPeaks(w)
wave w

// 2 s of "grey" before sinusoid starts (6 - 8 s during stimulus). 
// Use the final 1 s period of "grey" to get glutamate release during "grey"
// Use mean + SD as threshold for a response

variable GreyWinStart = 7000 // start point of "grey" window in pnts
variable GreyWinEnd = 8000 // end point in points
duplicate/o/r=[GreyWinStart,GreyWinEnd][] w, GreyRelease
wavestats/q GreyRelease
make/o/n=(1) Threshold = v_sdev + v_avg
killwaves GreyRelease

wave PeakRise_Amp_PerStim, PeakRise_xloc_PerStim, peak_Amp_perStim, peak_xloc_perStim
duplicate/o PeakRise_Amp_PerStim, PeakRise_Amp_PerStim_Thresh
duplicate/o PeakRise_xloc_PerStim, PeakRise_xloc_PerStim_Thresh
duplicate/o peak_Amp_perStim, peak_Amp_perStim_Thresh
duplicate/o peak_xloc_perStim, peak_xloc_perStim_Thresh

variable nPeaks = dimsize(peak_Amp_perStim,0)
variable i
for (i=0;i<nPeaks;i+=1)
	if (peak_Amp_perStim[i]<Threshold[0])
		PeakRise_Amp_PerStim_Thresh[i] = NaN
		PeakRise_xloc_PerStim_Thresh[i] = NaN
		peak_Amp_perStim_Thresh[i] = NaN
		peak_xloc_perStim_Thresh[i] = NaN
	endif
endfor

appendtograph/W=TracePeakPlot/L=L_Trace_Decon peak_Amp_perStim_Thresh vs peak_xloc_perStim_Thresh
ModifyGraph mode(peak_Amp_perStim_Thresh)=3,marker(peak_Amp_perStim_Thresh)=19,mrkThick(peak_Amp_perStim_Thresh)=2,rgb(peak_Amp_perStim_Thresh)=(0,0,65535)
ModifyGraph msize(peak_Amp_perStim_Thresh)=2
ModifyGraph mrkThick=0.5
SetDrawEnv xcoord= bottom,ycoord= L_Trace_decon;DelayUpdate
DrawLine 0,threshold[0],45,threshold[0]

END