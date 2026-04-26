`include "mem8.v"

module mem8_tb;

    reg clk;
    reg [7:0] address;
    reg [7:0] in_data;
    reg w_en, en, p_en;
    wire [7:0] out_data;

    // Instantiate DUT
    mem8 uut (
        .clk(clk),
        .address(address),
        .in_data(in_data),
        .out_data(out_data),
        .w_en(w_en),
        .en(en),
        .p_en(p_en)
    );

    // Clock generation: 10 time unit period
    initial clk = 0;
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        // Init all signals
        address = 0; in_data = 0;
        w_en = 0; en = 0; p_en = 0;

        // Write 45 to addr 9
        #10 address = 8'd9;  in_data = 8'd45; w_en = 1; en = 1;
        #10 w_en = 0;

        // Read from addr 13
        #10 address = 8'd13; in_data = 8'd0;  en = 1;

        // Write 54 to addr 29
        #10 address = 8'd29; in_data = 8'd54; w_en = 1;

        // Write 4 to addr 9 again (overwrite)
        #10 address = 8'd9; in_data = 8'd4;

        // Write 40 to addr 1
        #10 address = 8'd1; in_data = 8'd40;

        // Write 14 to addr 13, but disable reading
        #10 address = 8'd13; in_data = 8'd14; en = 0;

        // Just read from addr 15
        #10 address = 8'd15; w_en = 0; en = 1;

        // Enable memory dump
        #10 p_en = 1;
        #20 p_en = 0;

        #20 $finish;
    end

    // Monitor signal changes
    initial begin
        $monitor("t=%3d clk=%b address=%d in_data=%d out_data=%d w_en=%b en=%b p_en=%b",
                 $time, clk, address, in_data, out_data, w_en, en, p_en);
    end

    // Dump waveform
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, mem8_tb);
    end

endmodule