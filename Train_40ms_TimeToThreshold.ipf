#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

// measure time to threshold for train off step responses

Function TimeToThreshold_Train40ms(trace_decon, SnipMat, Snips_MaxAmp, Snips_MaxAmpXlocs)
wave trace_decon, SnipMat, Snips_MaxAmp, Snips_MaxAmpXlocs

// TimeToThreshold_Train40ms(trace_decon, RespSnips_Decon, RespPeak_Amps_Decon, RespPeak_xLocs_Decon)

// get mean and SD of glutamate release during constant light
// i.e. during 2 - 4 s at start and 116 and 118 s at end

duplicate/o/r=[2000+100,4000] trace_decon, baseline_strt
duplicate/o/r=[55000+100,57000] trace_decon, baseline_end
concatenate/np=0 {baseline_strt, baseline_end}, baselines
wavestats/q baselines

make/o/n=(1) Trace_Decon_Baseline_mean = v_avg
make/o/n=(1) Trace_Decon_Baseline_SD = v_sdev
make/o/n=(1) Trace_Decon_Baseline_Threshold = v_avg + (2*v_sdev)

variable Threshold = Trace_Decon_Baseline_Threshold[0] // set threshold, i.e. mean baseline + 2 SD
print "threshold = " + num2str(threshold)

killwaves baseline_strt, baseline_end, baselines

// find when response reaches threshold
duplicate/o Snips_MaxAmpXlocs, Snips_MaxAmpXlocs_s
Snips_MaxAmpXlocs_s/=1000

variable Threshpeaktime1 = NaN
variable Threshpeakvalue1 = NaN
variable threshpeaktime2 = NaN
variable threshpeakvalue2 = NaN
variable maxsteps = 500
variable i, j, ss
variable nStimReps = dimsize(SnipMat, 1)

make/o/n=(nStimReps) ThreshPeak_Xlocs // make array to save xLoc of half peak.
	for (j=0;j<nStimReps;j+=1) // loop over rows (Stim reps)
		duplicate/o/r=[][j] SnipMat, tempSnip
		Redimension/N=-1 tempSnip
		// if response already excluded, NaN out in threshold matrix
		//if (SnipMat[0][j][i] == NaN)
		if (numtype(tempSnip[0]) == 2)
			threshpeaktime1 = NaN // include so that is response never goes below half peak, value remains as NaN
     		threshpeakvalue1 = NaN
  	   		threshpeaktime2 = NaN
     		threshpeakvalue2 = NaN
     		print "response " + num2str(j) + " of condition " + num2str(i) + " already excluded"
     		
		// If response peak is below threshold, don't include response
		//elseif (tempSnip[Snips_MaxAmpXlocs[j]][j]<threshold)
		elseif (Snips_MaxAmp[j] < threshold)
			threshpeaktime1 = NaN // include so that is response never goes below half peak, value remains as NaN
	     	threshpeakvalue1 = NaN
    	 	threshpeaktime2 = NaN
    	 	threshpeakvalue2 = NaN
     		print "response " + num2str(j) + " of condition " + num2str(i) + " as response never reaches threshold"
		
		// if response never goes below threshold, don't include response
		elseif (wavemin(tempSnip)>threshold)
			threshpeaktime1 = NaN // include so that is response never goes below half peak, value remains as NaN
     		threshpeakvalue1 = NaN
  	   		threshpeaktime2 = NaN
     		threshpeakvalue2 = NaN
     		print "response " + num2str(j) + " of condition " + num2str(i) + " as response never goes below threshold"

		// if peak response is above threshold, include
		//elseif (SnipMat[Snips_MaxAmpXlocs[j]][j]>threshold)	
		elseif (Snips_MaxAmp[j] > threshold)
//			duplicate/o/r=[][j][i] SnipMat, tempSnip
//			Redimension/N=-1 tempSnip
			variable peaktime = (Snips_MaxAmpXlocs[j][i])
			variable peakvalue = tempSnip[peaktime]
			for (ss=0;ss<maxsteps;ss+=1) //(//do)
				if (tempSnip[peaktime-ss]<threshold)
   	  	  			threshpeaktime1 = peaktime-ss+1 // these are just above half
     	  			threshpeakvalue1 = tempSnip[threshpeaktime1]
     	  			threshpeaktime2 = peaktime-ss // these are just below half
     	  			threshpeakvalue2 = tempSnip[threshpeaktime2]
     	  			ss=maxsteps // so that it leave the loop
 	  			endif
   			endfor
   			print "response " + num2str(j) + " of condition " + num2str(i) + " included"
   		endif
		variable diffinamp = threshpeakvalue1-threshpeakvalue2
	//	print "Above thresh pnt = " + num2str(threshpeakvalue1)
	//	print "below thresh pnt = " + num2str(threshpeakvalue2)
	//	print "difference in amps = " + num2str(diffinamp)
		variable difffromP2tothresh = threshold - threshpeakvalue2
	//	print "threshold = " + num2str(threshold)
	//	print "which is " + num2str(difffromP2tothresh) + " above belowthresh pnt"
		variable thresh_withinrange = difffromP2tothresh/diffinamp
	//	print "that is, " + num2str(thresh_withinrange) + " of the range between the two thresh pnts"
		variable realxvalue = threshpeaktime2 + thresh_withinrange
	//	print "so, real xloc value where response crosses threshold is " + num2str(realxvalue)
		ThreshPeak_Xlocs[j] = realxvalue
	endfor

killwaves tempsnip

// remove xlocs of reponses that occur BEFORE stimulus onset, i.e. threshold is reached before stim onset (due to noise). 
variable counter = 0

	for (i=0;i<nStimReps;i+=1)
		if (ThreshPeak_Xlocs[i]<55)
			ThreshPeak_Xlocs[i] = NaN
			counter+=1
			print "response " + num2str(j) + " of condition " + num2str(i) + " excluded as detected before stim onset"
		endif
		if (ThreshPeak_Xlocs[i]>120)
			ThreshPeak_Xlocs[i] = NaN
			counter+=1
			print "response " + num2str(j) + " of condition " + num2str(i) + " excluded as detected > 100 ms after stim onset"
		endif
	endfor

//print num2str(counter) + " threshold xlocs detected before stimulus onset, removed from temporal jitter analysis for " + nameofwave(trace_decon)


// save xlocs and amps for when response crosses threshold
string Threshxlocname = nameofwave(trace_decon) + "_Amp_Thresh_xloc"
duplicate/o ThreshPeak_Xlocs, $Threshxlocname

string Thresxlocname_s = nameofwave(trace_decon) + "_Amp_Thresh_xloc_s"
duplicate/o ThreshPeak_Xlocs, xlocinS
xlocinS/=1000
duplicate/o xlocinS, $Thresxlocname_s
killwaves xlocinS

string ThreshAmpName = nameofwave(trace_decon) + "_Amp_Thresh"
make/o/n=(dimsize(ThreshPeak_Xlocs,0)) $ThreshAmpName = threshold


// ThreshPeak_xlocs is in pnts within repsponse snippet
// convert xlocs to time (ms) after stimulus onset, to get time to threshold

duplicate/o ThreshPeak_Xlocs, TimeToMSDThresh
TimeToMSDThresh-=50

// calculate mean, SD and var of time to threshold for each condition
make/o/n=(1) TimeToThresh_Mean
make/o/n=(1) TimeToThresh_SD
make/o/n=(1) TimeToThresh_Var

wavestats/q TimeToMSDThresh
TimeToThresh_Mean[0] = v_avg
TimeToThresh_SD[0] = v_sdev
TimeToThresh_Var[0] = v_sdev^2

string TToThreshName = nameofwave(trace_decon) + "_TimeToThresh"
string TToThreshMeanName = nameofwave(trace_decon) + "_TimeToThresh_mean"
string TToThreshSDName = nameofwave(trace_decon) + "_TimeToThresh_SD"
string TToThreshVarName = nameofwave(trace_decon) + "_TimeToThresh_Var"

duplicate/o TimeToMSDThresh, $TToThreshName
duplicate/o TimeToThresh_Mean, $TToThreshMeanName
duplicate/o TimeToThresh_SD, $TToThreshSDName
duplicate/o TimeToThresh_Var, $TToThreshVarName

// save threshold value
string threshvalname = nameofwave(trace_decon) + "_Threshold"
make/o/n=(1) $threshvalname = threshold

// check thresholding peak detection 
	display/k=1 snipMat[][0]
	for (i=1;i<nStimReps;i+=1)
		appendtograph SnipMat[][i]
	endfor
	modifygraph rgb=(0,0,0,32768)
	// add threshold as dashed line
	SetDrawEnv xcoord= bottom,ycoord= left,dash= 1;DelayUpdate 
	DrawLine 0,threshold,0.5,threshold
	
	// add threshold amps
	appendtograph $ThreshAmpName[][j] vs $Thresxlocname_s[][j]
	ModifyGraph mode($ThreshAmpName)=3,marker($ThreshAmpName)=19,rgb($ThreshAmpName)=(16385,16388,65535)
	variable baselinemean = Trace_Decon_Baseline_mean[0]
	SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65535,0,0),dash= 1;DelayUpdate
	DrawLine 0,baselinemean,0.5,baselinemean

	SetAxis/A/N=1 left;DelayUpdate
	ModifyGraph lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
	Label left "Glutamate release";DelayUpdate
	Label bottom "Time (s)"
	variable meanTTthresh = TimeToThresh_Mean[0]
	variable SDTTthresh = TimeToThresh_SD[0]

	DrawText 0.545034642032333,0.158653846153846, "Condition " + num2str(j) + "\rTime to threshold = " + num2str(meanTTthresh) + " ± " + num2str(SDTTthresh) + " ms"


killwaves ThreshPeak_Xlocs, TimeToMSDThresh, TimeToThresh_Mean, TimeToThresh_SD, TimeToThresh_Var

end

Function GetAmpsFromThresholdedSnips(TimeToThreshMat, PeakAmpsMat) // use GetAmpsFromThresholdedSnips(Trace_Decon_TimeToThresh, RespPeakAmps)
wave TimeToThreshMat, PeakAmpsMat

duplicate/o PeakAmpsMat, PeakAmpsMat_TimeThreshed

variable i, j
variable nStimReps = dimsize(TimeToThreshMat,0)
variable nStimConds = dimsize(TimeToThreshMat,1)
for (i=0;i<nStimConds;i+=1)
	for (j=0;j<nStimReps;j+=1)
		if (numtype(TimeToThreshMat[j][i]) == 2)
			PeakAmpsMat_TimeThreshed[j][i] = NaN
		endif
	endfor
endfor

// calculate mean, SD, var and CV of amplitudes
make/o/n=(nStimConds) Ave , SD, Var, CV

for (i=0;i<nStimConds;i+=1)
	duplicate/o/r=[][i] PeakAmpsMat_TimeThreshed, temp
	wavestats/q temp
	Ave[i] = v_avg
	SD[i] = v_sdev
	Var[i] = v_sdev^2
	CV[i] = v_sdev/v_avg
	killwaves temp
endfor

// rename matrix, avg, SD, Var and CV waves
string ThreshAmpMat = nameofwave(PeakAmpsMat) + "_TimeThreshed"
string ThreshAmpMat_mean = nameofwave(PeakAmpsMat) + "_TimeThreshed_mean"
string ThreshAmpMat_SD = nameofwave(PeakAmpsMat) + "_TimeThreshed_SD"
string ThreshAmpMat_Var = nameofwave(PeakAmpsMat) + "_TimeThreshed_Var"
string ThreshAmpMat_CV = nameofwave(PeakAmpsMat) + "_TimeThreshed_CV"
duplicate/o PeakAmpsMat_TimeThreshed, $ThreshAmpMat
duplicate/o Ave, $ThreshAmpMat_mean
duplicate/o SD, $ThreshAmpMat_SD
duplicate/o Var, $ThreshAmpMat_Var
duplicate/o CV, $ThreshAmpMat_CV
killwaves PeakAmpsMat_TimeThreshed, Ave, SD, Var, CV
end