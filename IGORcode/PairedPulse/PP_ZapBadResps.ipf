#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later


Function ListBadResps()
// make a table of all responses to be zapped
make/o/n=(0,2) RepCond_Zppd
Edit/K=0 RepCond_Zppd
end


Function RemoveBadPPResps(RepCond_Zppd)
wave RepCond_Zppd

// remove responses from peak detection matrices
wave Peak1_Amps, Peak1_xlocs, Peak2_Amps, Peak2_Ampsonfit, Peak2_AmpsTrue, Peak2_xlocs, PPratios
zapBadResps(Peak1_Amps)
zapBadResps(Peak1_xlocs)
zapBadResps(Peak2_Amps)
zapBadResps(Peak2_Ampsonfit)
zapBadResps(Peak2_AmpsTrue)
zapBadResps(Peak2_xlocs)
zapBadResps(PPratios)

// re-calculate mean and SD PPratios_Zppd
wave PPratios_Zppd
variable nStimConds = dimsize(PPratios,1)
variable i
make/o/n=(nStimConds) PPratios_mean_Zppd, PPratios_SD_Zppd

for (i=0;i<nStimConds;i+=1)
	duplicate/o/r=[][i] PPratios_Zppd, tempPPR
	wavestats/q tempPPR
	PPratios_mean_Zppd[i] = v_avg
	PPratios_SD_Zppd[i] = v_sdev
endfor
killwaves tempPPR

//display new PP ratios as a function of stimulus condition
wave stimConds

display/k=1  PPratios_mean_Zppd vs stimconds
ModifyGraph mode=4,marker=19
ModifyGraph rgb=(0,0,0);DelayUpdate
ErrorBars PPratios_mean_Zppd SHADE= {0,0,(0,0,0,0),(0,0,0,0)},wave=(PPratios_SD_Zppd,PPratios_SD_Zppd)
ErrorBars PPratios_mean_Zppd SHADE= {0,0,(0,0,0,0),(0,0,0,0)},wave=(PPratios_SD_Zppd,PPratios_SD_Zppd)
Label left "Paired pulse ratio clean (Amp2/Amp1)";DelayUpdate
Label bottom "Interstimulus interval (ms)";DelayUpdate
ModifyGraph lblMargin=5,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
SetAxis/A/N=1 left;DelayUpdate
SetAxis bottom 0,*
SetDrawEnv xcoord= bottom,ycoord= left,dash= 1;DelayUpdate
DrawLine 0,1,100,1
end


end

function zapBadResps(input) // input is matrix of peak amp or peak xloc to be copied and zapped
wave input
wave RepCond_Zppd
duplicate/o input, input_zppd
variable i
variable nRespsToZap = dimsize(RepCond_Zppd,0)
for (i=0;i<nRespsToZap;i+=1)
	input_zppd[RepCond_Zppd[i][0]][RepCond_Zppd[i][1]] = NaN
endfor

string zppdwavename = nameofwave(input) + "_zppd"
duplicate/o input_zppd, $zppdwavename
killwaves input_zppd
end


