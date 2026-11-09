module instruction_memory #(
    parameter DEPTH = 256,
    parameter INIT_FILE = ""
)(
    input  wire [31:0] address,
    output wire [31:0] instruction
);

    reg [31:0] memory [0:DEPTH-1];

    initial begin
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, memory);
    end

    assign instruction = (address[1:0] == 2'b00 &&
                          address[31:2] < DEPTH)
                         ? memory[address[31:2]]
                         : 32'h00000013;

endmodule