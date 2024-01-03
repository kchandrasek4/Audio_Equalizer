package tb_tasks;

	localparam UNITY_GAIN = 12'h800;
	localparam integer LOW_BAND[2] = {0, 80};
	localparam integer B1_BAND[2] = {80, 280};
	localparam integer B2_BAND[2] = {280, 1000};
	localparam integer B3_BAND[2] = {1000, 3600};
	localparam integer HIGH_BAND[2] = {3600, 10000};
	localparam integer SYSTEM_CLK_FREQ = 50*(10**6); // 50 MHz System Clk

	typedef struct {
		logic [11:0] LP, B1, B2, B3, HP, VOL;
	} slide_pots_t;

	typedef struct {
		logic next_n, prev_n;
	} BT_buttons_t;

	typedef enum logic [2:0] { LP, B1, B2, B3, HP } bands_t;
	typedef enum logic {NXT, PRV} btns_t;
	
	typedef enum logic [3:0] { BAND_TEST_LP, BAND_TEST_B1, BAND_TEST_B2, BAND_TEST_B3, BAND_TEST_HP, VOL_TEST, POT_TEST,ALL_PASS_TEST, BTN_TEST_NXT, BTN_TEST_PREV} test_cases_t;

	test_cases_t test; 

	task automatic set_bands(ref slide_pots_t pots, input slide_pots_t val);
		pots.LP = val.LP;
		pots.B1 = val.B1;
		pots.B2 = val.B2;
		pots.B3 = val.B3;
		pots.HP = val.HP;
		pots.VOL = val.VOL;
	endtask


	task automatic init(ref clk, rst_n, ref slide_pots_t pots, ref BT_buttons_t buttons);
		set_bands(pots, '{UNITY_GAIN, UNITY_GAIN, UNITY_GAIN, UNITY_GAIN, UNITY_GAIN, UNITY_GAIN});
		buttons.next_n = 1;
		buttons.prev_n = 1;
		rst_n = 0;
		repeat(2) @(negedge clk);
		rst_n = 1;
		repeat(100) @(negedge clk);
	endtask 

	task automatic band_check(ref slide_pots_t pots, ref clk, ref logic [20:0] clk_counter_lft, clk_counter_rght, ref logic counter_vld_lft, counter_vld_rght, input bands_t band_to_check, ref start, ref smpl_vld);
		slide_pots_t val;
		integer freq_lft, freq_rght;
		$display("\n********************************************************");
		$display("Starting test case for %s band", band_to_check.name());
		case(band_to_check)
			LP: begin 
				val = '{UNITY_GAIN, 0, 0, 0, 0, UNITY_GAIN};
				test = BAND_TEST_LP;
			    end
			B1: begin 
				val = '{0, UNITY_GAIN, 0, 0, 0, UNITY_GAIN};
				test = BAND_TEST_B1;
			    end
			B2: begin
				val = '{0, 0, UNITY_GAIN, 0, 0, UNITY_GAIN};
				test = BAND_TEST_B2;
			    end
			B3: begin
				val = '{0, 0, 0, UNITY_GAIN, 0, UNITY_GAIN};
				test = BAND_TEST_B3;
			    end
			HP: begin
				val = '{0, 0, 0, 0, UNITY_GAIN, UNITY_GAIN};
				test = BAND_TEST_HP;
			    end
			default: val = '{UNITY_GAIN, UNITY_GAIN, UNITY_GAIN, UNITY_GAIN, UNITY_GAIN, UNITY_GAIN};
		endcase
		@(negedge clk);
		set_bands(pots, val);
		calc_freq(.clk(clk), .clk_counter_lft(clk_counter_lft), .clk_counter_rght(clk_counter_rght), .counter_vld_lft(counter_vld_lft), .counter_vld_rght(counter_vld_rght), 
				.start(start), .smpl_vld(smpl_vld), .freq_lft(freq_lft), .freq_rght(freq_rght));
		$display("Freq (avg) of Left Channel = %d, Freq (avg) of Right Channel = %d", freq_lft, freq_rght);
		
		case(band_to_check)
			LP: if(!(freq_lft > LOW_BAND[0] && freq_lft < LOW_BAND[1]))
				$display("!!Error!! Observed freq does not fall within the Low Pass Band. Please check");
			    else
				$display("Test Passed");
			B1:  if(!(freq_lft > B1_BAND[0] && freq_lft < B1_BAND[1]))
				$display("!!Error!! Observed freq does not fall within the B1 Band. Please check");
			     else
				$display("Test Passed");
			B2:  if(!(freq_lft > B2_BAND[0] && freq_lft < B2_BAND[1]))
				$display("!!Error!! Observed freq does not fall within the B2 Band. Please check");
			     else
				$display("Test Passed");
			B3:  if(!(freq_lft > B3_BAND[0] && freq_lft < B3_BAND[1]))
				$display("!!Error!! Observed freq does not fall within the B3 Band. Please check");
			     else
				$display("Test Passed");
			HP:  if(!(freq_lft > HIGH_BAND[0] && freq_lft < HIGH_BAND[1]))
				$display("!!Error!! Observed freq does not fall within the High Pass Band. Please check");
			     else
				$display("Test Passed");
			default: $display("\n Incorrect Band to Check");
		endcase
		
	endtask

	task automatic vol_check(ref slide_pots_t pots, ref clk, ref logic [15:0] peak_lft, peak_rght, ref logic amplitude_vld_lft, amplitude_vld_rght,  input bands_t band_to_check, ref start, ref smpl_vld);
		integer amplitude_lft;
		integer amplitude_rght;
		integer amplitude_lft_after;
		integer amplitude_rght_after;
		integer factor_lft, factor_rght;
		
		slide_pots_t val;
		integer freq_lft, freq_rght;
		$display("\n********************************************************");
		$display("Starting vol_check for %s band", band_to_check.name());
		test=VOL_TEST;
		// check VOL increase in B2
		val = '{0, 0, UNITY_GAIN, 0, 0, UNITY_GAIN};

		@(negedge clk);
		set_bands(pots, val);
		calc_amplitude(.clk(clk), .peak_lft(peak_lft), .peak_rght(peak_rght), .amplitude_vld_lft(amplitude_vld_lft), .amplitude_vld_rght(amplitude_vld_rght), 
				.start(start), .smpl_vld(smpl_vld), .amplitude_lft(amplitude_lft), .amplitude_rght(amplitude_rght));
		$display("Amplitude (avg) of Left Channel = %d, Amplitude (avg) of Right Channel = %d", amplitude_lft, amplitude_rght);
		

		val = '{0, 0, UNITY_GAIN, 0, 0, 16'h400};

		@(negedge clk);
		set_bands(pots, val);
		calc_amplitude(.clk(clk), .peak_lft(peak_lft), .peak_rght(peak_rght), .amplitude_vld_lft(amplitude_vld_lft), .amplitude_vld_rght(amplitude_vld_rght), 
				.start(start), .smpl_vld(smpl_vld), .amplitude_lft(amplitude_lft_after), .amplitude_rght(amplitude_rght_after));
		
		$display("Amplitude (avg) of Left Channel = %d, Amplitude (avg) of Right Channel = %d", amplitude_lft_after, amplitude_rght_after);
		
		
		factor_lft=int'(real'(amplitude_lft)/real'(amplitude_lft_after));
		factor_rght=int'(real'(amplitude_rght)/real'(amplitude_rght_after));
		//factor_rght=amplitude_rght/amplitude_rght_after;

		if(factor_lft==2&&factor_rght==2)begin
			$display("Test Passed!");
			$display("The left amplitude after volume change decrease by %d",factor_lft);
			$display("The right amplitude after volume change decrease by %d",factor_rght);
		end
		else begin
			$display("Error!");
			$display("The left amplitude after volume change decrease by %d",factor_lft);
			$display("The right amplitude after volume change decrease by %d",factor_rght);
		end

	endtask

	task automatic pot_check(ref slide_pots_t pots, ref clk, ref logic [15:0] peak_lft, peak_rght, ref logic amplitude_vld_lft, amplitude_vld_rght,  input bands_t band_to_check, ref start, ref smpl_vld);
		integer amplitude_lft;
		integer amplitude_rght;
		integer amplitude_lft_after;
		integer amplitude_rght_after;
		integer factor_lft, factor_rght;
		
		slide_pots_t val;
		integer freq_lft, freq_rght;
		$display("\n********************************************************");
		$display("Starting pot check for %s band", band_to_check.name());
		test=POT_TEST;
		// check VOL increase in B2
		val = '{0, 0, UNITY_GAIN, 0, 0, UNITY_GAIN};

		@(negedge clk);
		set_bands(pots, val);
		calc_amplitude(.clk(clk), .peak_lft(peak_lft), .peak_rght(peak_rght), .amplitude_vld_lft(amplitude_vld_lft), .amplitude_vld_rght(amplitude_vld_rght), 
				.start(start), .smpl_vld(smpl_vld), .amplitude_lft(amplitude_lft), .amplitude_rght(amplitude_rght));
		$display("Amplitude (avg) of Left Channel = %d, Amplitude (avg) of Right Channel = %d", amplitude_lft, amplitude_rght);
		

		val = '{0, 0, 16'h400, 0, 0, UNITY_GAIN};

		@(negedge clk);
		set_bands(pots, val);
		calc_amplitude(.clk(clk), .peak_lft(peak_lft), .peak_rght(peak_rght), .amplitude_vld_lft(amplitude_vld_lft), .amplitude_vld_rght(amplitude_vld_rght), 
				.start(start), .smpl_vld(smpl_vld), .amplitude_lft(amplitude_lft_after), .amplitude_rght(amplitude_rght_after));
		
		$display("Amplitude (avg) of Left Channel = %d, Amplitude (avg) of Right Channel = %d", amplitude_lft_after, amplitude_rght_after);
		
		
		factor_lft=int'(real'(amplitude_lft)/real'(amplitude_lft_after));
		factor_rght=int'(real'(amplitude_rght)/real'(amplitude_rght_after));
		//factor_rght=amplitude_rght/amplitude_rght_after;

		if(factor_lft==4&&factor_rght==4)begin
			$display("Test Passed!");
			$display("The left amplitude after volume change decrease by %d",factor_lft);
			$display("The right amplitude after volume change decrease by %d",factor_rght);
		end
		else begin
			$display("Error!");
			$display("The left amplitude after volume change decrease by %d",factor_lft);
			$display("The right amplitude after volume change decrease by %d",factor_rght);
		end

	endtask

	task automatic amp_check(ref slide_pots_t pots, ref clk, ref logic [15:0] peak_lft, peak_rght, ref logic amplitude_vld_lft, amplitude_vld_rght,  input bands_t band_to_check, ref start, ref smpl_vld);
		integer amplitude_lft;
		integer amplitude_rght;
		slide_pots_t val;
		integer freq_lft, freq_rght;
		$display("\n********************************************************");
		$display("Starting test case for %s band", band_to_check.name());
		case(band_to_check)
			LP: val = '{UNITY_GAIN, 0, 0, 0, 0, UNITY_GAIN};
			B1: val = '{0, UNITY_GAIN, 0, 0, 0, UNITY_GAIN};
			B2: val = '{0, 0, UNITY_GAIN, 0, 0, UNITY_GAIN};
			B3: val = '{0, 0, 0, UNITY_GAIN, 0, UNITY_GAIN};
			HP: val = '{0, 0, 0, 0, UNITY_GAIN, UNITY_GAIN};
			default: val = '{UNITY_GAIN, UNITY_GAIN, UNITY_GAIN, UNITY_GAIN, UNITY_GAIN, UNITY_GAIN};
		endcase
		@(negedge clk);
		set_bands(pots, val);
		calc_amplitude(.clk(clk), .peak_lft(peak_lft), .peak_rght(peak_rght), .amplitude_vld_lft(amplitude_vld_lft), .amplitude_vld_rght(amplitude_vld_rght), 
				.start(start), .smpl_vld(smpl_vld), .amplitude_lft(amplitude_lft), .amplitude_rght(amplitude_rght));
	endtask


	task automatic calc_amplitude(ref clk,  ref logic [15:0] peak_lft, peak_rght, ref logic amplitude_vld_lft, amplitude_vld_rght, start, smpl_vld, output integer amplitude_lft, amplitude_rght);
		integer i;
		integer amp_lft_avg,amp_rght_avg;
		integer amplitude_lft_instant, amplitude_rght_instant;
		amp_lft_avg =0;
		amp_rght_avg = 0;
		// Wait until the first sample is output from equaliser.
		$display("Waiting for Equaliser to output the first sample");
		
		wait_for_sig(.sig(start), .clk(clk), .clks_to_wait(2500000), .sig_name("start"));
		repeat(300000)@(posedge clk);


		$display("Sampling Waveform for Amplitude Calculation...");
		for(i=0; i<5; i++) begin
			fork
				begin
					wait_for_sig(.sig(amplitude_vld_lft), .clk(clk), .clks_to_wait(3000000), .sig_name("amplitude_vld_lft"));
					amplitude_lft_instant =  (peak_lft-32768)*2;
					amp_lft_avg=amp_lft_avg+amplitude_lft_instant;
				end
				begin
					wait_for_sig(.sig(amplitude_vld_rght), .clk(clk), .clks_to_wait(3000000), .sig_name("amplitude_vld_rght"));
					amplitude_rght_instant =  (peak_rght-32768)*2;
					amp_rght_avg=amp_rght_avg+amplitude_rght_instant;
				end
			join
			$display("amplitude_lft: %d,amplitude_rght: %d", amplitude_lft_instant, amplitude_rght_instant);
		end
		amplitude_lft=amp_lft_avg/5;
		amplitude_rght=amp_rght_avg/5;
	endtask

	task automatic calc_freq(ref clk, ref logic [20:0] clk_counter_lft, clk_counter_rght, ref logic counter_vld_lft, counter_vld_rght, start, smpl_vld, output integer freq_lft, freq_rght);
		integer i, freq_smpl_lft, freq_smpl_rght;
		freq_lft =0;
		freq_rght = 0;
		
		// Wait until the first sample is output from equaliser.
		$display("Waiting for Equaliser to output the first sample");
		wait_for_sig(.sig(start), .clk(clk), .clks_to_wait(2500000), .sig_name("start"));
		
		// After the first sample appears, wait for some time. Goal is to start sampling at the middle of the waveform for high accuracy.
		$display("First sample received. Skipping few samples for accuracy reasons");
		repeat(100000)@(posedge clk);	

		// Now, we begin tracking signal for frequency calculation
		// Take 5 cycles and compute average frequency
		$display("Sampling Waveform for Frequency Calculation...");
		for(i=0; i<5; i++) begin
			fork
				begin
					wait_for_sig(.sig(counter_vld_lft), .clk(clk), .clks_to_wait(3000000), .sig_name("counter_vld_lft"));
					freq_smpl_lft =  (SYSTEM_CLK_FREQ/clk_counter_lft);
					freq_lft = freq_lft + freq_smpl_lft;	
					//$display("Sample %d: Freq_Left = %d", i+1, (SYSTEM_CLK_FREQ/clk_counter_lft));
				end
				begin
					wait_for_sig(.sig(counter_vld_rght), .clk(clk), .clks_to_wait(3000000), .sig_name("counter_vld_rght"));
					freq_smpl_rght =  (SYSTEM_CLK_FREQ/clk_counter_rght);
					freq_rght = freq_rght + freq_smpl_rght;
					// $display("Sample %d: Freq_Rght = %d", i+1, (SYSTEM_CLK_FREQ/clk_counter_rght));
				end
			join
			$display("Sample %d: Freq_Left = %d, Freq_Right = %d",  i+1, freq_smpl_lft, freq_smpl_rght);
		end
		freq_lft = freq_lft/5;
		freq_rght = freq_rght/5;
	endtask

	task automatic wait_for_sig(ref sig, clk, input integer clks_to_wait, string sig_name);
		fork
			begin : timeout
				repeat(clks_to_wait)@(posedge clk);
				$display("Timed out waiting for signal %s", sig_name);
				$stop;
			end : timeout

			begin
				@(posedge sig);
				disable timeout;
			end
		join
	endtask

	task automatic all_bands(ref slide_pots_t pots, ref clk);

		test = ALL_PASS_TEST;
		$display("\n********************************************************");
		$display("Starting test case: All Bands");
		@(negedge clk);
		set_bands(pots, '{UNITY_GAIN, UNITY_GAIN, UNITY_GAIN, UNITY_GAIN, UNITY_GAIN, UNITY_GAIN});
		$display("Waiting for Equaliser to output the first sample");
		//wait_for_sig(.sig(start), .clk(clk), .clks_to_wait(2500000), .sig_name("start"));
		// Track waveform for some duration
		repeat(400000) @(posedge clk);

	endtask

	task automatic change_song(ref slide_pots_t pots, ref clk, ref BT_buttons_t btns, input btns_t btn_to_test);
		$display("\n********************************************************");
		$display("Starting test case: change song");
		set_bands(.pots(pots), .val('{0, 0, UNITY_GAIN, 0, 0, UNITY_GAIN}));
		case(btn_to_test)
		NXT: begin
			test = BTN_TEST_NXT;
			@(negedge clk);
			btns.next_n = 0;
			@(negedge clk);
			btns.next_n = 1;
		     end
		PRV: begin
			test = BTN_TEST_PREV;
			@(negedge clk);
			btns.prev_n = 0;
			@(negedge clk);
			btns.prev_n = 1;
		     end
		endcase
		repeat(4000000) @(posedge clk);
	endtask

	/*
    task automatic change_song(ref slide_pots_t pots, ref clk, ref BT_buttons_t btns, input btns_t btn_to_test);
        set_bands(.pots(pots), .val('{0, 0, UNITY_GAIN, 0, 0, UNITY_GAIN}));
        case(btn_to_test)
        NXT: begin
            test = BTN_TEST_NXT;
            @(negedge clk);
            btns.next_n = 0;
            @(negedge clk);
            btns.next_n = 1;
             end
        PRV: begin
            test = BTN_TEST_PREV;
            @(negedge clk);
            btns.prev_n = 0;
            @(negedge clk);
            btns.prev_n = 1;
             end
        endcase

 

        repeat(4000000) @(posedge clk);
    endtask

 


    task start_assertions(ref BT_buttons_t btns, ref clk, ref logic [1:0] song);
        sequence btn_push_prop;
            logic [1:0] old_song;
            (~TX, old_song = song) |-> ##[0:30000] (old_song != song);
        endsequence

 

        property btn_push_prop;
            @(posedge clk)
                disable iff (!rst_n)
                (~btns.prev_n | ~btns.next_n) |-> ##[0:100] btn_push_prop;
        endproperty

 

        assert (btn_push_prop)
        else $error("Button pushed but song not changed);

 

    endtask
*/

endpackage
