#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Calculate and plot temporal jitter for mixed off step visual stim

FUNCTION MixedOffStep_TemporalJitter()
wave RespPeakxLocs_Ex_Thresh
PullHalfPeakXloc(RespPeakxLocs_Ex_Thresh)
wave HalfPeakXlocs
CalcTempJitter(HalfPeakXlocs)

DisplayTempJitter()
end


// Pull the xloc half way up the peak of the response

Function PullHalfPeakXloc(PeakXlocsMat) // use RespPeakxLocs_Ex_Thresh

wave PeakXlocsMat
wave RespSnips

variable halfpeaktime1 = NaN
variable halfpeakvalue1 = NaN
variable halfpeaktime2 = NaN
variable halfpeakvalue2 = NaN
variable maxsteps = 500
variable i, j, ss

variable nStimReps = dimsize(PeakXlocsMat, 0)
variable nStimConds = dimsize(PeakXlocsMat, 1)
make/o/n=(nStimReps,nStimConds) HalfPeakXlocs // make array to put half peak xLoc values into

// Loop over light off steps first, which give a positive peak response

for (i=0;i<nStimConds;i+=1) // loop over layers (stim conditions)
	for (j=0;j<nStimReps;j+=1) // loop over rows (Stim reps)
		// only get half peak if included in threhsold etc.
		if (numtype(PeakXlocsMat[j][i]) == 0)
			duplicate/o/r=[][j][i] RespSnips, snip
			Redimension/N=-1 snip
			variable peaktime = PeakXlocsMat[j][i]
			variable peakvalue = snip[peaktime]
			for (ss=0;ss<maxsteps;ss+=1) //(//do)
				if (snip[peaktime-ss]<peakvalue/2)
					halfpeaktime1 = peaktime-ss+1 // these are just above half
					halfpeakvalue1 = snip[halfpeaktime1+1]
					halfpeaktime2 = peaktime-ss // these are just below half
					halfpeakvalue2 = snip[halfpeaktime2]
					ss=maxsteps // so that it leave the loop
				endif
			endfor
			variable valuediff1 = halfpeakvalue1 - peakvalue/2
			// question - what fraction (0-1) difference is valuediff1 compared to peakvalue
			variable fractiondiff1 = valuediff1/peakvalue // rename these fractiondiff1
			variable fractiondiff2 = 1 - fractiondiff1
			variable realtime_halfvalue = halfpeaktime1 + fractiondiff1
			HalfPeakXlocs[j][i] = realtime_halfvalue
			killwaves snip
		endif
		if (numtype(PeakXlocsMat[j][i]) == 2)
			HalfPeakXlocs[j][i] = NaN
		endif
	endfor //(//while(1)) // "break"
endfor

end

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Calculate temp jitter as the variance in time to half peak

Function CalcTempJitter(HalfPeakXlocs) 

wave HalfPeakXlocs
variable inputType
wave stimconds

duplicate/o HalfPeakXlocs, TtoHalfPeak
TtoHalfPeak-=50 // gets account for 50 ms of trace before stim onset in RespSnips
variable nStimReps = dimsize(HalfPeakXlocs, 0)
variable nStimConds = dimsize(TtoHalfPeak, 1)
variable i, j

for (i=0;i<nStimConds;i+=1) //get rid of values less than 0 as there is an error in calculation due to noise
	for (j=0;j<nStimReps;j+=1)
		if (TtoHalfPeak[j][i]<0)
			TtoHalfPeak[j][i] = NaN
		endif
	endfor
endfor
	
make/o/n=(nStimconds) TtoHalfPeak_mean
make/o/n=(nStimConds) TtoHalfPeak_SD
make/o/n=(nStimConds) TtoHalfPeak_variance

for (i=0;i<nStimConds;i+=1)
	duplicate/o/r=[][i] TtoHalfPeak, tempwave
	wavestats/q tempwave
	TtoHalfPeak_mean[i] = v_avg
	TtoHalfPeak_SD[i] = v_SDev
	TtoHalfPeak_variance[i] = v_sdev^2
	killwaves tempwave
endfor

end

///////////////////////////////////////////////////////////////////////////////////////////////////

Function DisplayTempJitter()

wave TtoHalfPeak_Mean, TtoHalfPeak_SD, TtoHalfPeak_Variance, stimconds

// display mean +/- SD of time to half peak as a function of stimulus condition
display/k=1 TtoHalfPeak_Mean vs stimconds
ErrorBars TtoHalfPeak_Mean Y,wave=(TtoHalfPeak_SD,TtoHalfPeak_SD)
ModifyGraph lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
Label left "Time to half peak (ms)";DelayUpdate
Label bottom "Off-step duration (ms)"
SetAxis/A/N=1 left;DelayUpdate
SetAxis bottom 0,*
Modifygraph RGB = (0,0,0)
ModifyGraph mode=4,marker=19,msize=1

// display temporal jitter as SD of time to peak
display/k=1 TtoHalfPeak_SD vs stimconds
ModifyGraph lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
Label left "Temporal jitter (ms)(SD of time to peak)";DelayUpdate
Label bottom "Off-step duration (ms)"
SetAxis/A/N=1 left;DelayUpdate
SetAxis bottom 0,*
Modifygraph RGB = (0,0,0)
ModifyGraph mode=4,marker=19,msize=1

end
