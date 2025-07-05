module ddr4_rtl(
	input ddr4_ckt,
	input ddr4_ckc,
	input ddr4_reset_n,
	input ddr4_cs_n,
	input ddr4_we_n,
	input ddr4_dm,
	input ddr4_ras_n,
	input ddr4_cas_n,
    input [31:0] ddr4_addr,
    output reg ddr4_ready,
	inout [15:0] ddr4_dq  );

    wire [15:0] dq_w;
	reg [15:0] dq_r;
	reg [71:0] ddr4_command, next_ddr4_command;
	reg [15:0] row_addr;
	reg [9:0] col_addr;
	reg [7:0] mem [65535:0];
	reg [1:0] bank_group;
	reg [1:0] bank_addr;
	reg [1:0] mr_config;
	reg [4:0] cas_RD_latency;
	reg [2:0] cas_WR_latency;
	reg burst_type; 
    reg [1:0]burst_len;
    reg [15:0] active_row;
	reg [9:0] active_col;
	reg [5:0] delay;
	reg done;

    localparam IDLE      = "IDLE"; 
	localparam ACTIVATE  = "ACTIVATE";
	localparam MRS_STATE = "MRS";
	localparam READ      = "READ";
	localparam WRITE     = "WRITE";
	localparam PRECHARGE = "PRECHARGE";

	assign dq_w = (ddr4_command==WRITE || PRECHARGE)? ddr4_dq: 8'hzzz;
    always@(ddr4_addr) 
	begin
		row_addr   = ddr4_addr[17:2];
        col_addr   = ddr4_addr[17:8]; 
        bank_group = ddr4_addr[1:0]; 
        bank_addr  = ddr4_addr[3:2]; 
	end
always @(posedge ddr4_ckt or posedge ddr4_ckc)
	begin
	    if (!ddr4_reset_n)
	        ddr4_command <= IDLE;
	    else
	        ddr4_command <= next_ddr4_command;
	end
/////////////////////////////////////////////////////////////////////////
always@(*) 
    begin
	ddr4_ready <= 0;	
	case(ddr4_command)
IDLE:begin
				done<=0;
				cas_RD_latency  <= 5'd31; 			  
			    burst_len       <= 2'b11;

			 if({ddr4_ras_n,ddr4_cas_n,ddr4_we_n}==3'b000)
			 	next_ddr4_command <= MRS_STATE;
			 	else
				next_ddr4_command <= ACTIVATE;
		     end
/////////////////////////////////////////////////////////////////////////
MRS_STATE:begin
	 		 mr_config<=ddr4_addr[12:11];
			case(mr_config)
				2'b00:begin
					  cas_RD_latency  <= ddr4_addr[7:3]; 			  
			 		  burst_type      <= ddr4_addr[2]; 	
					  burst_len       <= ddr4_addr[1:0];
					  end					
				2'b01:begin
					cas_WR_latency    <= ddr4_addr[10:8];
					end
			endcase				
			 if (!ddr4_cs_n && !ddr4_cas_n && ddr4_ras_n==0) 
		     next_ddr4_command <= ACTIVATE;
			end
/////////////////////////////////////////////////////////////////////////
ACTIVATE:begin
			  	      active_row<=row_addr;
                      case(cas_RD_latency)
									5'b00000:delay<=9;
									5'b00001:delay<=10;
									5'b00010:delay<=11;
									5'b00011:delay<=12;
									5'b00100:delay<=13;
									5'b00101:delay<=14;
									5'b00110:delay<=15;
									5'b00111:delay<=16;
									5'b01000:delay<=18;
									5'b01001:delay<=20;
									5'b01010:delay<=22;
									5'b01011:delay<=24;
									5'b01100:delay<=23;
									5'b01101:delay<=17;
									5'b01110:delay<=19;
									5'b01111:delay<=21;
									5'b10000:delay<=25;
									5'b10001:delay<=26;
									5'b10010:delay<=28;
									5'b10011:delay<=29;
									5'b10100:delay<=30;
									5'b10101:delay<=31;
									5'b10110:delay<=32;
									5'b11111:delay<=0;
									default: delay<=9;
								endcase

	if(!ddr4_we_n && ddr4_dm && ddr4_cas_n==0)
		   next_ddr4_command   <= WRITE;
    else if(ddr4_we_n && !ddr4_dm && ddr4_cas_n==0) 				                
           next_ddr4_command   <= READ;
	end
/////////////////////////////////////////////////////////////////////////
READ:begin
			next_ddr4_command <= PRECHARGE;		
					repeat(2*delay)
					begin
					@(ddr4_ckt or ddr4_ckc);
					end
		
   case(bank_group)
        2'b00:begin
	    active_col<=col_addr;							
		case(burst_len)
			2'b00:begin
                        if(burst_type==0)	
					    for(int i=0;i<8;i++)
						begin 
						@(posedge ddr4_ckt or posedge ddr4_ckc);
                        dq_r <= mem[active_row+i];
						end
                        else 
                        begin
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+0];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+2];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+1];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+7];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+3];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
				    	dq_r <= mem[active_row+6];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+4];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+5];	
						end
                        end							
			2'b01:begin
                    	if(burst_type==0)	
						for(int i=0;i<4;i++)
						begin 
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+i];								
						end
						else 
						begin
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+0];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+2];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+1];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+3];	
						end
						end

		 	2'b11: 	dq_r <= mem[active_row];
    endcase
    end  

        2'b01:begin
	    active_col<=col_addr;							
		case(burst_len)
			2'b00:begin
                        if(burst_type==0)	
					    for(int i=0;i<8;i++)
						begin 
						@(posedge ddr4_ckt or posedge ddr4_ckc);
                        dq_r <= mem[active_row+i];
						end
                        else 
                        begin
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+0];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+2];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+1];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+7];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+3];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
				    	dq_r <= mem[active_row+6];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+4];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+5];	
						end
                        end							
			2'b01:begin
                    	if(burst_type==0)	
						for(int i=0;i<4;i++)
						begin 
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+i];								
						end
						else 
						begin
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+0];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+2];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+1];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+3];	
						end
						end

		 	2'b11: 	dq_r <= mem[active_row];
    endcase
    end 

        2'b10:begin
	    active_col<=col_addr;							
		case(burst_len)
			2'b00:begin
                        if(burst_type==0)	
					    for(int i=0;i<8;i++)
						begin 
						@(posedge ddr4_ckt or posedge ddr4_ckc);
                        dq_r <= mem[active_row+i];
						end
                        else 
                        begin
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+0];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+2];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+1];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+7];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+3];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
				    	dq_r <= mem[active_row+6];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+4];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+5];	
						end
                        end							
			2'b01:begin
                    	if(burst_type==0)	
						for(int i=0;i<4;i++)
						begin 
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+i];								
						end
						else 
						begin
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+0];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+2];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+1];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+3];	
						end
						end

		 	2'b11: 	dq_r <= mem[active_row];
    endcase
    end 

        2'b11:begin
	    active_col<=col_addr;							
		case(burst_len)
			2'b00:begin
                        if(burst_type==0)	
					    for(int i=0;i<8;i++)
						begin 
						@(posedge ddr4_ckt or posedge ddr4_ckc);
                        dq_r <= mem[active_row+i];
						end
                        else 
                        begin
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+0];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+2];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+1];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+7];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+3];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
				    	dq_r <= mem[active_row+6];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+4];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+5];	
						end
                        end							
			2'b01:begin
                    	if(burst_type==0)	
						for(int i=0;i<4;i++)
						begin 
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+i];								
						end
						else 
						begin
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+0];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+2];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);
						dq_r <= mem[active_row+1];	
						@(posedge ddr4_ckt or posedge ddr4_ckc);           
						dq_r <= mem[active_row+3];	
						end
						end

		 	2'b11: 	dq_r <= mem[active_row];
    endcase
  end
    endcase
  done <= 1;
  end
/////////////////////////////////////////////////////////////////////////
WRITE:begin
			next_ddr4_command <= PRECHARGE;
    case(bank_group)
		2'b00:begin
	    active_col<=col_addr;
		case(burst_len)
			  2'b00:begin
				        if(burst_type==0)
				        begin
				        for(int i=0;i<8;i++)
				        begin
				        @(posedge ddr4_ckt or posedge ddr4_ckc);           
				        mem[active_row+i]<=dq_w;
				        end
				        end
            	        else
				        begin
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+0]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+2]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+4]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+3]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+1]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+5]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+7]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+6]<=dq_w;
				        end
				        end
			  2'b01:begin
				        if(burst_type==0)
				        begin
				        for(int i=0;i<4;i++)
				        begin
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+i]<=dq_w;
				        end						
				        end
                        else
                        begin
			            @(posedge ddr4_ckt or posedge ddr4_ckc);	
				        mem[active_row+0]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+2]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+1]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+3]<=dq_w;
				        end
				        end
			 2'b11: 	dq_r <= mem[active_row];
	endcase
			done <= 1;
			dq_r <= 8'hzzz;
	end

		2'b01:begin
	    active_col<=col_addr;
		case(burst_len)
			  2'b00:begin
				        if(burst_type==0)
				        begin
				        for(int i=0;i<8;i++)
				        begin
				        @(posedge ddr4_ckt or posedge ddr4_ckc);           
				        mem[active_row+i]<=dq_w;
				        end
				        end
            	        else
				        begin
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+0]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+2]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+4]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+3]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+1]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+5]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+7]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+6]<=dq_w;
				        end
				        end
			  2'b01:begin
				        if(burst_type==0)
				        begin
				        for(int i=0;i<4;i++)
				        begin
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+i]<=dq_w;
				        end						
				        end
                        else
                        begin
			            @(posedge ddr4_ckt or posedge ddr4_ckc);	
				        mem[active_row+0]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+2]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+1]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+3]<=dq_w;
				        end
				        end
			 2'b11: 	dq_r <= mem[active_row];
	endcase
			done <= 1;
			dq_r <= 8'hzzz;
	end

		2'b10:begin
	    active_col<=col_addr;
		case(burst_len)
			  2'b00:begin
				        if(burst_type==0)
				        begin
				        for(int i=0;i<8;i++)
				        begin
				        @(posedge ddr4_ckt or posedge ddr4_ckc);           
				        mem[active_row+i]<=dq_w;
				        end
				        end
            	        else
				        begin
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+0]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+2]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+4]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+3]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+1]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+5]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+7]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+6]<=dq_w;
				        end
				        end
			  2'b01:begin
				        if(burst_type==0)
				        begin
				        for(int i=0;i<4;i++)
				        begin
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+i]<=dq_w;
				        end						
				        end
                        else
                        begin
			            @(posedge ddr4_ckt or posedge ddr4_ckc);	
				        mem[active_row+0]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+2]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+1]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+3]<=dq_w;
				        end
				        end
			 2'b11: 	dq_r <= mem[active_row];
	endcase
			done <= 1;
			dq_r <= 8'hzzz;
	end

        2'b11:begin
	    active_col<=col_addr;
		case(burst_len)
			  2'b00:begin
				        if(burst_type==0)
				        begin
				        for(int i=0;i<8;i++)
				        begin
				        @(posedge ddr4_ckt or posedge ddr4_ckc);           
				        mem[active_row+i]<=dq_w;
				        end
				        end
            	        else
				        begin
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+0]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+2]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+4]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+3]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+1]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+5]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+7]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+6]<=dq_w;
				        end
				        end
			  2'b01:begin
				        if(burst_type==0)
				        begin
				        for(int i=0;i<4;i++)
				        begin
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+i]<=dq_w;
				        end						
				        end
                        else
                        begin
			            @(posedge ddr4_ckt or posedge ddr4_ckc);	
				        mem[active_row+0]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+2]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+1]<=dq_w;
				        @(posedge ddr4_ckt or posedge ddr4_ckc);
				        mem[active_row+3]<=dq_w;
				        end
				        end
			 2'b11: 	dq_r <= mem[active_row];
	endcase
			done <= 1;
			dq_r <= 8'hzzz;
	end
    endcase
 end
 ////////////////////////////////////////////////////////////////////////
 PRECHARGE: 
			if(done==1)
			begin
			ddr4_ready<=1;
			next_ddr4_command<=IDLE;
		    end
			else
			next_ddr4_command<=PRECHARGE;
endcase
end

assign ddr4_dq=(ddr4_dm==0)?dq_r:8'hzzz;
endmodule
/////////////////////////////////////////////////////////////////////////
