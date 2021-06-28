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
reg [1:0] ipf_type_r, ipf_type_w;
reg [4:0] ipf_band_pos_r, ipf_band_pos_w;
reg ipf_wo_class_r, ipf_wo_class_w;
reg[15:0] ipf_offset_r, ipf_offset_w;
//In order to reduce hardwave usage, maybe we can use ipf_offset_w[15:12] to replace ipf_offset_0_r
//split ipf_offset to different remainder
//reg signed[3:0] ipf_offset_0_r, ipf_offset_1_r, ipf_offset_2_r, ipf_offset_3_r;
reg [2:0]  lcu_x_r, lcu_x_w;
reg [2:0]  lcu_y_r, lcu_y_w;
reg [1:0]  lcu_size_r, lcu_size_w;
reg busy_r, busy_w;
reg finish_r, finish_w;
reg out_en_r, out_en_w;
reg [7:0] dout_r, dout_w;
reg [13:0] dout_addr_r, dout_addr_w;
reg [1:0] state_r, state_w;
reg [7:0] pixel_memory_r[0:191]; //64*3 8-bits memory, MSB for signed, when calculating offset, both of the inputs must be signed to make the operation signed
reg [7:0] pixel_memory_w[0:191]; //64*3 8-bits memory

reg [6:0] row_r, row_w;//present cal pixel coordinate, change to 7 bits for calculating numbers bigger than 63
reg [6:0] col_r, col_w;//present cal pixel coordinate, change to 7 bits for calculating numbers bigger than 63
reg [6:0] read_row_r, read_row_w; //present read-in pixel coordinate
reg [6:0] read_col_r, read_col_w; //present read-in pixel coordinate
reg [7:0] mem_pos_r, mem_pos_w;//present location of pixel in memory
integer i; //for loop below

//Outputs
assign busy = busy_r;
assign finish = finish_r;
assign out_en = out_en_r;
assign dout = dout_r;
assign dout_addr = dout_addr_r;

//Combinational circuits
always @(*) begin
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
	for (i=0; i<=191; i=i+1) begin
		pixel_memory_w[i] = pixel_memory_r[i];
	end
	row_w = row_r;
	col_w = col_r;
	read_row_w = read_row_r;
	read_col_w = read_col_r;
	mem_pos_w = mem_pos_r;
	//-------------------------
	//dout calculation
	//---------------------------
    case (state_r)
        READ: begin
			out_en_w = 1'b0;
			if(in_en)begin
				ipf_type_w = ipf_type;
				ipf_band_pos_w = ipf_band_pos;
				ipf_wo_class_w = ipf_wo_class;
				ipf_offset_w = ipf_offset;
				lcu_size_w = lcu_size;
				lcu_x_w = lcu_x;
				lcu_y_w = lcu_y;
				if(read_row_r==7'd0 || read_row_r==7'd1 || read_row_r==7'd2) begin
					if(read_row_r==7'd2 && read_col_r==(7'd16<<lcu_size_r-7'd1)) begin
						read_row_w = read_row_r + 7'd1;
						read_col_w = 7'd0;
						pixel_memory_w[(7'd16<<lcu_size_r)*read_row_r+read_col_r] = din;
						busy_w = 1'b1;
						state_w = CAL;
					end
					else if(read_col_r==(7'd16<<lcu_size_r-7'd1))begin
						read_row_w = read_row_r + 7'd1;
						read_col_w = 7'd0;
						pixel_memory_w[(7'd16<<lcu_size_r)*read_row_r+read_col_r] = din;
					end
					else begin
						read_col_w = read_col_r + 7'd1;
						pixel_memory_w[(7'd16<<lcu_size_r)*read_row_r+read_col_r] = din;
					end				
				end
				else if(read_row_r==(7'd16<<lcu_size_r-7'd1)) begin  
					if(read_col_r==(7'd16<<lcu_size_r-7'd1))begin //finish reading a lcu
						read_row_w = 7'd0;
						read_col_w = 7'd0;
						pixel_memory_w[7'd32<<lcu_size_r+read_col_r] = din;
						state_w = CAL;
						busy_w = 1'b1;
					end
					else begin
						read_col_w = read_col_r + 7'd1;
						pixel_memory_w[7'd32<<lcu_size_r+read_col_r] = din;
					end
				end
				else begin
					if(read_col_r==(7'd16<<lcu_size_r-7'd1))begin
						read_row_w = read_row_r + 7'd1;
						read_col_w = 7'd0;
						pixel_memory_w[7'd32<<lcu_size_r+read_col_r] = din;
						state_w = CAL;
						busy_w = 1'b1;
					end
					else begin
						read_col_w = read_col_r + 7'd1;
						pixel_memory_w[7'd32<<lcu_size_r+read_col_r] = din;
					end
				end
			end
        end
        CAL: begin
			out_en_w = 1'b1;
			//dout_addr calculation
			dout_addr_w = ({7'b0,row_r}<<7)+({7'b0,col_r})+({11'b0,lcu_x_r}<<11)+({11'b0,lcu_y_r}<<4); //use shift opetator to reduce hardware usage
			//dout calculation
			case(ipf_type_r)
				2'd0:begin//OFF
					dout_w = pixel_memory_r[mem_pos_r];
				end
				2'd1:begin//PO
						
					//Need to consider ipf_band_pos=0 and ipf_band_pos=31
					if((ipf_band_pos_r==5'd0 && pixel_memory_r[mem_pos_r]<16) || (ipf_band_pos_r==5'd31 && pixel_memory_r[mem_pos_r]>= 112))//ipf_band_pos=0 or31
						dout_w = pixel_memory_r[mem_pos_r];
					
					else if (pixel_memory_r[mem_pos_r]>>3 >= ipf_band_pos_r-1 && pixel_memory_r[mem_pos_r]>>3 <= ipf_band_pos_r+1)//in the band
						dout_w = pixel_memory_r[mem_pos_r];
					
					else begin//PO operation
						case(pixel_memory_r[mem_pos_r][4:3])
							2'b00:begin
								if((ipf_offset_r[15]==1'b1)&&(pixel_memory_r[mem_pos_r]<~(ipf_offset_r[15:12]-4'd1)))
									dout_w = 8'd0;
								else if((ipf_offset_r[15]==1'b0)&&(pixel_memory_r[mem_pos_r]>8'd255-ipf_offset_r[15:12]))
									dout_w = 8'd255;
								else
									dout_w = (pixel_memory_r[mem_pos_r]+ipf_offset_r[15:12]);
							end
							2'b01:begin
								if((ipf_offset_r[11]==1'b1)&&(pixel_memory_r[mem_pos_r]<~(ipf_offset_r[11:8]-4'd1)))
									dout_w = 8'd0;
								else if((ipf_offset_r[11]==1'b0)&&(pixel_memory_r[mem_pos_r]>8'd255-ipf_offset_r[11:8]))
									dout_w = 8'd255;
								else
									dout_w = (pixel_memory_r[mem_pos_r]+ipf_offset_r[11:8]);
							end
							2'b10:begin
								if((ipf_offset_r[7]==1'b1)&&(pixel_memory_r[mem_pos_r]<~(ipf_offset_r[7:4]-4'd1)))
									dout_w = 8'd0;
								else if((ipf_offset_r[7]==1'b0)&&(pixel_memory_r[mem_pos_r]>8'd255-ipf_offset_r[7:4]))
									dout_w = 8'd255;
								else
									dout_w = (pixel_memory_r[mem_pos_r]+ipf_offset_r[7:4]);

							end
							2'b11:begin
								if((ipf_offset_r[3]==1'b1)&&(pixel_memory_r[mem_pos_r]<~(ipf_offset_r[3:0]-4'd1)))
									dout_w = 8'd0;
								else if((ipf_offset_r[3]==1'b0)&&(pixel_memory_r[mem_pos_r]>8'd255-ipf_offset_r[3:0]))
									dout_w = 8'd255;
								else
									dout_w = (pixel_memory_r[mem_pos_r]+ipf_offset_r[3:0]);
							end
						endcase	
					end
				end
					
					
				2'd2:begin//WO
					case(ipf_wo_class_r)//2 classes of filter
						0:begin //horizontal
							if(col_r==6'd0 || col_r==(7'd16<<lcu_size_r-7'd1))begin //right-most and left-most column
								dout_w = pixel_memory_r[mem_pos_r];
							end
							else begin
								//five categories
								//category 0
								if((pixel_memory_r[mem_pos_r]<pixel_memory_r[mem_pos_r-1]) && (pixel_memory_r[mem_pos_r]<pixel_memory_r[mem_pos_r+1])) begin
									if(pixel_memory_r[mem_pos_r]>(8'd255-ipf_offset[15:12]))
										dout_w = 8'd255;
									else
										dout_w = pixel_memory_r[mem_pos_r]+ipf_offset[15:12];
								end
								//category 3
								else if((pixel_memory_r[mem_pos_r]>pixel_memory_r[mem_pos_r-1]) && (pixel_memory_r[mem_pos_r]>pixel_memory_r[mem_pos_r+1])) begin
									if(pixel_memory_r[mem_pos_r]<(~(ipf_offset_r[3:0]-4'd1)))
										dout_w = 8'd0;
									else
										dout_w = pixel_memory_r[mem_pos_r]-(~(ipf_offset_r[3:0]-4'd1));
								end
								//category 1
								else if(2*pixel_memory_r[mem_pos_r]<pixel_memory_r[mem_pos_r-1]+pixel_memory_r[mem_pos_r+1]) begin
									if(pixel_memory_r[mem_pos_r]>(8'd255-ipf_offset[11:8]))
										dout_w = 8'd255;
									else
										dout_w = pixel_memory_r[mem_pos_r]+ipf_offset[11:8];
								end
								//category 2
								else if(2*pixel_memory_r[mem_pos_r]>pixel_memory_r[mem_pos_r-1]+pixel_memory_r[mem_pos_r+1]) begin
									if(pixel_memory_r[mem_pos_r]<(~(ipf_offset_r[7:4]-4'd1)))
										dout_w = 8'd0;
									else
										dout_w = pixel_memory_r[mem_pos_r]-(~(ipf_offset_r[7:4]-4'd1));
								end
								//category 4
								else begin
									dout_w = pixel_memory_r[mem_pos_r];

								end
							end
						end
						1:begin //vertical
							if(row_r==6'd0 || row_r==(7'd16<<lcu_size_r-7'd1))begin //up-most and down-most row
								dout_w = pixel_memory_r[mem_pos_r];
							end
							else begin
								//five categories
								//category 0
								if((pixel_memory_r[mem_pos_r]<pixel_memory_r[mem_pos_r-(8'd16<<lcu_size_r)]) && (pixel_memory_r[mem_pos_r]<pixel_memory_r[mem_pos_r+(8'd16<<lcu_size_r)])) begin
									if(pixel_memory_r[mem_pos_r]>(8'd255-ipf_offset[15:12]))
										dout_w = 8'd255;
									else
										dout_w = pixel_memory_r[mem_pos_r]+ipf_offset[15:12];
								end
								//category 3
								else if((pixel_memory_r[mem_pos_r]>pixel_memory_r[mem_pos_r-(8'd16<<lcu_size_r)]) && (pixel_memory_r[mem_pos_r]>pixel_memory_r[mem_pos_r+(8'd16<<lcu_size_r)])) begin
									if(pixel_memory_r[mem_pos_r]<(~(ipf_offset_r[3:0]-4'd1)))
										dout_w = 8'd0;
									else
										dout_w = pixel_memory_r[mem_pos_r]-(~(ipf_offset_r[3:0]-4'd1));
								end
								//category 1
								else if(2*pixel_memory_r[mem_pos_r]<pixel_memory_r[mem_pos_r-(8'd16<<lcu_size_r)]+pixel_memory_r[mem_pos_r+(8'd16<<lcu_size_r)]) begin
									if(pixel_memory_r[mem_pos_r]>(8'd255-ipf_offset[11:8]))
										dout_w = 8'd255;
									else
										dout_w = pixel_memory_r[mem_pos_r]+ipf_offset[11:8];
								end
								//category 2
								else if(2*pixel_memory_r[mem_pos_r]>pixel_memory_r[mem_pos_r-(8'd16<<lcu_size_r)]+pixel_memory_r[mem_pos_r+(8'd16<<lcu_size_r)]) begin
									if(pixel_memory_r[mem_pos_r]<(~(ipf_offset_r[7:4]-4'd1)))
										dout_w = 8'd0;
									else
										dout_w = pixel_memory_r[mem_pos_r]-(~(ipf_offset_r[7:4]-4'd1));
								end
								//category 4
								else 
									dout_w = pixel_memory_r[mem_pos_r];

							end
						end
							
					endcase
				end

			endcase

			//Update  row, col  and memory location. Determine next state.
			if(col_r==(7'd16<<lcu_size_r-7'd1))begin //right-most column in LCU
				col_w = 7'd0;
				if(row_r==7'd0 || row_r==(7'd16<<lcu_size_r-7'd2)) begin //0 or 14,30,62 row in LCU
					row_w = row_r + 7'd1;
					mem_pos_w = mem_pos_r + 8'd1; //ouput 1,2 column and output 15,16 column
				end
				else if(row_r==(7'd16<<lcu_size_r-7'd1)) begin //The down-most row in LCU.
					row_w = 7'd0;
					mem_pos_w = 8'd0;
					if(lcu_x_r==(3'd7>>lcu_size_r) && lcu_y_r==(3'd7>>lcu_size_r)) begin //Finish condition. (3'd7>>lcu_size_r) means 7,3,1 depends on lcu_size_r
						state_w = FINISH;
						busy_w = 1'b0;
					end
					else begin
						state_w = READ;
						busy_w = 1'b0;
						for (i=0; i<=191; i=i+1) begin
							pixel_memory_w[i] = 8'b0;
						end
						//pixel_memory_w = '{default:8'b0}; //turn to next lcu, clear pixel_memory
					end
				end
				else begin
					row_w = row_r + 7'd1;
					mem_pos_w = mem_pos_r - (8'd16<<lcu_size_r-8'b1); //return to the first element of the second row in memory.
					state_w = READ;
					busy_w = 1'b0;
					
					for (i=0; i<=(8'd32<<lcu_size_r-8'd1); i=i+1) begin
						pixel_memory_w[i] = pixel_memory_w[i+(8'd16<<lcu_size_r)];
					end
					//pixel_memory_w[0:(8'd32<<lcu_size_r-8'd1)] = pixel_memory_r[(8'd16<<lcu_size_r):((8'd64<<lcu_size_r)-(8'd16<<lcu_size_r)-8'd1)]; //push second and third row of pixel_memory to first and second row of pixel_memory 
				end
			end
			else begin
				col_w = col_r + 7'd1;
				mem_pos_w = mem_pos_r + 8'd1;
			end

        end
        FINISH: begin
			finish_w = 1'b1;
        end
    endcase    

end

//Sequential circuits
always @(posedge clk or posedge reset) begin
    if (reset) begin
		ipf_type_r <= 2'b0;
		ipf_band_pos_r <= 5'b0;
		ipf_wo_class_r <= 1'b0;
		ipf_offset_r <= 16'b0;
		lcu_x_r <= 3'b0;
		lcu_y_r <= 3'b0;
		lcu_size_r <= 2'b0;
		busy_r <= 1'b0;
		finish_r <= 1'b0;
		out_en_r <= 1'b0;
		dout_r <= 8'b0;
		dout_addr_r <= 14'b0;
		state_r <= 2'b0;
		for (i=0; i<=191; i=i+1) begin
			pixel_memory_r[i] <= 8'b0;
		end
		row_r <= 6'b0;
		col_r <= 6'b0;
		read_row_r <= 7'b0;
		read_col_r <= 7'b0;
		mem_pos_r <= 8'b0;
    end
    else begin
        ipf_type_r <= ipf_type_w;
        ipf_band_pos_r <= ipf_band_pos_w;
        ipf_wo_class_r <= ipf_wo_class_w;
        ipf_offset_r <= ipf_offset_w;
        lcu_x_r <= lcu_x_w;
        lcu_y_r <= lcu_y_w;
        lcu_size_r <= lcu_size_w;
        busy_r <= busy_w;
        finish_r <= finish_w;
        out_en_r <= out_en_w;
        dout_r <= dout_w;
        dout_addr_r <= dout_addr_w;
        state_r <= state_w;
        for (i=0; i<=191; i=i+1) begin
			pixel_memory_r[i] <= pixel_memory_w[i];
		end
		row_r <= row_w;
		col_r <= col_w;
		read_row_r <= read_row_w;
		read_col_r <= read_col_w;
		mem_pos_r <= mem_pos_w;
    end
end
     
endmodule

