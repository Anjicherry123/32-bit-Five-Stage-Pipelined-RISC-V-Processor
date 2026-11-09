
module forwarding_unit (

    input wire [4:0] id_ex_rs1,
    input wire [4:0] id_ex_rs2,

    input wire [4:0] ex_mem_rd,
    input wire ex_mem_reg_write,
    input wire ex_mem_mem_read,

    input wire [4:0] mem_wb_rd,
    input wire mem_wb_reg_write,

    output reg [1:0] forward_a,
    output reg [1:0] forward_b

);

    always @(*) begin

        // Default: no forwarding
        forward_a = 2'b00;
        forward_b = 2'b00;

        // Forward operand A from EX/MEM
        if (ex_mem_reg_write &&
            !ex_mem_mem_read &&
            (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rs1)) begin

            forward_a = 2'b10;

        end

        // Otherwise forward operand A from MEM/WB
        else if (mem_wb_reg_write &&
                 (mem_wb_rd != 5'd0) &&
                 (mem_wb_rd == id_ex_rs1)) begin

            forward_a = 2'b01;

        end


        // Forward operand B from EX/MEM
        if (ex_mem_reg_write &&
            !ex_mem_mem_read &&
            (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rs2)) begin

            forward_b = 2'b10;

        end

        // Otherwise forward operand B from MEM/WB
        else if (mem_wb_reg_write &&
                 (mem_wb_rd != 5'd0) &&
                 (mem_wb_rd == id_ex_rs2)) begin

            forward_b = 2'b01;

        end

    end

endmodule
