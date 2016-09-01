module cam_si(cam_clk, cam_si);

	output reg cam_si;
	input cam_clk;
	
   integer count;
	reg PWM;
	
	initial
  	begin
		count <= 0;
		cam_si <= 0;
		PWM<=0;
	end
	
	
	always @(posedge cam_clk) begin
		if (count >= 155) count <= 0;
		else begin 
			count <= count + 1;
			if (count == 2) 
			begin
			PWM <= 1;
			end
			else 
			begin
			PWM <= 0;
			end
		end
	end
	
	always @(cam_clk) begin
		cam_si=PWM;
	end

endmodule 