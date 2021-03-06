# Two-color photometry analysis
photometry analysis
Stephen Zhang 7/30/2019

First-order analysis package for two-color photometry in the Andermann lab, which supports:
* Data that are collected with or without using a lock-in amplifier
* Preprocessing for data that are collected with square-wave pulses
* Quadratic off-line demodulation for data that are collected with frequency modulation (modified from Thomas Davidson's implementation)
* Pre-filtering and pre-smoothing before alignment. These steps only affects the coefficients that are used for alignment and not the data traces themselves
* Pre-flattening before alignment. This step is also applied to the data traces themselves.
* Several linear forms of alignment and straight-up ratio metric calculations
* Using all, a single segment, or multiple segments of the data for alignment (with gui)
* Post-filtering and post-flattening after alignment

A. If you use the **square-wave photometry cubes**:

Sample:
![Square-box data sample](https://github.com/xzhang03/Photometry_analysis/blob/master/Sample%20images/Preprocesed%20square-wave%20data.png)
1. Run tcpPreprocess
2. Run tcpAlign

B. If you use **lock-in amplifiers**:
1. Run tcpAlign

C. If you use the **sine-wave photometry cubes**:

Sample (data credit: Andrew Lutas):

![Sine-box data sample](https://github.com/xzhang03/Photometry_analysis/blob/master/Sample%20images/Preprocessed%20sine-wave%20data.png)
1. Run tcpDemodulation
3. Run tcpAlign
