#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

// measure time to threshold for mixed off step responses

Function TimeToThreshold_VarCont(SnipMat, AmpMat, AmpxlocMat)
// use TimeToThreshold_VarCont(D_RespSnips_z, D_TransPeak_amp, D_TransPeak_xloc)
wave SnipMat, AmpMat, AmpxlocMat

// get mean and SD of glutamate release during constant light
// i.e. during 2 - 4 s at start and 116 and 118 s at end
variable nStimReps = dimsize(SnipMat, 1)

duplicate/o/r=[100,500][][] SnipMat, MidLight_strt
duplicate/o/r=[1100,][][] SnipMat, MidLight_end
concatenate/np=0 {MidLight_strt, MidLight_end}, MidLight_resps
wavestats/q MidLight_resps
string Snips_MeanLight_mean = nameofwave(SnipMat) + "_MeanLight_mean"
string Snips_MeanLight_SD = nameofwave(SnipMat) + "_MeanLight_SD"
string Snips_ThreshNeg = nameofwave(SnipMat) + "_Threshold_Neg"
string Snips_ThreshPos = nameofwave(SnipMat) + "_Threshold_Pos"

make/o/n=(1) $Snips_MeanLight_mean = v_avg
make/o/n=(1) $Snips_MeanLight_SD = v_sdev
make/o/n=(nStimReps) $Snips_ThreshNeg = v_avg + (1*v_sdev)
make/o/n=(nStimReps) $Snips_ThreshPos = v_avg - (1*v_sdev)

variable MeanLight_MeanRelease = v_avg

variable Threshold_Neg = v_avg + (1*v_sdev) // set threshold, i.e. mean baseline + 2 SD
print "threshold for neg contrast = " + num2str(Threshold_Neg)

variable Threshold_Pos = v_avg - (1*v_sdev) // set threshold, i.e. mean baseline + 2 SD
print "threshold for pos contrast = " + num2str(Threshold_Pos)

killwaves MidLight_strt, MidLight_end, MidLight_resps

// find when response reaches threshold
variable Threshpeaktime1 = NaN
variable Threshpeakvalue1 = NaN
variable threshpeaktime2 = NaN
variable threshpeakvalue2 = NaN
variable maxsteps = 500
variable i, j, ss

make/o/n=(nStimReps) ThreshPeak_100Neg_Xlocs // make array to save xLoc of when response reaches threshold.
	for (j=0;j<nStimReps;j+=1) // loop over rows (Stim reps)
		duplicate/o/r=[][j][0] SnipMat, tempSnip // duplicate responses from 100% neg condition (layer 0)
		Redimension/N=-1 tempSnip
     		
		// If response peak is always below threshold, don't include response
		if (wavemax(tempSnip) < Threshold_Neg)
			threshpeaktime1 = NaN // include so that is response never goes below half peak, value remains as NaN
	     	threshpeakvalue1 = NaN
    	 	threshpeaktime2 = NaN
    	 	threshpeakvalue2 = NaN
     		print "response " + num2str(j) + " of -100% contrast not included as response never reaches threshold"
		
		// if response never goes below threshold, don't include response
		elseif (wavemin(tempSnip) > Threshold_Neg)
			threshpeaktime1 = NaN // include so that is response never goes below half peak, value remains as NaN
     		threshpeakvalue1 = NaN
  	   		threshpeaktime2 = NaN
     		threshpeakvalue2 = NaN
     		print "response " + num2str(j) + " of -100% contrat not included as response never goes below threshold"

		// if peak response is above threshold, include
		elseif (wavemax(tempSnip) > Threshold_Neg)
			variable peaktime = (AmpxlocMat[j][0]*1000)
			variable peakvalue = tempSnip[peaktime]
			for (ss=0;ss<maxsteps;ss+=1) //(//do)
				if (tempSnip[peaktime-ss]<Threshold_Neg)
   	  	  			threshpeaktime1 = peaktime-ss+1 // these are just above half
     	  			threshpeakvalue1 = tempSnip[threshpeaktime1]
     	  			threshpeaktime2 = peaktime-ss // these are just below half
     	  			threshpeakvalue2 = tempSnip[threshpeaktime2]
     	  			ss=maxsteps // so that it leave the loop
 	  			endif
   			endfor
   			print "response " + num2str(j) + " of -100% contrast included"
   		endif
		variable diffinamp = threshpeakvalue1-threshpeakvalue2
	//	print "Above thresh pnt = " + num2str(threshpeakvalue1)
	//	print "below thresh pnt = " + num2str(threshpeakvalue2)
	//	print "difference in amps = " + num2str(diffinamp)
		variable difffromP2tothresh = Threshold_Neg - threshpeakvalue2
	//	print "threshold = " + num2str(threshold)
	//	print "which is " + num2str(difffromP2tothresh) + " above belowthresh pnt"
		variable thresh_withinrange = difffromP2tothresh/diffinamp
	//	print "that is, " + num2str(thresh_withinrange) + " of the range between the two thresh pnts"
		variable realxvalue = threshpeaktime2 + thresh_withinrange
	//	print "so, real xloc value where response crosses threshold is " + num2str(realxvalue)
		ThreshPeak_100Neg_Xlocs[j] = realxvalue
	endfor

killwaves tempsnip

// remove xlocs of reponses that occur BEFORE stimulus onset, i.e. threshold is reached before stim onset (due to noise). 
for (i=0;i<nStimReps;i+=1)
	if (ThreshPeak_100Neg_Xlocs[i]<500)
		ThreshPeak_100Neg_Xlocs[i] = NaN
		print "response " + num2str(i) + " of -100% condition excluded as detected before stim onset"
	endif
	if (ThreshPeak_100Neg_Xlocs[i]>600)
		ThreshPeak_100Neg_Xlocs[i] = NaN
		print "response " + num2str(i) + " of -100% condition excluded as detected > 100 ms after stim onset"
	endif
endfor

// same again for positive contrast responses:
Threshold_Pos*=-1
make/o/n=(nStimReps) ThreshPeak_100Pos_Xlocs // make array to save xLoc of when response reaches threshold.
	for (j=0;j<nStimReps;j+=1) // loop over rows (Stim reps)
		duplicate/o/r=[][j][9] SnipMat, tempSnip // duplicate responses from 100% neg condition (layer 0)
		Redimension/N=-1 tempSnip
		tempsnip*=-1
     		
		// If response peak is always below threshold, don't include response
		if (wavemax(tempSnip) < Threshold_Pos)
			threshpeaktime1 = NaN // include so that is response never goes below half peak, value remains as NaN
	     	threshpeakvalue1 = NaN
    	 	threshpeaktime2 = NaN
    	 	threshpeakvalue2 = NaN
     		print "response " + num2str(j) + " of +100% contrast not included as response never reaches threshold"
		
		// if response never goes below threshold, don't include response
		elseif (wavemin(tempSnip) > Threshold_Pos)
			threshpeaktime1 = NaN // include so that is response never goes below half peak, value remains as NaN
     		threshpeakvalue1 = NaN
  	   		threshpeaktime2 = NaN
     		threshpeakvalue2 = NaN
     		print "response " + num2str(j) + " of +100% contrat not included as response never goes below threshold"

		// if peak response is above threshold, include
		// rewrite this bit so that peak detection is based on from stimulus onset to when response crosses the threshold
		elseif (wavemax(tempSnip) > Threshold_Pos)
			//peaktime = (AmpxlocMat[j][9]*1000)
			//peakvalue = tempSnip[peaktime]
			for (ss=0;ss<maxsteps;ss+=1) //(//do)
				if (tempSnip[500+ss]>Threshold_Pos)
   	  	  			threshpeaktime1 = 500+ss // these are just above half
     	  			threshpeakvalue1 = tempSnip[threshpeaktime1]
     	  			threshpeaktime2 = 500+ss-1 // these are just below half
     	  			threshpeakvalue2 = tempSnip[threshpeaktime2]
     	  			ss=maxsteps // so that it leave the loop
 	  			endif
   			endfor
   			print "response " + num2str(j) + " of +100% contrast included"
   		endif
		diffinamp = threshpeakvalue1-threshpeakvalue2
	//	print "Above thresh pnt = " + num2str(threshpeakvalue1)
	//	print "below thresh pnt = " + num2str(threshpeakvalue2)
	//	print "difference in amps = " + num2str(diffinamp)
		difffromP2tothresh = Threshold_Pos - threshpeakvalue2
	//	print "threshold = " + num2str(threshold)
	//	print "which is " + num2str(difffromP2tothresh) + " above belowthresh pnt"
		thresh_withinrange = difffromP2tothresh/diffinamp
	//	print "that is, " + num2str(thresh_withinrange) + " of the range between the two thresh pnts"
		realxvalue = threshpeaktime2 + thresh_withinrange
	//	print "so, real xloc value where response crosses threshold is " + num2str(realxvalue)
		ThreshPeak_100Pos_Xlocs[j] = realxvalue
	endfor

killwaves tempsnip
Threshold_Pos*=-1

// remove xlocs of reponses that occur BEFORE stimulus onset, i.e. threshold is reached before stim onset (due to noise). 
for (i=0;i<nStimReps;i+=1)
	if (ThreshPeak_100Pos_Xlocs[i]<500)
		ThreshPeak_100Pos_Xlocs[i] = NaN
		print "response " + num2str(i) + " of +100% condition excluded as detected before stim onset"
	endif
	if (ThreshPeak_100Pos_Xlocs[i]>700)
		ThreshPeak_100Pos_Xlocs[i] = NaN
		print "response " + num2str(i) + " of +100% condition excluded as detected > 150 ms after stim onset"
	endif
endfor

// xlocs is in points (ms) and xlocs_s is in s
duplicate/o ThreshPeak_100Neg_Xlocs, ThreshPeak_100Neg_Xlocs_s
duplicate/o ThreshPeak_100Pos_Xlocs, ThreshPeak_100Pos_Xlocs_s
ThreshPeak_100Neg_Xlocs_s/=1000
ThreshPeak_100Pos_Xlocs_s/=1000

// Get time to thresold from xlocs mat
duplicate/o ThreshPeak_100Neg_Xlocs, TimeToThresh_100Neg
duplicate/o ThreshPeak_100Pos_Xlocs, TimeToThresh_100Pos
TimeToThresh_100Neg-=500
TimeToThresh_100Pos-=500

string TimeToThresh_Neg_name = nameofwave(SnipMat) + "_TimeToThresh_neg"
string TimeToThresh_Negmean_name = nameofwave(SnipMat) + "_TimeToThresh_neg_mean"
string TimeToThresh_NegSD_name = nameofwave(SnipMat) + "_TimeToThresh_neg_SD"
wavestats/q TimeToThresh_100Neg
make/o/n=(1) $TimeToThresh_Negmean_name = v_avg
make/o/n=(1) $TimeToThresh_NegSD_name = v_sdev
duplicate/o TimeToThresh_100Neg, $TimeToThresh_Neg_name
killwaves TimeToThresh_100Neg
variable TTThresh_mean_neg = v_avg
variable TTThresh_SD_neg = v_sdev

string TimeToThresh_pos_name = nameofwave(SnipMat) + "_TimeToThresh_pos"
string TimeToThresh_posmean_name = nameofwave(SnipMat) + "_TimeToThresh_pos_mean"
string TimeToThresh_PosSD_name = nameofwave(SnipMat) + "_TimeToThresh_pos_SD"
wavestats/q TimeToThresh_100Pos
make/o/n=(1) $TimeToThresh_Posmean_name = v_avg
make/o/n=(1) $TimeToThresh_PosSD_name = v_sdev
duplicate/o TimeToThresh_100Pos, $TimeToThresh_Pos_name
killwaves TimeToThresh_100Pos
variable TTThresh_mean_pos = v_avg
variable TTThresh_SD_pos = v_sdev

// rename thresh xloc and xloc_s waves 
string Threshxlocname_neg = nameofwave(SnipMat) + "_ThreshNeg_Amp_xloc"
duplicate/o ThreshPeak_100Neg_Xlocs, $Threshxlocname_neg
string ThreshxlocSname_neg = nameofwave(SnipMat) + "_ThreshNeg_Amp_xloc_s"
duplicate/o ThreshPeak_100Neg_Xlocs_s, $ThreshxlocSname_neg

string Threshxlocname_pos = nameofwave(SnipMat) + "_ThreshPos_Amp_xloc"
duplicate/o ThreshPeak_100Pos_Xlocs, $Threshxlocname_Pos
string ThreshxlocSname_Pos = nameofwave(SnipMat) + "_ThreshPos_Amp_xloc_s"
duplicate/o ThreshPeak_100Pos_Xlocs_s, $ThreshxlocSname_pos

killwaves ThreshPeak_100Neg_Xlocs, ThreshPeak_100Neg_Xlocs_s, ThreshPeak_100Pos_Xlocs, ThreshPeak_100Pos_Xlocs_s

// check thresholding peak detection by plotting response snippets and detected threshold crossing.
display/k=1 snipMat[][0][0]
for (i=1;i<nStimReps;i+=1)
	appendtograph SnipMat[][i][0]
endfor
modifygraph rgb=(0,0,0,32768)
// add threshold as dashed line
SetDrawEnv xcoord= bottom,ycoord= left,dash= 1;DelayUpdate 
DrawLine 0,Threshold_Neg,1.5,Threshold_Neg
// add threshold amps
appendtograph $Snips_ThreshNeg[] vs $ThreshxlocSname_neg[]
ModifyGraph mode($Snips_ThreshNeg)=3,marker($Snips_ThreshNeg)=19,rgb($Snips_ThreshNeg)=(16385,16388,65535)
// add baseline as dashed line
SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65535,0,0),dash= 1;DelayUpdate
DrawLine 0,MeanLight_MeanRelease,1.5,MeanLight_MeanRelease
// modify axes
SetAxis/A/N=1 left;DelayUpdate
ModifyGraph lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
Label left "Glutamate release (F's-1)";DelayUpdate
Label bottom "Time (s)"
// add label of mean time to threshold
DrawText 0.545034642032333,0.158653846153846, "100% neg contrast\rTime to threshold = " + num2str(TTThresh_mean_neg) + " ± " + num2str(TTThresh_SD_neg) + " ms"

// same for positive contrast
display/k=1 snipMat[][0][9]
for (i=1;i<nStimReps;i+=1)
	appendtograph SnipMat[][i][9]
endfor
modifygraph rgb=(0,0,0,32768)
// add threshold as dashed line
SetDrawEnv xcoord= bottom,ycoord= left,dash= 1;DelayUpdate 
DrawLine 0,Threshold_Pos,1.5,Threshold_Pos
// add threshold amps
appendtograph $Snips_ThreshPos[] vs $ThreshxlocSname_Pos[]
ModifyGraph mode($Snips_ThreshPos)=3,marker($Snips_ThreshPos)=19,rgb($Snips_ThreshPos)=(16385,16388,65535)
// add baseline as dashed line
SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65535,0,0),dash= 1;DelayUpdate
DrawLine 0,MeanLight_MeanRelease,1.5,MeanLight_MeanRelease
// modify axes
SetAxis/A/N=1 left;DelayUpdate
ModifyGraph lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
Label left "Glutamate release (F's-1)";DelayUpdate
Label bottom "Time (s)"
// add label of mean time to threshold

DrawText 0.545034642032333,0.158653846153846, "100% pos contrast\rTime to threshold = " + num2str(TTThresh_mean_pos) + " ± " + num2str(TTThresh_SD_pos) + " ms"

end

Function GetAmpsFromThresholdedSnips(SnipMat, TimeToThresh_Neg, TimeToThresh_Pos, PeakAmpsMat) 
// use GetAmpsFromThresholdedSnips(D_RespSnips_Z, D_RespSnips_Z_TimeToThresh_neg, D_RespSnips_Z_TimeToThresh_pos, D_TransPeak_amp)
wave SnipMat, TimeToThresh_Neg, TimeToThresh_Pos, PeakAmpsMat

duplicate/o/r=[][0] PeakAmpsMat, PeakAmpsMat_Neg
redimension/n=-1 PeakAmpsMat_Neg
duplicate/o/r=[][9] PeakAmpsMat, PeakAmpsMat_Pos
redimension/n=-1 PeakAmpsMat_Pos

// NaN amplitude if NaNed in timing wave (i.e. excluded as doesn't reach threshold within time window)
variable i
variable nStimReps = dimsize(TimeToThresh_Neg,0)
for (i=0;i<nStimReps;i+=1) // for -100% contrast responses
	if (numtype(TimeToThresh_Neg[i]) == 2)
		PeakAmpsMat_Neg[i] = NaN
	endif
endfor
for (i=0;i<nStimReps;i+=1) // for +100% contrast responses
	if (numtype(TimeToThresh_Pos[i]) == 2)
		PeakAmpsMat_Pos[i] = NaN
	endif
endfor

// calculate mean, SD, var and CV of amplitudes
string Amps_Neg_name = nameofwave(SnipMat) + "_ThreshNeg_RespAmp"
string Amps_Neg_name_mean = nameofwave(SnipMat) + "_ThreshNeg_RespAmp_mean"
string Amps_Neg_name_SD = nameofwave(SnipMat) + "_ThreshNeg_RespAmp_SD"
string Amps_Neg_name_Var = nameofwave(SnipMat) + "_ThreshNeg_RespAmp_Var"
string Amps_Neg_name_CV = nameofwave(SnipMat) + "_ThreshNeg_RespAmp_CV"

wavestats/q PeakAmpsMat_Neg
make/o/n=(1) $Amps_Neg_name_mean = v_avg
make/o/n=(1) $Amps_Neg_name_SD = v_sdev
make/o/n=(1) $Amps_Neg_name_Var = v_sdev^2
make/o/n=(1) $Amps_Neg_name_CV = v_sdev/v_avg
duplicate/o PeakAmpsMat_Neg, $Amps_Neg_name
killwaves PeakAmpsMat_Neg

string Amps_Pos_name = nameofwave(SnipMat) + "_ThreshPos_RespAmp"
string Amps_Pos_name_mean = nameofwave(SnipMat) + "_ThreshPos_RespAmp_mean"
string Amps_Pos_name_SD = nameofwave(SnipMat) + "_ThreshPos_RespAmp_SD"
string Amps_Pos_name_Var = nameofwave(SnipMat) + "_ThreshPos_RespAmp_Var"
string Amps_Pos_name_CV = nameofwave(SnipMat) + "_ThreshPos_RespAmp_CV"

wavestats/q PeakAmpsMat_Pos
make/o/n=(1) $Amps_Pos_name_mean = v_avg
make/o/n=(1) $Amps_Pos_name_SD = v_sdev
make/o/n=(1) $Amps_Pos_name_Var = v_sdev^2
make/o/n=(1) $Amps_Pos_name_CV = v_sdev/v_avg
duplicate/o PeakAmpsMat_Pos, $Amps_Pos_name
killwaves PeakAmpsMat_Pos

end
