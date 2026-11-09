
module writeback_unit (
    input  [31:0] alu_result,
    input  [31:0] mem_read_data,
    input  [31:0] pc_plus4,
    input  [1:0]  result_src,

    output reg [31:0] writeback_data
);

always @(*) begin

    case (result_src)

        2'b00: writeback_data = alu_result;

        2'b01: writeback_data = mem_read_data;

        2'b10: writeback_data = pc_plus4;

        default: writeback_data = 32'b0;

    endcase

end

endmodule
