`timescale 1ns/1ps

`define data_size 6
`define max_size  6
`define END_TIME 10000

`define path_inputA "./inputA.txt"
`define path_inputB "./inputB.txt"
`define path_output "./output.txt"
`define path_answer "./answer.txt"
`define path_verify "./verify.txt"
module tb;
	//signal
	reg start;
	reg signed [15:0]rdata = 0;//input data
	
	wire ren; //read enable
	wire raddr; //read matrix address,now simply use address A=0 and B=1 to choose which to read
	wire signed [15:0]wdata; //output data
	wire wen; //write enable
	wire finish; 
	wire [4:0] state;
	wire [8:0] input_data_num;
	wire [8:0] out_data_num;
	
	//size
	reg [3:0] sizes = `data_size;//matrix size: like n*n
	// parameter max_size = 6;
	parameter offset = `max_size; //every line size
	reg signed [15:0] data_inA[`max_size*offset-1:0]; //input data ram size
	reg signed [15:0] data_inB[`max_size*offset-1:0]; //input data ram size


	//clock
	parameter period = 40;
	integer i,j;
	reg clk  =0;
	reg rstn ;
	always #(period/2) clk = ~clk;

//module
	matrix_mul u_matrix_mul(
			 .clk(clk),
			 .rstn(rstn),
			 .start(start),
			 .rdata(rdata),
			 .sizes(sizes),
			 .ren  (ren),
			 .raddr(raddr),
			 .wdata(wdata),
			 .wen  (wen),
			 .finish(finish),
			 .state(state),
			 .input_data_num(input_data_num),
			 .out_data_num(out_data_num)
			);

// SDF
`ifdef SDF_FILE
	initial $sdf_annotate(`SDF_FILE,u_matrix_mul);
`endif

// file
	integer file_output;  
	integer file_inputA;
	integer file_inputB;
	integer file_answer;
	integer file_verify;
	initial begin
		// open file
		file_output = $fopen(`path_output, "w");
		file_inputA = $fopen(`path_inputA, "r");
        file_inputB = $fopen(`path_inputB, "r");
		file_answer = $fopen(`path_answer, "r");
		file_verify = $fopen(`path_verify, "w");		
		
		#`END_TIME;
		$fclose(file_output);
		$fclose(file_inputA);
		$fclose(file_inputB);
		$fclose(file_answer);
		$fclose(file_verify);
	end

//signal ctr
	initial 
		begin
			rstn=0;
			start=0;
		#period;
			start=1;
			rstn=1;
		end

//read input file
    integer data[8:0];
    initial begin
        //read data from file and display
		//A
		$display("A =");
        for ( i = 0; i < sizes**2; i = i + 1) begin
                $fscanf(file_inputA, "%d", data_inA[i]); //read data from file
				$write("%d ",data_inA[i]);	//display data
				if(i%sizes == sizes-1) $display;
        end
		$display();		
		//B
		$display("B =");
        for ( i = 0; i < sizes**2; i = i + 1) begin
                $fscanf(file_inputB, "%d", data_inB[i]);
				$write("%d ",data_inB[i]);
				if(i%sizes == sizes-1) $display;				
        end
		$display;	
	end
	
//input data
	always@(*) 
		begin
			if(!rstn) rdata = 0;
			else if(ren) begin
				if(raddr == 0)begin
					for(i=0;i<sizes**2;i=i+1)begin
						rdata = data_inA[i];
						#period;
					end
				end
				else if(raddr == 1)begin
					for(i=0;i<sizes**2;i=i+1)begin
						rdata = data_inB[i];
						#period;
					end
				end	
			end
		end

//verification
	integer answer=0;
	integer error=0;
	integer total_error=0;
	integer check_num=0;
	integer flag=0;
	
	always@(negedge clk)begin
		if(wen == 1 )
			begin
				#(period/2);
				$fscanf(file_answer, "%d", answer);
				error <= (wdata > answer) ? ((wdata - answer) / answer) : ((answer - wdata) / answer);
				total_error <= error/sizes**2 + total_error;
				check_num <= check_num+1;
				
				if(wdata != answer)begin
					flag<=1;
					$display("Total %4d error in %4d testdata.\n", error, check_num);
					$fdisplay(file_verify,"Total %4d error in %4d testdata.\n", error, check_num);
				end
			end
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
				if(num == sizes) begin
					num = 0;
					$fdisplay(file_output);
				end
			end
				
		if(finish) begin
			start = 0;
			$fdisplay(file_output);
			#period;
			rstn = 0;
			#period;
			rstn=1;
			start=0;
		end
	end
	//display wen data
	always@(negedge clk)begin
		if(wen == 1)
			begin
				// #(period/2);
				$write("%3d ",wdata); //display
				$fwrite(file_output,"%3d ",wdata); //write to file
				num = num+1;
				if(num == sizes) begin //change line
					num = 0;
					$display;
					$fdisplay(file_output);
				end
			end
				
		if(finish) begin //change line in the end (can be disable)
			$display;
			$fdisplay(file_output);
		end
	end
	//print title
	always@(posedge ren) $fdisplay(file_output,"A =");
	always@(posedge raddr) $fdisplay(file_output,"B =");
	always@(posedge wen) $fdisplay(file_output,"C = A*B =");
	always@(posedge wen) $display("C = A*B =");

//finish ctr
initial 
	begin
		#`END_TIME;
		$finish;
	end

//fsdb
`ifdef FSDB
	initial begin
		$fsdbDumpfile("tb.fsdb");
		$fsdbDumpvars;
		$fsdbDumpMDA;
	end
`endif




endmodule



