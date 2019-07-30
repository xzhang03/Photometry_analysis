# Photometry_analysis
photometry analysis
Stephen Zhang 7/30/2019

Analysis for two-color photometry in the Andermann lab
* Supports data that collected with or without using a lock-in amplifier
* Supports pre-filtering and pre-smoothing before allignment. These steps only affects the coefficients that are used for allignment and not the data traces themselves
* Supports pre-flattening before allignment. This step is also applied to the data traces themselves.
* Supports several linear forms of allignment and straight-up ratio metric calculations
* Supports using all, a single segment, or multiple segments of the data for allignment (with gui)
* Supports post-filtering and post-flattening after allignment

If you use the photometry cubes
1. Run tcpPreprocess
2. Change the settings on the top of tcpAllign
3. Run tcpAllign

If you use lock-in amplifiers
1. Change the settings on the top of tcpAllign
2. Run tcpAllign
