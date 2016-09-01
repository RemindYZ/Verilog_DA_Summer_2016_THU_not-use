module f_divider(clk, clk_11KHz);

	output reg clk_11KHz;
	input clk;
	
	parameter TIME0 = 2273;
	
	integer count0;
	
	initial begin
		count0 <= 0;
		clk_11KHz <= 0;
	end
	
	always @(posedge clk) begin
		count0 <= count0 + 1;
		if (count0 == TIME0) begin
			clk_11KHz <= ~clk_11KHz;
			count0 <= 0;
		end
	end

endmodule 