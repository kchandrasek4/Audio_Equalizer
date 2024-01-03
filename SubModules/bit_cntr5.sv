module bit_cntr5(clk, init, shift,
		done16);

	input clk, init, shift;
	output done16;

	logic [4:0] cnt;

	always@(posedge clk, posedge init) begin
		if(init)
			cnt <= '0;
		else if(shift)
			cnt <= cnt + 5'b1;
	end
	assign done16 = cnt[4];

endmodule


