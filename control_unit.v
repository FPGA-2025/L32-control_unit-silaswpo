module Control_Unit (
    input clk,
    input rst_n,
    input [6:0] instruction_opcode,
    output reg pc_write,
    output reg ir_write,
    output reg pc_source,
    output reg reg_write,
    output reg memory_read,
    output reg is_immediate,
    output reg memory_write,
    output reg pc_write_cond,
    output reg lorD,
    output reg memory_to_reg,
    output reg [1:0] aluop,
    output reg [1:0] alu_src_a,
    output reg [1:0] alu_src_b
);

    // Estados codificados manualmente
    parameter FETCH = 5'd0, DECODE = 5'd1, MEMADR = 5'd2, MEMREAD = 5'd3, MEMWB = 5'd4, 
              MEMWRITE = 5'd5, EXECUTER = 5'd6, ALUWB = 5'd7, BRANCH = 5'd8,
              ADDI_EXEC = 5'd9, ADDI_WB = 5'd10, LUI_EXEC = 5'd11, LUI_WB = 5'd12,
              JAL_EXEC = 5'd13, JALR_EXEC = 5'd14,
              AUIPC_EXEC = 5'd15, AUIPC_WB = 5'd16,
              JAL_WB = 5'd17, JALR_WB = 5'd18;

    parameter LW = 7'b0000011;
    parameter SW = 7'b0100011;
    parameter RTYPE = 7'b0110011;
    parameter ITYPE = 7'b0010011;
    parameter JALI = 7'b1101111;
    parameter BRANCHI = 7'b1100011;
    parameter JALRI = 7'b1100111;
    parameter AUIPCI = 7'b0010111;
    parameter LUII = 7'b0110111;

    reg [4:0] state, next_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= FETCH;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = FETCH;
        case (state)
            FETCH:    next_state = DECODE;
            DECODE: begin
                case (instruction_opcode)
                    LW:      next_state = MEMADR;
                    SW:      next_state = MEMADR;
                    RTYPE:   next_state = EXECUTER;
                    BRANCHI: next_state = BRANCH;
                    ITYPE:   next_state = ADDI_EXEC;
                    LUII:    next_state = LUI_EXEC;
                    JALI:    next_state = JAL_EXEC;
                    JALRI:   next_state = JALR_EXEC;
                    AUIPCI:  next_state = AUIPC_EXEC;
                    default: next_state = FETCH;
                endcase
            end
            MEMADR:     next_state = (instruction_opcode == LW) ? MEMREAD : MEMWRITE;
            MEMREAD:    next_state = MEMWB;
            MEMWB:      next_state = FETCH;
            MEMWRITE:   next_state = FETCH;
            EXECUTER:   next_state = ALUWB;
            ALUWB:      next_state = FETCH;
            BRANCH:     next_state = FETCH;
            ADDI_EXEC:  next_state = ADDI_WB;
            ADDI_WB:    next_state = FETCH;
            LUI_EXEC:   next_state = LUI_WB;
            LUI_WB:     next_state = FETCH;
            JAL_EXEC:   next_state = JAL_WB;
            JAL_WB:     next_state = FETCH;
            JALR_EXEC:  next_state = JALR_WB;
            JALR_WB:    next_state = FETCH;
            AUIPC_EXEC: next_state = AUIPC_WB;
            AUIPC_WB:   next_state = FETCH;
        endcase
    end

    always @(*) begin
        pc_write = 0;
        ir_write = 0;
        pc_source = 0;
        reg_write = 0;
        memory_read = 0;
        is_immediate = 0;
        memory_write = 0;
        pc_write_cond = 0;
        lorD = 0;
        memory_to_reg = 0;
        aluop = 0;
        alu_src_a = 0;
        alu_src_b = 0;

        case (state)
            FETCH: begin
                memory_read = 1;
                ir_write = 1;
                pc_write = 1;
                alu_src_a = 2'b00;
                alu_src_b = 2'b01;
                aluop = 2'b00;
                lorD = 0;
            end
            DECODE: begin
                alu_src_a = 2'b10;
                alu_src_b = 2'b10;
                aluop = 2'b00;
            end
            MEMADR: begin
                alu_src_a = 2'b01;
                alu_src_b = 2'b10;
                aluop = 2'b00;
            end
            MEMREAD: begin
                memory_read = 1;
                lorD = 1;
            end
            MEMWB: begin
                memory_to_reg = 1;
                reg_write = 1;
            end
            MEMWRITE: begin
                memory_write = 1;
                lorD = 1;
            end
            EXECUTER: begin
                alu_src_a = 2'b01;
                alu_src_b = 2'b00;
                aluop = 2'b10;
            end
            ALUWB: begin
                reg_write = 1;
                memory_to_reg = 0;
            end
            BRANCH: begin
                alu_src_a = 2'b01;
                alu_src_b = 2'b00;
                aluop = 2'b01;
                pc_write_cond = 1;
                pc_source = 1;
            end
            ADDI_EXEC: begin
                alu_src_a = 2'b01;
                alu_src_b = 2'b10;
                aluop = 2'b10;
                is_immediate = 1;
            end
            ADDI_WB: begin
                reg_write = 1;
                memory_to_reg = 0;
            end
            LUI_EXEC: begin
                alu_src_a = 2'b11;
                alu_src_b = 2'b10;
                aluop = 2'b00;
            end
            LUI_WB: begin
                reg_write = 1;
                memory_to_reg = 0;
            end
            JAL_EXEC: begin
            pc_write = 1;
            pc_source = 1;
            alu_src_a = 2'b10; // usar PC como entrada da ALU
            alu_src_b = 2'b01; // somar 4 (endereço de retorno)
            end
            JAL_WB: begin
                reg_write = 1;
                memory_to_reg = 0;
            end
            JALR_EXEC: begin
            alu_src_a = 2'b01;       // rs1
            alu_src_b = 2'b10;       // imediato
            aluop = 2'b00;
            is_immediate = 1;        // ← corrigido
            end
            JALR_WB: begin
            pc_write = 1;
            pc_source = 1;
            reg_write = 0;           // ← corrigido
            alu_src_a = 2'b10;
            alu_src_b = 2'b01;
            is_immediate = 0;
            end
            AUIPC_EXEC: begin
                alu_src_a = 2'b10;
                alu_src_b = 2'b10;
                aluop = 2'b00;
            end
            AUIPC_WB: begin
                reg_write = 1;
                memory_to_reg = 0;
            end
        endcase
    end
endmodule
