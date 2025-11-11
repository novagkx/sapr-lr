module apb_slave_v2 (
    input  logic        pclk,
    input  logic        presetn,
    input  logic [31:0] paddr,
    input  logic [31:0] pwdata,
    input  logic        psel,
    input  logic        penable,
    input  logic        pwrite,
    output logic        pready,
    output logic        pslverr,
    output logic [31:0] prdata
);

    // Внутренние регистры
    logic [31:0] ctrl_reg;      // управление (индекс аргумента sin)
    logic [31:0] sin_out_reg;   // результат sin(x)
    
    // Предрасчитанные значения sin(x)
    logic [31:0] sin_lut [0:7];

    initial begin
        sin_lut[0] = 32'h00000000; // 0.0000
        sin_lut[1] = 32'h00007071; // 0.7071
        sin_lut[2] = 32'h00010000; // 1.0000
        sin_lut[3] = 32'h00007071; // 0.7071
        sin_lut[4] = 32'h00000000; // 0.0000
        sin_lut[5] = 32'hFFFF8F8F; // -0.7071
        sin_lut[6] = 32'hFFFF0000; // -1.0000
        sin_lut[7] = 32'hFFFF8F8F; // -0.7071
    end

    // FSM
    enum logic [1:0] { APB_SETUP, APB_W_ENABLE, APB_R_ENABLE } apb_st;

    always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            ctrl_reg    <= 32'h0;
            sin_out_reg <= 32'h0;
            prdata      <= 32'h0;
            pready      <= 1'b0;
            pslverr     <= 1'b0;
            apb_st      <= APB_SETUP;
        end
        else begin
            case (apb_st)
                APB_SETUP: begin
                    pready  <= 1'b0;
                    pslverr <= 1'b0;
                    prdata  <= 32'h0;
                    if (psel && !penable) begin
                        apb_st <= pwrite ? APB_W_ENABLE : APB_R_ENABLE;
                    end
                end

                APB_W_ENABLE: begin
                    if (psel && penable && pwrite) begin
                        pready <= 1'b1;
                        case (paddr[7:0])
                            8'h10: begin
                                ctrl_reg <= pwdata;
                                if (pwdata[2:0] <= 7)
                                    sin_out_reg <= sin_lut[pwdata[2:0]];
                                else begin
                                    sin_out_reg <= 32'hDEAD_BEEF;
                                    pslverr <= 1'b1;
                                end
                            end
                            default: pslverr <= 1'b1;
                        endcase
                        apb_st <= APB_SETUP;
                    end
                end

                APB_R_ENABLE: begin
                    if (psel && penable && !pwrite) begin
                        pready <= 1'b1;
                        case (paddr[7:0])
                            8'h10: prdata <= ctrl_reg;
                            8'h14: prdata <= sin_out_reg;
                            default: pslverr <= 1'b1;
                        endcase
                        apb_st <= APB_SETUP;
                    end
                end

                default: begin
                    pslverr <= 1'b1;
                    apb_st  <= APB_SETUP;
                end
            endcase
        end
    end
endmodule
