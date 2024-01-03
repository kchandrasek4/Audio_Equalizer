module EQ_engine(clk, rst_n, aud_in_lft, aud_in_rght, vld, POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, POT_VOL, aud_out_lft, aud_out_rght, seq_low, bass);
  
	input clk, rst_n;
	input [15:0] aud_in_lft, aud_in_rght;
	input vld;
  	input [11:0] POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, POT_VOL;
  	output logic signed [15:0] aud_out_lft, aud_out_rght;
	output logic seq_low;
  	output logic [15:0] bass ;

	logic [15:0] lft_out_high_q, rght_out_high_q;
	logic [15:0] lft_out_low_q, rght_out_low_q;
  
  	logic [15:0] lft_out_lp, rght_out_lp, lft_out_b1, rght_out_b1, lft_out_b2, rght_out_b2, lft_out_b3, rght_out_b3, lft_out_hp, rght_out_hp;
	
	logic sequencing_low;
	logic sequencing_high;
	
	logic wrt_smpl_low, alt_pulse_state, alt_pulse_nxt_state;
  
  	logic signed [15:0] scaled_LP_lft, scaled_B1_lft, scaled_B2_lft, scaled_B3_lft, scaled_HP_lft, scaled_LP_rght, scaled_B1_rght, scaled_B2_rght, scaled_B3_rght, scaled_HP_rght;
  	logic signed [15:0] audio_combined_lft, audio_combined_rght;
  	logic signed [28:0] audio_vol_lft, audio_vol_rght;
  
	logic signed [13:0] volume_signed;
	// Alternate pulse detector (for low freq queue)	

	always_ff@(posedge clk, negedge rst_n)
		if(!rst_n)
			alt_pulse_state <= 1'b0;
		else if(vld)
			alt_pulse_state <= alt_pulse_nxt_state;


	always_comb begin
		alt_pulse_nxt_state = alt_pulse_state;
		case(alt_pulse_state)
		1'b0: if(vld)
			alt_pulse_nxt_state = 1'b1;
		1'b1: if(vld)
			alt_pulse_nxt_state = 1'b0;
		endcase
	end

	assign wrt_smpl_low = (alt_pulse_state == 1'b0)?vld:0;

	/*
	always_ff@(posedge clk,negedge rst_n)begin
    if(!rst_n)
      	divider<=0;
    else if(vld)
      	divider<=~divider;
	end
	
	assign wrt_smpl_low = vld & ~divider;
	*/

	//QUEUE INSTANTIATIONS
	high_freq_queue i_high_queue(.clk(clk),.rst_n(rst_n),.lft_smpl(aud_in_lft),.rght_smpl(aud_in_rght),.wrt_smpl(vld),
						.lft_out(lft_out_high_q),.rght_out(rght_out_high_q),.sequencing(sequencing_high));
	
	low_freq_queue i_low_queue(.clk(clk),.rst_n(rst_n),.lft_smpl(aud_in_lft),.rght_smpl(aud_in_rght),.wrt_smpl(wrt_smpl_low),
						.lft_out(lft_out_low_q),.rght_out(rght_out_low_q),.sequencing(sequencing_low));
	
  //FIR INSTANTIATIONS
  FIR_LP fir_lp_dut(.clk(clk), .rst_n(rst_n), .lft_in(lft_out_low_q), .rght_in(rght_out_low_q), .sequencing(sequencing_low), .lft_out(lft_out_lp), .rght_out(rght_out_lp));
	FIR_B1 fir_b1_dut(.clk(clk), .rst_n(rst_n), .lft_in(lft_out_low_q), .rght_in(rght_out_low_q), .sequencing(sequencing_low), .lft_out(lft_out_b1), .rght_out(rght_out_b1));
	FIR_B2 fir_b2_dut(.clk(clk), .rst_n(rst_n), .lft_in(lft_out_high_q), .rght_in(rght_out_high_q), .sequencing(sequencing_high), .lft_out(lft_out_b2), .rght_out(rght_out_b2));
	FIR_B3 fir_b3_dut(.clk(clk), .rst_n(rst_n), .lft_in(lft_out_high_q), .rght_in(rght_out_high_q), .sequencing(sequencing_high), .lft_out(lft_out_b3), .rght_out(rght_out_b3));
	FIR_HP fir_hp_dut(.clk(clk), .rst_n(rst_n), .lft_in(lft_out_high_q), .rght_in(rght_out_high_q), .sequencing(sequencing_high), .lft_out(lft_out_hp), .rght_out(rght_out_hp));
  
  
  
  
  //BANDSCALE INSTANTIATIONS
	//band_scale band_lp_lft(.POT(POT_LP), .audio(lft_out_lp), .scaled(scaled_LP_lft));
	//band_scale band_lp_rght(.POT(POT_LP), .audio(rght_out_lp), .scaled(scaled_LP_rght));
	//band_scale band_b1_lft(.POT(POT_B1), .audio(lft_out_b1), .scaled(scaled_B1_lft));
	//band_scale band_b1_rght(.POT(POT_B1), .audio(rght_out_b1), .scaled(scaled_B1_rght));
	//band_scale band_b2_lft(.POT(POT_B2), .audio(lft_out_b2), .scaled(scaled_B2_lft));
	//band_scale band_b2_rght(.POT(POT_B2), .audio(rght_out_b2), .scaled(scaled_B2_rght));
	//band_scale band_b3_lft(.POT(POT_B3), .audio(lft_out_b3), .scaled(scaled_B3_lft));
	//band_scale band_b3_rght(.POT(POT_B3), .audio(rght_out_b3), .scaled(scaled_B3_rght));
	//band_scale band_hp_lft(.POT(POT_HP), .audio(lft_out_hp), .scaled(scaled_HP_lft));
	//band_scale band_hp_rght(.POT(POT_HP), .audio(rght_out_hp), .scaled(scaled_HP_rght));
	
	band_scale band_lp_lft(.clk(clk),.rst_n(rst_n),
	.POT(POT_LP), .audio(lft_out_lp), .scaled(scaled_LP_lft));
	band_scale band_lp_rght(.clk(clk),.rst_n(rst_n),
	.POT(POT_LP), .audio(rght_out_lp), .scaled(scaled_LP_rght));
	band_scale band_b1_lft(.clk(clk),.rst_n(rst_n),
	.POT(POT_B1), .audio(lft_out_b1), .scaled(scaled_B1_lft));
	band_scale band_b1_rght(.clk(clk),.rst_n(rst_n),
	.POT(POT_B1), .audio(rght_out_b1), .scaled(scaled_B1_rght));
	band_scale band_b2_lft(.clk(clk),.rst_n(rst_n),
	.POT(POT_B2), .audio(lft_out_b2), .scaled(scaled_B2_lft));
	band_scale band_b2_rght(.clk(clk),.rst_n(rst_n),
	.POT(POT_B2), .audio(rght_out_b2), .scaled(scaled_B2_rght));
	band_scale band_b3_lft(.clk(clk),.rst_n(rst_n),
	.POT(POT_B3), .audio(lft_out_b3), .scaled(scaled_B3_lft));
	band_scale band_b3_rght(.clk(clk),.rst_n(rst_n),
	.POT(POT_B3), .audio(rght_out_b3), .scaled(scaled_B3_rght));
	band_scale band_hp_lft(.clk(clk),.rst_n(rst_n),
	.POT(POT_HP), .audio(lft_out_hp), .scaled(scaled_HP_lft));
	band_scale band_hp_rght(.clk(clk),.rst_n(rst_n),
	.POT(POT_HP), .audio(rght_out_hp), .scaled(scaled_HP_rght));
	//flop for bandscale
	logic signed [15:0] scaled_LP_lft_ff, scaled_B1_lft_ff, scaled_B2_lft_ff, scaled_B3_lft_ff, scaled_HP_lft_ff, scaled_LP_rght_ff, scaled_B1_rght_ff, scaled_B2_rght_ff, scaled_B3_rght_ff, scaled_HP_rght_ff;
    
	always_ff@(posedge clk, negedge rst_n)begin
		if(!rst_n)begin
			scaled_LP_lft_ff<=0;
			scaled_B1_lft_ff<=0;
			scaled_B2_lft_ff<=0;
			scaled_B3_lft_ff<=0;
			scaled_HP_lft_ff<=0;
			scaled_LP_rght_ff<=0;
			scaled_B1_rght_ff<=0;
			scaled_B2_rght_ff<=0;
			scaled_B3_rght_ff<=0;
			scaled_HP_rght_ff<=0;
		end
		else begin
			scaled_LP_lft_ff<=scaled_LP_lft;
			scaled_B1_lft_ff<=scaled_B1_lft;
			scaled_B2_lft_ff<=scaled_B2_lft;
			scaled_B3_lft_ff<=scaled_B3_lft;
			scaled_HP_lft_ff<=scaled_HP_lft;
			scaled_LP_rght_ff<=scaled_LP_rght;
			scaled_B1_rght_ff<=scaled_B1_rght;
			scaled_B2_rght_ff<=scaled_B2_rght;
			scaled_B3_rght_ff<=scaled_B3_rght;
			scaled_HP_rght_ff<=scaled_HP_rght;
		end
	end
	
	
  // Combine signals from different bands
  assign audio_combined_lft = (scaled_LP_lft_ff + scaled_B1_lft_ff) + (scaled_B2_lft_ff + scaled_B3_lft_ff) + scaled_HP_lft_ff;
  assign audio_combined_rght = (scaled_LP_rght_ff + scaled_B1_rght_ff) + (scaled_B2_rght_ff + scaled_B3_rght_ff) + scaled_HP_rght_ff;
  
  // Audio scaled by volume
  assign volume_signed = {1'b0, POT_VOL};
  
  
  
  // flop for timing
  logic signed [15:0] audio_combined_lft_ff, audio_combined_rght_ff;
  
  always_ff@(posedge clk,negedge rst_n)begin
	if(!rst_n)begin
		audio_combined_lft_ff<=0;
		audio_combined_rght_ff<=0;
	end
	else begin
		audio_combined_lft_ff<=audio_combined_lft;
		audio_combined_rght_ff<=audio_combined_rght;
	end
  end

  assign audio_vol_lft = audio_combined_lft_ff * volume_signed;
  assign audio_vol_rght = audio_combined_rght_ff * volume_signed;
  
  
  //FINAL AUDIO OUTPUT
  assign aud_out_lft = audio_vol_lft[27:12];
  assign aud_out_rght = audio_vol_rght[27:12];

  assign seq_low = sequencing_low;

  // For LEDs
  assign bass = scaled_LP_lft_ff;
endmodule
