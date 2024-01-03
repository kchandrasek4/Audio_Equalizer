/*
module LED(clk,rst_n,lft,rht,LED);
	input clk,rst_n;
	
	input [15:0] lft, rht;
	
	output [7:0] LED;

	assign LED = lft[10:3];
endmodule
*/


module LED(clk,rst_n,lft_LP,lft_B1,lft_B2,lft_B3, lft_HP, lft_vld, LED);
	input clk,rst_n;
	
	input [15:0] lft_LP, lft_B1, lft_B2, lft_B3, lft_HP;
	
	input lft_vld;
	output [7:0] LED;

	logic amp_vld_left_LP,amp_vld_left_B1,amp_vld_left_B2,amp_vld_left_B3,amp_vld_left_HP;


	logic [15:0] peak_left_LP,peak_left_B1, peak_left_B2, peak_left_B3, peak_left_HP;
	logic [15:0] peak_left_LP_ff,peak_left_B1_ff, peak_left_B2_ff, peak_left_B3_ff, peak_left_HP_ff;


	amplitude_calculator cal_LP(.clk(clk),.rst_n(rst_n),.duty_cycle(lft_LP),.duty_cycle_vld(lft_vld),.amplitude_vld(amp_vld_left_LP),.peak(peak_left_LP));
	amplitude_calculator cal_B1(.clk(clk),.rst_n(rst_n),.duty_cycle(lft_B1),.duty_cycle_vld(lft_vld),.amplitude_vld(amp_vld_left_B1),.peak(peak_left_B1));
	amplitude_calculator cal_B2(.clk(clk),.rst_n(rst_n),.duty_cycle(lft_B2),.duty_cycle_vld(lft_vld),.amplitude_vld(amp_vld_left_B2),.peak(peak_left_B2));
	amplitude_calculator cal_B3(.clk(clk),.rst_n(rst_n),.duty_cycle(lft_B3),.duty_cycle_vld(lft_vld),.amplitude_vld(amp_vld_left_B3),.peak(peak_left_B3));
	amplitude_calculator cal_HP(.clk(clk),.rst_n(rst_n),.duty_cycle(lft_HP),.duty_cycle_vld(lft_vld),.amplitude_vld(amp_vld_left_HP),.peak(peak_left_HP));

	always_ff@(posedge clk, negedge rst_n)begin
		if(!rst_n)begin
			peak_left_LP_ff<=0;
			peak_left_B1_ff<=0;
			peak_left_B2_ff<=0;
			peak_left_B3_ff<=0;
			peak_left_HP_ff<=0;
		end
		else if(lft_vld) begin
			peak_left_LP_ff<=peak_left_LP;
			peak_left_B1_ff<=peak_left_B1;
			peak_left_B2_ff<=peak_left_B2;
			peak_left_B3_ff<=peak_left_B3;
			peak_left_HP_ff<=peak_left_HP;
		end
	end

	PDM PDM_LED_LP(.clk(clk),.rst_n(rst_n),.duty(peak_left_LP_ff),.PDM(LED[0]),.PDM_n());
	PDM PDM_LED_B1(.clk(clk),.rst_n(rst_n),.duty(peak_left_B1_ff),.PDM(LED[1]),.PDM_n());
	PDM PDM_LED_B2(.clk(clk),.rst_n(rst_n),.duty(peak_left_B2_ff),.PDM(LED[2]),.PDM_n());
	PDM PDM_LED_B3(.clk(clk),.rst_n(rst_n),.duty(peak_left_B3_ff),.PDM(LED[3]),.PDM_n());
	PDM PDM_LED_HP(.clk(clk),.rst_n(rst_n),.duty(peak_left_HP_ff),.PDM(LED[4]),.PDM_n());



endmodule
