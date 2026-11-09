
module data_memory #(
    parameter DEPTH = 1024
)(
    input wire clk,

    input wire mem_read,
    input wire mem_write,

    input wire [31:0] address,
    input wire [31:0] write_data,

    input wire [2:0] funct3,

    output reg [31:0] read_data
);

    // Byte-addressable memory
    reg [7:0] memory [0:DEPTH-1];

    // Use lower address bits for memory indexing
    wire [9:0] addr = address[9:0];

    // Memory write operation
    always @(posedge clk) begin

        if (mem_write) begin

            case (funct3)

                // SB: Store Byte
                3'b000: begin
                    memory[addr] <= write_data[7:0];
                end

                // SH: Store Halfword
                3'b001: begin
                    memory[addr]   <= write_data[7:0];
                    memory[addr+10'd1] <= write_data[15:8];
                end

                // SW: Store Word
                3'b010: begin
                    memory[addr]   <= write_data[7:0];
                    memory[addr+10'd1] <= write_data[15:8];
                    memory[addr+10'd2] <= write_data[23:16];
                    memory[addr+10'd3] <= write_data[31:24];
                end

                default: begin
                end

            endcase

        end

    end

    // Memory read operation
    always @(*) begin

        read_data = 32'b0;

        if (mem_read) begin

            case (funct3)

                // LB: Load Byte (signed)
                3'b000: begin
                    read_data = {
                        {24{memory[addr][7]}},
                        memory[addr]
                    };
                end

                // LH: Load Halfword (signed)
                3'b001: begin
                    read_data = {
                        {16{memory[addr+10'd1][7]}},
                        memory[addr+10'd1],
                        memory[addr]
                    };
                end

                // LW: Load Word
                3'b010: begin
                    read_data = {
                        memory[addr+10'd3],
                        memory[addr+10'd2],
                        memory[addr+10'd1],
                        memory[addr]
                    };
                end

                // LBU: Load Byte Unsigned
                3'b100: begin
                    read_data = {
                        24'b0,
                        memory[addr]
                    };
                end

                // LHU: Load Halfword Unsigned
                3'b101: begin
                    read_data = {
                        16'b0,
                        memory[addr+10'd1],
                        memory[addr]
                    };
                end

                default: begin
                    read_data = 32'b0;
                end

            endcase

        end

    end

endmodule
