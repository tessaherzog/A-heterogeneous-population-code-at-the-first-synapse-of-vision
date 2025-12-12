#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function VarCont_TemporalJitter()

wave TransPeak_xloc, RespSnips_Z, D_TransPeak_xloc, D_RespSnips_Z
Pull_HP_trans(TransPeak_xloc, RespSnips_Z, 0)
Pull_HP_trans(D_TransPeak_xloc, D_RespSnips_Z, 2)

wave RebPeak_xloc, D_RebPeak_xloc
Pull_HP_reb(RebPeak_xloc, RespSnips_Z, 0)
Pull_HP_reb(D_RebPeak_xloc, D_RespSnips_Z, 2)

wave TransPeak_HalfPXloc, D_TransPeak_HalfPXloc
CalcTempJitter_trans(TransPeak_HalfPXloc, 0)
CalcTempJitter_trans(D_TransPeak_HalfPXloc, 2)

wave RebPeak_HalfPXloc, D_RebPeak_HalfPXloc
CalcTempJitter_reb(RebPeak_HalfPXloc, 0)
CalcTempJitter_reb(D_RebPeak_HalfPXloc, 2)

wave TransPeak_TtoHP_mean, TransPeak_TtoHP_SD, RebPeak_TtoHP_mean, RebPeak_TtoHP_SD
wave D_TransPeak_TtoHP_mean, D_TransPeak_TtoHP_SD, D_RebPeak_TtoHP_mean, D_RebPeak_TtoHP_SD
//DisplayTimeToHalfPeak(TransPeak_TtoHP_mean, TransPeak_TtoHP_SD, RebPeak_TtoHP_mean, RebPeak_TtoHP_SD, 0)
//DisplayTimeToHalfPeak(D_TransPeak_TtoHP_mean, D_TransPeak_TtoHP_SD, D_RebPeak_TtoHP_mean, D_RebPeak_TtoHP_SD, 2)

end

// 1) Pull the xloc half way up the rise of the transient

Function Pull_HP_trans(TransPeak_xlocMat, RespSnipMat, tracetype) // use Pull_HP_trans(Time_trans_PeakAmp, Time_trans_PeakXloc)

wave TransPeak_xlocMat, RespSnipMat
variable tracetype

TransPeak_xlocMat*=1000

variable halfpeaktime1 = NaN
variable halfpeakvalue1 = NaN
variable halfpeaktime2 = NaN
variable halfpeakvalue2 = NaN
variable maxsteps = 500
variable i, j, ss

variable nStimReps = dimsize(RespSnipMat, 1)
variable nStimConds = dimsize(RespSnipMat, 2)
make/o/n=(nStimReps,nStimConds) HalfPeakXlocs // make array to put half peak xLoc values into

// Loop over light off steps first, which give a positive peak response

for (i=0;i<5;i+=1)
	for (j=0;j<nStimReps;j+=1)
		duplicate/o/r=[][j][i] RespSnipMat, tempsnip
		Redimension/N=-1 tempsnip
		variable peaktime = TransPeak_xlocMat[j][i]
		variable peakvalue = tempsnip[peaktime]
		for (ss=0;ss<maxsteps;ss+=1) //(//do)
    		if (tempsnip[peaktime-ss]<peakvalue/2)
      	  		halfpeaktime1 = peaktime-ss+1 // these are just above half
      	  		halfpeakvalue1 = tempsnip[halfpeaktime1+1]
      	  		halfpeaktime2 = peaktime-ss // these are just below half
      	  		halfpeakvalue2 = tempsnip[halfpeaktime2]
      	  		ss=maxsteps // so that it leave the loop
    		endif
    	endfor
		variable valuediff1 = halfpeakvalue1 - peakvalue/2
		//variable valuediff2 = peakvalue/2 - halfpeakvalue2 (redundant)
		// question - what fraction (0-1) difference is valuediff1 compared to peakvalue
		variable fractiondiff1 = valuediff1/peakvalue // rename these fractiondiff1
		variable fractiondiff2 = 1 - fractiondiff1
		variable realtime_halfvalue = halfpeaktime1 + fractiondiff1
		HalfPeakXlocs[j][i] = realtime_halfvalue
    endfor //(//while(1)) // "break"
endfor

// Loop over light ON steps second, which give an off response. 

for (i=5;i<nStimConds;i+=1) // loop over layers (stim conditions)
	for (j=0;j<nStimReps;j+=1) // loop over rows (Stim reps)
		duplicate/o/r=[][j][i] RespSnipMat, tempsnip
		Redimension/N=-1 tempsnip
		variable peaktimee = TransPeak_xlocMat[j][i]
		variable peakvaluee = tempsnip[peaktimee]
		for (ss=0;ss<maxsteps;ss+=1) //(//do)
    		if (tempsnip[peaktimee-ss]>peakvaluee/2)
      	  		halfpeaktime1 = peaktimee-ss+1 // these are just above half
      	  		halfpeakvalue1 = tempsnip[halfpeaktime1+1]
      	  		halfpeaktime2 = peaktimee-ss // these are just below half
      	  		halfpeakvalue2 = tempsnip[halfpeaktime2]
      	  		ss=maxsteps // so that it leave the loop
    		endif
    	endfor
		variable valuedifff1 = halfpeakvalue1 - peakvalue/2
		//variable valuediff2 = peakvalue/2 - halfpeakvalue2 (redundant)
		// question - what fraction (0-1) difference is valuediff1 compared to peakvalue
		variable fractiondifff1 = valuediff1/peakvaluee // rename these fractiondiff1
		variable fractiondifff2 = 1 - fractiondiff1
		variable realtime_halfvaluee = halfpeaktime1 + fractiondiff1
		HalfPeakXlocs[j][i] = realtime_halfvaluee
    endfor //(//while(1)) // "break"
endfor
killwaves tempsnip

if (tracetype == 0)
	duplicate/o HalfPeakXlocs, TransPeak_HalfPXloc
	killwaves HalfPeakXlocs
endif

if (tracetype == 2)
	duplicate/o HalfPeakXlocs, D_TransPeak_HalfPXloc
	killwaves HalfPeakXlocs
endif

TransPeak_xlocMat/=1000

end

///////////////////////////////////////////////////////////////////////////////////////////////////
// 2) same again for Rebound
Function Pull_HP_reb(RebPeak_xlocMat, RespSnipMat, tracetype) // use Pull_HP_reb(Time_reb_PeakAmp, Time_reb_PeakXloc)

wave RebPeak_xlocMat, RespSnipMat
variable tracetype
RebPeak_xlocMat*=1000

variable halfpeaktime1 = NaN
variable halfpeakvalue1 = NaN
variable halfpeaktime2 = NaN
variable halfpeakvalue2 = NaN
variable maxsteps = 500
variable i, j, ss

variable nStimReps = dimsize(RespSnipMat, 1)
variable nStimConds = dimsize(RespSnipMat, 2)
make/o/n=(nStimReps,nStimConds) HalfPeakXlocs // make array to put half peak xLoc values into

// Loop over light off steps first, which give a positive peak response

for (i=5;i<nStimConds;i+=1)
	for (j=0;j<nStimReps;j+=1)
		duplicate/o/r=[][j][i] RespSnipMat, tempsnip
		Redimension/N=-1 tempsnip
		variable peaktime = RebPeak_xlocMat[j][i]
		variable peakvalue = tempsnip[peaktime]
		for (ss=0;ss<maxsteps;ss+=1) //(//do)
    		if (tempsnip[peaktime-ss]<peakvalue/2)
      	  		halfpeaktime1 = peaktime-ss+1 // these are just above half
      	  		halfpeakvalue1 = tempsnip[halfpeaktime1+1]
      	  		halfpeaktime2 = peaktime-ss // these are just below half
      	  		halfpeakvalue2 = tempsnip[halfpeaktime2]
      	  		ss=maxsteps // so that it leave the loop
    		endif
    	endfor
		variable valuediff1 = halfpeakvalue1 - peakvalue/2
		//variable valuediff2 = peakvalue/2 - halfpeakvalue2 (redundant)
		// question - what fraction (0-1) difference is valuediff1 compared to peakvalue
		variable fractiondiff1 = valuediff1/peakvalue // rename these fractiondiff1
		variable fractiondiff2 = 1 - fractiondiff1
		variable realtime_halfvalue = halfpeaktime1 + fractiondiff1
		HalfPeakXlocs[j][i] = realtime_halfvalue
    endfor //(//while(1)) // "break"
endfor

// Loop over light ON steps second, which give an off response. 

for (i=0;i<5;i+=1) // loop over layers (stim conditions)
	for (j=0;j<nStimReps;j+=1) // loop over rows (Stim reps)
		duplicate/o/r=[][j][i] RespSnipMat, tempsnip
		Redimension/N=-1 tempsnip
		variable peaktimee = RebPeak_xlocMat[j][i]
		variable peakvaluee = tempsnip[peaktimee]
		for (ss=0;ss<maxsteps;ss+=1) //(//do)
    		if (tempsnip[peaktimee-ss]>peakvaluee/2)
      	  		halfpeaktime1 = peaktimee-ss+1 // these are just above half
      	  		halfpeakvalue1 = tempsnip[halfpeaktime1+1]
      	  		halfpeaktime2 = peaktimee-ss // these are just below half
      	  		halfpeakvalue2 = tempsnip[halfpeaktime2]
      	  		ss=maxsteps // so that it leave the loop
    		endif
    	endfor
		variable valuedifff1 = halfpeakvalue1 - peakvalue/2
		//variable valuediff2 = peakvalue/2 - halfpeakvalue2 (redundant)
		// question - what fraction (0-1) difference is valuediff1 compared to peakvalue
		variable fractiondifff1 = valuediff1/peakvaluee // rename these fractiondiff1
		variable fractiondifff2 = 1 - fractiondiff1
		variable realtime_halfvaluee = halfpeaktime1 + fractiondiff1
		HalfPeakXlocs[j][i] = realtime_halfvaluee
    endfor //(//while(1)) // "break"
endfor
killwaves tempsnip

if (tracetype == 0)
	duplicate/o HalfPeakXlocs, RebPeak_HalfPXloc
	killwaves HalfPeakXlocs
endif

if (tracetype == 2)
	duplicate/o HalfPeakXlocs, D_RebPeak_HalfPXloc
	killwaves HalfPeakXlocs
endif

RebPeak_xlocMat/=1000
end
///////////////////////////////////////////////////////////////////////////////////////////////////////////
// 3) calculate temp jitter as the variance in time to half peak

Function CalcTempJitter_trans(Trans_HalfPeakXlocMat, tracetype) // use CalcTempJitter_trans(Time_trans_HalfPeakXloc)

wave Trans_HalfPeakXlocMat
variable tracetype
wave stimconds

duplicate/o Trans_HalfPeakXlocMat, Time_Trans_TtoHP // make matrix of time to half peak values
Time_Trans_TtoHP-=500
variable nStimConds = dimsize(Time_Trans_TtoHP, 1)
variable nStimReps = dimsize(Time_Trans_TtoHP, 0)
variable i, j

for (i=0;i<nStimConds;i+=1) //get rid of values less than 0 as there is an underestimation of peak rise due to noise
	for (j=0;j<nStimReps;j+=1)
		if (Time_Trans_TtoHP[i][j]<0)
			Time_Trans_TtoHP[i][j] = NaN
		endif
	endfor
endfor

make/o/n=(nStimconds) Time_Trans_TtoHP_mean
make/o/n=(nStimConds) Time_Trans_TtoHP_SD
make/o/n=(nStimConds) Time_Trans_TtoHP_var

for (i=0;i<nStimConds;i+=1)
	duplicate/o/r=[][i] Time_Trans_TtoHP, tempwave
	wavestats/q tempwave
	Time_trans_TtoHP_mean[i] = v_avg
	Time_trans_TtoHP_SD[i] = v_SDev
	Time_trans_TtoHP_var[i] = v_sdev^2
endfor

duplicate/o/r=[0] Time_trans_TtoHP_mean, Time_trans_TtoHP_mean_100n
duplicate/o/r=[0] Time_trans_TtoHP_SD, Time_trans_TtoHP_SD_100n
killwaves tempwave

if (tracetype == 0)
	duplicate/o Time_Trans_TtoHP, TransPeak_TtoHP
	duplicate/o Time_Trans_TtoHP_mean, TransPeak_TtoHP_mean
	duplicate/o Time_Trans_TtoHP_SD, TransPeak_TtoHP_SD
	duplicate/o Time_Trans_TtoHP_var, TransPeak_TtoHP_Var
	duplicate/o Time_trans_TtoHP_mean_100n, TransPeak_TtoHP_mean100n
	duplicate/o Time_trans_TtoHP_SD_100n, TransPeak_TtoHP_SD100n
	
	killwaves Time_Trans_TtoHP, Time_Trans_TtoHP_mean, Time_Trans_TtoHP_SD, Time_Trans_TtoHP_var
	killwaves Time_trans_TtoHP_mean_100n, Time_trans_TtoHP_SD_100n
endif

if (tracetype == 2)
	duplicate/o Time_Trans_TtoHP, D_TransPeak_TtoHP
	duplicate/o Time_Trans_TtoHP_mean, D_TransPeak_TtoHP_mean
	duplicate/o Time_Trans_TtoHP_SD, D_TransPeak_TtoHP_SD
	duplicate/o Time_Trans_TtoHP_var, D_TransPeak_TtoHP_Var
	duplicate/o Time_trans_TtoHP_mean_100n, D_TransPeak_TtoHP_mean100n
	duplicate/o Time_trans_TtoHP_SD_100n, D_TransPeak_TtoHP_SD100n
	
	killwaves Time_Trans_TtoHP, Time_Trans_TtoHP_mean, Time_Trans_TtoHP_SD, Time_Trans_TtoHP_var
	killwaves Time_trans_TtoHP_mean_100n, Time_trans_TtoHP_SD_100n
endif
end

//////////////////////////////////////////////////////////////////////////////////////////////
// 4) same again for rebound
Function CalcTempJitter_reb(Reb_HalfPeakXlocMat, tracetype) // use CalcTempJitter_reb(Time_Reb_HalfPeakXloc)

wave Reb_HalfPeakXlocMat
variable tracetype
wave stimconds

duplicate/o Reb_HalfPeakXlocMat, Time_Reb_TtoHP // make matrix of time to half peak values
Time_Reb_TtoHP-=1000
variable nStimConds = dimsize(Time_Reb_TtoHP, 1)
variable nStimReps = dimsize(Time_Reb_TtoHP, 0)
variable i, j

for (i=0;i<nStimConds;i+=1) //get rid of values less than 0 as there is an underestimation of peak rise due to noise
	for (j=0;j<nStimReps;j+=1)
		if (Time_Reb_TtoHP[i][j]<0)
			Time_Reb_TtoHP[i][j] = NaN
		endif
	endfor
endfor

make/o/n=(nStimconds) Time_Reb_TtoHP_mean
make/o/n=(nStimConds) Time_Reb_TtoHP_SD
make/o/n=(nStimConds) Time_Reb_TtoHP_var

for (i=0;i<nStimConds;i+=1)
	duplicate/o/r=[][i] Time_Reb_TtoHP, tempwave
	wavestats/q tempwave
	Time_Reb_TtoHP_mean[i] = v_avg
	Time_Reb_TtoHP_SD[i] = v_SDev
	Time_Reb_TtoHP_var[i] = v_sdev^2
endfor

duplicate/o/r=[0] Time_Reb_TtoHP_mean, Time_Reb_TtoHP_mean_100n
duplicate/o/r=[0] Time_Reb_TtoHP_SD, Time_Reb_TtoHP_SD_100n
killwaves tempwave

if (tracetype == 0)
	duplicate/o Time_Reb_TtoHP, RebPeak_TtoHP
	duplicate/o Time_Reb_TtoHP_mean, RebPeak_TtoHP_mean
	duplicate/o Time_Reb_TtoHP_SD, RebPeak_TtoHP_SD
	duplicate/o Time_Reb_TtoHP_var, RebPeak_TtoHP_Var
	duplicate/o Time_Reb_TtoHP_mean_100n, RebPeak_TtoHP_mean100n
	duplicate/o Time_Reb_TtoHP_SD_100n, RebPeak_TtoHP_SD100n
	
	killwaves Time_Reb_TtoHP, Time_Reb_TtoHP_mean, Time_Reb_TtoHP_SD, Time_Reb_TtoHP_var
	killwaves Time_Reb_TtoHP_mean_100n, Time_Reb_TtoHP_SD_100n
endif

if (tracetype == 2)
	duplicate/o Time_Reb_TtoHP, D_RebPeak_TtoHP
	duplicate/o Time_Reb_TtoHP_mean, D_RebPeak_TtoHP_mean
	duplicate/o Time_Reb_TtoHP_SD, D_RebPeak_TtoHP_SD
	duplicate/o Time_Reb_TtoHP_var, D_RebPeak_TtoHP_Var
	duplicate/o Time_Reb_TtoHP_mean_100n, D_RebPeak_TtoHP_mean100n
	duplicate/o Time_Reb_TtoHP_SD_100n, D_RebPeak_TtoHP_SD100n
	
	killwaves Time_Reb_TtoHP, Time_Reb_TtoHP_mean, Time_Reb_TtoHP_SD, Time_Reb_TtoHP_var
	killwaves Time_Reb_TtoHP_mean_100n, Time_Reb_TtoHP_SD_100n
endif
end

/////////////////////////////////////////////////////////////////////////////////////////////////////
// 5) Display time to half peak, and temporal jitter as a function of off-step duration 

Function DisplayTimeToHalfPeak(TransMean, TransSD, RebMean, RebSD, tracetype)
wave TransMean, TransSD, RebMean, RebSD
variable tracetype

wave stimconds
string TransMeanName = nameofwave(TransMean)
string TransSDname = nameofwave(TransSD)
string RebMeanName = nameofwave(RebMean)
string RebSDname = nameofwave(RebSD)
print TransMeanName
print TransSDname
print RebMeanName
print RebSDname


// time to half peak of transient as a function of off-step duration
display/k=1 $TransMeanName vs stimconds 
ModifyGraph rgb=(0,0,0);DelayUpdate
ErrorBars $TransMeanName Y,wave=($TransSDname,$TransSDname)
SetAxis/A/N=1 left;DelayUpdate
ModifyGraph zero(bottom)=2,lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
Label left "Transient time to half peak (ms)";DelayUpdate
Label bottom "Contrast step from mean light level (ms)"
if (tracetype == 0)
	DrawText 0.046189376443418,0.897196261682243,"DF/F trace"
endif
if (tracetype == 2)
	DrawText 0.046189376443418,0.897196261682243,"Decon trace"
endif
	
//temporal jitter of transient as a function of off-step duration 
display/k=1 $TransSDname vs stimconds
setAxis/A/N=1 left;DelayUpdate
ModifyGraph zero(bottom)=2,lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
Label left "Transient temporal jitter (ms)";DelayUpdate
Label bottom "Contrast step from mean light level (ms)"
ModifyGraph rgb=(0,0,0)
if (tracetype == 0)
	DrawText 0.046189376443418,0.897196261682243,"DF/F trace"
endif
if (tracetype == 2)
	DrawText 0.046189376443418,0.897196261682243,"Decon trace"
endif

// time to half rebound peak as a function of off-step duration 
display/k=1 $RebMeanName vs stimconds 
ModifyGraph rgb=(0,0,0);DelayUpdate
ErrorBars $RebMeanName Y,wave=($RebSDName,$RebSDName)
SetAxis/A/N=1 left;DelayUpdate
ModifyGraph zero(bottom)=2,lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
Label left "Rebound time to half peak (ms)";DelayUpdate
Label bottom "Contrast step from mean light level (ms)"
if (tracetype == 0)
	DrawText 0.046189376443418,0.897196261682243,"DF/F trace"
endif
if (tracetype == 2)
	DrawText 0.046189376443418,0.897196261682243,"Decon trace"
endif
	
//temporal jitter of rebound as a function of off-step duration 
display/k=1 $RebSDName vs stimconds
setAxis/A/N=1 left;DelayUpdate
ModifyGraph zero(bottom)=2,lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
Label left "Rebound temporal jitter (ms)";DelayUpdate
Label bottom "Contrast step from mean light level (ms)"
ModifyGraph rgb=(0,0,0);DelayUpdate
if (tracetype == 0)
	DrawText 0.046189376443418,0.897196261682243,"DF/F trace"
endif
if (tracetype == 2)
	DrawText 0.046189376443418,0.897196261682243,"Decon trace"
endif

end
