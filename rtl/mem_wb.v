
module mem_wb (

    input wire clk,
    input wire reset,
    input wire stall,
    input wire flush,

    // PC inputs
    input wire [31:0] pc_in,
    input wire [31:0] pc_plus4_in,

    // Data inputs
    input wire [31:0] alu_result_in,
    input wire [31:0] mem_read_data_in,

    // Destination register
    input wire [4:0] rd_in,

    // Control inputs
    input wire reg_write_in,
    input wire [1:0] result_src_in,

    // PC outputs
    output reg [31:0] pc_out,
    output reg [31:0] pc_plus4_out,

    // Data outputs
    output reg [31:0] alu_result_out,
    output reg [31:0] mem_read_data_out,

    // Destination register
    output reg [4:0] rd_out,

    // Control outputs
    output reg reg_write_out,
    output reg [1:0] result_src_out

);

    always @(posedge clk) begin

        // RESET
        if (reset) begin

            pc_out <= 0;
            pc_plus4_out <= 0;

            alu_result_out <= 0;
            mem_read_data_out <= 0;

            rd_out <= 0;

            reg_write_out <= 0;
            result_src_out <= 0;

        end

        // FLUSH
        else if (flush) begin

            pc_out <= 0;
            pc_plus4_out <= 0;

            alu_result_out <= 0;
            mem_read_data_out <= 0;

            rd_out <= 0;

            reg_write_out <= 0;
            result_src_out <= 0;

        end

        // STALL
        else if (stall) begin

            // Hold previous values

        end

        // NORMAL OPERATION
        else begin

            pc_out <= pc_in;
            pc_plus4_out <= pc_plus4_in;

            alu_result_out <= alu_result_in;
            mem_read_data_out <= mem_read_data_in;

            rd_out <= rd_in;

            reg_write_out <= reg_write_in;
            result_src_out <= result_src_in;

        end

    end

endmodule
