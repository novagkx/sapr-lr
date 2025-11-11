`timescale 1ns/1ps
module tb_apb_v2;

    // APB signals
    reg         pclk;
    reg         presetn;
    reg         psel;
    reg         penable;
    reg         pwrite;
    reg  [31:0] paddr;
    reg  [31:0] pwdata;
    wire [31:0] prdata;
    wire        pready;
    wire        pslverr;

    // data variables
    integer i;
    reg [31:0] out;

    // Instantiate DUT
    apb_slave_v2 DUT (
        .pclk(pclk),
        .presetn(presetn),
        .paddr(paddr),
        .pwdata(pwdata),
        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .pready(pready),
        .pslverr(pslverr),
        .prdata(prdata)
    );

    // clock
    always #5 pclk = ~pclk;

    // write task - ИСПРАВЛЕННЫЙ
    task apb_write(input [31:0] addr, input [31:0] data);
    begin
        @(posedge pclk);
        psel <= 1;
        pwrite <= 1;
        paddr <= addr;
        pwdata <= data;
        penable <= 0;
        
        @(posedge pclk);
        penable <= 1;
        
        wait (pready);
        @(posedge pclk);
    end
    endtask

    // read task - ИСПРАВЛЕННЫЙ
    task apb_read(input [31:0] addr, output [31:0] data);
    begin
        @(posedge pclk);
        psel <= 1;
        pwrite <= 0;
        paddr <= addr;
        penable <= 0;
        
        @(posedge pclk);
        penable <= 1;
        
        wait (pready);
        @(posedge pclk); // Ждем дополнительный такт для стабилизации данных
        data = prdata;
        @(posedge pclk);
    end
    endtask

    // main stimulus - ИСПРАВЛЕННЫЙ
    initial begin
        // Initialize with non-blocking assignments
        pclk = 0;
        presetn = 0;
        psel <= 0;
        penable <= 0;
        pwrite <= 0;
        paddr <= 0;
        pwdata <= 0;
        out <= 0;
        
        // Reset sequence
        repeat (5) @(posedge pclk);
        presetn <= 1;
        repeat (3) @(posedge pclk);

        // Test all sin(pi/4 * i)
        for (i = 0; i < 8; i = i + 1) begin
            // Write index to control register
            apb_write(32'h10, i);
            
            // Clear signals between transactions
            psel <= 0;
            penable <= 0;
            pwrite <= 0;
            repeat (2) @(posedge pclk);
            
            // Read result from output register
            apb_read(32'h14, out);
            
            // Clear signals between transactions
            psel <= 0;
            penable <= 0;
            pwrite <= 0;
            
            $display("[TB] sin(pi/4*%0d) = 0x%h", i, out);
            repeat (2) @(posedge pclk);
        end

        repeat (5) @(posedge pclk);
        $display("Simulation finished.");
        $stop;
    end

endmodule