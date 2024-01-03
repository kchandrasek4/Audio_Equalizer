module frequency_calculator(clk,rst_n,duty_cycle,duty_cycle_vld,counter_vld,clk_counter);
	input clk, rst_n;
	input [15:0] duty_cycle;
	input duty_cycle_vld; // duty cycle vld needs to be a pulse
	output logic counter_vld;
	output logic [20:0] clk_counter;// assume FGPA is 50MHz, the lowest frequency it can count is 32Hz. log2(50000000/32)=21. 
									// needs to be converted to frequency in the test bench
	
	
	localparam zero_point=16'd32768;
	
	logic [15:0] duty_cycle_ff,duty_cycle_ff_1,duty_cycle_ff_2,duty_cycle_ff_3,duty_cycle_ff_4,duty_cycle_avg,duty_cycle_avg_nxt;
	
	wire zero_crossing;
	logic clk_counter_start;


	
	
	
	// timer counter_vld
	always_ff@(posedge clk,negedge rst_n)begin
		if(!rst_n)begin
			clk_counter<=0;
		end
		else if(clk_counter_start)begin
			clk_counter<=0;
		end
		else
			clk_counter<=clk_counter+1;
	end
	
	
	
	// zero crossing checking
	
	always_ff@(posedge clk,negedge rst_n)begin
		if(!rst_n)begin
			//first flop
			duty_cycle_ff<=0;
			duty_cycle_ff_1<=0;
			duty_cycle_ff_2<=0;
			duty_cycle_ff_3<=0;
			duty_cycle_ff_4<=0;
		end
		else if(duty_cycle_vld)begin
			//first flop
			duty_cycle_ff<=duty_cycle;
			duty_cycle_ff_1<=duty_cycle_ff;
			duty_cycle_ff_2<=duty_cycle_ff_1;
			duty_cycle_ff_3<=duty_cycle_ff_2;
			duty_cycle_ff_4<=duty_cycle_ff_3;
		end
	end

	assign duty_cycle_avg_nxt=(duty_cycle_ff+duty_cycle_ff_1+duty_cycle_ff_2+duty_cycle_ff_3+duty_cycle_ff_4)/5;
	assign duty_cycle_avg=(duty_cycle_ff+duty_cycle_ff_1+duty_cycle_ff_2+duty_cycle_ff_3+duty_cycle)/5;


	

	
	assign zero_crossing=((duty_cycle_avg_nxt>=zero_point)&(duty_cycle_avg<zero_point)&duty_cycle_vld)|((duty_cycle_avg_nxt<zero_point)&(duty_cycle_avg>=zero_point)&duty_cycle_vld);
	
	
	// state machine to count zero crossings
	typedef enum reg [1:0] {IDLE, FRT_ZERO, SED_ZERO} state_t;
	 
	
	state_t nxt_state, state;
	
	always_ff@(posedge clk,negedge rst_n)begin
		if(!rst_n)
			state<=IDLE;
		else
			state<=nxt_state;
	end
	
	always_comb begin
		nxt_state=state;
		counter_vld=0;
		clk_counter_start=0; 
		case(state)
			IDLE:
				if(zero_crossing)begin
					nxt_state=FRT_ZERO;
					clk_counter_start=1; // start the timer counter from zero at the first zerocrossing
				end
			FRT_ZERO:
				if(zero_crossing)
					nxt_state=SED_ZERO;
			SED_ZERO:
				if(zero_crossing)begin
					nxt_state=IDLE;
					counter_vld=1; // the counter timer at the last zero crossing 
				end
			default:
				nxt_state=IDLE;
		endcase
	end
endmodule