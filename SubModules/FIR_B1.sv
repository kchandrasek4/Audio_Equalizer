module FIR_B1(clk,rst_n,lft_in,rght_in,sequencing,lft_out,rght_out);
	input signed [15:0] lft_in,rght_in;
	input sequencing;
	input clk,rst_n;
	output [15:0] lft_out, rght_out;
	
	
	wire signed [15:0] coeff_dout;
	logic [9:0] ROM_addr;
	logic signed [31:0] lft_conv_sum,rght_conv_sum;
	
	
	ROM_B1 ROM(.clk(clk),.addr(ROM_addr),.dout(coeff_dout));
	
	logic addr_adder_clear;
	logic addr_adder_accum;
	
	logic conv_adder_clear;
	logic conv_adder_accum;
	
	assign lft_out=lft_conv_sum[30:15];
	assign rght_out=rght_conv_sum[30:15];
	
	always_ff@(posedge clk,negedge rst_n)begin
		if(!rst_n)
			ROM_addr<=0;
		else if(addr_adder_clear)
			ROM_addr<=0;
		else if(addr_adder_accum)
			ROM_addr<=ROM_addr+1;
	end
	
	always_ff@(posedge clk,negedge rst_n)begin
		if(!rst_n)begin
			lft_conv_sum<=0;
			rght_conv_sum<=0;
		end
		else if(conv_adder_clear)begin
			lft_conv_sum<=0;
			rght_conv_sum<=0;
		end
		else if(conv_adder_accum)begin
			lft_conv_sum<=lft_in*coeff_dout+lft_conv_sum;
			rght_conv_sum<=rght_in*coeff_dout+rght_conv_sum;
		end
	end
	
	
	
	typedef enum reg {IDLE,CONVOLUTION} state_t;
	state_t nxt_state, state;
	
	
	always_ff@(posedge clk,negedge rst_n)begin
		if(!rst_n)
			state<=IDLE;
		else
			state<=nxt_state;
	end
	
	always_comb begin
		addr_adder_clear=0;
		addr_adder_accum=0;
		conv_adder_clear=0;
		conv_adder_accum=0;
		nxt_state=state;
		case(state)
			IDLE:
				if(sequencing)begin
					addr_adder_accum=1; // make the addr output of the counter 1 in the first cycle in the COVOLUTION CYCLE,
					conv_adder_clear=1;
					nxt_state=CONVOLUTION;
				end
			CONVOLUTION:
				if(!sequencing)begin // when transition back from CONVOLUTION TO IDLE, all the convolution is already done, so no need to accumulate the convolution counter
					addr_adder_clear=1;
					nxt_state=IDLE;
				end
				else begin
					addr_adder_accum=1;// the first cycle of the CONVOLUTION, ROM out is ROM[addr[0]], and the product is added to lft_out
					conv_adder_accum=1;
				end
			default:
				nxt_state=IDLE;
		endcase
	end
	
endmodule