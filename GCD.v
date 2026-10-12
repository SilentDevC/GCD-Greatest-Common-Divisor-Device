
////////////////////////////////////////////////////
//// operation /// l_oper /// r_oper ///////////////
////////////////////////////////////////////////////

module gcd_ ( clk, reset, a, b ,gcd , result ,done ) ;
  input clk , reset , gcd; 
  input [7:0]a,b;
  output [7:0] result;
  output done;

  wire y1, y2, y3, y4;
  wire x1,x2;
  
  // x1 - equal 
  // x2 - greater 
  FSM_k fsm (.clk(clk) ,.reset(reset) ,.x1(x1) , .x2(x2) , .y1(y1), .y2(y2), .y3(y3), .y4(y4) , .gcd(gcd));
  datapath_logic datapath (.clk(clk) , .reset(reset) , .r_oper(b) ,.l_oper(a) , .y1(y1) , .y2(y2) , .y3(y3) , .y4(y4), .x1(x1) , .x2(x2), .res(result), .done(done));

module datapath_logic (clk, reset, r_oper, l_oper, y1, y2, y3, y4, x1, x2, res, done) ;
  input clk , reset;
  input [7:0]r_oper , l_oper;
  input y1,y2,y3,y4;
  output reg [7:0]res;
  output x1,x2;
  output reg done ;

  reg [7:0] ra , rb;

  comparator internal_comp (
    .leftop(ra), 
    .rightop(rb), 
    .comp_out_eq(x1), 
    .comp_out_gt(x2)
  );

  always @(posedge clk or negedge reset) begin
    if ( !reset ) begin
      ra <= 8'b0;
      rb <= 8'b0;
      done  <= 1'b0;
    end
    else begin
        if ( y1 ) begin
          ra <= l_oper ;
          rb <= r_oper;
	  done <= 1'b0;
        end
        else if ( y2 ) begin
          ra <= ra - rb ;
        end
        else if ( y3 ) begin 
          rb <= rb - ra ;
        end 
        else if ( y4 ) begin
          done <= 1'b1;
	  res <= ra;
        end
    end
  end
endmodule

module FSM_k (clk, reset, x1 , x2, y1 , y2, y3, y4, gcd );
 input clk , reset ;
 input gcd ;
 input x1 ,x2 ;
 output y1,y2,y3,y4 ;  
 reg [2:0] st , nst ; 
 parameter S0 = 3'd0 , S1 = 3'd1 , S2 = 3'd2 , S3 = 3'd3 , S4 = 3'd4; 

 reg gcd_ext;
 always @(posedge clk or negedge reset) begin
    if (!reset) begin
        gcd_ext <= 1'b0;
    end
    else begin
        if (gcd)          gcd_ext <= 1'b1;   
        else if (st == S4) gcd_ext <= 1'b0; 
    end
 end

 //x1 - ra == rb , x2 - rb > ra 
always @(negedge clk or negedge reset ) begin 
  if( !reset ) st <= S0;
  else st <= nst;
end 
always @(st or x1 or x2 or gcd_ext) begin 
  case(st)
  S0 : begin 
   if (gcd_ext)nst = S1;
   else if (!gcd_ext) nst = S0;
  end 
  S1 : begin 
   if ( !x1 && x2 ) nst = S2 ;
   else if ( !x1 && !x2 ) nst = S3 ; 
   else if ( x1 ) nst = S4;
  end
  S2 : begin
    if ( x1 ) nst = S4;
    else if ( !x1 && x2 ) nst = S2;
    else if ( !x1 && !x2 ) nst = S3; 
  end
  S3 : begin
     if ( x1 ) nst = S4;
     else if ( !x1 && x2 ) nst = S2;
     else if ( !x1 && !x2 ) nst = S3 ;
  end  
  S4 : nst = S0;
  default : nst = S0;
  endcase
end
 	assign y1 = (st == S1); //load 
	assign y2 = (st == S2); //ra - rb
	assign y3 = (st == S3); //rb - ra 
	assign y4 = (st == S4); //done 
endmodule

module comparator (leftop , rightop , comp_out_eq, comp_out_gt) ;
  input [7:0] rightop , leftop ;
  output wire comp_out_eq;
  output wire comp_out_gt;
  assign comp_out_eq = (leftop == rightop);
  assign comp_out_gt = (leftop > rightop);
endmodule 

endmodule 


module tb_gcdtest;
reg clk;
reg rst_n;
reg [7:0] a, b;
reg gcd ;
wire [7:0]result;
wire done;

gcd_ gcdtest 
(
  .reset (rst_n),
  .clk (clk),
  .a(a), .b(b), .gcd(gcd), .result(result), .done(done)
);
localparam CLK_PERIOD = 10;
always #(CLK_PERIOD/2) clk=~clk;

initial begin
  //reset phase 
  #1 rst_n<=1'bx;clk<=1'bx;
  #(CLK_PERIOD*3) rst_n<=1;
  #(CLK_PERIOD*3) rst_n<=0;clk<=0;
  repeat(5) @(posedge clk);
  rst_n<=1;
  @(posedge clk);

  // gcd(45,15) 
  a = 8'd45;
  b = 8'd15;
  @(posedge clk);
  gcd = 1'b1;
  @(posedge clk);
  gcd = 1'b0;

  wait (done);
  @(posedge clk);   
  $display("T=%0t  gcd(45,15) = %0d  (expected 15)", $time, result);

  repeat(3) @(posedge clk);

  // gcd(48,18) 
  a = 8'd48;
  b = 8'd18;
  @(posedge clk);
  gcd = 1'b1;
  @(posedge clk);
  gcd = 1'b0;
 
  wait(!done);
  wait (done);       
  @(posedge clk);
  $display("T=%0t  gcd(48,18) = %0d  (expected 6)", $time, result);

  // equal operands, tests the a==b
  repeat(3) @(posedge clk);
  a = 8'd21;
  b = 8'd21;
  @(posedge clk);
  gcd = 1'b1;
  @(posedge clk);
  gcd = 1'b0;
  
  wait (!done);
  wait (done);
  @(posedge clk);
  $display("T=%0t  gcd(21,21) = %0d  (expected 21)", $time, result);

  repeat(10) @(posedge clk);
  $finish(2);
end
endmodule
