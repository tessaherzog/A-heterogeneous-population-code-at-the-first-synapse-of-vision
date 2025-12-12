#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtGlobals=1		// Use modern global access method.

// Procedure from Leon to deconvolve traces
// use with OG trace. 

Function/WAVE DeconvolveT(waveIn,kernel)
wave waveIn, kernel
//variable TauOn, TauOff

string waveInname = nameofwave(waveIn)+"_fft"
//duplicate /o waveIn, kernel
//kernel =  exp(-x/TauOff)-exp(-x/TauOn)

duplicate /o kernel, w_kernel
//wavestats /q/m=1 w_kernel
//w_kernel /= v_sum

fft /dest=dc_wave waveIn

//duplicate /o/c dcwave, $waveInname
fft /dest=kernel_fft w_kernel
duplicate /o/c kernel_fft, result
result = dc_wave / kernel_fft
ifft /dest=result2 result
duplicate/o result2, $(nameofwave(waveIn)+"_temp")

Wave wOut=$(nameofwave(waveIn)+"_temp")
killwaves /z dcwave, result2, result, w_kernel

return wOut
end

////////////////////////////



////////////////////////////////////////////////////////////////////////////////////
//WaveIn is 2d wave. Responses for different contrasts
//TauOn is time-constant for rise in iGluSnFR signal (say 1-2 ms).  
//TauOff is time-constant for decline in iGlusnFr signal (say 100 ms) 
//WaveOut is another 2d wave of all the deconvolved traces. 

Function DeconvolveT2(waveIn,TauOn,TauOff) // use (meanResps, 0, 0.06)
wave waveIn
variable TauOn, TauOff

variable npnts = dimsize(waveIn, 0)
variable nContrasts = dimsize(waveIn, 1)
variable i, j, k

duplicate /o waveIn, waveInCopy

//FFTs require waves with even number of points
if(mod(npnts, 2) == 1)
	DeletePoints/M=0 (npnts-1), 1, waveInCopy
endif

string waveInname = nameofwave(waveIn)+"_fft"
duplicate /o waveInCopy, kernel

//make the kernel (filter) with unit area
kernel =  exp(-x/TauOff)-exp(-x/TauOn)
Redimension/N=-1 kernel
wavestats /q/m=1 kernel
kernel /= v_sum


//Find the minimum from the iGluSnFR wave, which we hope is zero release.
//This min found during brightest stimulus and over a window of 100 ms after box smooth of 50 ms (i.e 50 points at 1 ms per point)
//Then subtract it from *all* waves
Duplicate/O waveInCopy, waveOut, waveInCopy_smth;DelayUpdate
//Smooth/EVEN/B 50, waveInCopy_smth;DelayUpdate
//Smooth/S=2 5, waveInCopy_smth;DelayUpdate
Duplicate/O/R=(3.9,4)(nContrasts-1,nContrasts-1), waveInCopy_smth, minIntWave  
variable minSignal = mean(minIntWave)
waveInCopy-=minSignal

//Display/K=1 
//SetAxis/A

for(i=0; i<nContrasts;i+=1)
	Duplicate/O/R=[][i], waveInCopy, oneWave
	Redimension/N=-1 oneWave	
	Wave decon = WienerFilter(oneWave,tauOn, tauOff)
	Duplicate/O decon, filtered; DelayUpdate
	//FilterFIR/DIM=0/LO={0.1,0.1,101}/NMF={0.015,0.04,9.09495e-13,1}filtered
	//FilterFIR/DIM=0/NMF={0.015,0.05,9.09495e-13,2}filtered
	//Smooth 10, decon
	duplicate/o filtered, $(nameofwave(waveIn)+"_decon_"+ num2str(i))
	WaveOut[][i]=filtered[p]	
//	AppendToGraph $(nameofwave(waveIn)+"_decon_"+ num2str(i))
endfor

//Label left "\\F'SymbolPi'D\\F'Helvetica'F/F";DelayUpdate
//Label bottom "Time (s)"
//SetAxis/A
//ModifyGraph gfSize=16, zero(left)=2,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate


killwaves /z dcwave, result2, result, waveInCopy_smth, minIntWave

wave xsignal,XSIG,xfiltered,XCONVG,W_coef,wave_smth,waveInCopy,trace_decon_0,trace,SNR,SF,oneWave_S,oneWave_H,oneWave_D,oneWave,N,kernel_smth,kernel,HMAGSQR,HF,h,G,filtered
KillWaves xsignal,XSIG,xfiltered,XCONVG,W_coef,wave_smth,waveInCopy,trace_decon_0,trace,SNR,SF,oneWave_S,oneWave_H,oneWave_D,oneWave,N,kernel_smth,kernel,HMAGSQR,HF,h,G,filtered

wave WaveOut
duplicate/o waveOut, DeconTrace
killwaves WaveOut

end
////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////
////////////////////// aveTempWeiner(waveName,filterName) /////////////////////////
//

Function/WAVE WienerFilter(waveIn, tauOn, tauOff)
	Wave waveIn
	
	Variable tauOn//=0.09
	Variable tauOff//
	Variable/C noiseVariance
	Variable sr = 1/(dimdelta(waveIn, 0))
	Variable deltat=dimdelta(waveIn, 0)
	Variable Nsmoothpoints = 21
	
	variable npnts = dimsize(waveIn, 0)
	
//FFTs require waves with even number of points
	if(mod(npnts, 2) == 1)
		DeletePoints/M=0 (npnts-1), 1, waveIn
	endif

	//////////////////////////////////////////////////////
	Variable unitaryEvent = 0.2	//Estimate of the amplitude of an individual event (usually 0.2 for bipolar cells)
	/////////////////////////////////////////////////////

	//Variable scalingfactor=unitaryEvent/tauOff  //This scaling factor gets the amplitudes right
	
	duplicate/o waveIn, xsignal, h, xfiltered, wave_smth
	//Smooth/S=2 Nsmoothpoints, wave_smth				//Savitsky-Golay

	//STEP 1: Make the impulse response, h 	
	duplicate/o WaveIn, h
	h=unitaryEvent*exp(-x/tauOff)
	wavestats /q/m=1 h
	h /= v_sum
	Duplicate/O h kernel_smth
	Variable scaleunitary=(unitaryevent/wavemax(h))	
	
	string firstFilterName = NameofWave(wavein) + "_k1"
	
	//STEP 2: Make the FT of the impulse response (H) and the power spectrum (HMAGSQR)
	FFT/OUT=1/DEST=HF  h
	FFT/OUT=4/DEST=HMAGSQR  h	
	
	//STEP 3: Make FT of the original signal to get mean power density of original signal, S
	FFT/OUT=1/DEST=SF  wave_smth
	
	//STEP 4: Make FT of the noise to get mean power density, N
	String RawHistName=NameofWave(wavein)+"_H"					//Histogram of values in the DF/F wave
	String fitRawHistName="fit_"+RawHistName		//For fitting a Gaussian to the first part _H wave so as to estimate baseline SD 
	Make/N=0/O $RawHistName
	Make/N=100/O $RawHistName;DelayUpdate
	Histogram/B=1 $NameofWave(wavein), $RawHistName;DelayUpdate 

	K0 = 0													//Constrain fit to baseline = 0
	Make/O/N=4 W_coef
	//CurveFit/Q gauss $RawHistName[x2pnt($RawHistName,-0.05),x2pnt($RawHistName,0.05)] /D 
	//noiseVariance = (W_coef[3]/2.355)^2   //FWHM = 2.355 * sd
	//print "Noise variance = " + num2str(W_coef[3])
	
	
	
	//////////////////////////////////////////////////////////////////////////////
	//      THE "FILTERING BIT"
	// Set level of noise variance "filter" here.  Originally used 0.00001.  Lower noise variance (e.g 0.001) means "stronger filter".
	//	noise variance = 0.0000001 looks about optimal to me to smooth trace while not distorting rising phase 
	noiseVariance = 0.0000001
	//////////////////////////////////////////////////////////////////////////////
	
	
	//STEP 5: Calculate SNR(f)
	Duplicate/O/C SF SNR
	Duplicate/O/C SF N
	N=noiseVariance
	SNR = (unitaryEvent*tauOff*HMAGSQR)/N   //I don't know understand why I need to scale in this way! SNR is frequency-dependent.  Gaussian power spectrum is flat
	
	//STEP 6: Calculate the FT of the Wiener deconvolution filter, G
	Duplicate/O/C SF G
	G = (HF^-1)*( HMAGSQR / (HMAGSQR + SNR^-1) )
		
	//STEP7: Convolution filtering of the original, xsignal, and the Wiener filter
	FFT/OUT=1/DEST=XSIG  xsignal
	Duplicate/O/C XSIG XCONVG
	XCONVG=XSIG*G
	
	IFFT/DEST=xfiltered  XCONVG; PauseUpdate
	//xfiltered*=scalingFactor
	
	String smoothwaveName = NameofWave(wavein) +"_S"
	String DeconWaveName = NameofWave(wavein) +"_D"
	Duplicate/O xfiltered $DeconWaveName
	Duplicate/O wave_smth $smoothWaveName
	
	//wave W_StatsQuantiles, W_sigma

	Wave wOut=$DeconWaveName
	return wOut
	
	killwaves/Z coefs, W_findlevels,W_sigma,W_StatsQuantiles
	KillWaves/Z amps, ones, tempfit 
	KillWaves/Z ws, W_coef, levelsWave, wd, wd_smth
	killwaves /z dcwave, result2, result, w_kernel

End
////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
