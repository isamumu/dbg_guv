`timescale 1ns / 1ps

`include "axis_governor.v"

module dbg_guv # (
    // will move this to dbg_guv module later
    parameter DATA_WIDTH = 64,
    parameter DEST_WIDTH = 16, 
    parameter ID_WIDTH = 16
) (
    input clk,
    input rst,
    input wire [31:0] cmd_in_TDATA,
    input wire cmd_in_TVALID,
    output wire cmd_in_TREADY,

    //Input AXI Stream rdata.
    input wire [DATA_WIDTH-1:0] din_TDATA_rdata,
    input wire [DEST_WIDTH -1:0] din_TDEST_rdata,
    input wire din_TVALID_rdata,
    output wire din_TREADY_rdata,

    //Input AXI Stream wdata.
    output wire [DATA_WIDTH-1:0] din_TDATA_wdata,
    output wire din_TVALID_wdata,
    input wire din_TREADY_wdata,

    //Input AXI Stream raddr.
    output wire [DATA_WIDTH-1:0] din_TDATA_raddr,
    output wire din_TVALID_raddr,
    input wire din_TREADY_raddr,

    //Input AXI Stream awaddr.
    output wire [DATA_WIDTH-1:0] din_TDATA_awaddr,
    output wire din_TVALID_awaddr,
    input wire din_TREADY_awaddr,

    //Input AXI Stream resp.
    input wire [DATA_WIDTH-1:0] din_TDATA_resp,
    input wire din_TVALID_resp,
    output wire din_TREADY_resp,

    /////////////////////////////////////////////////////////////////////////////////

    //Output AXI Stream rdata.
    output wire [DATA_WIDTH-1:0] dout_TDATA_rdata,
    output wire [DEST_WIDTH -1:0] dout_TDEST_rdata,
    output wire dout_TVALID_rdata,
    input wire dout_TREADY_rdata,

    //Output AXI Stream wdata.
    input wire [DATA_WIDTH-1:0] dout_TDATA_wdata,
    input wire dout_TVALID_wdata,
    output wire dout_TREADY_wdata,

    //Output AXI Stream raddr.
    input wire [DATA_WIDTH-1:0] dout_TDATA_raddr,
    input wire dout_TVALID_raddr,
    output wire dout_TREADY_raddr,

    //Output AXI Stream awaddr.
    input wire [DATA_WIDTH-1:0] dout_TDATA_awaddr,
    input wire dout_TVALID_awaddr,
    output wire dout_TREADY_awaddr,

    //Output AXI Stream resp.
    output wire [DATA_WIDTH-1:0] dout_TDATA_resp,
    output wire dout_TVALID_resp,
    input wire dout_TREADY_resp

);

    // CONTROLPATH signals 
    wire done_START;
    wire done_DROP;
    wire done_INJECT; 
    wire done_WAIT;
    wire done_LOG;
    wire done_PAUSE; 
    wire done_DONE_DROP; 
    wire done_DONE_LOG; 
    wire done_DONE_INJECT; 
    wire done_DONE_PAUSE;

    wire [9:0] curr_state;
    wire master_inject_enable_resp;
    wire master_inject_enable_rdata;
    wire master_drop_enable_rdata;
    wire master_drop_enable_wdata;

    wire [9:0] state_next_o; 

    logic [26:0] data = 0;
    wire [28:0] data_in_o;


    control_FSM U2(
        clk,
        rst,
        // axi stream
        cmd_in_TDATA,
        cmd_in_TVALID,
        cmd_in_TREADY,

        done_START, 
        done_DROP, 
        done_INJECT, 
        done_WAIT, 
        done_LOG, 
        done_PAUSE, 
        done_DONE_DROP, 
        done_DONE_LOG, 
        done_DONE_INJECT, 
        done_DONE_PAUSE,
        curr_state,
        master_inject_enable_resp,
        master_inject_enable_rdata,
        master_drop_enable_rdata,
        master_drop_enable_wdata
    );

    // init module
    datapath U1 (
        clk,
        rst,
        curr_state,
        master_inject_enable_resp,
        master_inject_enable_rdata,
        master_drop_enable_rdata,
        master_drop_enable_wdata,

        //Input command stream
        cmd_in_TDATA,

        //Input AXI Stream rdata.
        din_TDATA_rdata,
        din_TDEST_rdata,
        din_TVALID_rdata,
        din_TREADY_rdata,

        //Input AXI Stream wdata.
        din_TDATA_wdata,
        din_TVALID_wdata,
        din_TREADY_wdata,

        //Input AXI Stream raddr.
        din_TDATA_raddr,
        din_TVALID_raddr,
        din_TREADY_raddr,

        //Input AXI Stream awaddr.
        din_TDATA_awaddr,
        din_TVALID_awaddr,
        din_TREADY_awaddr,

        //Input AXI Stream resp.
        din_TDATA_resp,
        din_TVALID_resp,
        din_TREADY_resp,
        
        //Output AXI Stream rdata.
        dout_TDATA_rdata,
        dout_TDEST_rdata,
        dout_TVALID_rdata,
        dout_TREADY_rdata,

        //Output AXI Stream wdata.
        dout_TDATA_wdata,
        dout_TVALID_wdata,
        dout_TREADY_wdata,

        //Output AXI Stream raddr.
        dout_TDATA_raddr,
        dout_TVALID_raddr,
        dout_TREADY_raddr,

        //Output AXI Stream awaddr.
        dout_TDATA_awaddr,
        dout_TVALID_awaddr,
        dout_TREADY_awaddr,

        //Output AXI Stream resp.
        dout_TDATA_resp,
        dout_TVALID_resp,
        dout_TREADY_resp,

        // Done signals
        done_START,
        done_DROP,
        done_INJECT,
        done_WAIT,
        done_LOG,
        done_PAUSE,
        done_DONE_DROP,
        done_DONE_LOG,
        done_DONE_INJECT,
        done_DONE_PAUSE
    );

endmodule