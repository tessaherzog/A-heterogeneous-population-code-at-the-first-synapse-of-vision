#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// Calculate paired pulse ratio
// amplitude peak 2 / amplitude peak 1

Function CalcPairedPulseRatio()
findP2AmpOnFit()
CalcPeak2TrueAmp()
wave RespSnips_decon
displayPeakValues(RespSnips_decon)
CalcPPratio()
wave PPRatios_mean, PPRatios_SD, PPRatios_mean_noL0, PPRatios_SD_noL0
DisplayPPratios()

end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
// 1) Find amplitude of second peak on the fit.
// For each response pair, normalise the template fit to the amplitude of peak 1.
// Then, for each peak 2 response, find the amplitude on the fit at the same xloc. 

Function findP2AmpOnFit()
wave Peak1_Amps, Peak1_xLocs, Peak2_xLocs
wave fit_FinalResp_nrm

variable nStimReps = dimsize(Peak1_Amps,0)
variable nStimConds = dimsize(Peak1_Amps,1)
variable i, j

make/o/n=(nStimReps,nStimConds) Peak2_Ampsonfit
for (i=0;i<nStimConds;i+=1)
	for (j=0;j<nStimReps;j+=1)
		duplicate/o fit_FinalResp_nrm, normFitTemp
		normFitTemp*=Peak1_Amps[j][i] // scale the fit to the amplitude of peak 1
		Peak2_Ampsonfit[j][i] = normFitTemp[x2pnt(normFitTemp,Peak2_xLocs[j][i])]
		killwaves normFitTemp
	endfor
endfor

end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 2) Calculate true amp of 2nd peak (peak2_Amp - Peak2_AmpsonFit)

Function CalcPeak2TrueAmp()
wave Peak2_Amps, Peak2_AmpsOnFit

duplicate/o Peak2_Amps, Peak2_AmpsTrue
Peak2_AmpsTrue-=Peak2_AmpsOnFit

// if Peak2 ampTrue is less than 0, make = 0, as values < 0 give -ve PPratio value. 

//variable nConds = dimsize(Peak2_Amps,1)
//variable nStimIts = dimsize(Peak2_Amps,0)
//variable i, j
//
//for (i=0;i<nConds;i+=1)
//	for (j=0;j<nStimIts;j+=1)
//		if (Peak2_AmpsTrue[j][i] < 0)
//			Peak2_AmpsTrue[j][i] = 0
//		endif
//	endfor
//endfor

end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 3) Display peak1, peak2 and peak2onFit values on snippets

Function displayPeakValues(RespSnips_decon)
wave RespSnips_decon

wave Peak1_Amps, Peak1_xLocs, Peak2_Amps, Peak2_AmpsonFit, Peak2_xLocs
variable snipLen = dimsize(RespSnips_decon, 0)
variable nStimReps = dimsize(RespSnips_decon,1)
variable nStimConds = dimsize(RespSnips_decon,2)
variable i, j

for (i=0;i<nStimConds;i+=1)
	display/k=1 RespSnips_Decon[][0][i]
	appendtograph Peak1_Amps[][i] vs Peak1_xLocs[][i]
	appendtograph Peak2_Amps[][i] vs Peak2_xLocs[][i]
	appendtograph Peak2_AmpsonFit[][i] vs Peak2_xLocs[][i]
	for (j=1;j<nStimReps;j+=1)
		appendtograph RespSnips_decon[][j][i]
		ModifyGraph rgb=(0,0,0)
		ModifyGraph mode(Peak1_Amps)=2,rgb(Peak1_Amps)=(65535,0,0),lsize(Peak1_Amps)=4,mode(Peak2_Amps)=2,lsize(Peak2_Amps)=4,rgb(Peak2_Amps)=(0,0,65535),mode(Peak2_AmpsonFit)=2,lsize(Peak2_AmpsonFit)=4,rgb(Peak2_AmpsonFit)=(26205,52428,1)
	endfor
endfor

end


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 4) Generate Paired Pulse ratios (true amp of second peak/amp of first peak)

Function CalcPPratio()
wave Peak2_AmpsTrue, Peak1_Amps

variable nStimReps = dimsize(Peak1_Amps,0)
variable nStimConds = dimsize(Peak1_Amps,1)
variable i, j

duplicate/o Peak2_ampsTrue, PPratios

for (i=0;i<nStimConds;i+=1)
	for (j=0;j<nStimReps;j+=1)
		if (Peak1_Amps[j][i]>0)
			PPratios[j][i]/=Peak1_Amps[j][i] // if P1 Amp >0, divide by P2 true amp, if P1 amp <0 PP ratio = P2 true amp
		else
			PPratios[j][i] = NaN
		endif
	endfor
endfor
			
// calculate mean and SD PPratios
make/o/n=(nStimConds) PPratios_mean, PPratios_SD

for (i=0;i<nStimConds;i+=1)
	duplicate/o/r=[][i] PPratios, tempPPR
	wavestats/q tempPPR
	PPratios_mean[i] = v_avg
	PPratios_SD[i] = v_sdev
endfor
killwaves tempPPR

end

/////////////////////////////////////////////////////////////////////////////////////////////

Function DisplayPPratios()
wave PPRatios_Mean, PPRatios_SD
wave stimConds

display/k=1  PPRatios_Mean vs stimconds
ModifyGraph mode=4,marker=19
ModifyGraph rgb=(0,0,0);DelayUpdate
ErrorBars PPRatios_Mean SHADE= {0,0,(0,0,0,0),(0,0,0,0)},wave=(PPRatios_SD,PPRatios_SD)
ErrorBars PPRatios_Mean SHADE= {0,0,(0,0,0,0),(0,0,0,0)},wave=(PPRatios_SD,PPRatios_SD)
Label left "Paired pulse ratio (Amp2/Amp1)";DelayUpdate
Label bottom "Interstimulus interval (ms)";DelayUpdate
ModifyGraph lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
SetAxis/A/N=1 left;DelayUpdate
SetAxis bottom 0,*
SetDrawEnv xcoord= bottom,ycoord= left,dash= 1;DelayUpdate
DrawLine 0,1,100,1
end