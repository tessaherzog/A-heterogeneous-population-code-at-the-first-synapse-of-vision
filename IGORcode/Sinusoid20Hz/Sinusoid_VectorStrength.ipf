#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function VectorStrength(PeakRise_NormPhase1)

wave PeakRise_NormPhase1 // matrix of rise time converted to stimulus phase in degrees
variable i, j
variable nCones = dimsize(PeakRise_NormPhase1,1)
variable nStimIts = dimsize(PeakRise_NormPhase1, 0)

make/o/n=(NCones) VectorStrengthValues

for (i=0;i<nCones;i+=1)
	duplicate/o/r=[][i] PeakRise_NormPhase1, temp_NormPhase
	redimension/n=-1 temp_NormPhase
	wavetransform zapNaNs temp_NormPhase //get rid of NaNs as causes error in sum functions
	variable NewnStimIts = dimsize(temp_NormPhase,0)
	
	// convert degrees to radians
	temp_NormPhase*=(pi/180)
	
	make/o/n=(NewnStimIts) CosValues, SinValues // get Cos and Sin values
	for (j=0;j<NewnStimIts;j+=1)
		cosValues[j]= cos(temp_NormPhase[j])
		SinValues[j]= sin(temp_NormPhase[j])
	endfor
	
	//Get sum of cos and sin values
	variable CosValueSum = sum(cosValues)
	variable SinValueSum = sum(SinValues)
	
	//Square the summed cos and sin values
	variable CosValueSum_Sq = CosValueSum^2
	variable SinValueSum_Sq = SinValueSum^2
	
	//Sum the squared cos and sin values
	variable SumCosSinValues = CosValueSum_Sq + SinValueSum_Sq
	
	//Square root the sum of the cos and sin values
	variable SqRootCosSinVals = sqrt(SumCosSinValues)
	
	// divide by n of stim iterations
	variable VS = SqRootCosSinVals/NewnStimIts
	
	// Save vector strength value in wave
	VectorStrengthValues[i] = VS
	
	//killwaves temp_NormPhase, CosValues, SinValues
	
endfor	
	
	
END