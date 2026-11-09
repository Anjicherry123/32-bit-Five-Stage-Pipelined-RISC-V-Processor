
module hazard_detection (

    input wire [4:0] id_ex_rd,
    input wire id_ex_mem_read,

    input wire [4:0] if_id_rs1,
    input wire [4:0] if_id_rs2,

    output reg pc_write,
    output reg if_id_write,
    output reg control_stall

);

    always @(*) begin

        // Default: normal pipeline operation
        pc_write = 1'b1;
        if_id_write = 1'b1;
        control_stall = 1'b0;

        // Detect load-use hazard
        if (id_ex_mem_read &&
            (id_ex_rd != 5'd0) &&
            ((id_ex_rd == if_id_rs1) ||
             (id_ex_rd == if_id_rs2))) begin

            // Hold program counter
            pc_write = 1'b0;

            // Hold IF/ID pipeline register
            if_id_write = 1'b0;

            // Insert bubble into ID/EX
            control_stall = 1'b1;

        end

    end

endmodule
