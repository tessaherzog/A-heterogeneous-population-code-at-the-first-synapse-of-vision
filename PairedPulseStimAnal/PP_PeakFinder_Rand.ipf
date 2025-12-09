#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// Pull the amplitude and xloc values for the first and second peaks

Function PeakFinder_Rand(RespSnips_decon_FSTU)
wave RespSnips_decon_FSTU
GetSecPulseStartTimes()
PullPeakVals2to100(RespSnips_decon_FSTU)
CheckPeakValues()
end

////////////////////////////////////////////////////////////////////////////////////////////
Function GetSecPulseStartTimes()

wave stimConds
variable nStimConds = dimsize(stimConds,0)
make/o/n=(nStimConds) SecPulseStart
variable SnipPreWindow = 50
variable OffStepDur = 40

variable i
for (i=0;i<nStimConds;i+=1)
	SecPulseStart[i] = SnipPreWindow + OffStepDur + stimConds[i]
endfor
END
///////////////////////////////////////////////////////////////////////////////////////////////////

Function PullPeakVals2to100(RespSnips_decon_FSTU)
wave RespSnips_decon_FSTU

variable snipLen = dimsize(RespSnips_decon_FSTU, 0)
variable nStimReps = dimsize(RespSnips_decon_FSTU, 1)
variable nStimConds = dimsize(RespSnips_decon_FSTU,2)
variable midpoint = 128 //lowest point between two peaks, will need to be checked for each array. Usually around 145.
variable i, j
wave SecPulseStart

// pull the peak of peak 1 and peak 2 in each response snippet

wave Peak1_Amps, Peak1_xLocs, Peak2_Amps, Peak2_xLocs
killwaves Peak1_Amps, Peak1_xLocs, Peak2_Amps, Peak2_xLocs
variable PeakWinDelay = 15 // ms before peak detection win starts
variable firstpulsestart = 50

for (i=0;i<nStimConds;i+=1)
	for (j=0;j<nStimReps;j+=1)
		duplicate/o/r=[][j][i] RespSnips_decon_FSTU, TempRespSnip
		Redimension/N=-1 TempRespSnip
		if (numtype(TempRespSnip[0]) == 0)
			duplicate/o/r=[firstpulsestart+PeakWinDelay,firstpulsestart + 70][0] TempRespSnip, TempRespSnip_1
			duplicate/o/r=[SecPulseStart[i]+PeakWinDelay*2,SecPulseStart[i]+PeakWinDelay+70][0] TempRespSnip, TempRespSnip_2
			wavestats/q TempRespSnip_1		
			make/o/n=(1) Peak1_Amp = v_max
			make/o/n=(1) Peak1_xloc = v_maxloc
			wavestats/q TempRespSnip_2
			make/o/n=(1) Peak2_Amp = v_max
			make/o/n=(1) Peak2_xloc = v_maxloc
		elseif (numtype(TempRespSnip[0]) == 2)
			make/o/n=(1) Peak1_Amp = Nan
			make/o/n=(1) Peak1_xloc = NaN
			make/o/n=(1) Peak2_Amp = NaN
			make/o/n=(1) Peak2_xloc = NaN
		endif			
		concatenate/np=0 {Peak1_Amp}, Peak1_Amps_temp
		concatenate/np=0 {Peak1_xloc}, Peak1_xlocs_temp
		concatenate/np=0 {Peak2_Amp}, Peak2_Amps_temp
		concatenate/np=0 {Peak2_xloc}, Peak2_xlocs_temp
		killwaves TempRespSnip_1, TempRespSnip_2
		killwaves Peak1_Amp, Peak1_xloc, Peak2_Amp, Peak2_xloc
	endfor
	concatenate/np=1 {Peak1_Amps_temp}, Peak1_Amps
	concatenate/np=1 {Peak1_xlocs_temp}, Peak1_xlocs
	concatenate/np=1 {Peak2_Amps_temp}, Peak2_Amps
	concatenate/np=1 {Peak2_xlocs_temp}, Peak2_xlocs
	killwaves Peak1_Amps_temp, Peak1_xlocs_temp, Peak2_Amps_temp, Peak2_xlocs_temp
endfor
	
killwaves TempRespSnip
end


////////////////////////////////////////////////////////
Function CheckPeakValues()

wave RespSnips_decon, Peak1_Amps, Peak1_xlocs, Peak2_Amps, Peak2_xlocs
variable nStimReps = dimsize(respsnips_decon,1)
variable nStimConds = dimsize(respsnips_decon,2)

variable i,j
for (i=0;i<nStimConds;i+=1)
	display/k=1 RespSnips_decon[][0][i]
	appendtograph RespSnips_decon[][1][i]
	appendtograph RespSnips_decon[][2][i]
	appendtograph RespSnips_decon[][3][i]
	appendtograph RespSnips_decon[][4][i]
	SetAxis bottom *,0.3;DelayUpdate
	ModifyGraph axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
	Label left "Decon DF/F";DelayUpdate
	Label bottom "Time (s)"
	ModifyGraph rgb=(0,0,0)
	appendtograph Peak1_Amps[][i] vs Peak1_xlocs[][i]
	ModifyGraph mode(Peak1_Amps)=3,marker(Peak1_Amps)=16,mrkThick(Peak1_Amps)=1,msize(Peak1_Amps)=2
	appendtograph Peak2_Amps[][i] vs Peak2_xlocs[][i]
	ModifyGraph mode(Peak2_Amps)=3,marker(Peak2_Amps)=16,mrkThick(Peak2_Amps)=1,msize(Peak2_Amps)=2
endfor

end