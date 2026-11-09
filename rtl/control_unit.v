
module control_unit (

    input wire [6:0] opcode,

    output reg RegWrite,
    output reg MemRead,
    output reg MemWrite,
    output reg ALUSrc,
    output reg Branch,
    output reg Jump,
    output reg Jalr,

    output reg [1:0] ResultSrc,
    output reg [1:0] ALUOp,

    output reg Illegal

);

    // ResultSrc encoding
    // 00 = ALU result
    // 01 = Memory data
    // 10 = PC + 4

    // ALUOp encoding
    // 00 = Addition
    // 01 = Branch comparison
    // 10 = R-type / I-type ALU decoding

    always @(*) begin

        // Default control signals
        RegWrite = 0;
        MemRead  = 0;
        MemWrite = 0;
        ALUSrc   = 0;
        Branch   = 0;
        Jump     = 0;
        Jalr     = 0;

        ResultSrc = 2'b00;
        ALUOp     = 2'b00;

        Illegal = 0;

        case (opcode)

            // R-type instructions
            7'b0110011: begin
                RegWrite = 1;
                ALUOp = 2'b10;
            end

            // I-type arithmetic instructions
            7'b0010011: begin
                RegWrite = 1;
                ALUSrc = 1;
                ALUOp = 2'b10;
            end

            // Load instructions
            7'b0000011: begin
                RegWrite = 1;
                MemRead = 1;
                ALUSrc = 1;
                ResultSrc = 2'b01;
                ALUOp = 2'b00;
            end

            // Store instructions
            7'b0100011: begin
                MemWrite = 1;
                ALUSrc = 1;
                ALUOp = 2'b00;
            end

            // Branch instructions
            7'b1100011: begin
                Branch = 1;
                ALUOp = 2'b01;
            end

            // JAL instruction
            7'b1101111: begin
                RegWrite = 1;
                Jump = 1;
                ResultSrc = 2'b10;
            end

            // JALR instruction
            7'b1100111: begin
                RegWrite = 1;
                Jump = 1;
                Jalr = 1;
                ALUSrc = 1;
                ResultSrc = 2'b10;
            end

            // LUI instruction
            7'b0110111: begin
                RegWrite = 1;
                ALUSrc = 1;
            end

            // AUIPC instruction
            7'b0010111: begin
                RegWrite = 1;
                ALUSrc = 1;
            end

            // Unsupported instruction
            default: begin
                Illegal = 1;
            end

        endcase

    end

endmodule
