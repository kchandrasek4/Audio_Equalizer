module PDM(clk,rst_n,duty,PDM,PDM_n);
	input clk;
	input rst_n;
	input [15:0] duty;
	
	output reg PDM;
	output reg PDM_n;
	
	
	reg [15:0] duty_ff;
	reg [15:0] accum_ff;
	wire [15:0] duty_ff_inverse;
	wire comparison;
	
	assign duty_ff_inverse=(comparison?16'hffff:16'h0000)-duty_ff;
	assign comparison=(duty_ff>=accum_ff)?1:0; // can I just do assign comparison=duty_ff>=accum_ff
	//dff to store the duty input
	always_ff@(posedge clk, negedge rst_n)begin
		if(!rst_n)
			duty_ff<=0;
		else
			duty_ff<=duty;
	end
	
	// accumulator dff
	always_ff@(posedge clk, negedge rst_n)begin
		if(!rst_n)
			accum_ff<=0;
		else
			accum_ff<=accum_ff+duty_ff_inverse;
	end
	
	
	//PDM dff
	always_ff@(posedge clk, negedge rst_n)begin
		if(!rst_n)begin
			PDM<=0;
			PDM_n<=1;
		end
		else begin
			PDM<=comparison;
			PDM_n<=~comparison;
		end
	end
	
	
endmodule