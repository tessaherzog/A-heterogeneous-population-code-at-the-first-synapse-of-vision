//#pragma TextEncoding = "UTF-8"
//#pragma rtGlobals=3		// Use modern global access method and strict wave access.
//
//// Get adaptation index for each stimulus condition
//// Adaptation calculated as (a-b)/(a+b) where a=peak transient resp amp, and b = average sustained response amp.
//// Plot adaptation index as a function of stimulus condition
//
//// Use procedures "VarContSteps_1Hz_MakeArrays" and "VarContSteps_1Hz_PullAmps" to get the response amps.
//
Function AdaptationIndexCalc()
wave TransPeak_amp, AmpsSust, D_TransPeak_amp, D_AmpsSust
CalculateAdapIndex(TransPeak_amp,AmpsSust, 0)
CalculateAdapIndex(D_TransPeak_amp,D_AmpsSust, 2)

wave AdaptationIndex, D_AdaptationIndex
aveAdapIndex(AdaptationIndex, 0)
aveAdapIndex(D_AdaptationIndex, 2)

//dispAdapIndex(AdaptationIndex_mean, AdaptationIndex_SD)
//dispAdapIndex(D_AdaptationIndex_mean, D_AdaptationIndex_SD)

end

//////////////////////////////////////////////////////////////////////////////////////////////////////
// calculate adaptation index as (Trans peak amp - Sust amp)/(Trans amp + Sust amp)
Function CalculateAdapIndex(w1, w2, tracetype) //use (TransPeak_amp,AmpsSust,0)

wave w1, w2
variable tracetype
variable i, j
variable nStimReps = dimsize(w1,0)
variable nStimConds = dimsize(w1,1)

make/o/n=(nStimReps, nStimConds) AdapIndex
for (i=0;i<5;i+=1) // loop over responses to negative contrast
	for (j=0;j<nStimReps;j+=1)
		variable aNeg = w1[j][i]
		variable bNeg = w2[j][i]
		if (aNeg<0)
			aNeg=0
		endif
		if (bNeg<0)
			bNeg=0
		endif
		AdapIndex[j][i] = (aNeg-bNeg)/(aNeg+bNeg)
	endfor
endfor

for (i=5;i<nStimConds;i+=1) //loop over responses to positive contrast
	for(j=0;j<nStimReps;j+=1)
		variable aPos = w1[j][i]
		variable bPos = w2[j][i]
		aPos*=-1
		bPos*=-1
		if (aPos<0)
			aPos=0
		endif
		if (bPos<0)
			bPos=0
		endif
		AdapIndex[j][i] = (aPos-bPos)/(aPos+bPos)
	endfor
endfor

if (tracetype == 0)
	duplicate/o AdapIndex, AdaptationIndex
	killwaves AdapIndex
endif

if (tracetype == 2)
	duplicate/o AdapIndex, D_AdaptationIndex
	killwaves AdapIndex
endif

end

//////////////////////////////////////////////////////////////////////////////////////////////////////

Function aveAdapIndex(AdapIndexMatrix, tracetype)

wave AdapIndexMatrix
variable tracetype
variable i
variable nStimReps = dimsize(AdapIndexMatrix,0)

make/o/n=(nStimReps) AdapIndex_mean
make/o/n=(nStimReps) AdapIndex_SD

for (i=0;i<nStimReps;i+=1)
	duplicate/o/r=[][i] AdapIndexMatrix, tempwave
	wavestats/q tempwave
	AdapIndex_mean[i] = v_avg
	AdapIndex_SD[i] = V_sdev
endfor
killwaves tempwave

if (tracetype == 0)
	duplicate/o AdapIndex_mean, AdaptationIndex_mean
	duplicate/o AdapIndex_SD, AdaptationIndex_SD
	killwaves AdapIndex_mean, AdapIndex_SD
endif

if (tracetype == 2)
	duplicate/o AdapIndex_mean, D_AdaptationIndex_mean
	duplicate/o AdapIndex_SD, D_AdaptationIndex_SD
	killwaves AdapIndex_mean, AdapIndex_SD
endif

end

//////////////////////////////////////////////////////////////////////////////////////////////////////

Function dispAdapIndex(AImean, AISD)

wave AImean, AISD
variable tracetype

string meanName = nameofwave(AImean)
string SDName = nameofwave (AISD)
wave stimConds
display/k=1 $meanName vs stimconds
ModifyGraph rgb=(0,0,0);DelayUpdate
ErrorBars $meanName Y,wave=($SDName,$SDName)
ModifyGraph zero=2,lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
SetAxis/A/N=1 left
Label left "Adaptation index";DelayUpdate
Label bottom "Contrast step from mean light level (%)"

end
