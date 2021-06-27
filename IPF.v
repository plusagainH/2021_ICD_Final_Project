module IPF ( clk, reset, in_en, din, ipf_type, ipf_band_pos, ipf_wo_class, ipf_offset, lcu_x, lcu_y, lcu_size, busy, out_en, dout, dout_addr, finish);
input   clk;
input   reset;
input   in_en;
input   [7:0]  din;
input   [1:0]  ipf_type;
input   [4:0]  ipf_band_pos;
input          ipf_wo_class;
input   [15:0] ipf_offset;
input   [2:0]  lcu_x;
input   [2:0]  lcu_y;
input   [1:0]  lcu_size;
output  busy;
output  finish;
output  out_en;
output  [7:0] dout;
output  [13:0] dout_addr;

//Self-defined variables
parameter READ = 2'b00 ;
parameter CAL = 2'b01;
parameter FINISH = 2'b10;
reg [7:0] din_r, din_w;
reg [1:0] ipf_type_r, ipf_type_w;
reg [4:0] ipf_band_pos_r, ipf_band_pos_w;
reg ipf_wo_class_r, ipf_wo_class_w;
reg[15:0] ipf_offset_w;
//split ipf_offset to different remainder
reg signed[3:0] ipf_offset_0_r, ipf_offset_1_r, ipf_offset_2_r, ipf_offset_3_r;
reg [2:0]  lcu_x_r, lcu_x_w;
reg [2:0]  lcu_y_r, lcu_y_w;
reg [1:0]  lcu_size_r, lcu_size_w;
reg busy_r, busy_w;
reg finish_r, finish_w;
reg out_en_r, out_en_w;
reg [7:0] dout_r, dout_w;
reg [13:0] dout_addr_r, dout_addr_w;
reg [1:0] state_r, state_w;
reg signed[7:0] pixel_memory_r[0:191]; //64*3 8-bits memory, when calculating offset, both of the inputs must be signed to make the operation signed
reg signed[7:0] pixel_memory_w[0:191]; //64*3 8-bits memory

reg [5:0] row_r, row_w;//present cal pixel coordinate
reg [5:0] col_r, col_w;//present cal pixel coordinate

//Outputs
assign busy = busy_r;
assign finish = finish_r;
assign out_en = out_en_r;
assign dout = dout_r;
assign dout_addr = dout_addr_r;

//Combinational circuits
always @(*) begin
    din_w = din;//modify from din_w = din_r
    ipf_type_w = ipf_type_r;
    ipf_band_pos_w = ipf_band_pos_r;
    ipf_wo_class_w = ipf_wo_class_r;
    ipf_offset_w = ipf_offset_r;
    lcu_x_w = lcu_x_r;
    lcu_y_w = lcu_y_r;
    lcu_size_w = lcu_size_r;
    busy_w = busy_r;
    finish_w = finish_r;
    out_en_w = out_en_r;
    dout_w = dout_r;
    dout_addr_w = dout_addr_r;
    state_w = state_r;
	//-------------------------
	//dout calculation
	//---------------------------
    case (state_r)
        READ: begin
            case(lcu_size_r)
				0: begin//16x16
					for (k=0; k<47; k=k+1)begin//16*3row
						pixel_memory_w[k] = pixel_memory_r[k+1];
					end
					pixel_memory_w[47] = din_r;
				end
				1: begin//32x32
					for (k=0; k<95; k=k+1)begin//32*3row
						pixel_memory_w[k] = pixel_memory_r[k+1];
					end
					pixel_memory_w[95] = din_r;
				end
				2: begin//64x64
					for (k=0; k<191; k=k+1)begin//64*3row
						pixel_memory_w[k] = pixel_memory_r[k+1];
					end
					pixel_memory_w[191] = din_r;
				end
			endcase
        end
        CAL: begin
            case(lcu_size_r)
				0: begin//16x16
					//dout_addr calculation
					dout_addr_w = 128*row_r+col_r+lcu_x_r*128*16+lcu_y_r*16;
					//dout calculation
					case(ipf_type_r)
						0:begin//OFF
							case(row_r)
								0://output 1st row
									dout_w = pixel_memory_r[col_r];
									
								15://output 16th row
									dout_w = pixel_memory_r[16*2+col_r];
									
								default: //output current row
									dout_w = pixel_memory_r[16*1+col_r];
									
							endcase
							

						end
						1:begin//PO
							case(row_r)
								0:begin//output 1st row
									if((16*row_r+col_r>=(ipf_band_pos_r-1)*8) or (16*row_r+col_r<=((ipf_band_pos_r+1)*8-1)))//if current pixel falls into no-operation bands
										dout_w = pixel_memory_r[col_r];
									else begin//PO operation
										case(col_r[1:0])//ipf_offset for different offset
											2'b00:begin
												if(pixel_memory_r[col_r]+ipf_offset_0_r<0)
													dout_w = 0;
												else if(pixel_memory_r[col_r]+ipf_offset_0_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[col_r]+ipf_offset_0_r);

											end
											2'b01:begin
												if(pixel_memory_r[col_r]+ipf_offset_1_r<0)
													dout_w = 0;
												else if(pixel_memory_r[col_r]+ipf_offset_1_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[col_r]+ipf_offset_1_r);

											end
											2'b10:begin
												if(pixel_memory_r[col_r]+ipf_offset_2_r<0)
													dout_w = 0;
												else if(pixel_memory_r[col_r]+ipf_offset_2_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[col_r]+ipf_offset_2_r);

											end
											2'b11:begin
												if(pixel_memory_r[col_r]+ipf_offset_3_r<0)
													dout_w = 0;
												else if(pixel_memory_r[col_r]+ipf_offset_3_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[col_r]+ipf_offset_3_r);

											end
											
										endcase
										
									end
									
								end	
								15:begin//output 16th row
									if((16*row_r+col_r>=(ipf_band_pos_r-1)*8) or (16*row_r+col_r<=((ipf_band_pos_r+1)*8-1)))begin//if current pixel falls into no-operation bands
										dout_w = pixel_memory_r[col_r];
										dout_addr_w = 128*row_r+col_r+lcu_x_r*128*16+lcu_y_r*16;
									end
									else begin//PO operation
										case(col_r[1:0])//ipf_offset for different offset
											2'b00:begin
												//dout calculation
												if(pixel_memory_r[16*2+col_r]+ipf_offset_0_r<0)
													dout_w = 0;
												else if(pixel_memory_r[16*2+col_r]+ipf_offset_0_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[16*2+col_r]+ipf_offset_0_r);
												//dout_addr calculation
												dout_addr_w = 128*row_r+col_r+lcu_x_r*128*16+lcu_y_r*16;
											end
											2'b01:begin
												//dout calculation
												if(pixel_memory_r[16*2+col_r]+ipf_offset_1_r<0)
													dout_w = 0;
												else if(pixel_memory_r[16*2+col_r]+ipf_offset_1_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[16*2+col_r]+ipf_offset_1_r);
												//dout_addr calculation
												dout_addr_w = 128*row_r+col_r+lcu_x_r*128*16+lcu_y_r*16;
											end
											2'b10:begin
												//dout calculation
												if(pixel_memory_r[16*2+col_r]+ipf_offset_2_r<0)
													dout_w = 0;
												else if(pixel_memory_r[16*2+col_r]+ipf_offset_2_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[16*2+col_r]+ipf_offset_2_r);
												//dout_addr calculation
												dout_addr_w = 128*row_r+col_r+lcu_x_r*128*16+lcu_y_r*16;
											end
											2'b11:begin
												//dout calculation
												if(pixel_memory_r[16*2+col_r]+ipf_offset_3_r<0)
													dout_w = 0;
												else if(pixel_memory_r[16*2+col_r]+ipf_offset_3_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[16*2+col_r]+ipf_offset_3_r);
												//dout_addr calculation
												dout_addr_w = 128*row_r+col_r+lcu_x_r*128*16+lcu_y_r*16;
											end
											
										endcase
									end
									

									
								end	
								default: begin//output current row
									if((16*row_r+col_r>=(ipf_band_pos_r-1)*8) or (16*row_r+col_r<=((ipf_band_pos_r+1)*8-1)))begin//if current pixel falls into no-operation bands
										dout_w = pixel_memory_r[col_r];
										dout_addr_w = 128*row_r+col_r+lcu_x_r*128*16+lcu_y_r*16;
									end
									else begin//PO operation
										case(col_r[1:0])//ipf_offset for different offset
											2'b00:begin
												//dout calculation
												if(pixel_memory_r[16*1+col_r]+ipf_offset_0_r<0)
													dout_w = 0;
												else if(pixel_memory_r[16*1+col_r]+ipf_offset_0_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[16*1+col_r]+ipf_offset_0_r);
												//dout_addr calculation
												dout_addr_w = 128*row_r+col_r+lcu_x_r*128*16+lcu_y_r*16;
											end
											2'b01:begin
												//dout calculation
												if(pixel_memory_r[16*1+col_r]+ipf_offset_1_r<0)
													dout_w = 0;
												else if(pixel_memory_r[16*1+col_r]+ipf_offset_1_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[16*1+col_r]+ipf_offset_1_r);
												//dout_addr calculation
												dout_addr_w = 128*row_r+col_r+lcu_x_r*128*16+lcu_y_r*16;
											end
											2'b10:begin
												//dout calculation
												if(pixel_memory_r[16*1+col_r]+ipf_offset_2_r<0)
													dout_w = 0;
												else if(pixel_memory_r[16*1+col_r]+ipf_offset_2_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[16*1+col_r]+ipf_offset_2_r);
												//dout_addr calculation
												dout_addr_w = 128*row_r+col_r+lcu_x_r*128*16+lcu_y_r*16;
											end
											2'b11:begin
												//dout calculation
												if(pixel_memory_r[16*1+col_r]+ipf_offset_3_r<0)
													dout_w = 0;
												else if(pixel_memory_r[16*1+col_r]+ipf_offset_3_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[16*1+col_r]+ipf_offset_3_r);
												//dout_addr calculation
												dout_addr_w = 128*row_r+col_r+lcu_x_r*128*16+lcu_y_r*16;
											end
											
										endcase
									end
									

									
								end	
							endcase
						end
						2:begin//WO
							case(ipf_wo_class_r)//2 classes of filter
								0://horizontal
									case(row_r)
									0:begin//output 1st row
										if(col_r==0 or col_r==15)//on left or right edge
											dout_w = pixel_memory_r[col_r];
										 
										else begin
											//five categories
											//category 0
											if((pixel_memory_r[col_r]<pixel_memory_r[col_r-1]) and (pixel_memory_r[col_r]<pixel_memory_r[col_r+1])) begin
												if(pixel_memory_r[col_r]+ipf_offset_0_r<0)
													dout_w = 0;
												else if(pixel_memory_r[col_r]+ipf_offset_0_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[col_r]+ipf_offset_0_r);
											end
											//category 3
											else if((pixel_memory_r[col_r]>pixel_memory_r[col_r-1]) and (pixel_memory_r[col_r]>pixel_memory_r[col_r+1])) begin
												if(pixel_memory_r[col_r]+ipf_offset_3_r<0)
													dout_w = 0;
												else if(pixel_memory_r[col_r]+ipf_offset_3_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[col_r]+ipf_offset_3_r);
											end
											//category 1
											else if(2*pixel_memory_r[col_r]<pixel_memory_r[col_r-1]+pixel_memory_r[col_r+1]) begin
												if(pixel_memory_r[col_r]+ipf_offset_1_r<0)
													dout_w = 0;
												else if(pixel_memory_r[col_r]+ipf_offset_1_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[col_r]+ipf_offset_1_r);
											end
											//category 2
											else if(2*pixel_memory_r[col_r]>pixel_memory_r[col_r-1]+pixel_memory_r[col_r+1]) begin
												if(pixel_memory_r[col_r]+ipf_offset_2_r<0)
													dout_w = 0;
												else if(pixel_memory_r[col_r]+ipf_offset_2_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[col_r]+ipf_offset_2_r);
											end
											//category 4
											else begin
												dout_w = pixel_memory_r[col_r];
											end

										end
										
									end	
									15:begin//output 16th row
										if(col_r==0 or col_r==15)//on left or right edge
											dout_w = pixel_memory_r[16*2+col_r];
										 
										else begin
											//five categories
											//category 0
											if((pixel_memory_r[16*2+col_r]<pixel_memory_r[16*2+col_r-1]) and (pixel_memory_r[16*2+col_r]<pixel_memory_r[16*2+col_r+1])) begin
												if(pixel_memory_r[16*2+col_r]+ipf_offset_0_r<0)
													dout_w = 0;
												else if(pixel_memory_r[16*2+col_r]+ipf_offset_0_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[16*2+col_r]+ipf_offset_0_r);
											end
											//category 3
											else if((pixel_memory_r[16*2+col_r]>pixel_memory_r[16*2+col_r-1]) and (pixel_memory_r[16*2+col_r]>pixel_memory_r[16*2+col_r+1])) begin
												if(pixel_memory_r[16*2+col_r]+ipf_offset_3_r<0)
													dout_w = 0;
												else if(pixel_memory_r[16*2+col_r]+ipf_offset_3_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[16*2+col_r]+ipf_offset_3_r);
											end
											//category 1
											else if(2*pixel_memory_r[16*2+col_r]<pixel_memory_r[16*2+col_r-1]+pixel_memory_r[16*2+col_r+1]) begin
												if(pixel_memory_r[16*2+col_r]+ipf_offset_1_r<0)
													dout_w = 0;
												else if(pixel_memory_r[16*2+col_r]+ipf_offset_1_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[16*2+col_r]+ipf_offset_1_r);
											end
											//category 2
											else if(2*pixel_memory_r[16*2+col_r]>pixel_memory_r[16*2+col_r-1]+pixel_memory_r[16*2+col_r+1]) begin
												if(pixel_memory_r[16*2+col_r]+ipf_offset_2_r<0)
													dout_w = 0;
												else if(pixel_memory_r[16*2+col_r]+ipf_offset_2_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[16*2+col_r]+ipf_offset_2_r);
											end
											//category 4
											else begin
												dout_w = pixel_memory_r[16*2+col_r];
											end

										end
										

										
									end	
									default: begin//output current row
										if(col_r==0 or col_r==15)//on left or right edge
											dout_w = pixel_memory_r[16*1+col_r];
										 
										else begin
											//five categories
											//category 0
											if((pixel_memory_r[16*1+col_r]<pixel_memory_r[16*1+col_r-1]) and (pixel_memory_r[16*1+col_r]<pixel_memory_r[16*1+col_r+1])) begin
												if(pixel_memory_r[16*1+col_r]+ipf_offset_0_r<0)
													dout_w = 0;
												else if(pixel_memory_r[16*1+col_r]+ipf_offset_0_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[16*1+col_r]+ipf_offset_0_r);
											end
											//category 3
											else if((pixel_memory_r[16*1+col_r]>pixel_memory_r[16*1+col_r-1]) and (pixel_memory_r[16*1+col_r]>pixel_memory_r[16*1+col_r+1])) begin
												if(pixel_memory_r[16*1+col_r]+ipf_offset_3_r<0)
													dout_w = 0;
												else if(pixel_memory_r[16*1+col_r]+ipf_offset_3_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[16*1+col_r]+ipf_offset_3_r);
											end
											//category 1
											else if(2*pixel_memory_r[16*1+col_r]<pixel_memory_r[16*1+col_r-1]+pixel_memory_r[16*1+col_r+1]) begin
												if(pixel_memory_r[16*1+col_r]+ipf_offset_1_r<0)
													dout_w = 0;
												else if(pixel_memory_r[16*1+col_r]+ipf_offset_1_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[16*1+col_r]+ipf_offset_1_r);
											end
											//category 2
											else if(2*pixel_memory_r[16*1+col_r]>pixel_memory_r[16*1+col_r-1]+pixel_memory_r[16*1+col_r+1]) begin
												if(pixel_memory_r[16*1+col_r]+ipf_offset_2_r<0)
													dout_w = 0;
												else if(pixel_memory_r[16*1+col_r]+ipf_offset_2_r>255)
													dout_w = 255;
												else
													dout_w = (pixel_memory_r[16*1+col_r]+ipf_offset_2_r);
											end
											//category 4
											else 
												dout_w = pixel_memory_r[16*1+col_r];

										end
										

										
									end	
									endcase
								1://vertical
									case(row_r)
									0://output 1st row
										dout_w = pixel_memory_r[col_r];
									15://output 16th row
										dout_w = pixel_memory_r[16*2+col_r];
									default: begin//output current row
										//five categories
										//category 0
										if((pixel_memory_r[16*1+col_r]<pixel_memory_r[16*0+col_r]) and (pixel_memory_r[16*1+col_r]<pixel_memory_r[16*2+col_r])) begin
											if(pixel_memory_r[16*1+col_r]+ipf_offset_0_r<0)
												dout_w = 0;
											else if(pixel_memory_r[16*1+col_r]+ipf_offset_0_r>255)
												dout_w = 255;
											else
												dout_w = (pixel_memory_r[16*1+col_r]+ipf_offset_0_r);
										end
										//category 3
										else if((pixel_memory_r[16*1+col_r]>pixel_memory_r[16*0+col_r]) and (pixel_memory_r[16*1+col_r]>pixel_memory_r[16*2+col_r])) begin
											if(pixel_memory_r[16*1+col_r]+ipf_offset_3_r<0)
												dout_w = 0;
											else if(pixel_memory_r[16*1+col_r]+ipf_offset_3_r>255)
												dout_w = 255;
											else
												dout_w = (pixel_memory_r[16*1+col_r]+ipf_offset_3_r);
										end
										//category 1
										else if(2*pixel_memory_r[16*1+col_r]<pixel_memory_r[16*0+col_r]+pixel_memory_r[16*2+col_r]) begin
											if(pixel_memory_r[16*1+col_r]+ipf_offset_1_r<0)
												dout_w = 0;
											else if(pixel_memory_r[16*1+col_r]+ipf_offset_1_r>255)
												dout_w = 255;
											else
												dout_w = (pixel_memory_r[16*1+col_r]+ipf_offset_1_r);
										end
										//category 2
										else if(2*pixel_memory_r[16*1+col_r]>pixel_memory_r[16*0+col_r]+pixel_memory_r[16*2+col_r]) begin
											if(pixel_memory_r[16*1+col_r]+ipf_offset_2_r<0)
												dout_w = 0;
											else if(pixel_memory_r[16*1+col_r]+ipf_offset_2_r>255)
												dout_w = 255;
											else
												dout_w = (pixel_memory_r[16*1+col_r]+ipf_offset_2_r);
										end
										//category 4
										else begin
											dout_w = pixel_memory_r[16*1+col_r];
										end
									end
									endcase
							endcase
						end
					endcase
					//update the pixel index processed by coordinate(row, col)
					if(col_r==15)begin
						col_w = 0;
						if(row_r==15)
							row_w = 0;
							//a LCU has finished
							//states should be changed to READ, except all LCUs have been output
						else
							row_w = row_r+1;
							//a row has finished
							//states should be changed to READ, except row_r is 0(1st row) or 14(15th row)
					end
					else begin
						col_w = col_w+1;
						row_w = row_r;
					end
				end
				1: begin//32x32
					case(ipf_type_r)
						0:begin//OFF
						
						end
						1:begin//PO
						
						end
						2:begin//WO
						
						end
					endcase
				end
				2: begin//64x64
					case(ipf_type_r)
						0:begin//OFF
						
						end
						1:begin//PO
						
						end
						2:begin//WO
						
						end
					endcase
				end

			endcase
        end
        FINISH: begin
            case(lcu_size_r)
				0: begin//16x16

				end
				1: begin//32x32
		
				end
				2: begin//64x64
					
				end

			endcase
        end
    endcase    

end

//Sequential circuits
always @(posedge clk or posedge rst) begin
    if (rst) begin
        din_r <= 8'b0;
        ipf_type_r <= 2'b0;
        ipf_band_pos_r <= 5'b0;
        ipf_wo_class_r <= 1'b0;
        ipf_offset_0_r <= 4'b0;//split ipf_offset to different remainder
	ipf_offset_1_r <= 4'b0;
	ipf_offset_2_r <= 4'b0;
	ipf_offset_3_r <= 4'b0;
        lcu_x_r <= 3'b0;
        lcu_y_r <= 3'b0;
        lcu_size_r <= 2'b0;
        busy_r <= 1'b0;
        finish_r <= 1'b0;
        out_en_r <= 1'b0;
        dout_r <= 8'b0;
        dout_addr_r <= 14'b0;
        state_r <= 2'b0;
        pixel_memory_r <= '{default:0};
	row_r <= 2'b0;
	col_r <= 2'b0;
    end
    else begin
        din_r <= din_w;
        ipf_type_r <= ipf_type_w;
        ipf_band_pos_r <= ipf_band_pos_w;
        ipf_wo_class_r <= ipf_wo_class_w;
        ipf_offset_r <= ipf_offset_w;
	ipf_offset_0_r <= ipf_offset_w[15:12];//split ipf_offset to different remainder
	ipf_offset_1_r <= ipf_offset_w[11:8];
	ipf_offset_2_r <= ipf_offset_w[7:4];
	ipf_offset_3_r <= ipf_offset_w[3:0];
        lcu_x_r <= lcu_x_w;
        lcu_y_r <= lcu_y_w;
        lcu_size_r <= lcu_size_w;
        busy_r <= busy_w;
        finish_r <= finish_w;
        out_en_r <= out_en_w;
        dout_r <= dout_w;
        dout_addr_r <= dout_addr_w;
        state_r <= state_w;
        pixel_memory_r <= pixel_memory_w;
	row_r <= row_w;
	col_r <= col_w;
    end
end
     
endmodule

