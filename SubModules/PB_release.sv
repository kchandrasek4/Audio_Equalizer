module PB_release(PB, clk, rst_n, released);

	input logic PB, clk, rst_n;
	output logic released;
	
	logic flop1, flop2, flop3;

	always@(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			flop1 <= 1'b1;
			flop2 <= 1'b1;
			flop3 <= 1'b1;
		end
		else begin
			flop1 <= PB;
			flop2 <= flop1;
			flop3 <= flop2;
		end
	end

	assign released = flop2 & ~flop3;

endmodule
