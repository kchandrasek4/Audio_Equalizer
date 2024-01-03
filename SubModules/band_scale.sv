
module band_scale(
	input clk,rst_n, 
	input [11:0] POT,
	input signed [15:0] audio,
	output signed [15:0] scaled);

// unsigned square POT
logic [23:0]POT_square;
// signed FIR scale multiplier drawn from POT
logic signed [12:0]FIR_scale;
// Audio scaled according to POT reading (but not saturated or finalized )
logic signed [28:0] audio_scaled;
//prefix value to be used if saturation is required according to positive or negative number
logic [14:0] saturate_attach;
//final audio sample ready for output with or without saturation
logic signed [15:0] saturated_product;


assign POT_square = POT * POT;
assign FIR_scale = {1'b0, POT_square[23:12]} ;


//flops for timing
logic signed [12:0]FIR_scale_ff;
always_ff@(posedge clk,negedge rst_n)begin
	if(!rst_n)begin
		FIR_scale_ff<=0;
	end
	else begin
		FIR_scale_ff<=FIR_scale;
	end
end
assign audio_scaled = FIR_scale_ff * audio;

//CHECKING MSB TO SEE IF POSITIVE OR NEGATIVE AND SETTING prefix to most positive or negative value for saturation
assign saturate_attach = (audio_scaled[28]) ? (15'b000000000000000) : (15'b111111111111111);

//CHECKING IF NUMBER IS MORE POSITIVE OR NEGATIVE THAN MAX POSITIVE OR NEGATIVE NUMBER; IF so saturation will take place
assign saturated_product = (audio_scaled[28]) ? ((!audio_scaled[27] || !audio_scaled[26] || !audio_scaled[25]) ?  {audio_scaled[28], saturate_attach} : audio_scaled[25:10]) : ((audio_scaled[27] || audio_scaled[26] || audio_scaled[25]) ?  {audio_scaled[28], saturate_attach} : audio_scaled[25:10]);

//FINAL SCALED AUDIO
assign scaled = saturated_product;

endmodule



