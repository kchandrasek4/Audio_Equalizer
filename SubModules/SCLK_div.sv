module SCLK_div(clk, rst_n, ld_SCLK, SCLK, full, shft);

	// CLK divider. Count from 1 to 32. MSB is SCLK.
	input clk, rst_n, ld_SCLK;
	output logic SCLK, full, shft;

	logic [4:0] cnt;

	always_ff@(posedge clk, negedge rst_n) begin
		if(!rst_n)
			cnt <= 5'b10111;
		else if(ld_SCLK)
			cnt <= 5'b10111;		// Why this absurd value? SCLK should fall sometime after SS_n falls. To keep SCLK high for sometime (8 clks in this case), we load this value.
		else
			cnt <= cnt + 5'b1;
	end
	
	always_comb begin
		SCLK = cnt[4];
		shft = cnt[4] & ~cnt[3] & ~cnt[2] & ~cnt[1] & cnt[0]; // cnt == 5'b10001? Why? Shift 2 clks after rise in SCLK. 
		full = &cnt;
	end

endmodule
