`timescale 1ns / 1ps

module tb_riscv_top;

    reg clk;
    reg reset;

    integer errors;
    integer cycles;

    integer seen_x3;
    integer seen_x5;
    integer seen_x6;
    integer seen_x7;

    riscv_top dut (
        .clk(clk),
        .reset(reset)
    );

    // 10 ns clock period
    always #5 clk = ~clk;

    // Monitor writeback stage
    // Sample at negative edge to avoid race conditions.
    always @(negedge clk) begin
        if (reset == 0 && dut.wb_reg_write) begin
            case (dut.wb_rd)

                5'd3: begin
                    if (dut.wb_writeback_data == 32'd15)
                        seen_x3 = 1;
                end

                5'd5: begin
                    if (dut.wb_writeback_data == 32'd20)
                        seen_x5 = 1;
                end

                5'd6: begin
                    if (dut.wb_writeback_data == 32'd20)
                        seen_x6 = 1;
                end

                5'd7: begin
                    if (dut.wb_writeback_data == 32'd30)
                        seen_x7 = 1;
                end

            endcase
        end
    end

    initial begin

        clk = 0;
        reset = 1;

        errors = 0;
        cycles = 0;

        seen_x3 = 0;
        seen_x5 = 0;
        seen_x6 = 0;
        seen_x7 = 0;

        // Initialize instruction memory with NOPs
        for (integer i = 0; i < 256; i = i + 1)
            dut.u_imem.memory[i] = 32'h00000013;

        // --------------------------------
        // PROGRAM
        // --------------------------------

        // 1. ADDI x1, x0, 5
        dut.u_imem.memory[0] = 32'h00500093;

        // 2. ADDI x2, x0, 10
        dut.u_imem.memory[1] = 32'h00A00113;

        // 3. ADD x3, x1, x2
        // Expected x3 = 15
        dut.u_imem.memory[2] = 32'h002081B3;

        // 4. ADD x5, x3, x1
        // Tests data forwarding
        // Expected x5 = 20
        dut.u_imem.memory[3] = 32'h001182B3;

        // 5. SW x5, 4(x0)
        // Store 20 at address 4
        dut.u_imem.memory[4] = 32'h00502223;

        // 6. LW x6, 4(x0)
        // Load 20 into x6
        dut.u_imem.memory[5] = 32'h00402303;

        // 7. ADD x7, x6, x2
        // Tests load-use hazard
        // Expected x7 = 30
        dut.u_imem.memory[6] = 32'h002303B3;

        // 8. SW x7, 8(x0)
        // Store 30 at address 8
        dut.u_imem.memory[7] = 32'h00702423;

        // --------------------------------
        // RESET
        // --------------------------------

        repeat (3) @(posedge clk);
        #1 reset = 0;

        // Execute program
        repeat (30) begin
            @(posedge clk);
            cycles = cycles + 1;
        end

        #2;

        // --------------------------------
        // RESULTS
        // --------------------------------

        $display("");
        $display("====================================");
        $display(" RISC-V PIPELINE TEST RESULTS");
        $display("====================================");

        // Register writeback checks

        if (seen_x3) begin
            $display("PASS: ADD result x3 = 15");
        end
        else begin
            $display("FAIL: ADD result x3");
            errors = errors + 1;
        end

        if (seen_x5) begin
            $display("PASS: Forwarding result x5 = 20");
        end
        else begin
            $display("FAIL: Forwarding result x5");
            errors = errors + 1;
        end

        if (seen_x6) begin
            $display("PASS: Load result x6 = 20");
        end
        else begin
            $display("FAIL: Load result x6");
            errors = errors + 1;
        end

        if (seen_x7) begin
            $display("PASS: Load-use result x7 = 30");
        end
        else begin
            $display("FAIL: Load-use result x7");
            errors = errors + 1;
        end

        // Memory checks

        $display("");
        $display("Memory address 4:");

        $display("Byte 4 = %0d",
                 dut.u_data_memory.memory[4]);

        $display("Byte 5 = %0d",
                 dut.u_data_memory.memory[5]);

        $display("Byte 6 = %0d",
                 dut.u_data_memory.memory[6]);

        $display("Byte 7 = %0d",
                 dut.u_data_memory.memory[7]);

        $display("");
        $display("Memory address 8:");

        $display("Byte 8 = %0d",
                 dut.u_data_memory.memory[8]);

        $display("Byte 9 = %0d",
                 dut.u_data_memory.memory[9]);

        $display("Byte 10 = %0d",
                 dut.u_data_memory.memory[10]);

        $display("Byte 11 = %0d",
                 dut.u_data_memory.memory[11]);

        if (dut.u_data_memory.memory[4] == 8'd20 &&
            dut.u_data_memory.memory[5] == 8'd0 &&
            dut.u_data_memory.memory[6] == 8'd0 &&
            dut.u_data_memory.memory[7] == 8'd0) begin

            $display("PASS: First store operation");

        end
        else begin
            $display("FAIL: First store operation");
            errors = errors + 1;
        end

        if (dut.u_data_memory.memory[8] == 8'd30 &&
            dut.u_data_memory.memory[9] == 8'd0 &&
            dut.u_data_memory.memory[10] == 8'd0 &&
            dut.u_data_memory.memory[11] == 8'd0) begin

            $display("PASS: Second store operation");

        end
        else begin
            $display("FAIL: Second store operation");
            errors = errors + 1;
        end

        // Final summary

        $display("");
        $display("Total cycles = %0d", cycles);
        $display("Total errors = %0d", errors);

        if (errors == 0)
            $display("OVERALL RESULT: ALL TESTS PASSED");
        else
            $display("OVERALL RESULT: TEST FAILED");

        $display("====================================");

        $finish;

    end

endmodule