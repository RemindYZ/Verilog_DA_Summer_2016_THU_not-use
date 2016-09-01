module cam_clk(clk, cam_clk);

	output reg cam_clk;
	input clk;
	
	parameter TIME = 50000; //500Hz
   integer count;
	
	initial
  	begin
		count <= 0;
		cam_clk <= 0;
	end
	
	always @(posedge clk) begin
		count <= count + 1;

		if (count == TIME) begin
			cam_clk <= ~cam_clk;
			count <= 0;
		end
	end

endmodule 