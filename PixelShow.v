module PixelShow(PixelIN,PixelShow_clk,Show_Data);
	
	input PixelShow_clk;
	input PixelIN;
	output [1:0] Show_Data;
	//reg [7:0] savePixel;
	//reg [7:0] savePixel2;
	reg [3:0] count;
	reg [1:0] out;
	reg [3:0] num_w,num_b;
	wire pixelin;
	
	initial
	begin
	count<=0;
	out<=2'b00;
	//savePixel<=8'b0;
	//savePixel2<=8'b0;
	num_w<=0;
	num_b<=0;
	end
	
	assign pixelin=PixelIN;
	assign Show_Data=out;
	
	always @(PixelShow_clk) begin//注意这里是每来一个时钟信号读取一个像素点，所以这里的clk频率一定要和singlepixel输出像素点频率一致
		if (count<7)
		begin
		//savePixel[count]<=pixelin;
		//savePixel2[7-count]<=pixelin;
		  if(pixelin==1'b1)
		   num_b<=num_b+1;
		  else
		   num_w<=num_w+1;
		count<=count+1;
		end
		
		else if (count==7)
		begin
		//savePixel[count]<=pixelin;
		//savePixel2[7-count]<=pixelin;
		  if(pixelin==1'b1)
		   num_b<=num_b+1;
		  else
		   num_w<=num_w+1;
		   count<=count+1;
/*		//count<=0;
		   if (savePixel<=3||savePixel2<=3)
		   //out=2'b00;
			out=2'b10;
		   else if (savePixel>=252||savePixel2>=252)
		   //out=2'b11;
			out=2'b01;
		   else if (savePixel2>3&&savePixel2<252)
		   //out=2'b10;
			out=2'b00;
			else
		   //out=2'b01;
			out=2'b11;*/
        if(num_b>num_w)
		    out<=2'b11;
		  else
		    out<=2'b00;
		end
		
	   else begin	
		  count<=0;
		  num_b<=0;
		  num_w<=0;
		end
		
	end	
	
endmodule 
//功能：从singlepixel模块连续接受8个像素点信号，判断这一段道路是全黑还是全白还是黑转白还是白转黑
//它的两位输出要给到LCD128
//1.pixelshow的clk要和singlepixel输出像素点频率一致
//2.pixelshow给入LCD12864的频率也要注意一下，因为LCD12864每输出16个要空一个，每输出64个要空8个，
//所以给出信号到LCD的时候也要求每给入16个空一个，每给出64个空8个（最开始第一次给入之前的时候空7个因为LCD初始化要7个时钟周期