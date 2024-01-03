module I2S_Serf(clk,rst_n,I2S_sclk,I2S_ws,I2S_data,lft_chnnl,rght_chnnl,vld);
	input clk,rst_n;
	input I2S_sclk;
	input I2S_ws;
	input I2S_data;
	output [23:0] lft_chnnl;
	output [23:0] rght_chnnl;
	output reg vld;
	
	reg sclk_ff1,sclk_ff2,sclk_ff3;
	wire sclk_rise;
	
	// rise edge detector for I2S_sclk
	// if there is a rise edge, I2S_rise is on for one cycle
	// I2S_sclk is double-flopped to prevent metastability
	assign sclk_rise=~sclk_ff3&sclk_ff2;
	always_ff@(posedge clk,negedge rst_n)begin
		if(!rst_n)begin
			sclk_ff1<=0;
			sclk_ff2<=0;
			sclk_ff3<=0;
		end
		else begin
			sclk_ff1<=I2S_sclk;
			sclk_ff2<=sclk_ff1;
			sclk_ff3<=sclk_ff2;
		end
	end
	
	
	reg ws_ff1,ws_ff2,ws_ff3;
	wire ws_fall;
	
	// falling edge detector for I2S_ws
	// if there is a falling edge, I2S_ws is on for one cycle
	// I2S_ws is double-flopped to prevent metastability
	assign ws_fall=ws_ff3&~ws_ff2;
	always_ff@(posedge clk,negedge rst_n)begin
		if(!rst_n)begin
			ws_ff1<=1;
			ws_ff2<=1;
			ws_ff3<=1;
		end
		else begin
			ws_ff1<=I2S_ws;
			ws_ff2<=ws_ff1;
			ws_ff3<=ws_ff2;
		end
	end
	
	
	reg [4:0] bit_cntr;
	reg clr_cnt;
	wire eq23,eq24;
	// A 5-bit counter to record how many useful bits are in the shift register
	always_ff@(posedge clk)begin
		bit_cntr<=clr_cnt?0:(sclk_rise?bit_cntr+1:bit_cntr);
	end
	
	assign eq23=(bit_cntr==5'd23)?1:0;
	assign eq24=(bit_cntr==5'd24)?1:0;
	
	// a 48-bit shift register to store the I2S data
	reg [47:0] shft_reg;
	assign lft_chnnl=shft_reg[47:24];
	assign rght_chnnl=shft_reg[23:0];
	
	always_ff@(posedge clk)begin
		shft_reg<=sclk_rise?{shft_reg[46:0],I2S_data}:shft_reg;
	end
	
	// state machine
	typedef enum reg [2:0] {not_synch,synching,left_data,right_data,synch_check} state_I2S;
	state_I2S state,nxt_state;
	always_ff@(posedge clk,negedge rst_n)begin
		if(!rst_n)begin
			state<=not_synch;
		end
		else
			state<=nxt_state;
	end
	
	always_comb begin
		vld=0;
		clr_cnt=0;
		nxt_state=state;
		case (state)
			not_synch:begin
				if(ws_fall)
					nxt_state=synching;
			end
			synching:begin // at this cycle, the I2S_data is R0, the left data appear in the next cycle
				if(sclk_rise)begin
					nxt_state=left_data;
					clr_cnt=1;
				end
			end
			left_data:begin // the bit_cntr is 1 when the I2S_data is L23
				if(eq24)begin
					nxt_state=right_data;
					clr_cnt=1;
				end
				end
			right_data:begin
				if(eq23&I2S_ws) // when the I2S_ws is 1, the I2S_data should be R1. Otherwise, it is not synchronized. 
					nxt_state=synch_check;
				else if(eq23&~I2S_ws) 
					nxt_state=not_synch;
			end
			synch_check:begin
				if(eq24&~I2S_ws)begin // when the I2S_ws is 0, the I2S_data should be R0. Otherwise, it is not synchronized. 
					nxt_state=left_data;
					clr_cnt=1;
					vld=1;
				end
				else if(eq24&I2S_ws)
					nxt_state=not_synch;
			end
			default:nxt_state=not_synch;
		endcase
	end

endmodule