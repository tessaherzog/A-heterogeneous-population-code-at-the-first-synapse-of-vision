#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

// timing analysis to threshold already done
// NaN out responses that don't reach thresold in amplitude matrix
// recalculate means etc. based on this thresholding


Function ThreshAmps(timingMat, AmpMat)
//use ThreshAmps(Trace_Decon_Amp_Thresh_xloc, RespPeak_Amps_Decon)
wave timingMat, AmpMat
variable nStimReps = dimsize(timingMat,0)
variable i

duplicate/o AmpMat, AmpMat_Threshed
for (i=0;i<nStimReps;i+=1)
	if (numtype(TimingMat[i]) == 2)
		AmpMat_Threshed[i] = NaN 
	endif
endfor

string threshedAmpsName = nameofwave(AmpMat) + "_threshed"
string threshedAmpsName_mean = nameofwave(AmpMat) + "_threshed_mean"
string threshedAmpsName_SD = nameofwave(AmpMat) + "_threshed_SD"
string threshedAmpsName_Var = nameofwave(AmpMat) + "_threshed_Var"
string threshedAmpsName_CV = nameofwave(AmpMat) + "_threshed_CV"

wavestats/q AmpMat_Threshed
make/o/n=(1) $threshedAmpsName_mean = v_avg
make/o/n=(1) $threshedAmpsName_SD = v_sdev
make/o/n=(1) $threshedAmpsName_Var = v_sdev^2
make/o/n=(1) $threshedAmpsName_CV = v_sdev/v_avg

duplicate/o AmpMat_Threshed, $threshedAmpsName
killwaves AmpMat_Threshed

END