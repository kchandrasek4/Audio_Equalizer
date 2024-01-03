module BT_intf(input clk, input rst_n, input next_n, input prev_n, output logic cmd_n, output logic TX, input logic RX);

logic [4:0] cmd_start;
logic [3:0] cmd_len;

logic send, resp_rcvd, prev_released, next_released, clr_cnt, done;
logic next_done, prev_done;
logic [16:0] bit_cntr;

snd_cmd snd_DUT(.clk(clk), .rst_n(rst_n), .cmd_start(cmd_start), .send(send), .cmd_len(cmd_len), .resp_rcvd(resp_rcvd), .TX(TX), .RX(RX));
PB_release prev_PB(.rst_n(rst_n), .clk(clk), .PB(prev_n), .released(prev_released));
PB_release next_PB(.rst_n(rst_n), .clk(clk), .PB(next_n), .released(next_released));



  // State machine states
  typedef enum logic [1:0] {IDLE, INIT_1, INIT_2, FINAL} state_t;
  // Internal state machine signals
  state_t state, next_state;


// bit_cntr determining flipflop and state assignment incase of reset
	always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= IDLE;
            bit_cntr <= 0;
			cmd_n <= 1;
        end
        else begin
            state <= next_state;
            bit_cntr <= (clr_cnt) ? (5'b00000) : (bit_cntr + 1);
			cmd_n <= (bit_cntr === 17'h1FFFF) ? (1'b0) : (cmd_n);
			
        end
    end
	
	//This entire block is built with the only purpose of making sure send is set to low the cycle after it has been recognized by snd_cmd.sv 
	always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            
			next_done <= 0;
			prev_done <= 0;
			
        end
		
		else if (state === FINAL) begin
				if (send === 1'b1) begin
					next_done <= 1;
					prev_done <= 1;
				end
				else begin
					next_done <= 0;
					prev_done <= 0;
				end
		end
		
	end
 
	
	always_comb  begin
	next_state = state;
	clr_cnt = 1'b0;
	send = 0;
	cmd_len = 0;
	cmd_start = 0;
      case (state)
	  //WAITING FOR BIT_CNTR TO BE FULL
        IDLE: begin
			
          if (!cmd_n & resp_rcvd) begin // bit_cntr is full
            next_state = INIT_1;
			cmd_start = 5'b00000;
			cmd_len = 4'b0110;
			send = 1;
          end
		  else
			next_state = state;
        end
		//sending of: S|,01 with carriage return switches output mode of RN-52 to I2S. Wait for 0x0A
        INIT_1: begin
			
			
			//making sure send is active only for one clock cyle and final state is set
			if (resp_rcvd) begin
					next_state = INIT_2;
					cmd_start = 5'b00110;
					cmd_len = 4'b1010;
					send = 1'b1;
			end
			else
			next_state = state;
        end
		//This sets the advertising name to ��$2G1K$” wait for 0x0A
		//The name stands for "$ 2 Grads 1 Kid $"
        INIT_2: begin
			
			
			//making sure send is active only for one clock cyle and final state is set
            if (resp_rcvd)
					next_state = FINAL;
			
			else
				next_state = state;
          end
        //PROCEED TO FINAL STATE WHICH CHECKS FOR NEXT OR PREV BUTTON TO BE CLICKED
        FINAL: begin
		  //checking if next button input received
			if(next_released) begin		//
					cmd_start = 5'b10000;
					cmd_len = 4'b0100;
					send = 1;
					//making sure send is active only for one clock cyle
					if(next_done) 
						send = 1'b0;				
				end
		//checking if prev button has been released
			else if(prev_released) begin
					cmd_start = 5'b10100;
					cmd_len = 4'b0100;
					send = 1;
					//making sure send is active only for one clock cyle
					if(prev_done) 
						send = 1'b0;
					
				end
				
		end		

        
      endcase
    end

endmodule
