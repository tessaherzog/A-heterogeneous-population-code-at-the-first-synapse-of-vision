#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function SpectralCentroid(w)
wave w

variable sampFreq = 1/(deltax(w))
variable MaxStimFreq = 20
variable StimStart = 8000
variable StimEnd = 57999
Variable StimDuration = stimEnd - StimStart

duplicate/o/r=[StimStart, StimEnd] w, ChirpResp
SetScale/P x 0,0.001,"", ChirpResp
wave chirpResp

// Get Fourier transform for response to chirp component of stimulus
FFT/OUT=4/WINF=Hanning/DEST=ChirpResp_FFT  ChirpResp;DelayUpdate
//Display/k=1 SF_FFT
//SetAxis left *,80000;DelayUpdate
//SetAxis bottom *,20

// Snip out the FT between 0 and 20 Hz, as that's what we're interested in (stim goes up to 20 Hz)
duplicate/o/r=(,MaxStimFreq) ChirpResp_FFT, ChirpResp_FFT_Snip

// 0 out the first 5 pnts of the FT, as they contain huge values note related to responses (NaN does not work)
duplicate/o ChirpResp_FFT_Snip,ChirpResp_FFT_Snip_LFZ
ChirpResp_FFT_Snip_LFZ[,4]=0

// Make wave of y values for same length as FFT snip
duplicate/o ChirpResp_FFT_Snip, FreqScale
variable i
for (i=0;i<dimsize(FreqScale,0);i+=1)
	FreqScale[i]=((MaxStimFreq)/dimsize(FreqScale,0))*i
endfor
duplicate/o FreqScale, FreqScale_LFZ
FreqScale_LFZ[,4]=0

// calculate weighted FFT
duplicate/o ChirpResp_FFT_Snip, ChirpResp_FFT_Snip_weighted
ChirpResp_FFT_Snip_weighted*=FreqScale

//Calculate weighted FFT for low freq. zeroed wave
duplicate/o ChirpResp_FFT_Snip_LFZ, ChirpResp_FFT_Snip_LFZ_weighted
ChirpResp_FFT_Snip_LFZ_weighted*=FreqScale_LFZ

// calculate spectral centroid (sum of weightedFT/sum of FT)

make/o/n=(1) SpecCentroid = (sum(ChirpResp_FFT_Snip_weighted)/sum(ChirpResp_FFT_Snip))
print "Spectral centroid = " + num2str(SpecCentroid[0])

// Calculate spectral centroid for Low-freq zeroed wave
make/o/n=(1) SpecCentroid_LFZ = (sum(ChirpResp_FFT_Snip_LFZ_weighted)/sum(ChirpResp_FFT_Snip_LFZ))
print "Spectral centroid (LFZ) = " + num2str(SpecCentroid_LFZ[0])

string SC_name = "SpecCent_" + nameofWave(w)
string SC_LFZ_name = "SpecCent_LFZ_" + nameofwave(w)
duplicate/o SpecCentroid, $SC_name
duplicate/o SpecCentroid_LFZ, $SC_LFZ_name
killwaves SpecCentroid, SpecCentroid_LFZ

END