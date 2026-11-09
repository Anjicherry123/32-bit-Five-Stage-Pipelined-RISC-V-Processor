
module alu_control (

    input wire [1:0] ALUOp,
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [6:0] funct7,

    output reg [3:0] alu_control

);

    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLL  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_SLT  = 4'b1000;
    localparam ALU_SLTU = 4'b1001;

    always @(*) begin

        alu_control = ALU_ADD;

        case (ALUOp)

            // Load and Store address calculation
            2'b00: begin
                alu_control = ALU_ADD;
            end

            // Branch comparison
            2'b01: begin

                case (funct3)

                    3'b000: alu_control = ALU_SUB;  // BEQ
                    3'b001: alu_control = ALU_SUB;  // BNE
                    3'b100: alu_control = ALU_SLT;  // BLT
                    3'b101: alu_control = ALU_SLT;  // BGE
                    3'b110: alu_control = ALU_SLTU; // BLTU
                    3'b111: alu_control = ALU_SLTU; // BGEU

                    default: alu_control = ALU_ADD;

                endcase

            end

            // R-type and I-type arithmetic
            2'b10: begin

                case (funct3)

                    // ADD / SUB / ADDI
                    3'b000: begin

                        if (opcode == 7'b0110011 &&
                            funct7 == 7'b0100000)
                            alu_control = ALU_SUB;
                        else
                            alu_control = ALU_ADD;

                    end

                    // SLL / SLLI
                    3'b001: begin
                        alu_control = ALU_SLL;
                    end

                    // SLT / SLTI
                    3'b010: begin
                        alu_control = ALU_SLT;
                    end

                    // SLTU / SLTIU
                    3'b011: begin
                        alu_control = ALU_SLTU;
                    end

                    // XOR / XORI
                    3'b100: begin
                        alu_control = ALU_XOR;
                    end

                    // SRL / SRA / SRLI / SRAI
                    3'b101: begin

                        if (funct7 == 7'b0100000)
                            alu_control = ALU_SRA;
                        else
                            alu_control = ALU_SRL;

                    end

                    // OR / ORI
                    3'b110: begin
                        alu_control = ALU_OR;
                    end

                    // AND / ANDI
                    3'b111: begin
                        alu_control = ALU_AND;
                    end

                    default: alu_control = ALU_ADD;

                endcase

            end

            default: begin
                alu_control = ALU_ADD;
            end

        endcase

    end

endmodule
