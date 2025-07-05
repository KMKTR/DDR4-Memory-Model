`include "mem_controller.sv"
`include "dfiinterface.sv"
`include "ddr4rtl.sv"

module ddr4_top(
    input clk,
    input reset,
    input write_en,
    input read_en,
    input clk_enable,
    input [31:0]address,
    input [7:0]data_in,
    output[7:0]ddr4_dq );
    
    wire cs_n;
    wire ras_n;
    wire cas_n;
    wire we_n;
    wire cke;
    wire wrdata_mask;
    wire [31:0]addr;
    wire [7:0]data_out;

mem_controller M1(.clk(clk), .reset(reset), .write_en(write_en), .read_en(read_en), .address(address), .clk_enable(clk_enable), .data_in(data_in), .addr(addr), .cs_n(cs_n), .ras_n(ras_n), .cas_n(cas_n), .we_n(we_n), .cke(cke), .data_out(data_out), .wrdata_mask(wrdata_mask), .ready(M3.ddr4_ready));

dfi_interface M2();
    assign M2.dfi_addr        = addr;
    assign M2.dfi_cs_n        = cs_n;
    assign M2.dfi_ras_n       = ras_n;
    assign M2.dfi_cas_n       = cas_n;
    assign M2.dfi_we_n        = we_n;
    assign M2.dfi_cke         = cke;
    assign M2.dfi_wrdata_mask = wrdata_mask;
    assign M2.dfi_wrdata      = data_out;

ddr4_rtl M3();
    assign M3.ddr4_reset_n    = reset;
    assign M3.ddr4_cas_n      = cas_n;
    assign M3.ddr4_ras_n      = ras_n;
    assign M3.ddr4_cs_n       = cs_n;
    assign M3.ddr4_addr       = addr;
    assign M3.ddr4_we_n       = we_n;
    assign M3.ddr4_dm         = wrdata_mask;
    assign M3.ddr4_cke        = cke;
    assign M3.ddr4_ckt        = (cke==1)?clk:1'b0;
    assign M3.ddr4_ckc        = (cke==1)?clk:1'b0;
    assign M3.ddr4_dq         = wrdata;
    
    assign M3.ddr4_dq  = (wrdata_mask==0) ? M3.ddr4_dq:8'hzzz

endmodule
