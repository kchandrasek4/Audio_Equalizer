module snd_cmd(input clk, input rst_n, input logic [4:0] cmd_start, input send, input logic [3:0] cmd_len, output resp_rcvd, output logic TX, input logic RX);
	 // State machine states
	typedef enum logic [1:0] {IDLE, ROM_WAIT, TRANSM, RCV} state_t;
	// Internal state machine signals
	state_t state, next_state;
	
	//necessary signals relevant to connect to module instantiations and incrementing address
	logic rx_rdy, tx_done, last_byte, trmt, inc_address;
	logic [7:0] rx_data, tx_data;
	
	//first and last addresses of commands
	logic [4:0] addr_flop; 
	logic [4:0]last_flop;
	
	
//instantiating helper UART and CMD_ROM modules and connecting signals. 
	UART uart_dut(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .rx_rdy(rx_rdy), .clr_rx_rdy(rx_rdy), .rx_data(rx_data), .trmt(trmt), .tx_data(tx_data), .tx_done(tx_done));
	cmdROM cmd_rom_dut(.clk(clk), .addr(addr_flop), .dout(tx_data));
	
	//once 0x0A  received transaction complete
	assign resp_rcvd = (rx_rdy) ? ((rx_data === 8'h0A) ? 1'b1:1'b0):(1'b0);
	
	//if last byte of data is to be sent this is asserted
	assign last_byte = (addr_flop === last_flop) ? (1'b1):(1'b0);
	
//flipflop concerned with initializing which addr (start if first byte, or incremented according to how many bytes sent) to cmdROM
	always_ff @(posedge clk) begin
	if(send)
	   addr_flop <= cmd_start;
	else if(inc_address === 1'b1)
		addr_flop <= addr_flop+1;

			
			
		
	end
//flipflop concerned with last_byte asserting	
	always_ff @(posedge clk) begin 
	if(send) 
		last_flop <= cmd_len + cmd_start;
	
	end

//flipflop that resets state of machine on rst_n or assign next_state to current state
	always_ff @(posedge clk or negedge rst_n) begin
	
	if(!rst_n)
		state <= IDLE;
	
	else
		state <= next_state; 
	end

//state machine control
	always_comb  begin
	next_state = state;
	trmt = 1'b0;
	inc_address = 1'b0;
      case (state)
	  //IDLE STATE WHEN WAITING FOR NEXT COMMAND TO BE SENT
        IDLE: begin
          if (send)  // send triggers state change
            next_state = ROM_WAIT;
          
		  else
		  next_state = state;
		  
        end
		//WAITING 1 CLOCK CYCLE FOR ROM TO PRODUCE DOUT
        ROM_WAIT: begin
		//have to wait one clock edge before continuing
		
			
			next_state = TRANSM;
			
			
        end
		//START TRANSMISSION OF CURRENT ADDRESS POINTER
        TRANSM: begin
		
		  trmt = 1'b1;			
		  inc_address = 1'b1;
		  next_state = RCV;
		
		
						
        end
       //WAITING TILL TRANSMITTED COMMAND IS RECEIVED. IF TX DONE THEN GO BACK TO IDLE
        RCV: begin
			if(tx_done) begin			
				if(last_byte)
					next_state = IDLE;
				else	
					next_state = TRANSM;
			end					
        end
      endcase
    end
	
endmodule
