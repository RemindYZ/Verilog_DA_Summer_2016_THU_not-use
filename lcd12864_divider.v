module lcd12864_divider(clk, lcd_clk);

	output reg lcd_clk;
	input clk;
	
	//parameter TIME = 6250000; //4Hz
	//parameter TIME = 2500000; //10Hz 
	parameter TIME =   1250000; //20Hz
	
   integer count;
	
	initial
  	begin
		count <= 0;
		lcd_clk <= 0;
	end
	
	always @(posedge clk) begin
		count <= count + 1;

		if (count == TIME) begin
			lcd_clk <= ~lcd_clk;
			count <= 0;
		end
	end

endmodule 