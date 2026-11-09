
`timescale 1ns / 1ps

module tb_riscv_stage3;

    reg clk;
    reg reset;

    integer errors;
    integer cycles;
    integer i;

    // Capture register writeback values
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
        // STAGE 3 PROGRAM
        // ------------------------------------

        // Initialize registers
        // x1 = 5
        dut.u_imem.memory[0] = 32'h00500093;

        // x2 = 10
        dut.u_imem.memory[1] = 32'h00A00113;

        // BEQ x1, x1, +8
        // Should skip instruction at index 3
        dut.u_imem.memory[2] = 32'h00108463;

        // Should NOT execute: x10 = 99
        dut.u_imem.memory[3] = 32'h06300513;

        // BNE x1, x2, +8
        dut.u_imem.memory[4] = 32'h00209463;

        // Should NOT execute: x11 = 99
        dut.u_imem.memory[5] = 32'h06300593;

        // BLT x1, x2, +8
        dut.u_imem.memory[6] = 32'h0020C463;

        // Should NOT execute: x12 = 99
        dut.u_imem.memory[7] = 32'h06300613;

        // BGE x2, x1, +8
        dut.u_imem.memory[8] = 32'h00115463;

        // Should NOT execute: x13 = 99
        dut.u_imem.memory[9] = 32'h06300693;

        // BLTU x1, x2, +8
        dut.u_imem.memory[10] = 32'h0020E463;

        // Should NOT execute: x14 = 99
        dut.u_imem.memory[11] = 32'h06300713;

        // BGEU x2, x1, +8
        dut.u_imem.memory[12] = 32'h00117463;

        // Should NOT execute: x15 = 99
        dut.u_imem.memory[13] = 32'h06300793;

        // JAL x8, +8
        // Link address should be 60
        dut.u_imem.memory[14] = 32'h0080046F;

        // Should NOT execute: x16 = 99
        dut.u_imem.memory[15] = 32'h06300813;

        // JALR target address = 80
        // x17 = 80
        dut.u_imem.memory[16] = 32'h05000893;

        // NOP
        dut.u_imem.memory[17] = 32'h00000013;

        // JALR x9, 0(x17)
        // Target address = 80
        // Link address should be 76
        dut.u_imem.memory[18] = 32'h000884E7;

        // Should NOT execute: x18 = 99
        dut.u_imem.memory[19] = 32'h06300913;

        // Jump target: x20 = 42
        dut.u_imem.memory[20] = 32'h02A00A13;

        // ------------------------------------
        // RESET
        // ------------------------------------

        repeat (3) @(posedge clk);
        #1 reset = 0;

        // Allow the program to execute
        repeat (45) begin
            @(posedge clk);
            cycles = cycles + 1;
        end

        #2;

        // ------------------------------------
        // RESULTS
        // ------------------------------------

        $display("");
        $display("====================================");
        $display(" RISC-V STAGE 3 TEST RESULTS");
        $display("====================================");

        // Check branch instructions:
        // If a branch fails, its skipped instruction
        // will incorrectly write 99 into a register.

        for (i = 10; i <= 15; i = i + 1) begin
            if (!wb_seen_valid[i]) begin
                $display("PASS: Branch test x%0d", i);
            end
            else begin
                $display("FAIL: Branch test x%0d = %0d",
                         i, wb_seen[i]);
                errors = errors + 1;
            end
        end

        // JAL: x8 should contain PC + 4 = 60
        if (wb_seen_valid[8] && wb_seen[8] == 32'd60) begin
            $display("PASS: JAL link address x8 = 60");
        end
        else begin
            $display("FAIL: JAL link address");
            errors = errors + 1;
        end

        // JAL skipped instruction
        if (!wb_seen_valid[16]) begin
            $display("PASS: JAL pipeline flush");
        end
        else begin
            $display("FAIL: JAL pipeline flush");
            errors = errors + 1;
        end

        // x17 should contain JALR target address 80
        if (wb_seen_valid[17] && wb_seen[17] == 32'd80) begin
            $display("PASS: JALR base address x17 = 80");
        end
        else begin
            $display("FAIL: JALR base address");
            errors = errors + 1;
        end

        // JALR link address = PC + 4 = 76
        if (wb_seen_valid[9] && wb_seen[9] == 32'd76) begin
            $display("PASS: JALR link address x9 = 76");
        end
        else begin
            $display("FAIL: JALR link address");
            errors = errors + 1;
        end

        // JALR skipped instruction
        if (!wb_seen_valid[18]) begin
            $display("PASS: JALR pipeline flush");
        end
        else begin
            $display("FAIL: JALR pipeline flush");
            errors = errors + 1;
        end

        // Jump target instruction
        if (wb_seen_valid[20] && wb_seen[20] == 32'd42) begin
            $display("PASS: JALR target execution x20 = 42");
        end
        else begin
            $display("FAIL: JALR target execution");
            errors = errors + 1;
        end

        // Final summary
        $display("");
        $display("Total cycles = %0d", cycles);
        $display("Total errors = %0d", errors);

        if (errors == 0)
            $display("OVERALL RESULT: ALL STAGE 3 TESTS PASSED");
        else
            $display("OVERALL RESULT: STAGE 3 TEST FAILED");

        $display("====================================");

        $finish;

    end

endmodule
