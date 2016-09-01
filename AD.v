module AD
(
				input clk,	// 50MHz
				input rst_n,//系统复位
				inout sda,	// PCF8591 SDA
				output scl,	// PCF8591 SCL
				output reg [7:0] final_data
);

	reg[2:0] cnt_state;	//cnt=0:scl上升沿，cnt=1:scl高电平中间，cnt=2:scl下降沿，cnt=3:scl低电平中间
	//reg[8:0] cnt_delay;	//500循环计数，产生iic所需要的时钟
	reg [11:0] cnt_delay; //2500,20000Hz
	reg scl_r;		//时钟脉冲寄存器
   
	always@(posedge clk or negedge rst_n)
		if(!rst_n) 
			cnt_delay <= 12'd0;
		else if(cnt_delay == 12'd2499) 
			cnt_delay <= 12'd0;	//10us为scl周期，100KHz
		else 
			cnt_delay <= cnt_delay+1'b1;	//时钟计数

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) 
			cnt_state <= 3'd5;
		else begin
			case(cnt_delay)
				12'd624:	cnt_state <= 3'd1;	//cnt_state=1:scl高电平中间,用于数据采样
				12'd1249:	cnt_state <= 3'd2;	//cnt_state=2:scl下降沿
				12'd1874:	cnt_state <= 3'd3;	//cnt_state=3:scl低电平中间,用于数据变化
				12'd2499:	cnt_state <= 3'd0;	//cnt_state=0:scl上升沿
				default: cnt_state <= 3'd5;
			endcase
		end
	end
	
	`define SCL_POS		(cnt_state==3'd0)		//cnt_state=0:scl上升沿
	`define SCL_HIG		(cnt_state==3'd1)		//cnt_state=1:scl高电平中间,用于数据采样
	`define SCL_NEG		(cnt_state==3'd2)		//cnt_state=2:scl下降沿
	`define SCL_LOW		(cnt_state==3'd3)		//cnt_state=3:scl低电平中间,用于数据变化

	always@(posedge clk or negedge rst_n)
		if(!rst_n) 
			scl_r <= 1'b0;
		else if(cnt_state==3'd0) 
			scl_r <= 1'b1;	//scl信号上升沿
		else if(cnt_state==3'd2) 
			scl_r <= 1'b0;	//scl信号下降沿

	assign scl = scl_r;	//产生iic所需要的时钟
			
	`define	DEVICE_READ		8'b1001_0001	//地址选择字，读
	`define DEVICE_WRITE	8'b1001_0000	//地址选择字，写
	`define BYTE_ADDR		8'b0000_0000	//转换控制字
	reg[7:0] db_r;		
	reg[7:0] read_data;	
	parameter 	IDLE 	= 4'd0;
	parameter 	START1 = 4'd1;
	parameter 	ADD1 	= 4'd2;
	parameter 	ACK1 	= 4'd3;
	parameter 	ADD2 	= 4'd4;
	parameter 	ACK2 	= 4'd5;
	parameter 	START2 = 4'd6;
	parameter 	ADD3 	= 4'd7;
	parameter 	ACK3	= 4'd8;
	parameter 	DATA 	= 4'd9;
	parameter 	ACK4	= 4'd10;
	parameter 	STOP 	= 4'd11;

	reg[3:0] cstate;	//状态转换机
	reg sda_r;	
	reg sda_link;	
	reg[3:0] num;	
	reg ack_flag;	
	reg ack_hold;	

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			cstate <= IDLE;
			sda_r <= 1'b1;
			sda_link <= 1'b0;
			num <= 4'd0;
			read_data <= 8'b0000_0000;
			ack_flag <= 1'b0;
			ack_hold <= 1'b0;
		end
		else 	  
			case (cstate)
				IDLE:begin
						sda_link <= 1'b1;			//sda output
						sda_r <= 1'b1;
						if(`SCL_LOW) begin	
							db_r <= `DEVICE_WRITE;	
							cstate <= START1;	
						end	
						else cstate <= IDLE;
					end
				START1:	begin
						if(`SCL_HIG) begin		
							sda_link <= 1'b1;	//sda output
							sda_r <= 1'b0;		
							cstate <= ADD1;
							num <= 4'd0;		
						end
						else cstate <= START1; 
					end
				ADD1:	begin
						if(`SCL_LOW) begin
							if(num == 4'd8) begin	
								num <= 4'd0;			
								sda_r <= 1'b1;
								sda_link <= 1'b0;		//sda为高阻态input)
								cstate <= ACK1;
							end
							else begin
								cstate <= ADD1;
								num <= num+1'b1;
								case (num)
									4'd0: sda_r <= db_r[7];
									4'd1: sda_r <= db_r[6];
									4'd2: sda_r <= db_r[5];
									4'd3: sda_r <= db_r[4];
									4'd4: sda_r <= db_r[3];
									4'd5: sda_r <= db_r[2];
									4'd6: sda_r <= db_r[1];
									4'd7: sda_r <= db_r[0];
									default: ;
								endcase
							end
						end
						else cstate <= ADD1;
					end
				ACK1:	begin
						if(`SCL_HIG) begin
							ack_flag<=!sda;//
							cstate<=ACK1; 
						end
						else if( (ack_flag==1) && `SCL_NEG ) begin	
							cstate <= ADD2;	
							db_r <= `BYTE_ADDR;		
							sda_link <= 1'b1;			
							ack_flag <= 0;
							end
						else cstate <= ACK1;		
					end
				ADD2:	begin
						if(`SCL_LOW) begin
							if(num==4'd8) begin	
								num <= 4'd0;			
								sda_r <= 1'b1;
								sda_link <= 1'b0;		
								cstate <= ACK2;
							end
							else begin
								cstate <= ADD2;	
								num <= num+1'b1;
								case (num)
									4'd0: sda_r <= db_r[7];
									4'd1: sda_r <= db_r[6];
									4'd2: sda_r <= db_r[5];
									4'd3: sda_r <= db_r[4];
									4'd4: sda_r <= db_r[3];
									4'd5: sda_r <= db_r[2];
									4'd6: sda_r <= db_r[1];
									4'd7: sda_r <= db_r[0];
									default: ;
								endcase						
							end
						end
						else cstate <= ADD2;				
						end
				ACK2:	begin
						if(`SCL_HIG) begin
							ack_flag<=!sda;
							cstate<=ACK2; 
						end
						else if( (ack_flag==1) && `SCL_NEG ) begin		//收到应答信号
							db_r <= `DEVICE_READ;	
							cstate <= START2;		
							ack_flag <= 0;	
						end
						else cstate <= ACK2;	
						end
				START2: begin	
						if(`SCL_LOW) begin
							sda_link <= 1'b1;	//sda作为output
							sda_r <= 1'b1;		//拉高数据线sda
							cstate <= START2;
						end
						else if(`SCL_HIG) begin	//scl为高电平中间
							sda_r <= 1'b0;		//拉低数据线
							cstate <= ADD3;
						end	 
						else cstate <= START2;
						end
				ADD3:	begin	
						if(`SCL_LOW) begin
							if(num==4'd8) begin	
								num <= 4'd0;			
								sda_r <= 1'b1;
								sda_link <= 1'b0;		
								cstate <= ACK3;
							end
							else begin
								cstate <= ADD3;	
								num <= num+1'b1;
								case (num)
									4'd0: sda_r <= db_r[7];
									4'd1: sda_r <= db_r[6];
									4'd2: sda_r <= db_r[5];
									4'd3: sda_r <= db_r[4];
									4'd4: sda_r <= db_r[3];
									4'd5: sda_r <= db_r[2];
									4'd6: sda_r <= db_r[1];
									4'd7: sda_r <= db_r[0];
									default: ;
								endcase											
							end
						end
						else cstate <= ADD3;				
						end
				ACK3:	begin
						if(`SCL_HIG) begin
							ack_flag<=!sda; //从机响应信号
							cstate<=ACK3; 
						end
						else if( (ack_flag==1) && `SCL_NEG ) begin
							cstate <= DATA;	       //等待从机响应
							sda_link <= 1'b0;
							ack_flag <= 0;	
						end
						else cstate <= ACK3; 		
					end
				DATA:	begin
						if(num<=4'd7) begin
							cstate <= DATA;
							if(`SCL_HIG) begin	
								num <= num+1'b1;	
								case (num)
									4'd0: read_data[7] <= sda;
									4'd1: read_data[6] <= sda;  
									4'd2: read_data[5] <= sda; 
									4'd3: read_data[4] <= sda; 
									4'd4: read_data[3] <= sda; 
									4'd5: read_data[2] <= sda; 
									4'd6: read_data[1] <= sda; 
									4'd7: read_data[0] <= sda; 
									default: ;
								endcase																		
							end
						end
						else if(`SCL_LOW && (num==4'd8)) begin
							num <= 4'd0;			
							cstate <= ACK4;
						end
						else cstate <= DATA;
						end
				ACK4: begin	
						if(`SCL_NEG) begin
							cstate <= ACK4;
							ack_hold <= 1'b1;					
						end
						else if( `SCL_LOW && (ack_hold==1'b1)) begin
							cstate <= STOP;	
							final_data <= read_data;	
							ack_hold <= 1'b0;				
						end
						else cstate <= ACK4;
						end
				STOP:	begin
						if(`SCL_LOW) begin
							sda_link <= 1'b1;
							sda_r <= 1'b0;
							cstate <= STOP;
						end
						else if(`SCL_HIG) begin
							sda_r <= 1'b1;//scl为高时，sda产生上升沿（结束信号）
							cstate <= IDLE;
						end
						else cstate <= STOP;
						end
				default: cstate <= IDLE;
			endcase
	end

	assign sda = sda_link ? sda_r:1'bz;

endmodule
