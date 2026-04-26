`include "pc6.v"

module pc6_tb;
    reg clk, reset;
    wire [5:0] q;

    pc6 rrrr(clk, reset, q);

    // Clock generation
    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    // Stimulus
    initial begin
        reset = 1;
        #20 reset = 0;
        #200 reset = 1;
        #20 $finish;
    end

    // Monitor signals
    initial
        $monitor($time, " clk=%b, reset=%b, q=%d", clk, reset, q);

    // Waveform dump
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, pc6_tb); // Ghi tất cả tín hiệu trong testbench
    end

endmodule