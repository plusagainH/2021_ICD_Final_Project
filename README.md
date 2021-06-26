# 2021_ICD_Final_Project

-----------------------------------------
| REQUEST VERIFICATION |
-----------------------------------------
將din匯入原本寫作din_w = din_r;

我把它改成din_w = din;

-----------------------------------------
| VARIAVLES DEFINATION |
-----------------------------------------
input ipf_offset is split according to different remainder
-- split ipf_offset into ipf_offset_0, ipf_offset_1, ipf_offset_2, ipf_offset_3
-- input ipf_offset is connected to ipf_offset_w, and ipf_offset_w is  connected to ipf_offset_0_r, ipf_offset_1_r, ipf_offset_2_r, ipf_offset_3_r thru FF
	
pixel_memory has changed  into signed num and add a MSB in order to make the operation signed

row and col are variables for current calculating pixel, updated after every CAL
 

