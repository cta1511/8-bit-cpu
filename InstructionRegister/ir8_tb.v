`include "ir8.v"

module ir8_tb;

    reg [5:0] address;
    wire [31:0] out_data;

    // Instantiate the instruction register module
    ir8 uut (
        .out_address(address),
        .out_data(out_data)
    );

    // Waveform dump setup
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, ir8_tb);
    end

    // Apply test sequence
    initial begin
        address = 6'd0;
        #20 address = 6'd1;
        #20 address = 6'd2;
        #20 address = 6'd8;
    end

    // Monitor signal values during simulation
    initial
        $monitor("t=%3d address=%d, out_data=%b", $time, address, out_data);

endmodule