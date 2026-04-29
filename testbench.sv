module apb_slave_tb;

logic        PCLK;
logic        PRESETn;
logic        PSEL;
logic        PENABLE;
logic        PWRITE;
logic [7:0]  PADDR;
logic [31:0] PWDATA;
logic [31:0] PRDATA;
logic        PREADY;

apb_slave dut (
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    .PSEL(PSEL),
    .PENABLE(PENABLE),
    .PWRITE(PWRITE),
    .PADDR(PADDR),
    .PWDATA(PWDATA),
    .PRDATA(PRDATA),
    .PREADY(PREADY)
);

always #5 PCLK = ~PCLK;

task apb_write(input [7:0] addr, input [31:0] data);
begin
    @(posedge PCLK);
    PADDR  = addr;
    PWDATA = data;
    PWRITE = 1;
    PSEL   = 1;
    PENABLE = 0;

    @(posedge PCLK);
    PENABLE = 1;

    wait(PREADY == 1);

    @(posedge PCLK);
    PSEL = 0;
    PENABLE = 0;
    PWRITE = 0;

    $display("WRITE: Address=%0d Data=%h", addr, data);
end
endtask

task apb_read(input [7:0] addr, input [31:0] expected);
begin
    @(posedge PCLK);
    PADDR  = addr;
    PWRITE = 0;
    PSEL   = 1;
    PENABLE = 0;

    @(posedge PCLK);
    PENABLE = 1;

    wait(PREADY == 1);

    @(posedge PCLK);
    if (PRDATA == expected)
        $display("PASS READ: Address=%0d Data=%h", addr, PRDATA);
    else
        $display("FAIL READ: Address=%0d Expected=%h Got=%h", addr, expected, PRDATA);

    PSEL = 0;
    PENABLE = 0;
end
endtask

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, apb_slave_tb);

    PCLK = 0;
    PRESETn = 0;
    PSEL = 0;
    PENABLE = 0;
    PWRITE = 0;
    PADDR = 0;
    PWDATA = 0;

    #20 PRESETn = 1;

    apb_write(8'h10, 32'hA5A5A5A5);
    apb_read (8'h10, 32'hA5A5A5A5);

    apb_write(8'h20, 32'h12345678);
    apb_read (8'h20, 32'h12345678);

    apb_write(8'h30, 32'hDEADBEEF);
    apb_read (8'h30, 32'hDEADBEEF);

    $display("APB verification completed.");
    $finish;
end

endmodule
