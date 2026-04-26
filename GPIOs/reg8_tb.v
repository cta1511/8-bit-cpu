`include "reg8.v"

module reg8_tb;

    reg clk;
    reg [4:0] address1, address2;
    reg [4:0] rwdt1, rwdt2;
    reg [7:0] in_data1, in_data2;
    reg w_en, p_en;
    wire [7:0] out_data1, out_data2;

    // Instantiate the DUT (Device Under Test)
    reg8 uut (
        .clk(clk),
        .rwdt1(rwdt1),
        .rwdt2(rwdt2),
        .address1(address1),
        .address2(address2),
        .in_data1(in_data1),
        .in_data2(in_data2),
        .out_data1(out_data1),
        .out_data2(out_data2),
        .w_en(w_en),
        .p_en(p_en)
    );

    // Generate clock
    initial clk = 0;
    always #5 clk = ~clk;  // Chu kỳ 10 đơn vị thời gian

    // Stimulus
    initial begin
        // Ghi vào reg[9] = 45, reg[13] = 67
        w_en = 1; p_en = 0;
        rwdt1 = 5'd9; rwdt2 = 5'd13;
        in_data1 = 8'd45; in_data2 = 8'd67;
        address1 = 5'd9; address2 = 5'd13;
        #10;

        // Đọc lại, không ghi
        w_en = 0;
        address1 = 5'd13; address2 = 5'd9;
        #10;

        // Ghi khác
        w_en = 1;
        rwdt1 = 5'd14; rwdt2 = 5'd15;
        in_data1 = 8'd11; in_data2 = 8'd22;
        #10;

        // In toàn bộ thanh ghi ra file
        p_en = 1;
        #10;
        p_en = 0;

        // Kết thúc
        #30 $finish;
    end

    // Monitor output
    initial
        $monitor("t=%3d clk=%b w_en=%b p_en=%b | rwdt1=%d in1=%d | rwdt2=%d in2=%d | addr1=%d out1=%d | addr2=%d out2=%d",
            $time, clk, w_en, p_en, rwdt1, in_data1, rwdt2, in_data2, address1, out_data1, address2, out_data2);

    // Dump waveform
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, reg8_tb);
    end

endmodule