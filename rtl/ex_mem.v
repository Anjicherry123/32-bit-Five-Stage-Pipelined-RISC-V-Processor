
module ex_mem (

    input wire clk,
    input wire reset,
    input wire stall,
    input wire flush,

    // PC inputs
    input wire [31:0] pc_in,
    input wire [31:0] pc_plus4_in,

    // Execution results
    input wire [31:0] alu_result_in,
    input wire [31:0] write_data_in,

    // Destination register
    input wire [4:0] rd_in,

    // Function field
    input wire [2:0] funct3_in,

    // Control signals
    input wire reg_write_in,
    input wire mem_read_in,
    input wire mem_write_in,

    input wire [1:0] result_src_in,

    // PC outputs
    output reg [31:0] pc_out,
    output reg [31:0] pc_plus4_out,

    // Execution result outputs
    output reg [31:0] alu_result_out,
    output reg [31:0] write_data_out,

    // Destination register output
    output reg [4:0] rd_out,

    // Function field output
    output reg [2:0] funct3_out,

    // Control outputs
    output reg reg_write_out,
    output reg mem_read_out,
    output reg mem_write_out,

    output reg [1:0] result_src_out

);

always @(posedge clk) begin

    if (reset || flush) begin

        pc_out <= 0;
        pc_plus4_out <= 0;

        alu_result_out <= 0;
        write_data_out <= 0;

        rd_out <= 0;
        funct3_out <= 0;

        reg_write_out <= 0;
        mem_read_out <= 0;
        mem_write_out <= 0;

        result_src_out <= 0;

    end

    else if (stall) begin
        // Hold previous values
    end

    else begin

        pc_out <= pc_in;
        pc_plus4_out <= pc_plus4_in;

        alu_result_out <= alu_result_in;
        write_data_out <= write_data_in;

        rd_out <= rd_in;
        funct3_out <= funct3_in;

        reg_write_out <= reg_write_in;
        mem_read_out <= mem_read_in;
        mem_write_out <= mem_write_in;

        result_src_out <= result_src_in;

    end

end

endmodule
