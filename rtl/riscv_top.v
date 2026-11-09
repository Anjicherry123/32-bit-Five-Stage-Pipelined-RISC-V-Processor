
`default_nettype none

module riscv_top #(
    parameter IMEM_DEPTH = 256,
    parameter DMEM_DEPTH = 1024,
    parameter INIT_FILE = ""
)(
    input wire clk,
    input wire reset
);

    // =====================================================
    // 1. ALL SIGNAL DECLARATIONS
    // =====================================================

    // Instruction Fetch
    wire [31:0] pc;
    wire [31:0] instruction;
    wire [31:0] pc_plus4;

    // PC and hazard control
    wire pc_write;
    wire if_id_write;
    wire control_stall;
    wire pc_stall;
    wire pc_src;
    wire [31:0] pc_target;

    // IF/ID
    wire [31:0] if_id_pc;
    wire [31:0] if_id_pc_plus4;
    wire [31:0] if_id_instruction;

    // Decode fields
    wire [6:0] id_opcode;
    wire [4:0] id_rs1;
    wire [4:0] id_rs2;
    wire [4:0] id_rd;
    wire [2:0] id_funct3;
    wire [6:0] id_funct7;

    // Decode data
    wire [31:0] id_read_data1;
    wire [31:0] id_read_data2;

    // Raw register-file outputs
    wire [31:0] id_read_data1_raw;
    wire [31:0] id_read_data2_raw;

    wire [31:0] id_immediate;

    // Decode control
    wire id_reg_write;
    wire id_mem_read;
    wire id_mem_write;
    wire id_alu_src;
    wire id_branch;
    wire id_jump;
    wire id_jalr;
    wire [1:0] id_result_src;
    wire [1:0] id_alu_op;
    wire id_illegal;

    // Hazard detection
    wire [4:0] hazard_rs1;
    wire [4:0] hazard_rs2;
    wire id_ex_mem_read;
    wire [4:0] id_ex_rd;

    // ID/EX
    wire [31:0] ex_pc;
    wire [31:0] ex_pc_plus4;
    wire [31:0] ex_read_data1;
    wire [31:0] ex_read_data2;
    wire [31:0] ex_immediate;

    wire [4:0] ex_rs1;
    wire [4:0] ex_rs2;
    wire [4:0] ex_rd;

    wire [6:0] ex_opcode;
    wire [2:0] ex_funct3;
    wire [6:0] ex_funct7;

    wire ex_reg_write;
    wire ex_mem_read;
    wire ex_mem_write;
    wire ex_alu_src;
    wire ex_branch;
    wire ex_jump;
    wire ex_jalr;

    wire [1:0] ex_result_src;
    wire [1:0] ex_alu_op;

    // Forwarding
    wire [1:0] forward_a;
    wire [1:0] forward_b;

    wire [31:0] forwarded_a;
    wire [31:0] forwarded_b;

    // ALU
    wire [31:0] alu_operand_a;
    wire [31:0] alu_operand_b;
    wire [3:0] alu_ctrl_signal;
    wire [31:0] alu_result;
    wire alu_zero;

    // Branch
    wire branch_taken;

    // EX/MEM
    wire [31:0] mem_pc;
    wire [31:0] mem_pc_plus4;
    wire [31:0] ex_mem_alu_result;
    wire [31:0] mem_write_data;

    wire [4:0] ex_mem_rd;
    wire [2:0] mem_funct3;

    wire mem_reg_write;
    wire mem_mem_read;
    wire mem_mem_write;
    wire [1:0] mem_result_src;

    // Memory
    wire [31:0] mem_read_data;

    // MEM/WB
    wire [31:0] wb_pc;
    wire [31:0] wb_pc_plus4;
    wire [31:0] wb_alu_result;
    wire [31:0] wb_mem_read_data;

    wire [4:0] wb_rd;
    wire wb_reg_write;
    wire [1:0] wb_result_src;

    // Writeback
    wire [31:0] wb_writeback_data;


    // =====================================================
    // 2. INSTRUCTION FETCH
    // =====================================================

    assign pc_plus4 = pc + 32'd4;
    assign pc_stall = ~pc_write;

    program_counter u_pc (
        .clk(clk),
        .reset(reset),
        .stall(pc_stall),
        .pc_src(pc_src),
        .pc_target(pc_target),
        .pc(pc)
    );

    instruction_memory #(
        .DEPTH(IMEM_DEPTH),
        .INIT_FILE(INIT_FILE)
    ) u_imem (
        .address(pc),
        .instruction(instruction)
    );


    // =====================================================
    // 3. IF/ID PIPELINE REGISTER
    // =====================================================

    if_id u_if_id (
        .clk(clk),
        .reset(reset),
        .stall(~if_id_write),
        .flush(pc_src),

        .pc_in(pc),
        .pc_plus4_in(pc_plus4),
        .instruction_in(instruction),

        .pc_out(if_id_pc),
        .pc_plus4_out(if_id_pc_plus4),
        .instruction_out(if_id_instruction)
    );


    // =====================================================
    // 4. INSTRUCTION DECODE
    // =====================================================

    assign id_opcode = if_id_instruction[6:0];
    assign id_rd     = if_id_instruction[11:7];
    assign id_funct3 = if_id_instruction[14:12];
    assign id_rs1    = if_id_instruction[19:15];
    assign id_rs2    = if_id_instruction[24:20];
    assign id_funct7 = if_id_instruction[31:25];

    // -----------------------------------------------------
    // REGISTER FILE
    // -----------------------------------------------------

    register_file u_register_file (
        .clk(clk),
        .reset(reset),
        .reg_write(wb_reg_write),
        .rs1(id_rs1),
        .rs2(id_rs2),
        .rd(wb_rd),
        .write_data(wb_writeback_data),
        .read_data1(id_read_data1_raw),
        .read_data2(id_read_data2_raw)
    );

    // -----------------------------------------------------
    // WB-TO-ID FORWARDING BYPASS
    // -----------------------------------------------------

    assign id_read_data1 =
        (id_rs1 != 5'd0 &&
         wb_reg_write &&
         (wb_rd == id_rs1))
        ? wb_writeback_data
        : id_read_data1_raw;

    assign id_read_data2 =
        (id_rs2 != 5'd0 &&
         wb_reg_write &&
         (wb_rd == id_rs2))
        ? wb_writeback_data
        : id_read_data2_raw;


    // Immediate Generator

    immediate_generator u_immediate (
        .instruction(if_id_instruction),
        .immediate(id_immediate)
    );


    // Control Unit

    control_unit u_control (
        .opcode(id_opcode),

        .RegWrite(id_reg_write),
        .MemRead(id_mem_read),
        .MemWrite(id_mem_write),
        .ALUSrc(id_alu_src),
        .Branch(id_branch),
        .Jump(id_jump),
        .Jalr(id_jalr),

        .ResultSrc(id_result_src),
        .ALUOp(id_alu_op),
        .Illegal(id_illegal)
    );


    // =====================================================
    // 5. HAZARD DETECTION
    // =====================================================

    reg uses_rs1;
    reg uses_rs2;

    always @(*) begin

        uses_rs1 = 1'b0;
        uses_rs2 = 1'b0;

        case (id_opcode)

            // R-type
            7'b0110011: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
            end

            // I-type arithmetic
            7'b0010011: begin
                uses_rs1 = 1'b1;
            end

            // Load
            7'b0000011: begin
                uses_rs1 = 1'b1;
            end

            // Store
            7'b0100011: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
            end

            // Branch
            7'b1100011: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
            end

            // JALR
            7'b1100111: begin
                uses_rs1 = 1'b1;
            end

            default: begin
                uses_rs1 = 1'b0;
                uses_rs2 = 1'b0;
            end

        endcase

    end

    assign hazard_rs1 = uses_rs1 ? id_rs1 : 5'd0;
    assign hazard_rs2 = uses_rs2 ? id_rs2 : 5'd0;

    hazard_detection u_hazard (
        .id_ex_rd(id_ex_rd),
        .id_ex_mem_read(id_ex_mem_read),

        .if_id_rs1(hazard_rs1),
        .if_id_rs2(hazard_rs2),

        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .control_stall(control_stall)
    );


    // =====================================================
    // 6. ID/EX PIPELINE REGISTER
    // =====================================================

    assign id_ex_mem_read = ex_mem_read;
    assign id_ex_rd = ex_rd;

    id_ex u_id_ex (

        .clk(clk),
        .reset(reset),
        .stall(1'b0),
        .flush(control_stall | pc_src),

        .pc_in(if_id_pc),
        .pc_plus4_in(if_id_pc_plus4),
        .read_data1_in(id_read_data1),
        .read_data2_in(id_read_data2),
        .immediate_in(id_immediate),

        .rs1_in(id_rs1),
        .rs2_in(id_rs2),
        .rd_in(id_rd),

        .opcode_in(id_opcode),
        .funct3_in(id_funct3),
        .funct7_in(id_funct7),

        .reg_write_in(id_reg_write),
        .mem_read_in(id_mem_read),
        .mem_write_in(id_mem_write),
        .alu_src_in(id_alu_src),
        .branch_in(id_branch),
        .jump_in(id_jump),
        .jalr_in(id_jalr),

        .result_src_in(id_result_src),
        .alu_op_in(id_alu_op),

        .pc_out(ex_pc),
        .pc_plus4_out(ex_pc_plus4),
        .read_data1_out(ex_read_data1),
        .read_data2_out(ex_read_data2),
        .immediate_out(ex_immediate),

        .rs1_out(ex_rs1),
        .rs2_out(ex_rs2),
        .rd_out(ex_rd),

        .opcode_out(ex_opcode),
        .funct3_out(ex_funct3),
        .funct7_out(ex_funct7),

        .reg_write_out(ex_reg_write),
        .mem_read_out(ex_mem_read),
        .mem_write_out(ex_mem_write),
        .alu_src_out(ex_alu_src),
        .branch_out(ex_branch),
        .jump_out(ex_jump),
        .jalr_out(ex_jalr),

        .result_src_out(ex_result_src),
        .alu_op_out(ex_alu_op)
    );


    // =====================================================
    // 7. EXECUTE STAGE
    // =====================================================

    forwarding_unit u_forwarding (

        .id_ex_rs1(ex_rs1),
        .id_ex_rs2(ex_rs2),

        .ex_mem_rd(ex_mem_rd),
        .ex_mem_reg_write(mem_reg_write),
        .ex_mem_mem_read(mem_mem_read),

        .mem_wb_rd(wb_rd),
        .mem_wb_reg_write(wb_reg_write),

        .forward_a(forward_a),
        .forward_b(forward_b)
    );


    // Forwarding Multiplexer A

    assign forwarded_a =
        (forward_a == 2'b10) ? ex_mem_alu_result :
        (forward_a == 2'b01) ? wb_writeback_data :
                               ex_read_data1;


    // Forwarding Multiplexer B

    assign forwarded_b =
        (forward_b == 2'b10) ? ex_mem_alu_result :
        (forward_b == 2'b01) ? wb_writeback_data :
                               ex_read_data2;


    // LUI and AUIPC operand selection

    assign alu_operand_a =
        (ex_opcode == 7'b0110111) ? 32'b0 :
        (ex_opcode == 7'b0010111) ? ex_pc :
                                    forwarded_a;

    assign alu_operand_b =
        ex_alu_src ? ex_immediate : forwarded_b;


    // ALU Control

    alu_control u_alu_control (
        .ALUOp(ex_alu_op),
        .opcode(ex_opcode),
        .funct3(ex_funct3),
        .funct7(ex_funct7),
        .alu_control(alu_ctrl_signal)
    );


    // ALU

    alu u_alu (
        .operand_a(alu_operand_a),
        .operand_b(alu_operand_b),
        .alu_control(alu_ctrl_signal),
        .alu_result(alu_result),
        .zero(alu_zero)
    );


    // Branch Unit

    branch_unit u_branch (
        .rs1_data(forwarded_a),
        .rs2_data(forwarded_b),
        .funct3(ex_funct3),
        .branch(ex_branch),
        .branch_taken(branch_taken)
    );


    // PC Update

    pc_update u_pc_update (
        .pc_current(ex_pc),
        .immediate(ex_immediate),
        .rs1_data(forwarded_a),

        .branch_taken(branch_taken),
        .jump(ex_jump),
        .jalr(ex_jalr),

        .pc_next(pc_target)
    );

    assign pc_src = branch_taken | ex_jump;


    // =====================================================
    // 8. EX/MEM PIPELINE REGISTER
    // =====================================================

    ex_mem u_ex_mem (

        .clk(clk),
        .reset(reset),
        .stall(1'b0),
        .flush(1'b0),

        .pc_in(ex_pc),
        .pc_plus4_in(ex_pc_plus4),

        .alu_result_in(alu_result),
        .write_data_in(forwarded_b),

        .rd_in(ex_rd),
        .funct3_in(ex_funct3),

        .reg_write_in(ex_reg_write),
        .mem_read_in(ex_mem_read),
        .mem_write_in(ex_mem_write),

        .result_src_in(ex_result_src),

        .pc_out(mem_pc),
        .pc_plus4_out(mem_pc_plus4),

        .alu_result_out(ex_mem_alu_result),
        .write_data_out(mem_write_data),

        .rd_out(ex_mem_rd),
        .funct3_out(mem_funct3),

        .reg_write_out(mem_reg_write),
        .mem_read_out(mem_mem_read),
        .mem_write_out(mem_mem_write),

        .result_src_out(mem_result_src)
    );


    // =====================================================
    // 9. MEMORY ACCESS STAGE
    // =====================================================

    data_memory #(
        .DEPTH(DMEM_DEPTH)
    ) u_data_memory (

        .clk(clk),
        .mem_read(mem_mem_read),
        .mem_write(mem_mem_write),

        .address(ex_mem_alu_result),
        .write_data(mem_write_data),
        .funct3(mem_funct3),

        .read_data(mem_read_data)
    );


    // =====================================================
    // 10. MEM/WB PIPELINE REGISTER
    // =====================================================

    mem_wb u_mem_wb (

        .clk(clk),
        .reset(reset),
        .stall(1'b0),
        .flush(1'b0),

        .pc_in(mem_pc),
        .pc_plus4_in(mem_pc_plus4),

        .alu_result_in(ex_mem_alu_result),
        .mem_read_data_in(mem_read_data),

        .rd_in(ex_mem_rd),
        .reg_write_in(mem_reg_write),

        .result_src_in(mem_result_src),

        .pc_out(wb_pc),
        .pc_plus4_out(wb_pc_plus4),

        .alu_result_out(wb_alu_result),
        .mem_read_data_out(wb_mem_read_data),

        .rd_out(wb_rd),
        .reg_write_out(wb_reg_write),

        .result_src_out(wb_result_src)
    );


    // =====================================================
    // 11. WRITEBACK STAGE
    // =====================================================

    writeback_unit u_writeback (

        .alu_result(wb_alu_result),
        .mem_read_data(wb_mem_read_data),
        .pc_plus4(wb_pc_plus4),
        .result_src(wb_result_src),

        .writeback_data(wb_writeback_data)
    );

endmodule

`default_nettype wire
