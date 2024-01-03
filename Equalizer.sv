module Equalizer(clk,RST_n,LED,ADC_SS_n,ADC_MOSI,ADC_SCLK,ADC_MISO,
                 I2S_data,I2S_ws,I2S_sclk,cmd_n,sht_dwn,lft_PDM,
				 rght_PDM,lft_PDM_n,rght_PDM_n,Flt_n,next_n,
				 prev_n,RX,TX);
				  
    input clk;			// 50MHz CLOCK
	input RST_n;		// unsynched active low reset from push button
	output [7:0] LED;   // Extra credit opportunity, otherwise tie low
	output ADC_SS_n;	// Next 4 are SPI interface to A2D
	output ADC_MOSI;
	output ADC_SCLK;
	input ADC_MISO;
	input I2S_data;		// serial data line from BT audio
	input I2S_ws;		// word select line from BT audio
	input I2S_sclk;		// clock line from BT audio
	output cmd_n;		// hold low to put BT module in command mode
	output reg sht_dwn;	// hold high until low freq queues full
	output lft_PDM;	    // Duty cycle of this drives left speaker
	output rght_PDM;	// Duty cycle of this drives right speaker
	output lft_PDM_n;   // Inverted PDM for differential drive
	output rght_PDM_n;  // Inverted PDM for differential drive
	input Flt_n;		// when low Amp(s) had a fault and need shtdwn
	input next_n;		// active low to skip to next song
	input prev_n;		// active low to repeat previous song
	input RX;			// UART RX (115200) from BT audio module
	output TX;			// UART TX to BT audio module

    /////////////////////////////////////////////////////
	// Declare wires for internal connection of units //
	///////////////////////////////////////////////////
	wire [11:0] POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOLUME;
	wire signed [23:0] lft_chnnl_in, rght_chnnl_in;
	wire signed [15:0] lft_chnnl_out, rght_chnnl_out;
	logic vld, seq_low;
	wire rst_n;
	logic [15:0] bass_comp;
	
	  
	//assign LED = {8'h00};

		 

	/////////////////////////////////////
	// Instantiate Reset synchronizer //
	///////////////////////////////////
	rst_synch iRST(.clk(clk),.RST_n(RST_n),.rst_n(rst_n));


	//////////////////////////////////////
	// Instantiate Slide Pot Interface //
	////////////////////////////////////					
	slide_intf iSLD(.clk(clk),.rst_n(rst_n),.SS_n(ADC_SS_n),.MOSI(ADC_MOSI),.MISO(ADC_MISO),
	                .SCLK(ADC_SCLK),.POT_LP(POT_LP),.POT_B1(POT_B1),.POT_B2(POT_B2),
					.POT_B3(POT_B3),.POT_HP(POT_HP),.VOLUME(VOLUME));
				  
	//////////////////////////////////////
	// Instantiate BT module interface //
	////////////////////////////////////
	BT_intf iBT(.clk(clk),.rst_n(rst_n),.next_n(next_n),.prev_n(prev_n),
	            .RX(RX),.TX(TX), .cmd_n(cmd_n));
					
			
    //////////////////////////////////////
    // Instantiate I2S_Slave interface //
    ////////////////////////////////////
	I2S_Serf iI2S(.clk(clk),.rst_n(rst_n),.I2S_sclk(I2S_sclk),.I2S_data(I2S_data),
	               .I2S_ws(I2S_ws),.lft_chnnl(lft_chnnl_in),.rght_chnnl(rght_chnnl_in),
				   .vld(vld));

    /////////////////////////////////////////////////
    // Instantiate Equalizer Engine or equivalent //
    ///////////////////////////////////////////////	
	EQ_engine iEQ(.clk(clk),.rst_n(rst_n),.POT_LP(POT_LP),
	              .POT_B1(POT_B1),.POT_B2(POT_B2),.POT_B3(POT_B3),.POT_HP(POT_HP), .POT_VOL(VOLUME),
			      .aud_in_lft(lft_chnnl_in[23:8]),.aud_out_lft(lft_chnnl_out),
			      .aud_in_rght(rght_chnnl_in[23:8]),.aud_out_rght(rght_chnnl_out),
			      .vld(vld),.seq_low(seq_low), .bass(bass_comp));
				  
	//LED iLED(.clk(clk),.rst_n(rst_n),.lft(bass_comp),.rht(bass_comp),.LED(LED));
	LED iLED(.clk(clk),.rst_n(rst_n),.lft_LP(iEQ.scaled_LP_lft_ff),.lft_B1(iEQ.scaled_B1_lft_ff),.lft_B2(iEQ.scaled_B2_lft_ff),.lft_B3(iEQ.scaled_B3_lft_ff), .lft_HP(iEQ.scaled_HP_lft_ff), .lft_vld(vld), .LED(LED));

	/////////////////////////////////////
	// Instantiate PDM speaker driver //
	///////////////////////////////////
	spkr_drv iDRV(.clk(clk),.rst_n(rst_n),.vld(vld),.lft_chnnl(lft_chnnl_out),
	              .rght_chnnl(rght_chnnl_out),.lft_PDM(lft_PDM),.rght_PDM(rght_PDM),
				  .lft_PDM_n(lft_PDM_n),.rght_PDM_n(rght_PDM_n));
				  
	///////////////////////////////////////////////////////////////
	// Infer sht_dwn/Flt_n logic or incorporate into other unit //
	/////////////////////////////////////////////////////////////

	reg [17:0] timer_cntr;
	reg Enable;
	
	// rising edge detector for Flt_n
	wire Flt_rise;
	reg Flt_ff1;
	reg Flt_ff2;
	reg Flt_ff3;
	always_ff@(posedge clk,negedge rst_n)begin
		if(!rst_n)begin
			Flt_ff1<=0;
			Flt_ff2<=0;
			Flt_ff3<=0;
		end
		else begin
			Flt_ff1<=Flt_n;
			Flt_ff2<=Flt_ff1;
			Flt_ff3<=Flt_ff2;
		end
	end
	
	assign Flt_rise=~Flt_ff3&Flt_ff2;
	
	//rising edge detector for rst_n
	reg rst_ff;
	wire rst_rise;
	always_ff@(posedge clk)begin
		rst_ff<=rst_n;
	end
	
	assign rst_rise=~rst_ff&rst_n;
	
	always_ff@(posedge clk,negedge rst_n)begin
		if(!rst_n)
			timer_cntr<=0;
		else if(~Flt_n)
			timer_cntr<=0;
		else if(Enable)
			timer_cntr<=timer_cntr+1;
	end
	
	// flop the Enable
	always_ff@(posedge clk)begin
		if(rst_rise|Flt_rise)
			Enable<=1;
		else if(timer_cntr>=18'd250000)begin
			Enable<=0;
		end
	end
	
	
	
	assign sht_dwn=timer_cntr<18'd250000;
	
	
	logic signed [15:0] lft_chnnl_uf, rght_chnnl_uf, fir_lft_chnnl, fir_rght_chnnl;
	always_ff@(posedge clk) begin
		if(vld) begin
			lft_chnnl_uf <= lft_chnnl_in[23:8];
			rght_chnnl_uf <= rght_chnnl_in[23:8];
		end
	end

	always_ff@(posedge clk) begin
		if(vld) begin
			fir_lft_chnnl <= lft_chnnl_out;
			fir_rght_chnnl <= rght_chnnl_out;
		end
	end
	

endmodule
