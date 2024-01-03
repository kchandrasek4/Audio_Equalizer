`timescale 1ns/1ps
module Equalizer_tb();

reg clk,RST_n;
reg next_n,prev_n,Flt_n;
reg [11:0] LP,B1,B2,B3,HP,VOL;

wire [7:0] LED;
wire ADC_SS_n,ADC_MOSI,ADC_MISO,ADC_SCLK;
wire I2S_data,I2S_ws,I2S_sclk;
wire cmd_n,RX_TX,TX_RX;
wire lft_PDM,rght_PDM;
wire lft_PDM_n,rght_PDM_n;

wire [20:0] clk_counter;
wire counter_vld;
wire duty_vld;
wire [15:0] duty_infered;

wire rst_n;

logic [1:0] BT_state;
logic BT_resp, PB;

//////////////////////
// Instantiate DUT //
////////////////////
Equalizer iDUT(.clk(clk),.RST_n(RST_n),.LED(LED),.ADC_SS_n(ADC_SS_n),
                .ADC_MOSI(ADC_MOSI),.ADC_SCLK(ADC_SCLK),.ADC_MISO(ADC_MISO),
                .I2S_data(I2S_data),.I2S_ws(I2S_ws),.I2S_sclk(I2S_sclk),.cmd_n(cmd_n),
				.sht_dwn(sht_dwn),.lft_PDM(lft_PDM),.rght_PDM(rght_PDM),
				.lft_PDM_n(lft_PDM_n),.rght_PDM_n(rght_PDM_n),.Flt_n(Flt_n),
				.next_n(next_n),.prev_n(prev_n),.RX(RX_TX),.TX(TX_RX), .BT_state(BT_state), .BT_resp(BT_resp), .BT_PB_next(PB));
	

rst_synch iRST(.clk(clk),.RST_n(RST_n),.rst_n(rst_n));
//////////////////////////////////////////
// Instantiate model of RN52 BT Module //
////////////////////////////////////////	
//RN52 iRN52(.clk(clk),.RST_n(rst_n),.cmd_n(1'b1),.RX(1'b1),.TX(RX_TX),.I2S_sclk(I2S_sclk),
//           .I2S_data(I2S_data),.I2S_ws(I2S_ws));


RN52 iRN52(.clk(clk),.RST_n(rst_n),.cmd_n(cmd_n),.RX(TX_RX),.TX(RX_TX),.I2S_sclk(I2S_sclk),
           .I2S_data(I2S_data),.I2S_ws(I2S_ws));


//////////////////////////////////////////////
// Instantiate model of A2D and Slide Pots //
////////////////////////////////////////////		   
A2D_with_Pots iPOTs(.clk(clk),.rst_n(rst_n),.SS_n(ADC_SS_n),.SCLK(ADC_SCLK),.MISO(ADC_MISO),
                    .MOSI(ADC_MOSI),.LP(LP),.B1(B1),.B2(B2),.B3(B3),.HP(HP),.VOL(VOL));
					
					
frequency_calculator ifreq_cal(.clk(clk),.rst_n(rst_n),.duty_cycle(duty_infered),.duty_cycle_vld(duty_vld),
								.counter_vld(counter_vld),.clk_counter(clk_counter));	

Inverse_PDM invPDM(.clk(clk), .rst_n(rst_n), .PDM(lft_PDM), .duty(duty_infered), .done(duty_vld));
			
initial begin
  
  //This is where your magic occurs

// Initialise modules - apply global reset, init prev and next buttons, set all gains to unity.
	clk = 0;
	RST_n = 0;
	prev_n = 1;
	next_n = 1;

	LP = 12'h800;
	B1 = 12'h800;
	B2 = 12'h800;
	B3 = 12'h800;
	HP = 12'h800;

	VOL = 12'h800;

	repeat(10) @(negedge clk);
	RST_n = 1;

	repeat(300000) @(posedge clk);
	
	
	//press next_n
	@(negedge clk);
	next_n = 0;
	@(negedge clk);
	next_n=1;
	
	repeat(300000) @(posedge clk);
	
	
	//press prev_n
	prev_n = 0;
	repeat(10)@(negedge clk)prev_n=1;


// Test Case 2: Preserve B2 (unity gain); attenuate all other bands
	LP = 12'h000;
	B1 = 12'h000;
	B2 = 12'h800;
	B3 = 12'h000;
	HP = 12'h000;
	
	VOL = 12'h800; // Keep vol at unity gain

	
	// Now we wait... for a long time
	repeat(3000000) @(posedge clk);


	$stop;
end

always
  #5 clk = ~ clk;

always@(posedge counter_vld)begin
	$display("counter:%d",clk_counter);
end
  
endmodule
