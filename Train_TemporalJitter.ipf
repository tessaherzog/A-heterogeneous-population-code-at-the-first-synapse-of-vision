#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Calculate and plot temporal jitter for Train stimulus

FUNCTION Trainstim_TemporalJitter()
HalfPeak_Xloc()
CalcTempJitter() 
end

Function HalfPeak_Xloc() // Pull the xloc half way up the peak of the response

wave RespPeak_xLocs, RespPeak_xLocs_Decon, RespSnips, RespSnips_decon

variable halfpeaktime1 = NaN
variable halfpeakvalue1 = NaN
variable halfpeaktime2 = NaN
variable halfpeakvalue2 = NaN
variable maxsteps = 500
variable j, ss
variable nStimReps = dimsize(RespPeak_xLocs, 0)

make/o/n=(nStimReps) HalfPeak_Xlocs // make array to put xLoc of half peak.

for (j=0;j<nStimReps;j+=1) // loop over rows (Stim reps)
	duplicate/o/r=[][j] RespSnips, tempSnip
	Redimension/N=-1 tempSnip
	variable peaktime = RespPeak_xLocs[j]
	variable peakvalue = tempSnip[peaktime]
	for (ss=0;ss<maxsteps;ss+=1) //(//do)
   		if (tempSnip[peaktime-ss]<peakvalue/2)
     	  		halfpeaktime1 = peaktime-ss+1 // these are just above half
     	  		halfpeakvalue1 = tempSnip[halfpeaktime1+1]
     	  		halfpeaktime2 = peaktime-ss // these are just below half
     	  		halfpeakvalue2 = tempSnip[halfpeaktime2]
     	  		ss=maxsteps // so that it leave the loop
   		endif
   	endfor
	variable valuediff1 = halfpeakvalue1 - peakvalue/2
	// question - what fraction (0-1) difference is valuediff1 compared to peakvalue
	variable fractiondiff1 = valuediff1/peakvalue // rename these fractiondiff1
	variable fractiondiff2 = 1 - fractiondiff1
	variable realtime_halfvalue = halfpeaktime1 + fractiondiff1
	HalfPeak_Xlocs[j] = realtime_halfvalue
	killwaves tempSnip
endfor

// same for decon wave

make/o/n=(nStimReps) HalfPeak_Xlocs_Decon // make array to put xLoc of half peak.

for (j=0;j<nStimReps;j+=1) // loop over rows (Stim reps)
	duplicate/o/r=[][j] RespSnips_Decon, tempSnip
	Redimension/N=-1 tempSnip
	peaktime = RespPeak_xLocs_Decon[j]
	peakvalue = tempSnip[peaktime]
	for (ss=0;ss<maxsteps;ss+=1) //(//do)
   		if (tempSnip[peaktime-ss]<peakvalue/2)
     	  		halfpeaktime1 = peaktime-ss+1 // these are just above half
     	  		print halfpeaktime1
     	  		halfpeakvalue1 = tempSnip[halfpeaktime1+1]
     	  		halfpeaktime2 = peaktime-ss // these are just below half
     	  		print halfpeaktime2
     	  		halfpeakvalue2 = tempSnip[halfpeaktime2]
     	  		ss=maxsteps // so that it leave the loop and doesn't carry on overwriting
   		endif
   	endfor
	valuediff1 = halfpeakvalue1 - peakvalue/2
	// question - what fraction (0-1) difference is valuediff1 compared to peakvalue
	fractiondiff1 = valuediff1/peakvalue // rename these fractiondiff1
	fractiondiff2 = 1 - fractiondiff1
	realtime_halfvalue = halfpeaktime1 + fractiondiff1
	HalfPeak_Xlocs_Decon[j] = realtime_halfvalue
	killwaves tempSnip
endfor


end

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Calculate temp jitter as the SD in time to half peak

Function CalcTempJitter()
wave HalfPeak_Xlocs

duplicate/o HalfPeak_Xlocs, TtoHalfPeak

variable nResps  =dimsize(HalfPeak_Xlocs,0)
variable i
for (i=0;i<nResps;i+=1) // remove xLocs of responses that rise BEFORE stimulus onset, i.e. half peak is detected ebfore stimulus onset at 50 ms
	if (TtoHalfPeak[i]<50)
		TtoHalfPeak[i] = NaN
	endif
endfor
TtoHalfPeak-=50 // gets rid of 50 ms of trace before stim onset in RespSnips

variable nStimReps = dimsize(TtoHalfPeak, 0)
variable j

make/o/n=(1) TtoHalfPeak_mean,TtoHalfPeak_SD,TtoHalfPeak_Var

wavestats/q TtoHalfPeak
TtoHalfPeak_mean = V_avg
TtoHalfPeak_SD = v_SDev
TtoHalfPeak_Var = v_sdev^2

//same for decon wave

wave HalfPeak_Xlocs_Decon

duplicate/o HalfPeak_Xlocs_Decon, TtoHalfPeak_decon
for (i=0;i<nResps;i+=1) // remove xLocs of responses that rise BEFORE stimulus onset, i.e. half peak is detected ebfore stimulus onset at 50 ms
	if (TtoHalfPeak_decon[i]<50)
		TtoHalfPeak_decon[i] = NaN
	endif
endfor
TtoHalfPeak_decon-=50 // gets rid of 50 ms of trace before stim onset in RespSnips

make/o/n=(1) TtoHalfPeak_mean_decon,TtoHalfPeak_SD_decon,TtoHalfPeak_Var_decon

wavestats/q TtoHalfPeak_decon
TtoHalfPeak_mean_decon = V_avg
TtoHalfPeak_SD_decon = v_SDev
TtoHalfPeak_Var_decon = v_sdev^2

end