module high_freq_queue(clk,rst_n,lft_smpl,rght_smpl,wrt_smpl,lft_out,rght_out,sequencing);
	input clk,rst_n;
	input [15:0] lft_smpl, rght_smpl;
	input wrt_smpl;
	
	output [15:0] lft_out, rght_out;
	output logic sequencing;
	
	
	logic [10:0] rd_ptr; // 11-bit rd_ptr, 0-1535
	logic [10:0] old_ptr; // 11-bit old_ptr, 0-1535
	logic [10:0] new_ptr;
	
	typedef enum reg {ACQ,READ} state_t;
	
	state_t state, nxt_state;
	
	logic [10:0] end_ptr;
	assign end_ptr=(old_ptr>11'd515)?(old_ptr-11'd516):(old_ptr+11'd1020);// when old_ptr=516, end_ptr=516+1020=1536 should be wrapped to 0
	
	logic read_done;
	assign read_done=(rd_ptr==end_ptr);
	dualPort1536x16 L_RAM(.clk(clk),.we(wrt_smpl),.waddr(new_ptr),.raddr(rd_ptr),.wdata(lft_smpl),.rdata(lft_out));
	dualPort1536x16 R_RAM(.clk(clk),.we(wrt_smpl),.waddr(new_ptr),.raddr(rd_ptr),.wdata(rght_smpl),.rdata(rght_out));
	//full flop
	logic full;
	always_ff@(posedge clk,negedge rst_n)begin
		if(!rst_n)
			full<=0;
		else if(new_ptr==11'd1531)
			full<=1;
	end
	
	//rd_ptr counter
	always_ff@(posedge clk,negedge rst_n)begin
		if(!rst_n)
			rd_ptr<=0;
		else if(state==READ)
			rd_ptr<=((rd_ptr+1)>11'd1535)?0:rd_ptr+1;// can store in address 0-1535, otherwise rolled over
		else if(full&wrt_smpl)
			rd_ptr<=old_ptr;
	end
	
	//old_ptr counter
	always_ff@(posedge clk,negedge rst_n)begin
		if(!rst_n)
			old_ptr<=0;
		else if(full&wrt_smpl)
			old_ptr<=((old_ptr+1)>11'd1535)?0:old_ptr+1;// can store in address 0-1535, otherwise rolled over
	end
	
	//new_ptr counter
	always_ff@(posedge clk,negedge rst_n)begin
		if(!rst_n)
			new_ptr<=0;
		else if(wrt_smpl)
			new_ptr<=((new_ptr+1)>11'd1535)?0:new_ptr+1;// can store in address 0-1535, otherwise rolled over
	end
	
	always_ff@(posedge clk,negedge rst_n)begin
		if(!rst_n)
			state<=ACQ;
		else
			state<=nxt_state;
	end
	
	always_comb begin
		nxt_state=state;
		sequencing=0;
		case (state)
			ACQ:begin
				if(full&wrt_smpl)
					nxt_state=READ;
			end
			READ:begin
				sequencing=1;
				if(read_done)
					nxt_state=ACQ;
			end
		endcase
	end
	
	
	
	
	
	
	
	

endmodule