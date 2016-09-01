module singlePixel(ADdata,singlePixel_clk,PixelData);
	
	input singlePixel_clk;
	input [7:0] ADdata;
	output reg PixelData;
	
	always @(singlePixel_clk) begin
		if (ADdata>8'd50/*127*/)//这里127这个阈值可能还需要调整修改...我也不太确定
			PixelData<=0;  //white
		else
			PixelData<=1;  //black
	end
	

endmodule 
//功能：从AD接收8位信号，设定阈值为127（大概一半的位置），如果大于阈值就是0小于就是1，因为白色阈值大黑色小
//clk可能要改分频器，这里就不改了