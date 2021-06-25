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
reg [15:0] ipf_offset_r, ipf_offset_w;
reg [2:0]  lcu_x_r, lcu_x_w;
reg [2:0]  lcu_y_r, lcu_y_w;
reg [1:0]  lcu_size_r, lcu_size_w;
reg busy_r, busy_w;
reg finish_r, finish_w;
reg out_en_r, out_en_w;
reg [7:0] dout_r, dout_w;
reg [13:0] dout_addr_r, dout_addr_w;
reg [1:0] state_r, state_w;
reg [7:0] pixel_memory_r[0:191]; //64*3 8-bits memory
reg [7:0] pixel_memory_w[0:191]; //64*3 8-bits memory

//Outputs
assign busy = busy_r;
assign finish = finish_r;
assign out_en = out_en_r;
assign dout = dout_r;
assign dout_addr = dout_addr_r;

//Combinational circuits
always @(*) begin
    din_w = din_r;
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
    case (state_r)
        READ: begin
            
        end
        CAL: begin
            
        end
        FINISH: begin
            
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
        pixel_memory_r <= '{default:0};
    end
    else begin
        din_r <= din_w;
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
        pixel_memory_r <= pixel_memory_w;
    end
end
     
endmodule

