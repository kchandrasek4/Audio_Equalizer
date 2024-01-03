module rst_synch(RST_n,clk,rst_n);
	input RST_n;
	input clk;
	output reg rst_n;
	
	reg ff_1;
	// ensure rst_n is coming to zero at the negative edge
	always_ff @ (negedge clk, negedge RST_n) begin
		if(!RST_n)begin
			rst_n<=1'b0;
			ff_1<=1'b0;
		end
		else begin
			ff_1<=1'b1;
			rst_n<=ff_1;
		end
	end
endmodule