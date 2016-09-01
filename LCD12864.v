module LCD12864
(
   input clk_10Hz,//10Hz Clock
	input rst_n, //系统复位
	input [1: 0] writein,
	//input writein0,
	output LCD_RW,  //LCD读写选择
	output LCD_EN,  //LCD使能
	output reg [7: 0] data, //LCD数据总线
	output reg LCD_RS  //1：数据模式，0：指令模式
);
   reg flag; //标志位，LCD所有显示完成置零 
	reg [6: 0] char_cnt;  //字数计数器
	reg [7: 0] data_disp; //中转站
	
	//状态机参数
	reg [8: 0] state; //state machine code
	//reg [1:0] writein;
	
	
	parameter IDLE=0;  //start state,next is CLEAR state
	parameter SETFUNCTION=1;//set function: 8 bits data
	parameter SETFUNCTION2=2;
	parameter SWITCHMODE=3; //display switch control
   parameter CLEAR=4; //clear display
   parameter SETMODE=5; //
   parameter SETDDRAM=6;//
   parameter WRITERAM=7;//
   parameter CLEARAGAIN=8; //

   assign LCD_RW=1'b0; //always WRITERAM
   assign LCD_EN=(flag==1)?clk_10Hz:1'b0;
   
	//对RS进行逻辑判断
	//写数据时，RS为高电平，其余为低电平
   always @(posedge clk_10Hz or negedge rst_n)
	begin
	   if(!rst_n)
		   LCD_RS<=1'b0;
		else if(state == WRITERAM)
		   LCD_RS<=1'b1;
		else
		   LCD_RS<=1'b0;
	end
	
	//state machine
	always @(posedge clk_10Hz or negedge rst_n)
	begin
	   if(!rst_n)
		begin
		   state<=IDLE;
			data<=8'bzzzzzzzz;
			char_cnt<=6'b0;
			flag<=1'b1;
		end
		else
		begin
		   case(state)
			IDLE:begin
			     state<=SETFUNCTION;
				  data<=8'bzzzzzzzz;
				  end
			SETFUNCTION:begin
			     state<=SETFUNCTION2;
				  data<=8'h30;
				  end
			SETFUNCTION2:begin
			     state<=SWITCHMODE;
				  data<=8'h30;
				  end
		   SWITCHMODE:begin
			     state<=CLEAR;
				  data<=8'h0c;
				  end
			CLEAR:begin
			     state<=SETMODE;
				  data<=8'h01; 
				  end
			SETMODE:begin
			     state<=SETDDRAM;
				  data<=8'h06;
			     end
			SETDDRAM:begin
			     state<=WRITERAM;
				  case(char_cnt)
				  0:
					  data<=8'h80;
				  16:
				     data<=8'h90;
				  32:
				     data<=8'h88;
				  48:
				     data<=8'h98;
				  64:
					  data<=8'h80;
				  default:
					  data<=8'h80;
				  endcase
			     end
			WRITERAM:begin
			     if(char_cnt>=0&&char_cnt<=15) //从第一排开始写，一排16个字
				  begin
				  char_cnt<=char_cnt+1'b1;
				  data<=data_disp;
				      if(char_cnt==15)
				      state<=SETDDRAM;
				      else
				      state<=WRITERAM;
				  end
				  else if(char_cnt>=16&&char_cnt<=31)
				  begin
				  char_cnt<=char_cnt+1'b1;
				  data<=data_disp;
				      if(char_cnt==31)
						state<=SETDDRAM;
						else
						state<=WRITERAM;
				  end
				  else if(char_cnt>=32&&char_cnt<=47)
				  begin
				  char_cnt<=char_cnt+1'b1;
				  data<=data_disp;
				      if(char_cnt==47)
						state<=SETDDRAM;
						else
						state<=WRITERAM;
				  end
				  else if(char_cnt>=48)
				  begin
				  char_cnt<=char_cnt+1'b1;
				  data<=data_disp;
				      if(char_cnt==63)
						state<=CLEARAGAIN;
						else
						state<=WRITERAM;
				  end
				  end
			CLEARAGAIN:begin
				state<=IDLE;
				data<=8'bzzzzzzzz;
				char_cnt<=6'b0;
				flag<=1'b1;
			end
			default:state<=IDLE;
			endcase
		end
	end
	
	always@(char_cnt)
		begin
		//writein[1]<=writein1;
		//writein[0]<=writein0;
		case (writein)
		3:
		data_disp<=8'h08;
		2:
		data_disp<=8'h10;
		1:
		data_disp<=8'h11;
		0:
		data_disp<=8'h20;
		default:
		data_disp<=8'h20;
		endcase
		end
	//写字

endmodule
	
	
	
	
	
	
	
	
	
	
	
	


	