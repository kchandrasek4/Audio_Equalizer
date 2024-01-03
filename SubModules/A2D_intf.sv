module A2D_intf(clk, rst_n, strt_cnv, chnnl, a2d_SS_n, SCLK, MOSI, MISO, cnv_cmplt, res);

	input clk, rst_n, strt_cnv, MISO;
	input [2:0] chnnl;

	output logic a2d_SS_n, SCLK, MOSI, cnv_cmplt;
	output logic [11:0] res;


	// SM signals
	// outputs
	logic snd, txn_end;
	logic [15:0] cmd;
	//inputs
	logic done;
	logic [15:0] resp;

	// SPI Interface Module
	SPI_mnrch SPI_intf(.clk(clk), .rst_n(rst_n), .snd(snd), .cmd(cmd), .MISO(MISO), .SS_n(a2d_SS_n), .SCLK(SCLK), .MOSI(MOSI), .done(done), .resp(resp));

	// SM state
	typedef enum logic [1:0] {IDLE, TX, WAIT, RX} state_t;
	state_t state, nxt_state;

	// State Registers.
	always_ff@(posedge clk, negedge rst_n) begin
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	end

	always_comb begin
		snd = 0;
		txn_end = 0;
		nxt_state = state; 
		case(state)
		IDLE: if(strt_cnv) begin
			  snd = 1;
			  nxt_state = TX;
		      end
		TX: if(done) begin
			nxt_state = WAIT;		// Wait one clock cycle before starting to read data from device.
		    end
		WAIT: begin
			snd = 1;			// One clock cycle elapsed. Start another transaction to read data.
			nxt_state = RX;
		      end
		RX: if(done) begin
			txn_end = 1;
			nxt_state = IDLE;
		    end
		endcase

	end
	
	assign cmd = {2'b00, chnnl, 11'b0};	// Start transaction - send channel number to read from device
	
	// Latch cnv_cmplt. It should remain high until the start of the next txn or reset.
	always_ff@(posedge clk, negedge rst_n)
		if(!rst_n)
			cnv_cmplt <= 0;
		else if(snd)
			cnv_cmplt <= 0;
		else if(txn_end)
			cnv_cmplt <= 1;

	// resp from SPI_mnrch is already latched. So, can assign it to res directly.
	assign res = resp[11:0];

endmodule
