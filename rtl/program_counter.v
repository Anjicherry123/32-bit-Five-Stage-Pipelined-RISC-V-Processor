
module program_counter (

    input wire clk,
    input wire reset,
    input wire stall,
    input wire pc_src,

    input wire [31:0] pc_target,

    output reg [31:0] pc

);

always @(posedge clk) begin

    if (reset) begin

        pc <= 32'h00000000;

    end

    // Branch or jump redirect has priority
    else if (pc_src) begin

        pc <= pc_target;

    end

    // Hold PC during load-use stall
    else if (stall) begin

        pc <= pc;

    end

    // Sequential execution
    else begin

        pc <= pc + 32'd4;

    end

end

endmodule
