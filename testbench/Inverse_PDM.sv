module Inverse_PDM(clk, rst_n, PDM, duty, done);

	input logic clk, rst_n, PDM;
	
	output logic done;
	output logic [15:0] duty; //2^11 	
	
	logic [10:0] high_cntr;
	logic [15:0] duty_smpl;
	logic [10:0] cycle_cntr;

	logic done_unflop;
	
	
	
	
	
	always_ff@(posedge clk, negedge rst_n) begin
		if(!rst_n)
			cycle_cntr <= 0;
		else
			cycle_cntr <= cycle_cntr + 1;
	end
	
	always_ff@(posedge clk, negedge rst_n) begin
		if(!rst_n)
			high_cntr <= 0;
		else if(done_unflop)
			high_cntr <= 0;
		else if(PDM)
			high_cntr <= high_cntr + 1;
	end
	
	assign done_unflop = (cycle_cntr == (2**11 - 1));
	assign duty_smpl=high_cntr*32;
	
	always_ff@(posedge clk, negedge rst_n) begin
		if(!rst_n)
			duty <= 0;
		else if(done_unflop)
			duty <= duty_smpl;
	end
	
	always_ff@(posedge clk, negedge rst_n) begin
		if(!rst_n)
			done <= 0;
		else
			done <= done_unflop;
	end
endmodule
