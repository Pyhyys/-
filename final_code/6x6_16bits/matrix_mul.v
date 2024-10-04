
module matrix_mul#(
parameter max_size = 6 // matrix operation max sizes
)(
input clk,
input rstn,
input start,
input signed[15:0]rdata,
input [3:0]sizes,
output reg ren,
output reg raddr,
output reg [15:0]wdata,
output reg wen,
output reg finish,
output reg [4:0] state,
output reg [8:0] input_data_num, //total number of matrix all items
output reg [8:0] out_data_num
);


integer counter; // count operation cost clock cycles
integer mul_numA_index; // row index
integer mul_numB_index; // col index
// integer out_data_num; // output data number
integer i;

//input ram size
reg signed [15:0] data_inA[max_size*max_size-1:0];
reg signed [15:0] data_inB[max_size*max_size-1:0];
reg signed [15:0] data_tmp[max_size-1:0];
reg signed [15:0] add_temp1[0:2]; // if adder tree level 1 six numbers plus ,then 6/2 = 3 ; if 8 , then 8/2 = 4, fill add_temp1[0:1]
reg signed [15:0] add_temp2[0:1]; // adder tree level 2, max eight numbers plus will require 2 level adder and 3 signal stage
reg signed [15:0] add_out; // connect to wtata, for output data
// reg [8:0] input_data_num;//total number of matrix all items

//FST
// reg [4:0] state;
reg [4:0] nxt_state;
parameter IDLE = 0;
parameter INPUT_A = 1;
parameter INPUT_B = 2;
parameter CALCULATE = 3;
parameter OUTPUT = 4; //not used
parameter FINISH = 5;


//address
parameter addrA = 0;
parameter addrB = 1;

//ctr signal
reg end_input_A;
reg end_input_B;
reg end_calculate;
reg ready; // for wen
reg ready_temp0;
reg ready_temp1;
reg ready_temp2;
reg add_ending1;
reg add_ending2;
reg mul_ending;



// counter
// all operation cost clock cycles
always@(posedge clk or negedge rstn)
	begin
		if(!rstn)
			counter<= 0;
		else
			begin
				if(finish) counter <= 0;
				else counter <= counter + 1;					
			end
	end

// output data number counter
always@(posedge clk or negedge rstn)
	begin
		if(!rstn)
			out_data_num<= 0;
		else
			begin
				if(wen) out_data_num <= out_data_num + 1;		
				else if(state == IDLE) out_data_num <= 0;					
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
			CALCULATE: 	begin
							if(end_calculate)begin
								nxt_state = FINISH;
							end
							else begin
								nxt_state = CALCULATE;
							end
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
							raddr = addrA;						
						end
			INPUT_A: 	begin
							finish = 0;
							ren = 1;
							wen = 0;
							raddr = addrA;					
						end
			INPUT_B: 	begin
							finish = 0;
							ren = 1;
							wen = 0;
							raddr = addrB;
						end
			CALCULATE: 	begin
							finish = 0;
							ren = 0;
							if(end_calculate) wen = 0;
							else if(ready) wen = 1;
							else wen = 0;
							raddr = addrA;
						end					
			FINISH: 	begin
			
							finish = 1;
							ren = 0;
							wen = 0;
							raddr = addrA;
						end	
		endcase
	end

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
            else if(state == INPUT_A)
                begin
					data_inA[0] <= rdata;				
					for(i=0;i<max_size**2-1;i=i+1)
						begin
							data_inA[i+1] <= data_inA[i];
						end
                end
        end
	//ctr
    always@(negedge clk or negedge rstn)
        begin
            if(!rstn)
				begin
					input_data_num <=0;
					end_input_A <=0;
					end_input_B <=0;
				end
	        else if(state == IDLE)
				begin
					input_data_num <=0;
					end_input_A <=0;
					end_input_B <=0;
				end			
            else if(state == INPUT_A)
                begin
					input_data_num <= input_data_num+1;
					if(input_data_num == sizes**2-1) 
						begin 
							input_data_num <= 0;
							end_input_A <= 1;
							end_input_B <=0;
						end
                end
			else if(state == INPUT_B)
                begin
					input_data_num <= input_data_num+1;
					end_input_A <=0;
					if(input_data_num == sizes**2-1) 
						begin 
							input_data_num <= 0;
							end_input_B <= 1;
						end
                end
			else 
				begin
					input_data_num <=0;
					end_input_A <=0;
					end_input_B <=0;
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
            else if(state == INPUT_B)
                begin
					data_inB[0] <= rdata;				
					for(i=0;i<max_size**2-1;i=i+1)
						begin
							data_inB[i+1] <= data_inB[i];
						end
                end
        end

//CALCULATE
	// assign wdata 
	always@(*)
        begin
			if(wen  && state == CALCULATE) begin
				wdata = add_out;
			end
			else begin
				wdata = 0;
			end				
		end
	
	//data out ctr
    always@(posedge clk or negedge rstn)
        begin
            if(!rstn)
                begin
					mul_numA_index <= 0;
					mul_numB_index <= 0;
					mul_ending <= 0;
                end
            else
                begin
					//B matrix input data index counter
					if(wen  || state == CALCULATE) begin
						mul_numB_index <= mul_numB_index+1;
					end
					else begin
						mul_numB_index <= 0;
					end			
					
					// A matrix input data index counter 
					// and its correlation to the B matrix input data index counter
					// Check if all data has been completely input to mul. 
					if(mul_numA_index == sizes-1 && mul_numB_index == sizes-1) begin
						mul_numA_index <=0;
						mul_numB_index <=0;
						mul_ending <= 1; // all datas required to input to mul have done.
					end
					else if(mul_numB_index == sizes-1) begin
						mul_numB_index <= 0;
						mul_numA_index <= mul_numA_index+1;
						mul_ending <= 0;
					end
					else if(state == CALCULATE)begin						
						mul_ending <= 0;
					end
					else begin
						mul_numA_index <=0;
						mul_numB_index <=0;
						mul_ending <= 0;
					end
                end
        end
		

		
//PE
	//mul
	always@(negedge clk, negedge rstn)begin
		if(!rstn) begin
			for(i=0;i<max_size;i=i+1)begin
				data_tmp[i] = 0;
			end	
		end
		else if(finish) begin
			for(i=0;i<max_size;i=i+1)begin
				data_tmp[i] = 0;
			end	
		end
		else if(state == CALCULATE) begin
			for(i=0;i<max_size;i=i+1)
			begin
				data_tmp[i] = data_inA[i + sizes*(sizes-1-mul_numA_index)]*data_inB[(sizes-1-mul_numB_index) + sizes*i];
			end		
		end
		else begin
			for(i=0;i<max_size;i=i+1)begin
				data_tmp[i] = 0;
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
	
	
	//adder tree
	// #1
		always@(posedge clk, negedge rstn)begin
		if(!rstn) begin
			add_temp1[0] <= 0;
			add_temp1[1] <= 0;
			add_temp1[2] <= 0;
			ready_temp1 <= 0;
			add_ending1 <= 0;
		end
		else begin
			// adder tree , if change matrix max size , thus need change adder number to match the number of max size
			add_temp1[0] <= ( (data_tmp[0]+data_tmp[1])  );
			add_temp1[1] <= ( (data_tmp[2]+data_tmp[3])  );
			add_temp1[2] <= ( (data_tmp[4]+data_tmp[5])  );
			if(nxt_state == CALCULATE) ready_temp1 <= ready_temp0;
			else ready_temp1 <= 0;
			add_ending1 <= mul_ending;
		end
	end
	// adder tree		
	// #2
	always@(posedge clk, negedge rstn)begin
		if(!rstn) begin
			add_temp2[0] <= 0;
			add_temp2[1] <= 0;
			ready_temp2 <= 0;
			add_ending2 <= 0;
		end
		else begin
			// adder tree , if change matrix max size , thus need change adder number to match the number of max size
			add_temp2[0] <= (  add_temp1[0] + add_temp1[1] );
			add_temp2[1] <= (  add_temp1[2]  );
			if(nxt_state == CALCULATE) ready_temp2 <= ready_temp1;
			else ready_temp2 <= 0;
			add_ending2 <= add_ending1;
		end
	end
	// adder tree	
	// #3
	always@(posedge clk, negedge rstn)begin
		if(!rstn) begin
			add_out <= 0;
			ready <= 0;
			end_calculate <= 0;
		end
		else begin
			// adder tree , if change matrix max size , thus need change adder number to match the number of max size
			add_out <= ( add_temp2[0] + add_temp2[1] );
			ready <= ready_temp2;
			end_calculate <= add_ending2;
		end
	end
	

endmodule




