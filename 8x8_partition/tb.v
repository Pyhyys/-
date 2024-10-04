`timescale 1ns/1ps

`define Data_size 8 // can modify. input data size, can define matrix size: like n*n
`define Matrix_size 4 // don't modify . 
`define max_size  4 // don't modify. once matrix can calculate size.
`define END_TIME 10000 // can change. obsolute finish time
`define PERIOD  10
	
`define path_input "./input.txt"
`define path_output "./output.txt"
`define path_answer "./answer.txt"
`define path_verify "./verify.txt"
module tb;
	//signal
	reg start;
	reg signed [15:0]rdata;//input data
	
	wire ren; //read enable
	wire [3:0] raddr; //read matrix address,now simply use address A=0 and B=1 to choose which to read
	wire signed [31:0]wdata; //output data
	wire waddr; //write address (not used)
	wire wen; //write enable
	wire finish; 
	wire [4:0] state,nxt_state;

	
	//size
	reg [3:0] mat_sizes = `Matrix_size;//matrix size: like n*n
	reg [3:0] data_sizes = `Data_size;
	// parameter offset = `max_size; //every line size
	reg signed [15:0] data_inA[0:3][`max_size**2-1:0]; //input data ram size
	reg signed [15:0] data_inB[0:3][`max_size**2-1:0]; //input data ram size


	//clock
	parameter period = `PERIOD;
	integer i,j,k;
	reg clk  =0;
	reg rstn ;
	always #(period/2) clk = ~clk;


	// read write ctr flag
	reg rready;
	reg wready ;

	//verification
	integer answer=0;
	integer error=0;
	integer total_error=0;
	integer check_num=0;
	integer flag=0;
	
	integer value_num=0;
	integer answer_array_index = 0;
	integer answer_num = 0;
	reg signed [15:0]wdata_array[0:16*4];


	// file 
	integer file_output;
	integer file_input;
	integer file_answer;
	integer file_verify;
	parameter sizes = 4;
	reg signed[15:0] data_inA_temp[0:3][0:3][sizes**2-1:0]; // input data ram
	reg signed[15:0] data_inB_temp[0:3][0:3][sizes**2-1:0]; // input data ram
	reg signed [15:0]answer_array[0:3][sizes**2-1:0];// answer data ram

//module
	matrix_mul #(`max_size)u_matrix_mul(
	 .start(start),
	 .rdata(rdata),
	 .data_sizes(data_sizes),
	 .clk(clk),
	 .rstn(rstn),

	 .ren  (ren),
	 .raddr(raddr),
	 .wdata(wdata),
	 .waddr(waddr),
	 .wen  (wen),
	 .all_finish(finish),
	 
	 .state(state),
	 .nxt_state(nxt_state),
	 
	 .rready(rready),
	 .wready(wready)

	);




//signal ctr
	initial 
		begin
			rstn=0;
			start=0;
		#(period*2);
			start=1;
			rstn=1;
		end
//restart
always@(*)
	begin
		if(finish) begin
			start = 0;
			$fdisplay(file_output);
			#period;
			rstn = 0;
			#period;
			rstn=1;
			#period;
			start=0;
		end
	end


//read input file
initial begin
	// open file
	file_output = $fopen(`path_output, "w");
	file_input = $fopen(`path_input, "r");
	file_answer = $fopen(`path_answer, "r");
	file_verify = $fopen(`path_verify, "w");		
	
	#`END_TIME;
	$fclose(file_output);
	$fclose(file_input);
	$fclose(file_answer);
	$fclose(file_verify);
end		
//////////////////readA
initial begin
	 for (k = 0; k < 2; k = k + 1) begin
		for (i = 0; i < sizes; i = i + 1) begin
			for (j = 0; j < sizes*2; j = j + 1) begin
				if(k==0)begin
					if(j < sizes)begin
						$fscanf(file_input, "%d", data_inA_temp[0][i][j%sizes]); // read data from file
						$write("%d ", data_inA_temp[0][i][j%sizes]);       // display data
					end
					else if(j >= sizes)begin
						$fscanf(file_input, "%d", data_inA_temp[1][i][j%sizes]); // read data from file
						$write("%d ", data_inA_temp[1][i][j%sizes]);       // display data
					end
				end
				else if(k==1)begin
					if(j < sizes)begin
						$fscanf(file_input, "%d", data_inA_temp[2][i][j%sizes]); // read data from file
						$write("%d ", data_inA_temp[2][i][j%sizes]);       // display data
					end
					else if(j >= sizes)begin
						$fscanf(file_input, "%d", data_inA_temp[3][i][j%sizes]); // read data from file
						$write("%d ", data_inA_temp[3][i][j%sizes]);       // display data
					end
				end	
			end
			$display;
		end
		$display();
	end
end

////////////////readB
initial begin
	 for (k = 0; k < 2; k = k + 1) begin
		for (i = 0; i < sizes; i = i + 1) begin
			for (j = 0; j < sizes*2; j = j + 1) begin
				if(k==0)begin
					if(j < sizes)begin
						$fscanf(file_input, "%d", data_inB_temp[0][i][j%sizes]); // read data from file
						$write("%d ", data_inB_temp[0][i][j%sizes]);       // display data
					end
					else if(j >= sizes)begin
						$fscanf(file_input, "%d", data_inB_temp[1][i][j%sizes]); // read data from file
						$write("%d ", data_inB_temp[1][i][j%sizes]);       // display data
					end
				end
				else if(k==1)begin
					if(j < sizes)begin
						$fscanf(file_input, "%d", data_inB_temp[2][i][j%sizes]); // read data from file
						$write("%d ", data_inB_temp[2][i][j%sizes]);       // display data
					end
					else if(j >= sizes)begin
						$fscanf(file_input, "%d", data_inB_temp[3][i][j%sizes]); // read data from file
						$write("%d ", data_inB_temp[3][i][j%sizes]);       // display data
					end
				end	
			end
			$display;
		end
		$display();
	end
end

/////////////read answer
initial begin
	 for (k = 0; k < 2; k = k + 1) begin
		for (i = 0; i < sizes; i = i + 1) begin
			for (j = 0; j < sizes*2; j = j + 1) begin
				if(k==0)begin
					if(j < sizes)begin
						$fscanf(file_answer, "%d", answer_array[0][j%sizes+4*i]); // read data from file
						$write("%d ", answer_array[0][j%sizes+4*i]);       // display data
					end
					else if(j >= sizes)begin
						$fscanf(file_answer, "%d", answer_array[1][j%sizes+4*i]); // read data from file
						$write("%d ", answer_array[1][j%sizes+4*i]);       // display data
					end
				end
				else if(k==1)begin
					if(j < sizes)begin
						$fscanf(file_answer, "%d", answer_array[2][j%sizes+4*i]); // read data from file
						$write("%d ", answer_array[2][j%sizes+4*i]);       // display data
					end
					else if(j >= sizes)begin
						$fscanf(file_answer, "%d", answer_array[3][j%sizes+4*i]); // read data from file
						$write("%d ", answer_array[3][j%sizes+4*i]);       // display data
					end
				end	
			end
			$display;
		end
		$display();
	end
end



//input database
initial 
	begin
		for(i=0;i<4;i=i+1)begin
			for(j=0;j<4;j=j+1)begin
				data_inA[0][4*i+j] = data_inA_temp[0][i][j] ;
				data_inA[1][4*i+j] = data_inA_temp[1][i][j] ;
				data_inA[2][4*i+j] = data_inA_temp[3][i][j] ;
				data_inA[3][4*i+j] = data_inA_temp[3][i][j] ;
			end
		end
		for(i=0;i<4;i=i+1)begin
			for(j=0;j<4;j=j+1)begin
				data_inB[0][4*i+j] = data_inB_temp[0][i][j] ;
				data_inB[1][4*i+j] = data_inB_temp[1][i][j] ;
				data_inB[2][4*i+j] = data_inB_temp[3][i][j] ;
				data_inB[3][4*i+j] = data_inB_temp[3][i][j] ;
			end
		end
	end



	
//input data
	always@(negedge clk, negedge rstn) 
		begin
			if(!rstn) begin
				rdata = 0;
				rready = 0;
			end
			else if(ren) begin
				case(raddr)
				4'b0000:begin
							for(i=0;i<mat_sizes**2;i=i+1)begin
								rdata = data_inA[0][i];
								rready =1;
								#period;
								rready = 0;
								#period;
							end
						end
				4'b0001:begin
							for(i=0;i<mat_sizes**2;i=i+1)begin
								rdata = data_inA[1][i];
								rready =1;
								#period;
								rready = 0;
								#period;
							end
						end
				4'b0010:begin
							for(i=0;i<mat_sizes**2;i=i+1)begin
								rdata = data_inA[2][i];
								rready =1;
								#period;
								rready = 0;
								#period;
							end
						end
				4'b0011:begin
							for(i=0;i<mat_sizes**2;i=i+1)begin
								rdata = data_inA[3][i];
								rready =1;
								#period;
								rready = 0;
								#period;
							end
						end		
				4'b1000:begin
							for(i=0;i<mat_sizes**2;i=i+1)begin
								rdata = data_inB[0][i];
								rready =1;
								#period;
								rready = 0;
								#period;
							end
						end
				4'b1001:begin
							for(i=0;i<mat_sizes**2;i=i+1)begin
								rdata = data_inB[1][i];
								rready =1;
								#period;
								rready = 0;
								#period;
							end
						end
				4'b1010:begin
							for(i=0;i<mat_sizes**2;i=i+1)begin
								rdata = data_inB[2][i];
								rready =1;
								#period;
								rready = 0;
								#period;
							end
						end
				4'b1011:begin
							for(i=0;i<mat_sizes**2;i=i+1)begin
								rdata = data_inB[3][i];
								rready =1;
								#period;
								rready = 0;
								#period;
							end
						end
				default:begin
							for(i=0;i<mat_sizes**2;i=i+1)begin
								rdata = 0;
								rready =1;
								#period;
								rready = 0;
								#period;
							end
						end
				endcase
			end
			else begin
				rready = 0;
				rdata = 0;
			end
		end


//verification

	always@(negedge clk,negedge rstn)begin
		if(!rstn)begin
			wready = 0;
		end
		else begin
			if(wen == 1 )
				begin
					wready = 1;
					#(period);
					if(wen && wready)begin						
						//$fscanf(file_answer, "%d", answer);
						answer = answer_array[answer_array_index][answer_num];
						answer_num = answer_num+1;
						if(answer_num >= 16)begin
							answer_array_index = answer_array_index+1;
							answer_num = 0;
						end
						
						error <= (wdata > answer) ? ((wdata - answer) / answer) : ((answer - wdata) / answer);
						total_error <= error/mat_sizes**2 + total_error;
						check_num <= check_num+1;
						
						if(wdata != answer)begin
							flag<=1;
							$display(" error, answer is %d",answer);
							$fdisplay(file_verify,," error, answer is %d",answer);
						end
					end
					wready = 0;
					#(period);
				
					//final conclusion
					if(finish) begin
						$display("----------------------------");
						if(flag==0)begin
							$display("All testdata correct!\n");
							$fdisplay(file_verify,"All testdata correct!\n");
						end
						else begin
							$display("ERROR!\n");
							$fdisplay(file_verify,"ERROR!\n");
						end
						$display("Avg error in %4d testdata: %f\n", check_num, total_error);
						$fdisplay(file_verify,"Avg error in %4d testdata: %f\n", check_num, total_error);
						total_error <= 0;
						flag<=0;
						check_num<=0;
						
							//ALL Wdata Array print result
							//part1
							$display("ALL Wdata Array") ;
							$fdisplay(file_output,"ALL Wdata Array") ;
							for(k=0;k<4;k=k+1)begin
								for(i=0;i<2;i=i+1)begin
									for(j=0;j<4;j=j+1)begin									
										$write("%d ",wdata_array[16*i + j + 4*k]) ;
										$fwrite(file_output,"%d ",wdata_array[16*i + j + 4*k]) ;										
									end
								end		
								$display;
								$fdisplay(file_output);
							end
							//part2
							for(k=0;k<4;k=k+1)begin
								for(i=0;i<2;i=i+1)begin
									for(j=0;j<4;j=j+1)begin									
										$write("%d ",wdata_array[32 + 16*i + j + 4*k]) ;									
										$fwrite(file_output,"%d ",wdata_array[32 + 16*i + j + 4*k]) ;									
									end
								end
								$display;					
								$fdisplay(file_output);													
							end
					end
				end
		end
	end

//print result
	integer num =0; //number of write data
	//display ren data
	always@(negedge clk)begin
		if(ren == 1 )
			begin
				#(period/2);
					$fwrite(file_output,"%3d ",rdata);
					num = num+1;
					if(num == mat_sizes) begin
						num = 0;
						$fdisplay(file_output);
					end						
				#(period/2);
			end
	end
	//display wen data
	always@(negedge clk)begin
		if(wen == 1)
			begin
				#(period/2);
				if(wen && wready)begin
					$write("%3d ",wdata); //display
					$fwrite(file_output,"%3d ",wdata); //write to file				
					if(num % mat_sizes == mat_sizes-1) begin //change line
						$display;
						$fdisplay(file_output);
					end
					//all wdata array
					wdata_array[value_num] = wdata;
					value_num = value_num +1;
				end
								
				//output matrix index
				if(num == mat_sizes**2-1) begin //change line
					num = 0;
					$display;
					$fdisplay(file_output);
				end
				else begin
					num = num+1;
				end
				#(period/2);	
			end
				
		if(finish) begin //change line in the end (can be disable)
			$display;
			$fdisplay(file_output);
		end
	end
	//print title
	reg [3:0] matrix_num = 0;
	always@(posedge ren) begin
		
		matrix_num = matrix_num+1;
		$fdisplay(file_output);		
		$fdisplay(file_output,"A #%d=",matrix_num);
		
	end
	always@(state) if(state == 2) $fdisplay(file_output,"B #%d=",matrix_num);
	always@(posedge wen) $fdisplay(file_output,"C = A*B =");
	always@(posedge wen) $display("C = A*B =");

//finish ctr
initial 
	begin
		#`END_TIME;
		$finish;
	end

//fsdb
	initial begin
		$fsdbDumpfile("tb.fsdb");
		$fsdbDumpvars;
		$fsdbDumpMDA;
	end




endmodule



