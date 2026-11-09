
`timescale 1ns / 1ps

module tb_riscv_stage4;

    reg clk;
    reg reset;

    integer errors;
    integer cycles;
    integer i;

    reg [31:0] wb_seen [0:31];
    reg wb_seen_valid [0:31];

    riscv_top dut (
        .clk(clk),
        .reset(reset)
    );

    // 10 ns clock period
    always #5 clk = ~clk;

    // Monitor register writeback
    always @(negedge clk) begin
        if (reset == 0 && dut.wb_reg_write &&
            dut.wb_rd != 5'd0) begin

            wb_seen[dut.wb_rd] = dut.wb_writeback_data;
            wb_seen_valid[dut.wb_rd] = 1'b1;

        end
    end

    initial begin

        clk = 0;
        reset = 1;
        errors = 0;
        cycles = 0;

        // Initialize monitoring arrays
        for (i = 0; i < 32; i = i + 1) begin
            wb_seen[i] = 32'd0;
            wb_seen_valid[i] = 1'b0;
        end

        // Initialize instruction memory with NOPs
        for (i = 0; i < 256; i = i + 1)
            dut.u_imem.memory[i] = 32'h00000013;

        // ------------------------------------
        // STAGE 4 PROGRAM
        // ------------------------------------

        // x1 = 20
        dut.u_imem.memory[0] = 32'h01400093;

        // x2 = 6
        dut.u_imem.memory[1] = 32'h00600113;

        // x3 = 2 (shift amount)
        dut.u_imem.memory[2] = 32'h00200193;

        // x9 = -16
        dut.u_imem.memory[3] = 32'hFF000493;

        // AND x4, x1, x2
        // 20 AND 6 = 4
        dut.u_imem.memory[4] = 32'h0020F233;

        // OR x5, x1, x2
        // 20 OR 6 = 22
        dut.u_imem.memory[5] = 32'h0020E2B3;

        // XOR x6, x1, x2
        // 20 XOR 6 = 18
        dut.u_imem.memory[6] = 32'h0020C333;

        // SLL x7, x2, x3
        // 6 << 2 = 24
        dut.u_imem.memory[7] = 32'h003113B3;

        // SRL x8, x1, x3
        // 20 >> 2 = 5
        dut.u_imem.memory[8] = 32'h0030D433;

        // SRA x10, x9, x3
        // -16 >>> 2 = -4
        dut.u_imem.memory[9] = 32'h4034D533;

        // SLT x11, x9, x1
        // -16 < 20 = 1
        dut.u_imem.memory[10] = 32'h0014A5B3;

        // SLTU x12, x9, x1
        // Unsigned comparison:
        // 0xFFFFFFF0 < 20 = 0
        dut.u_imem.memory[11] = 32'h0014B633;

        // ADD x13, x1, x2
        // 20 + 6 = 26
        dut.u_imem.memory[12] = 32'h002086B3;

        // SUB x14, x1, x2
        // 20 - 6 = 14
        dut.u_imem.memory[13] = 32'h40208733;

        // LUI x15, 0x12345
        // Expected 0x12345000
        dut.u_imem.memory[14] = 32'h123457B7;

        // AUIPC x16, 0x10
        // Instruction address = 60
        // Expected = 0x00010000 + 60
        //          = 0x0001003C
        dut.u_imem.memory[15] = 32'h00010817;

        // ------------------------------------
        // RESET
        // ------------------------------------

        repeat (3) @(posedge clk);
        #1 reset = 0;

        // Execute program
        repeat (50) begin
            @(posedge clk);
            cycles = cycles + 1;
        end

        #2;

        // ------------------------------------
        // RESULTS
        // ------------------------------------

        $display("");
        $display("====================================");
        $display(" RISC-V STAGE 4 TEST RESULTS");
        $display("====================================");

        // AND
        if (wb_seen_valid[4] && wb_seen[4] == 32'd4)
            $display("PASS: AND x4 = 4");
        else begin
            $display("FAIL: AND x4, actual = %h", wb_seen[4]);
            errors = errors + 1;
        end

        // OR
        if (wb_seen_valid[5] && wb_seen[5] == 32'd22)
            $display("PASS: OR x5 = 22");
        else begin
            $display("FAIL: OR x5, actual = %h", wb_seen[5]);
            errors = errors + 1;
        end

        // XOR
        if (wb_seen_valid[6] && wb_seen[6] == 32'd18)
            $display("PASS: XOR x6 = 18");
        else begin
            $display("FAIL: XOR x6, actual = %h", wb_seen[6]);
            errors = errors + 1;
        end

        // SLL
        if (wb_seen_valid[7] && wb_seen[7] == 32'd24)
            $display("PASS: SLL x7 = 24");
        else begin
            $display("FAIL: SLL x7, actual = %h", wb_seen[7]);
            errors = errors + 1;
        end

        // SRL
        if (wb_seen_valid[8] && wb_seen[8] == 32'd5)
            $display("PASS: SRL x8 = 5");
        else begin
            $display("FAIL: SRL x8, actual = %h", wb_seen[8]);
            errors = errors + 1;
        end

        // SRA
        if (wb_seen_valid[10] &&
            wb_seen[10] == 32'hFFFFFFFC)
            $display("PASS: SRA x10 = -4");
        else begin
            $display("FAIL: SRA x10, actual = %h", wb_seen[10]);
            errors = errors + 1;
        end

        // SLT
        if (wb_seen_valid[11] && wb_seen[11] == 32'd1)
            $display("PASS: SLT x11 = 1");
        else begin
            $display("FAIL: SLT x11, actual = %h", wb_seen[11]);
            errors = errors + 1;
        end

        // SLTU
        if (wb_seen_valid[12] && wb_seen[12] == 32'd0)
            $display("PASS: SLTU x12 = 0");
        else begin
            $display("FAIL: SLTU x12, actual = %h", wb_seen[12]);
            errors = errors + 1;
        end

        // ADD
        if (wb_seen_valid[13] && wb_seen[13] == 32'd26)
            $display("PASS: ADD x13 = 26");
        else begin
            $display("FAIL: ADD x13, actual = %h", wb_seen[13]);
            errors = errors + 1;
        end

        // SUB
        if (wb_seen_valid[14] && wb_seen[14] == 32'd14)
            $display("PASS: SUB x14 = 14");
        else begin
            $display("FAIL: SUB x14, actual = %h", wb_seen[14]);
            errors = errors + 1;
        end

        // LUI
        if (wb_seen_valid[15] &&
            wb_seen[15] == 32'h12345000)
            $display("PASS: LUI x15 = 0x12345000");
        else begin
            $display("FAIL: LUI x15, actual = %h", wb_seen[15]);
            errors = errors + 1;
        end

        // AUIPC
        if (wb_seen_valid[16] &&
            wb_seen[16] == 32'h0001003C)
            $display("PASS: AUIPC x16 = 0x0001003C");
        else begin
            $display("FAIL: AUIPC x16, actual = %h", wb_seen[16]);
            errors = errors + 1;
        end

        // ------------------------------------
        // FINAL SUMMARY
        // ------------------------------------

        $display("");
        $display("Total cycles = %0d", cycles);
        $display("Total errors = %0d", errors);

        if (errors == 0)
            $display("OVERALL RESULT: ALL STAGE 4 TESTS PASSED");
        else
            $display("OVERALL RESULT: STAGE 4 TEST FAILED");

        $display("====================================");

        $finish;

    end

endmodule
