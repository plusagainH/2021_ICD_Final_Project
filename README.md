# 2021_ICD_Final_Project

1. 在WO運算時，因為已知ipf_offset的正負，所以有些判斷大於255或小於0的判斷可以省略
2. 另外，如果直接寫x+y>255或x+y<0會有overflow發生，所以我換了一點寫法。
3. 另外，我把WO改成不同大小lcu_size都適用，這樣就不用重複寫好幾次，浪費硬體
4. PO是用每一個pixel的值來判斷Band idx，應該不是用pixel所在的位置
5. ipf_offset如果分成四個，也要有ipf_offset_0_w, ipf_offset_1_w, ipf_offset_2_w, ipf_offset_3_w來更新ipf_offset_0_r, ipf_offset_1_r, ipf_offset_2_r, ipf_offset_3_r。所以應該直接用ipf_offset[15:12], ipf_offset[11:8], …就好了

 

