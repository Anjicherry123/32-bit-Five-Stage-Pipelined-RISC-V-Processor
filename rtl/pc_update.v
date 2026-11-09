
module pc_update (
    input  [31:0] pc_current,
    input  [31:0] immediate,
    input  [31:0] rs1_data,

    input         branch_taken,
    input         jump,
    input         jalr,

    output reg [31:0] pc_next
);

always @(*) begin

    // Default: Next sequential instruction
    pc_next = pc_current + 32'd4;

    // Branch instruction
    if (branch_taken) begin
        pc_next = pc_current + immediate;
    end

    // JAL instruction
    if (jump && !jalr) begin
        pc_next = pc_current + immediate;
    end

    // JALR instruction
    if (jump && jalr) begin
        pc_next = (rs1_data + immediate) & 32'hFFFFFFFE;
    end

end

endmodule
