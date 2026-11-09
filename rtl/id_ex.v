
module id_ex (

    input wire clk,
    input wire reset,
    input wire stall,
    input wire flush,

    // Data inputs
    input wire [31:0] pc_in,
    input wire [31:0] pc_plus4_in,
    input wire [31:0] read_data1_in,
    input wire [31:0] read_data2_in,
    input wire [31:0] immediate_in,

    // Register addresses
    input wire [4:0] rs1_in,
    input wire [4:0] rs2_in,
    input wire [4:0] rd_in,

    // Instruction fields
    input wire [6:0] opcode_in,
    input wire [2:0] funct3_in,
    input wire [6:0] funct7_in,

    // Control inputs
    input wire reg_write_in,
    input wire mem_read_in,
    input wire mem_write_in,
    input wire alu_src_in,
    input wire branch_in,
    input wire jump_in,
    input wire jalr_in,

    input wire [1:0] result_src_in,
    input wire [1:0] alu_op_in,

    // Data outputs
    output reg [31:0] pc_out,
    output reg [31:0] pc_plus4_out,
    output reg [31:0] read_data1_out,
    output reg [31:0] read_data2_out,
    output reg [31:0] immediate_out,

    // Register address outputs
    output reg [4:0] rs1_out,
    output reg [4:0] rs2_out,
    output reg [4:0] rd_out,

    // Instruction field outputs
    output reg [6:0] opcode_out,
    output reg [2:0] funct3_out,
    output reg [6:0] funct7_out,

    // Control outputs
    output reg reg_write_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg alu_src_out,
    output reg branch_out,
    output reg jump_out,
    output reg jalr_out,

    output reg [1:0] result_src_out,
    output reg [1:0] alu_op_out

);

always @(posedge clk) begin

    if (reset || flush) begin

        pc_out <= 0;
        pc_plus4_out <= 0;
        read_data1_out <= 0;
        read_data2_out <= 0;
        immediate_out <= 0;

        rs1_out <= 0;
        rs2_out <= 0;
        rd_out <= 0;

        opcode_out <= 0;
        funct3_out <= 0;
        funct7_out <= 0;

        reg_write_out <= 0;
        mem_read_out <= 0;
        mem_write_out <= 0;
        alu_src_out <= 0;
        branch_out <= 0;
        jump_out <= 0;
        jalr_out <= 0;

        result_src_out <= 0;
        alu_op_out <= 0;

    end

    else if (stall) begin
        // Hold previous values
    end

    else begin

        pc_out <= pc_in;
        pc_plus4_out <= pc_plus4_in;
        read_data1_out <= read_data1_in;
        read_data2_out <= read_data2_in;
        immediate_out <= immediate_in;

        rs1_out <= rs1_in;
        rs2_out <= rs2_in;
        rd_out <= rd_in;

        opcode_out <= opcode_in;
        funct3_out <= funct3_in;
        funct7_out <= funct7_in;

        reg_write_out <= reg_write_in;
        mem_read_out <= mem_read_in;
        mem_write_out <= mem_write_in;
        alu_src_out <= alu_src_in;
        branch_out <= branch_in;
        jump_out <= jump_in;
        jalr_out <= jalr_in;

        result_src_out <= result_src_in;
        alu_op_out <= alu_op_in;

    end

end

endmodule
