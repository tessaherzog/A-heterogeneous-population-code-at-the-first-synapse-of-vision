#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function PhaseLocking_Tester(XlocMat) // matrix of rise xloc per stim for all cones
wave XlocMat

variable StimHz = 20
variable PhaseDur = 1/stimHz
variable msPerPhase = PhaseDur*1000
make/o/n=(msPerPhase) StimPhaseInDegrees

variable i
for (i=0;i<msPerPhase;i+=1)
	StimPhaseInDegrees[i] = (360/msPerPhase)*i
endfor

// conversion factor for each phase from ms to degrees
variable convFactor = 360/(PhaseDur*1000)

// Get Time to rise from mid peak. 
wave StimMidTimes // Looking at stim from half way down decreasing slope. 
variable nCones = dimsize(XlocMat,1)

for (i=0;i<nCones;i+=1)
	duplicate/o/r=[][i] XlocMat, temp
	Redimension/N=-1 temp
	temp-=StimMidtimes
	temp*=1000
	concatenate/np=1 {temp}, PeakRise_TimeFromMid
	killwaves temp
	duplicate/o PeakRise_TimeFromMid, PeakRise_inDeg
	PeakRise_inDeg*=convFactor
endfor
duplicate/o PeakRise_TimeFromMid, PeakRise_inDeg
PeakRise_inDeg*=convFactor

END