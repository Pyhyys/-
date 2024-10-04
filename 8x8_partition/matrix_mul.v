
module matrix_mul#(
parameter max_size = 4,//matrix max sizes
parameter offset = max_size,
parameter DIM = 2,  // matrix dimension. 8/4=2. 8 is max calculated sizes for now
parameter mul_sizes = 4 // used mul number 4 for 4*4 array can directly calculate
)(

input start,
input signed[15:0]rdata,
//input [3:0] sizes, //matrix sizes
input [3:0] data_sizes, // input data sizes
input clk,
input rstn,

output reg ren,
output reg [3:0] raddr,
output reg [31:0]wdata,
output reg waddr,
output reg wen,
output reg all_finish,
output reg [4:0] state,
output reg [4:0] nxt_state,

// read write ctr flag test
input rready,
input wready

);

reg signed [15:0]output_memory[0:3][0:15];
reg [3:0] partition;
reg finish;
reg rep; //repeat matrix calculation flag
reg [3:0] repeat_num; //
reg [3:0] batch; // 
reg  [4:0]out_counter;
reg  [4:0]memory_index; // index,use for output memory partition index
reg  [5:0] dim_counter; // use for repeat signal judge




// integer wait_count;
integer counter;
integer numA,numB; //row ,col index
integer i,j;

//input ram size
reg signed [15:0] data_inA[max_size*max_size-1:0];
reg signed [15:0] data_inB[max_size*max_size-1:0];
reg signed [15:0] data_tmp[max_size-1:0];
reg signed [15:0]add_temp1[0:1];
reg signed [15:0] add_out;
reg [8:0] data_num;//total number of matrix all items

//FST
// reg [4:0] state;
// reg [4:0]nxt_state;

parameter IDLE = 0;
parameter INPUT_A = 1;
parameter INPUT_B = 2;
parameter CALCULATE = 3;
parameter OUTPUT = 4; //not used
parameter FINISH = 5;
// parameter WAIT = 6; //split ren and wen time avoid overlaping

//address
parameter addr_default = 3'b0;
parameter addrA1 = 4'b0000;
parameter addrA2 = 4'b0001;
parameter addrA3 = 4'b0010;
parameter addrA4 = 4'b0011;
parameter addrB1 = 4'b1000;
parameter addrB2 = 4'b1001;
parameter addrB3 = 4'b1010;
parameter addrB4 = 4'b1011;

//ctr
reg end_input_A;
reg end_input_B;
reg end_calculate;
reg ready;
reg ready_temp1;
reg add_ending1;
reg mul_ending;
reg end_output;
reg add_ending;




//finish
always@(*)
	begin
		if(!rstn) all_finish = 0;
		else if(data_sizes <= 4) all_finish = finish && !rep ;
		else  all_finish = finish && !rep && partition==3; // finish and !repeat
	end
	

//repeat judge
always@(posedge clk,negedge rstn)
	begin
		if(!rstn) begin
			dim_counter <= 0;
		end
		else begin			
			if(finish && partition==3) dim_counter <= dim_counter + 1;
		end
	end
	
//repeat
//rep ctr
always@(*)
	begin
		if(!rstn) rep = 1;
		else if(data_sizes <= 4) rep = 0;
		else if(dim_counter >= DIM-1 ) rep = 0; // finish and !repeat
		else rep =1;
	end
//repeat number and batch number calculate
always@(posedge clk , negedge rstn)
	begin
		if(!rstn) begin
			repeat_num <= 0;
			batch <= 0;
		end
		else  begin
			if(finish) repeat_num <= repeat_num+1; // finish and !repeat
			if(repeat_num>=4) begin
				batch <= batch+1;
				repeat_num <= 0;
			end
		end
	end

//FST
always@(posedge clk , negedge rstn)
	begin
		if(!rstn)begin
			state <= IDLE;
		end
		else begin
			state <= nxt_state;
		end
	end
//NXT FST
always@(*)
	begin
		case(state)
		
			IDLE: 		begin
							if(start)begin
								nxt_state = INPUT_A;
							end
							else begin
								nxt_state = IDLE;
							end
						end
			INPUT_A: 	begin
							if(end_input_A)begin
								nxt_state = INPUT_B;
							end
							else begin
								nxt_state = INPUT_A;
							end
						end
			INPUT_B: 	begin
							if(end_input_B)begin
								nxt_state = CALCULATE;
							end
							else begin
								nxt_state = INPUT_B;
							end
						end
			// WAIT: 		begin
								// nxt_state = CALCULATE;
						// end						
			CALCULATE: 	begin
							if(end_calculate)begin
								if(data_sizes <= 4) nxt_state = OUTPUT;
								else if(!rep && partition == 3 )	nxt_state = OUTPUT;
								else  nxt_state = FINISH;
							end
							else begin
								nxt_state = CALCULATE;
							end
						end
			OUTPUT: 	begin
							if(end_output) nxt_state = FINISH;					
							else nxt_state = OUTPUT;					
						end							
			FINISH: 	begin
							nxt_state = IDLE;					
						end			
		endcase
	end

//control
always@(*)
	begin
		case(state)
		
			IDLE: 		begin
							finish = 0;
							ren = 0;
							wen = 0;
							raddr = addr_default;
						end
			INPUT_A: 	begin
							finish = 0;
							ren = 1;
							wen = 0;	
							
							if(batch ==0)begin
								case(partition)
									0: begin
										raddr = addrA1;
									   end
									1:begin
										raddr = addrA1;	
									   end
									2:begin
										raddr = addrA3;						
									   end
									3:begin
										raddr = addrA3;								
									   end
									default: raddr = addr_default;
								endcase
							end
							else if(batch == 1)begin
								case(partition)
									0: begin
										raddr = addrA2;
									   end
									1:begin
										raddr = addrA2;	
									   end
									2:begin
										raddr = addrA4;						
									   end
									3:begin
										raddr = addrA4;								
									   end
									default: raddr = addr_default;
								endcase						
							end

						end
			INPUT_B: 	begin
							finish = 0;
							ren = 1;
							wen = 0;	
							
							if(batch ==0)begin
								case(partition)
									0: begin
										raddr = addrB1;
									   end
									1:begin
										raddr = addrB2;	
									   end
									2:begin
										raddr = addrB1;						
									   end
									3:begin
										raddr = addrB2;								
									   end
									default: raddr = addr_default;
								endcase
							end
							else if(batch == 1)begin
								case(partition)
									0: begin
										raddr = addrB3;
									   end
									1:begin
										raddr = addrB4;	
									   end
									2:begin
										raddr = addrB3;						
									   end
									3:begin
										raddr = addrB4;								
									   end
									default: raddr = addr_default;
								endcase						
							end
						end
			// WAIT:		begin
							// finish = 0;
							// ren = 0;
							// wen = 0;	
							// raddr = addr_default;
						// end
			CALCULATE: 	begin
							finish = 0;
							ren = 0;
							wen = 0;
							raddr = addr_default;
						end
			OUTPUT:		begin
							finish = 0;
							ren = 0;
							if(!end_output) wen = 1;
							else wen = 0;
							raddr = addr_default;		
						end
			FINISH: 	begin
			
							finish = 1;
							ren = 0;
							wen = 0;
							raddr = addr_default;
						end	
		endcase
	end
reg move_stop;
//INPUT_A
	//linebuffer
    always@(negedge clk or negedge rstn)
        begin
            if(!rstn)
				begin
					for(i=0;i<max_size**2;i=i+1)begin
						data_inA[i] <= 0;
					end
				end
	        else if(state == IDLE)
				begin
					for(i=0;i<max_size**2;i=i+1)begin
						data_inA[i] <= 0;
					end
				end			
            else if(state == INPUT_A && rready)
                begin
					data_inA[0] <= rdata;				
					if(!move_stop)begin // only move at the moment of rready pull up 
						for(i=0;i<max_size**2-1;i=i+1)
							begin
								data_inA[i+1] <= data_inA[i];
							end
						//move_stop <= 1;
					end
                end
        end
	//ctr
	//move_stop ctr
	always@(posedge clk , negedge rstn)begin
		if(!rstn) begin
			move_stop <= 0;
		end
		else begin
			if((state == INPUT_A || state == INPUT_B) && rready)begin
				move_stop <= 1;
			end
			else begin
				move_stop <= 0;
			end
		end
	end
	
	//input ending ctr
    always@(negedge rready or negedge rstn)
        begin
            if(!rstn)
				begin
					// data_num <=0;
					end_input_A <=0;
					end_input_B <=0;
				end
	        else if(state == IDLE)
				begin
					// data_num <=0;
					end_input_A <=0;
					end_input_B <=0;
				end			
            else if(state == INPUT_A)
                begin
					// data_num <= data_num+1;
					if(data_num == mul_sizes**2-1) 
						begin 
							// data_num <= 0;
							end_input_A <= 1;
							end_input_B <=0;
						end
                end
			else if(state == INPUT_B)
                begin
					// data_num <= data_num+1;
					end_input_A <=0;
					if(data_num == mul_sizes**2-2) 
						begin 
							// data_num <= 0;
							end_input_B <= 1;
						end
                end
			else 
				begin
					// data_num <=0;
					end_input_A <=0;
					end_input_B <=0;
				end
        end

	//input data number counter 
    always@(negedge rready or negedge rstn)
        begin
            if(!rstn)
				begin
					data_num <=0;
				end		
            else if(state == INPUT_A)
                begin
					data_num <= data_num+1;
					if(data_num >= mul_sizes**2-1) 
						begin 
							data_num = 0;
						end
					// if(nxt_state == INPUT_B) data_num <= 0;
                end
			else if(state == INPUT_B)
                begin
					data_num <= data_num+1;
					if(data_num >= mul_sizes**2-2) 
						begin 
							data_num <= 0;
						end
                end
			else 
				begin
					data_num <=0;
				end
        end




//INPUT_B
	//linebuffer
    always@(negedge clk or negedge rstn)
        begin
            if(!rstn)
				begin
					for(i=0;i<max_size**2;i=i+1)begin
						data_inB[i] <= 0;
					end
				end
	        else if(state == IDLE)
				begin
					for(i=0;i<max_size**2;i=i+1)begin
						data_inB[i] <= 0;
					end
				end			
            else if(state == INPUT_B && rready)
                begin
					data_inB[0] <= rdata;				
					for(i=0;i<max_size**2-1;i=i+1)
						begin
							data_inB[i+1] <= data_inB[i];
						end
                end
        end

//CALCULATE
	//data out ctr
    always@(negedge clk or negedge rstn)
        begin
            if(!rstn)
                begin
					numA <= 0;
					numB <= 0;
					mul_ending <= 0;
                end
            else
                begin
					//B matrix input data index counter
					if( state == CALCULATE && !mul_ending) begin
						numB <= numB+1;
					end
					else begin
						numB <= 0;
					end			
					
					// A matrix input data index counter 
					// and its correlation to the B matrix input data index counter
					// Check if all data has been completely input to mul. 
					if(numA == mul_sizes-1 && numB == mul_sizes-1) begin
						numA <=0;
						numB <=0;
						mul_ending <= 1; // all datas required to input to mul have done.
					end
					else if(numB == mul_sizes-1) begin
						numB <= 0;
						numA <= numA+1;
					end
					else if(finish)begin
						mul_ending <= 0;
					end
                end
        end
	
	//end_calculate ctr
	always@(posedge clk,negedge rstn)
		begin
			if(!rstn) end_calculate <= 0;
			else begin
				if(add_ending) end_calculate <= 1;
				else end_calculate <= 0;
			end
		end
	
	//counter
    always@(posedge clk or negedge rstn)
        begin
            if(!rstn)
                counter<= 0;
            else
                begin
					if(finish) counter<=0;
					else counter<= counter + 1;					
                end
        end
		
		reg out_en;
//output
	// assign wdata
	always@(negedge clk)
		begin //"Please refer to the output memory part below for issues related to the linebuffer."
			if(wen ==1 && state == OUTPUT && wready && out_en) begin
				if(data_sizes <= 4) wdata <= output_memory[memory_index][16-mul_sizes**2]; //Rank last
				else wdata <= output_memory[memory_index][0];
			end
			else if(state == OUTPUT)begin
				wdata <= wdata;
			end	
			else begin
				wdata <= 0;
			end
		end
	
	always@(posedge clk , negedge rstn)begin
		if(!rstn) begin
			out_en <= 1;
		end
		else begin
			if(state == OUTPUT && wready)begin
				out_en <= 0;
			end
			else  begin
				out_en <= 1;
			end
		end
	end
	
	// always@(posedge clk)
        // begin
			// if(wen ==1 && state == OUTPUT) begin
				// for(i=15;i>=1;i=i-1)begin
					// output_memory[memory_index][i-1] <= output_memory[memory_index][i];					
				// end	
			// end			
		// end
	//counter & ctr	
	always@(posedge clk, negedge rstn)
		begin
			if(!rstn)begin
				end_output <= 0;
				out_counter <= 0;
				memory_index <= 0;
			end
			else begin
				if(state == OUTPUT && out_en)begin
					if(data_sizes <= 4 && out_counter >= mul_sizes**2-1)begin
						end_output <= 1;
						memory_index <= 0;
						out_counter <= 0;
					end
					else if(out_counter >= 15 && memory_index == 3)begin
						end_output <= 1;
						memory_index <= 0;
						out_counter <= 0;
					end
					else if(out_counter >= 15) begin
						out_counter <= 0;
						memory_index <= memory_index +1;
					end
					else if(!end_output)begin
						out_counter <= out_counter +1;
					end
					else begin
						out_counter <= 0;
					end
				end
			end
		end
	
//PE
reg ready_temp0;
	//mul
	always@(negedge clk, negedge rstn)begin
		if(!rstn) begin
			for(i=0;i<max_size;i=i+1)begin
				data_tmp[i] = 0;
			end	
		end
		else begin
			// mul calculation
			if(finish) begin
				for(i=0;i<max_size;i=i+1)begin
					data_tmp[i] = 0;
				end	
			end
			else if( (state == CALCULATE) && (!mul_ending)) begin
				for(i=0;i<max_size;i=i+1)
				begin
					data_tmp[i] = data_inA[i + mul_sizes*(mul_sizes-1-numA)] * data_inB[(mul_sizes-1-numB) + mul_sizes*i];
				end		
			end
			else begin
				for(i=0;i<max_size;i=i+1)begin
					data_tmp[i] = 0;
				end	
			end
		end
	end
	
	//start ready signal ctr
	always@(negedge clk, negedge rstn)begin
		if(!rstn)begin
			ready_temp0 <= 0;
		end
		else begin
			// ready signal ctr
			if(state == CALCULATE) ready_temp0 <= 1;
			else ready_temp0 <= 0;
		end
	end
	

	//adder	tree #1
	
		always@(posedge clk, negedge rstn)begin
		if(!rstn) begin
			add_temp1[0] <= 0;
			add_temp1[1] <= 0;
			ready_temp1 <= 0;
			add_ending1 <= 0;
		end
		else begin
			// adder tree , if change matrix max size , thus need change adder number to match the number of max size
			add_temp1[0] <= ( (data_tmp[0]+data_tmp[1])  );
			add_temp1[1] <= ( (data_tmp[2]+data_tmp[3])  );
			
			//ctr
			ready_temp1 <= ready_temp0;
			add_ending1 <= mul_ending;
		end
	end

	// adder tree #2
	always@(posedge clk, negedge rstn)begin
		if(!rstn) begin
			add_out <= 0;
			ready <= 0;
			add_ending <= 0;
			// end_calculate <= 0;
		end
		else begin
			// adder tree , if change matrix max size , thus need change adder number to match the number of max size
			add_out <= add_temp1[0] + add_temp1[1];
			ready <= ready_temp1;
			add_ending <= add_ending1;
			// end_calculate <= add_ending1;
		end
	end
	
	
	// output memory 
	// partition matrix 
	always@(posedge clk,negedge rstn)
		begin
			if(!rstn) begin
				for(i=0;i<4;i=i+1)begin
					for(j=0;j<16;j=j+1)begin
						output_memory[i][j] <= 0;					
					end
				end
				partition <= 0;
			end
			else begin
				if(finish) partition <= partition+1;
				if(partition>=4) partition <= 0;
				
				if(partition < 4 && nxt_state == CALCULATE && ready)begin
					output_memory[partition][15] <= add_out + output_memory[partition][0];
					//linebuffer move
					for(i=15;i>=1;i=i-1)begin
						output_memory[partition][i-1] <= output_memory[partition][i];					
					end
				end
				else if(wen ==1 && state == OUTPUT) begin
					if(wready && out_en)begin	
						for(i=15;i>=1;i=i-1)begin
							output_memory[memory_index][i-1] <= output_memory[memory_index][i];					
						end					
					end
				end
			end
		end
	

endmodule




