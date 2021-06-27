# 2021_ICD_Final_Project

1. 在WO運算時，因為已知ipf_offset的正負，所以有些判斷大於255或小於0的判斷可以省略
2. 另外，如果直接寫x+y>255或x+y<0會有overflow發生，所以我換了一點寫法。
3. 另外，我把WO改成不同大小lcu_size都適用，這樣就不用重複寫好幾次，浪費硬體
4. PO是用每一個pixel的值來判斷Band idx，應該不是用pixel所在的位置。另外，要考慮ipf_band_pos是0和31的情況，助教之前有寄信說如果0的話就0、1兩個band維持不動；如果是31，就30,31兩個band維持不動
5. ipf_offset_0_r, ipf_offset_1_r, ipf_offset_2_r, ipf_offset_3_r似乎直接用ipf_offset[15:12], ipf_offset[11:8], …就好了
6. 我加了mem_pos來表示現在的運算是在memory的哪個位置
7. 目前剩PO還有READ需要修改

 

