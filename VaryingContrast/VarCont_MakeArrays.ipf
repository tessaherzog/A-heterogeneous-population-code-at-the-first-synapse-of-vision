#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// For stimulus protocol: Varying contrast steps
// Pull out response snippets
// Organise response snippets into matrices, layered by stim condition

// NOTE: Check winTime in PullSnips function!
// Window 500,700 does not include rebound portion of wave. 


Function VarCont_Matrix()

wave order						//from stimulus file (1D vector, the order the different stimulus conditions are delivered in)
wave  roiMatName				// Glutamte signal trace.
variable nPer = 10 					//number of repetitions of each stimulus type e.g 10
variable firstStimtoUse = 0  		//Reject the first x responses to account for adaption.
variable tracetype 				// 0 = S wave, 1 = decon for amps, 2 = decon for timing

StimTimesMatrix(order, nPer, firstStimtoUse) //rows are different stimuli types, and the columns are the times they occur

// create matrix of response snippets
wave stimTimesMat, trace, trace_decon	
pullSnips(stimTimesMat, trace, 0) 
pullSnips(stimTimesMat, trace_decon, 2)

// Plot response snippets
wave RespSnips, D_RespSnips
//PlotSnips(RespSnips, 0)
//PlotSnips(D_RespSnips, 2)

//Calculate mean responses per stimulus condition
CalcMeans(RespSnips, 0)
CalcMeans(D_RespSnips, 2)

//Plot mean responses per stimulus condition
wave RespMeans, RespMeans_SD, D_RespMeans, D_RespMeans_SD
//PlotRespMeans(RespMeans, RespMeans_SD, 0)
//PlotRespMeans(D_RespMeans, D_RespMeans_SD, 2)

//zeroRespSnips(RespSnipsMat)
wave RespSnipsMat, RespMeanMat
//ZcorrResps(RespSnips, RespMeans, 0)
//ZcorrResps(D_RespSnips, D_RespMeans, 2)
ZshiftResps(RespSnips, RespMeans, 0)
ZshiftResps(D_RespSnips, D_RespMeans, 2)

// make array of stimulus steps per condition for plotting
makeContSteps()

end
	
///////////////////////////////////	
// 1) Create matrix of stim times//
///////////////////////////////////

Function StimTimesMatrix(order, nPer, firstStimtoUse) //nPer is number of stimulus conditions
	wave order
	variable nPer
	variable firstStimtoUse
	
	variable nS = wavemax(order)+1 	// getting number of stimuli conditions. Highest integer in "order" is the no. of stimuli conditions.
	variable i,j
	
	variable nP = dimsize(order,0)	// getting total number of stimulus iterations. 
	make/o/n=(nS,nPer) stimTimesMat	// create matrix of stimulus condition and what time it occurs.
	make/o/n=(nS) onWhich=0
	for (i=0;i<nP;i+=1)
		if(i>firstStimtoUse)
			stimTimesMat[order[i]][onWhich[order[i]]] = 7.5 + i *1 //first number is how many seconds in when the dark flashes
			// start e.g. 4, and the last number is how frequently the dark flashes occue, e.g 0.4 is every 400 ms 
			onWhich[order[i]]+=1
		else
			stimTimesMat[order[i]][onWhich[order[i]]]=nan
			onWhich[order[i]]+=1
		endif	
	endfor
killwaves onWhich

StimTimesMat[4][0]=7.5 // missed out in matrix for some reason... 
end

////////////////////////////////////////////////////////////////////////
// 2) Organise responses into a matrix, layered by stimulus condition///
////////////////////////////////////////////////////////////////////////

function pullSnips(stimTimesMat, roiMatName, tracetype) //pulls out the responses to the each stim cond.
wave stimTimesMat, roiMatName
variable tracetype
	
wave RespSnipsMat
killwaves RespSnipsMat
variable winTime = 1.5		//snippet length in secs, make sure this doesn't run into the next cycle
variable counter



duplicate/o roiMatName, roiMat
variable nStimTypes = dimsize(stimTimesMat,0) // number of stim conditions
variable nPer = dimsize(stimTimesMat,1)		// number of itertions per condition
variable dt = deltax(roiMat)						//delta scaling
variable nROIs = dimsize(roiMat,1)				// number of traces in array
setscale/p x,0,dt, roiMat
variable i,j,k,l
variable len = (winTime)/dt + 1

for (i=0;i<nRois;i+=1) //loop over ROIs
make/o/n=(len,nPer,nStimTypes) RespSnipsMat		// makes matrix of responses, layered by stim type. 
	duplicate/o roiMat,singleROI
	Redimension/N=-1 roiMat
setscale/p x,0,dt, RespSnipsMat
	for (j=0;j<nStimTypes;j+=1)
		for (k=0;k<nPer;k+=1)
			if(numtype(stimTimesMat[j][k]) == 2)	
				RespSnipsMat[][k][j] = nan
			else
				RespSnipsMat[][k][j] = singleROI[x2pnt(RespSnipsMat,stimTimesMat[j][k])+p]
				Make/O/N = (dimsize(RespSnipsMat, 0)) roiMat =  RespSnipsMat[p][k][j]
				SetScale/P x, 0, dt, ""  roiMat
			endif
		endfor
	endfor
endfor

killwaves singleROI, roiMat	

if (tracetype == 0)
	duplicate/o RespSnipsMat, RespSnips
endif

if (tracetype == 2)
	duplicate/o RespSnipsMat, D_RespSnips
endif
killwaves RespSnipsMat

// create wave of stimulus conditions
make/o/n=(10) StimConds
StimConds[0]=-100
StimConds[1]=-50
StimConds[2]=-30
StimConds[3]=-20
StimConds[4]=-10
StimConds[5]=10
StimConds[6]=20
StimConds[7]=30
StimConds[8]=50
StimConds[9]=100			

end

////////////////////////////////////////////////////////////////////////
// 3) Plot response snippets////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

Function PlotSnips(w, tracetype) // use RespSnipsMat

wave w
variable tracetype
wave StimConds
variable i, j
variable nStimReps = dimsize(w,1) // number of stim repetitions
variable nStimTypes = dimsize(w,2) // number of stim conditions


// plot overlay of response snippets. New plot per stimulus condition. 
for (i=0;i<nStimTypes;i+=1)
	display /k=1 w [][0][i]
	for (j=1;j<nStimReps;j+=1)
		appendtograph w [][j][i]
	endfor
	if (tracetype == 0)
		Label left "Glutamate release (DF/F)";DelayUpdate
	endif
	if (tracetype == 2)	
		Label left "Glutamate release (F's\\S-1\\M)"
	endif
	Label bottom "Time (s)";DelayUpdate
	Modifygraph rgb = (0,0,0)
	ModifyGraph lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1}
	SetAxis/A/N=1 left
	string CondText
	CondText = "Contrast Step: "+num2str(stimConds[i])+"%"
	DrawText 0.567741935483871,0.163120567375887, CondText
endfor

end

////////////////////////////////////////////////////////////////////////
// 4) Compute mean +/- SD///////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

// Calculate mean response for each stimulus condition from RespSnips matrix

Function CalcMeans(w, tracetype) // use RespSnipsMat

wave w
variable tracetype
variable nP = Dimsize(w,0)
variable nReps = Dimsize(w,1)
variable nStimConds = Dimsize(w, 2)
make /o/n=(nP) Average = 0
make /o/n=(nP) SD = 0
variable counter
variable i
wave stimConds

wave RespMeanMat, RespMeanMat_SD
killwaves RespMeanMat, RespMeanMat_SD

for (i=0;i<nStimConds;i+=1)
	for (counter=0;counter<nP;counter+=1)
		make /o/n=(nReps) currentwave = w[counter][p][i]
		WaveStats/Q currentwave
		variable CurrentAverage = V_Avg
		variable currentSD = V_SDev
		Average[counter]=Currentaverage
		SD[counter]=CurrentSD
		SetScale/P x 0,0.001,"", Average, SD 
	endfor
	concatenate/np=1 {Average}, RespMeanMat
	concatenate/np=1 {SD}, RespMeanMat_SD
endfor
killwaves Average, SD, currentwave

if (tracetype == 0)
	duplicate/o RespMeanMat, RespMeans
	duplicate/o RespMeanMat_SD, RespMeans_SD
endif
if (tracetype == 2)
	duplicate/o RespMeanMat, D_RespMeans
	duplicate/o RespMeanMat_SD, D_RespMeans_SD
endif
killwaves RespMeanMat, RespMeanMat_SD

end

////////////////////////////////////////////////////////////////////////
// 5) Plot Mean responses///////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

// display mean +/- SD for each stimulus condition

Function PlotRespMeans(RespMeanMat, RespMeanMat_SD, tracetype)
wave RespMeanMat, RespMeanMat_SD
variable tracetype
wave stimconds
variable i
variable nStimConds = dimSize(RespMeanMat,1)

string meanwavename = nameofwave(RespMeanMat)
string SDwavename = nameofwave(RespMeanMat_SD)

for (i=0;i<nStimConds;i+=1)
	display/k=1 $meanwavename[][i]
	SetAxis/A/N=1 left
	ModifyGraph rgb=(0,0,0);DelayUpdate
	ErrorBars $meanwavename SHADE= {0,0,(0,0,0,0),(0,0,0,0)},wave=($SDwavename[*][i],$SDwavename[*][i])
	if (tracetype == 0)
		Label left "Glutamate release (DF/F)";DelayUpdate
	endif
	if (tracetype == 2)	
		Label left "Glutamate release (F's\\S-1\\M)"
	endif
	Label bottom "Time (s)";DelayUpdate
	ModifyGraph lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1}
	string CondText
	CondText = "Contrast Step: "+num2str(stimConds[i])+"%"
	DrawText 0.567741935483871,0.163120567375887, CondText
endfor

// Overlay the means for each condition in one plot

display /k=1 RespMeanMat[][0]
for (i=1;i<nStimConds;i+=1)
	appendtograph RespMeanMat[][i]
	ModifyGraph rgb=(0,0,0)
	if (tracetype == 0)
		Label left "Glutamate release (DF/F)";DelayUpdate
	endif
	if (tracetype == 2)	
		Label left "Glutamate release (F's\\S-1\\M)"
	endif
	Label bottom "Time (s)";DelayUpdate
	ModifyGraph lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1}
endfor
	DrawText 0.0211267605633803,0.0420560747663551, "Overlay of mean responses to each stimulus condition"

end

///////////////////////////////////////////////////////////////////////////////////////////
// 6) Z-normalise the response snippets based on the first 500 ms of snip i.e. before stim onset//
//////So the first 500 ms of the resp mean = 0/////////////////////////////////////////////
// NOT INCLUDED AS Z-NORMALISING INCLUDED IN EARLIER PROC
 
//Function zeroRespSnips(w) // use RespSnipsMat
//
//wave w
//variable i, j
//variable nStimConds = dimsize(w,2)
//variable nStimReps = dimsize(w, 1)
//
//// zero the RespSnips matrix
//wave RespSnipMat_z, RespSnipMat_z_SD
//killwaves RespSnipMat_z, RespSnipMat_z_SD
//
//duplicate/o w, RespSnipMat_z //zero the pulled resps 
//for (i=0;i<nStimConds;i+=1)
//	for (j=0;j<nStimReps;j+=1)
//		duplicate/o/r=[0,500][j][i] RespSnipMat_z, tempsnip
//		wavestats/q tempsnip
//		variable baselineavg = v_avg
//		variable baselineSD = v_sdev
//		RespSnipMat_z[][j][i]-=baselineavg
//		//RespSnipMat_z[][j][i]/=baselineSD
//	endfor
//endfor
//
//killwaves tempsnip
//
//// calculate the mean zeroed responses from RespSnips_z
//
//variable nP = Dimsize(RespSnipMat_z,0)
//
//make /o/n=(nP) Average = 0
//make /o/n=(nP) SD = 0
//variable counter
//
//wave RespMeansMat_z, RespMeansMat_z_SD
//killwaves RespMeansMat_z, RespMeansMat_z_SD
//
//for (i=0;i<nStimConds;i+=1) // make the average from the zeroed waves
//	for (counter=0;counter<nP;counter+=1)
//		make /o/n=(nStimReps) currentwave = RespSnipMat_z[counter][p][i]
//		WaveStats/Q currentwave
//		variable CurrentAverage = V_Avg
//		variable currentSD = V_SDev
//		Average[counter]=Currentaverage
//		SD[counter]=CurrentSD
//		SetScale/P x 0,0.001,"", Average, SD 
//	endfor
//	concatenate/np=1 {Average}, RespMeansMat_z
//	concatenate/np=1 {SD}, RespMeansMat_z_SD
//endfor
//killwaves Average, SD, currentwave
//
//end

////////////////////////////////////////////////////////////////////////
// 7) Create stim snips for display purposes////////////////////////////
////////////////////////////////////////////////////////////////////////

Function makeContSteps() // make wave of the contrast step for each stimulus condition 

make/o/n = (1501) Off100
SetScale/P x 0,0.001,"", Off100
off100[500,999]=-1

make/o/n = (1501) Off50
SetScale/P x 0,0.001,"", Off50
Off50[500,999]=-0.5

make/o/n = (1501) Off30
SetScale/P x 0,0.001,"", Off30
Off30[500,999]=-0.3

make/o/n = (1501) Off20
SetScale/P x 0,0.001,"", Off20
off20[500,999]=-0.2

make/o/n = (1501) Off10
SetScale/P x 0,0.001,"", Off10
off10[500,999]=-0.1

make/o/n = (1501) On10
SetScale/P x 0,0.001,"", On10
on10[500,999]=0.1

make/o/n = (1501) on20
SetScale/P x 0,0.001,"", on20
on20[500,999]=0.2

make/o/n = (1501) on30
SetScale/P x 0,0.001,"", on30
on30[500,999]=0.3

make/o/n = (1501) on50
SetScale/P x 0,0.001,"", on50
on50[500,999]=0.5

make/o/n = (1501) on100
SetScale/P x 0,0.001,"", on100
on100[500,999]=1

Concatenate/o {Off100,Off50,Off30,Off20,Off10,On10,on20,on30,on50,on100},StimSnips
killwaves Off100,Off50,Off30,Off20,Off10,On10,on20,on30,on50,on100

end

// 8)  Z-correct ressponse snippets
// Get mean amplitude during mean light levels from the first 500 ms of the mean responses
// Duplicate RespSnips to RespSnips_z
// Minus from RespSnips_z to make release at mean light levels = mean of 0

Function ZshiftResps(RespSnipsMat, RespMeanMat, tracetype)

wave RespSnipsMat, RespMeanMat
variable tracetype
duplicate/o/r=[,500][][] RespMeanMat, first500
variable MeanBaseline = mean(first500)
print MeanBaseline
duplicate/o RespSnipsMat, RespSnipsMat_Z
RespSnipsMat_Z-=MeanBaseline

// get means of respsnips_z matrix
variable nP = Dimsize(RespSnipsMat,0)
variable nReps = dimsize(RespSnipsMat, 1)
variable nStimConds = dimsize(RespSnipsMat,2)
variable i
make /o/n=(nP) Average = 0
make /o/n=(nP) SD = 0
variable counter
for (i=0;i<nStimConds;i+=1)
	for (counter=0;counter<nP;counter+=1)
		make /o/n=(nReps) currentwave = RespSnipsMat_Z[counter][p][i]
		WaveStats/Q currentwave
		variable CurrentAverage = V_Avg
		variable currentSD = V_SDev
		Average[counter]=Currentaverage
		SD[counter]=CurrentSD
		SetScale/P x 0,0.001,"", Average, SD 
	endfor
	concatenate/np=1 {Average}, RespMeanMat_Z
	concatenate/np=1 {SD}, RespMeanMat_SD_Z
endfor

if (tracetype == 0)
	duplicate/o RespSnipsMat_Z, RespSnips_Z
	duplicate/o RespMeanMat_z, RespMeans_Z
	duplicate/o RespMeanMat_SD_z, RespMeans_SD_Z
endif
if (tracetype == 2)
	duplicate/o RespSnipsMat_Z, D_RespSnips_Z
		duplicate/o RespMeanMat_z, D_RespMeans_Z
	duplicate/o RespMeanMat_SD_z, D_RespMeans_SD_Z
endif
killwaves RespSnipsMat_Z, RespMeanMat_z, RespMeanMat_SD_z, Average, SD, currentwave, first500

end