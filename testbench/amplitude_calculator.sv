module amplitude_calculator(clk,rst_n,duty_cycle,duty_cycle_vld,amplitude_vld,peak);
	input clk, rst_n;
	input [15:0] duty_cycle;
	input duty_cycle_vld; // duty cycle vld needs to be a pulse
	output logic amplitude_vld;
	output logic [15:0] peak;
	

	
	logic [15:0] duty_cycle_ff,duty_cycle_ff_1,duty_cycle_ff_2,duty_cycle_ff_3,duty_cycle_ff_4, duty_cycle_ff_5, duty_cycle_avg,duty_cycle_avg_nxt,duty_cycle_avg_pre;
	
	
    
	
	always_ff@(posedge clk,negedge rst_n)begin
		if(!rst_n)begin
			//first flop
			duty_cycle_ff<=0;
			duty_cycle_ff_1<=0;
			duty_cycle_ff_2<=0;
            duty_cycle_ff_3<=0;
            duty_cycle_ff_4<=0;
            duty_cycle_ff_5<=0;
		end
		else if(duty_cycle_vld)begin
			//first flop
			duty_cycle_ff<=duty_cycle;
			duty_cycle_ff_1<=duty_cycle_ff;
			duty_cycle_ff_2<=duty_cycle_ff_1;
            duty_cycle_ff_3<=duty_cycle_ff_2;
            duty_cycle_ff_4<=duty_cycle_ff_3;
            duty_cycle_ff_5<=duty_cycle_ff_4;
		end
	end

	// if the middle point is larger than the previous point and the next point
	assign duty_cycle_avg_pre=(duty_cycle_ff_1+duty_cycle_ff_2+duty_cycle_ff_3+duty_cycle_ff_4+duty_cycle_ff_5)/5;
	assign duty_cycle_avg=(duty_cycle_ff+duty_cycle_ff_1+duty_cycle_ff_2+duty_cycle_ff_3+duty_cycle_ff_4)/5;
    assign duty_cycle_avg_nxt=(duty_cycle+duty_cycle_ff+duty_cycle_ff_1+duty_cycle_ff_2+duty_cycle_ff_3)/5;




	assign peak=(duty_cycle_ff_2+duty_cycle_ff_3)/2;
	assign amplitude_vld=((duty_cycle_avg>duty_cycle_avg_pre)&(duty_cycle_avg>duty_cycle_avg_nxt)&duty_cycle_vld)&(peak>32768);
	
	
	
endmodule