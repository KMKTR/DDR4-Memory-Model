module dfi_interface;
    wire dfi_ras_n;         //row address strobe negative signal
    wire dfi_cas_n;         //column address strobe
    wire dfi_we_n;          //write enable
    wire [31:0]dfi_addr;    //address bus
    wire dfi_clk;           //clock enable
    wire dfi_cs_n;          //chip selection
    wire dfi_wrdata_mask;   //data mask of write data
    wire [7:0]dfi_wrdata;   //write data
endmodule
