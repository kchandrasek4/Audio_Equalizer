module SPI_data_shreg(clk, init, shft, cmd, MISO, shft_reg);

	input clk, init, shft, MISO;
	input [15:0] cmd;
	output logic [15:0] shft_reg;

	always_ff@(posedge clk) begin
		casez({init, shft})
			2'b01: shft_reg <= {shft_reg[14:0], MISO};
			2'b1?: shft_reg <= cmd;
			default: shft_reg <= shft_reg;
		endcase
	end

endmodule
