
`timescale 1ns / 1ps

module tb_riscv_stage5;

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

    // Monitor writeback stage
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
        // STAGE 5 PROGRAM
        // ------------------------------------

        // x1 = 64 (base address)
        dut.u_imem.memory[0] = 32'h04000093;

        // x2 = -128
        dut.u_imem.memory[1] = 32'hF8000113;

        // SB x2, 0(x1)
        // Store 0x80 at address 64
        dut.u_imem.memory[2] = 32'h00208023;

        // LB x3, 0(x1)
        // Expected: 0xFFFFFF80 (-128)
        dut.u_imem.memory[3] = 32'h00008183;

        // LBU x4, 0(x1)
        // Expected: 0x00000080 (128)
        dut.u_imem.memory[4] = 32'h0000C203;

        // LUI x5, 0x8
        // Expected x5 = 0x00008000
        dut.u_imem.memory[5] = 32'h000082B7;

        // ADDI x5, x5, 1
        // Expected x5 = 0x00008001
        dut.u_imem.memory[6] = 32'h00128293;

        // SH x5, 4(x1)
        // Store 0x8001 at address 68
        dut.u_imem.memory[7] = 32'h00509223;

        // LH x6, 4(x1)
        // Expected: 0xFFFF8001
        dut.u_imem.memory[8] = 32'h00409303;

        // LHU x7, 4(x1)
        // Expected: 0x00008001
        dut.u_imem.memory[9] = 32'h0040D383;

        // LUI x8, 0x12345
        // Expected x8 = 0x12345000
        dut.u_imem.memory[10] = 32'h12345437;

        // ADDI x8, x8, 0x678
        // Expected x8 = 0x12345678
        dut.u_imem.memory[11] = 32'h67840413;

        // SW x8, 8(x1)
        // Store 0x12345678 at address 72
        dut.u_imem.memory[12] = 32'h0080A423;

        // LW x9, 8(x1)
        // Expected: 0x12345678
        dut.u_imem.memory[13] = 32'h0080A483;

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
        $display(" RISC-V STAGE 5 TEST RESULTS");
        $display("====================================");

        // LB
        if (wb_seen_valid[3] &&
            wb_seen[3] == 32'hFFFFFF80)
            $display("PASS: LB x3 = 0xFFFFFF80");
        else begin
            $display("FAIL: LB x3, actual = %h", wb_seen[3]);
            errors = errors + 1;
        end

        // LBU
        if (wb_seen_valid[4] &&
            wb_seen[4] == 32'h00000080)
            $display("PASS: LBU x4 = 0x00000080");
        else begin
            $display("FAIL: LBU x4, actual = %h", wb_seen[4]);
            errors = errors + 1;
        end

        // LH
        if (wb_seen_valid[6] &&
            wb_seen[6] == 32'hFFFF8001)
            $display("PASS: LH x6 = 0xFFFF8001");
        else begin
            $display("FAIL: LH x6, actual = %h", wb_seen[6]);
            errors = errors + 1;
        end

        // LHU
        if (wb_seen_valid[7] &&
            wb_seen[7] == 32'h00008001)
            $display("PASS: LHU x7 = 0x00008001");
        else begin
            $display("FAIL: LHU x7, actual = %h", wb_seen[7]);
            errors = errors + 1;
        end

        // LW
        if (wb_seen_valid[9] &&
            wb_seen[9] == 32'h12345678)
            $display("PASS: LW x9 = 0x12345678");
        else begin
            $display("FAIL: LW x9, actual = %h", wb_seen[9]);
            errors = errors + 1;
        end

        // ------------------------------------
        // MEMORY CHECKS
        // ------------------------------------

        $display("");
        $display("Memory address 64:");

        $display("Byte 64 = %h",
                 dut.u_data_memory.memory[64]);

        $display("Byte 65 = %h",
                 dut.u_data_memory.memory[65]);

        $display("");
        $display("Memory address 68:");

        $display("Byte 68 = %h",
                 dut.u_data_memory.memory[68]);

        $display("Byte 69 = %h",
                 dut.u_data_memory.memory[69]);

        $display("");
        $display("Memory address 72:");

        $display("Byte 72 = %h",
                 dut.u_data_memory.memory[72]);

        $display("Byte 73 = %h",
                 dut.u_data_memory.memory[73]);

        $display("Byte 74 = %h",
                 dut.u_data_memory.memory[74]);

        $display("Byte 75 = %h",
                 dut.u_data_memory.memory[75]);

        // SB check
        if (dut.u_data_memory.memory[64] == 8'h80) begin
            $display("PASS: SB memory operation");
        end
        else begin
            $display("FAIL: SB memory operation");
            errors = errors + 1;
        end

        // SH check
        // Little-endian: 01, 80
        if (dut.u_data_memory.memory[68] == 8'h01 &&
            dut.u_data_memory.memory[69] == 8'h80) begin
            $display("PASS: SH memory operation");
        end
        else begin
            $display("FAIL: SH memory operation");
            errors = errors + 1;
        end

        // SW check
        // Little-endian: 78, 56, 34, 12
        if (dut.u_data_memory.memory[72] == 8'h78 &&
            dut.u_data_memory.memory[73] == 8'h56 &&
            dut.u_data_memory.memory[74] == 8'h34 &&
            dut.u_data_memory.memory[75] == 8'h12) begin
            $display("PASS: SW memory operation");
        end
        else begin
            $display("FAIL: SW memory operation");
            errors = errors + 1;
        end

        // ------------------------------------
        // FINAL SUMMARY
        // ------------------------------------

        $display("");
        $display("Total cycles = %0d", cycles);
        $display("Total errors = %0d", errors);

        if (errors == 0)
            $display("OVERALL RESULT: ALL STAGE 5 TESTS PASSED");
        else
            $display("OVERALL RESULT: STAGE 5 TEST FAILED");

        $display("====================================");

        $finish;

    end

endmodule
