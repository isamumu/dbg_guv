`timescale 1ns / 1ps

`include "axis_governor.v"
`include "dbg_guv_width_adapter.v"
`include "tkeep_to_len.v"


`define SAFE_ID_WIDTH (ID_WIDTH < 1 ? 1 : ID_WIDTH)
`define SAFE_DEST_WIDTH (DEST_WIDTH < 1 ? 1 : DEST_WIDTH)

module datapath # (
    // will move this to dbg_guv module later
    parameter DATA_WIDTH = 64,
    parameter DEST_WIDTH = 16, 
    parameter ID_WIDTH = 16
) (
    input logic clk,
    input logic rst,
    input [9:0] state_current,
    input wire master_inject_enable_resp,
    input wire master_inject_enable_rdata,
    input wire master_drop_enable_rdata,
    input wire master_drop_enable_wdata,

    //Input command stream
    input wire [28:0] cmd_in_TDATA,

    //Input AXI Stream rdata.
    input wire [DATA_WIDTH-1:0] din_TDATA_rdata,
    input wire din_TLAST_rdata,
    input wire [DATA_WIDTH/8-1:0] din_TKEEP_rdata,
    input wire [DEST_WIDTH -1:0] din_TDEST_rdata,
    input wire [ID_WIDTH -1:0] din_TID_rdata,
    input wire din_TVALID_rdata,
    input wire din_TREADY_rdata,

    //Input AXI Stream wdata.
    input wire [DATA_WIDTH-1:0] din_TDATA_wdata,
    input wire din_TLAST_wdata,
    input wire [DATA_WIDTH/8-1:0] din_TKEEP_wdata,
    input wire [DEST_WIDTH -1:0] din_TDEST_wdata,
    input wire [ID_WIDTH -1:0] din_TID_wdata,
    input wire din_TVALID_wdata,
    input wire din_TREADY_wdata,

    //Input AXI Stream raddr.
    input wire [DATA_WIDTH-1:0] din_TDATA_raddr,
    input wire din_TLAST_raddr,
    input wire [DATA_WIDTH/8-1:0] din_TKEEP_raddr,
    input wire [DEST_WIDTH -1:0] din_TDEST_raddr,
    input wire [ID_WIDTH -1:0] din_TID_raddr,
    input wire din_TVALID_raddr,
    input wire din_TREADY_raddr,

    //Input AXI Stream awaddr.
    input wire [DATA_WIDTH-1:0] din_TDATA_awaddr,
    input wire din_TLAST_awaddr,
    input wire [DATA_WIDTH/8-1:0] din_TKEEP_awaddr,
    input wire [DEST_WIDTH -1:0] din_TDEST_awaddr,
    input wire [ID_WIDTH -1:0] din_TID_awaddr,
    input wire din_TVALID_awaddr,
    input wire din_TREADY_awaddr,

    //Input AXI Stream resp.
    input wire [DATA_WIDTH-1:0] din_TDATA_resp,
    input wire din_TLAST_resp,
    input wire [DATA_WIDTH/8-1:0] din_TKEEP_resp,
    input wire [DEST_WIDTH -1:0] din_TDEST_resp,
    input wire [ID_WIDTH -1:0] din_TID_resp,
    input wire din_TVALID_resp,
    input wire din_TREADY_resp,
    
    //Output AXI Stream rdata.
    output wire [DATA_WIDTH-1:0] dout_TDATA_rdata,
    output wire [DATA_WIDTH/8-1:0]dout_TKEEP_rdata,
    output wire [DEST_WIDTH -1:0] dout_TDEST_rdata,
    output wire [ID_WIDTH -1:0] dout_TID_rdata,
    output wire dout_TVALID_rdata,
    output wire dout_TREADY_rdata,

    //Output AXI Stream wdata.
    output wire [DATA_WIDTH-1:0] dout_TDATA_wdata,
    output wire [DATA_WIDTH/8-1:0]dout_TKEEP_wdata,
    output wire [DEST_WIDTH -1:0] dout_TDEST_wdata,
    output wire [ID_WIDTH -1:0] dout_TID_wdata,
    output wire dout_TVALID_wdata,
    output wire dout_TREADY_wdata,

    //Output AXI Stream raddr.
    output wire [DATA_WIDTH-1:0] dout_TDATA_raddr,
    output wire [DATA_WIDTH/8-1:0]dout_TKEEP_raddr,
    output wire [DEST_WIDTH -1:0] dout_TDEST_raddr,
    output wire [ID_WIDTH -1:0] dout_TID_raddr,
    output wire dout_TVALID_raddr,
    output wire dout_TREADY_raddr,

    //Output AXI Stream awaddr.
    output wire [DATA_WIDTH-1:0] dout_TDATA_awaddr,
    output wire [DATA_WIDTH/8-1:0]dout_TKEEP_awaddr,
    output wire [DEST_WIDTH -1:0] dout_TDEST_awaddr,
    output wire [ID_WIDTH -1:0] dout_TID_awaddr,
    output wire dout_TVALID_awaddr,
    output wire dout_TREADY_awaddr,

    //Output AXI Stream resp.
    output wire [DATA_WIDTH-1:0] dout_TDATA_resp,
    output wire [DATA_WIDTH/8-1:0]dout_TKEEP_resp,
    output wire [DEST_WIDTH -1:0] dout_TDEST_resp,
    output wire [ID_WIDTH -1:0] dout_TID_resp,
    output wire dout_TVALID_resp,
    output wire dout_TREADY_resp,

    // Done signals
    output wire w_done_START,
    output wire w_done_DROP,
    output wire w_done_INJECT,
    output wire w_done_WAIT,
    output wire w_done_LOG,
    output wire w_done_PAUSE,
    output wire w_done_DONE_DROP,
    output wire w_done_DONE_LOG,
    output wire w_done_DONE_INJECT,
    output wire w_done_DONE_PAUSE
    
);   

    /////////////////////////////
    //axis governor connections//
    /////////////////////////////
    // rdata
    wire [DATA_WIDTH-1:0] log_TDATA_rdata;
    wire log_TLAST_rdata;
    wire [DATA_WIDTH/8 -1:0] log_TKEEP_rdata;
    wire [DEST_WIDTH -1:0] log_TDEST_rdata;
    wire [ID_WIDTH -1:0] log_TID_rdata;
    wire log_TREADY_rdata; 
    wire log_TVALID_rdata;
    wire inj_TVALID_rdata;
    wire inj_TREADY_rdata;
    
    logic [DATA_WIDTH -1:0] inj_TDATA_rdata = 0; 
    logic inj_TLAST_rdata = 0; 
    logic [DATA_WIDTH/8 -1:0] inj_TKEEP_rdata = 0;
    logic [DEST_WIDTH -1:0] inj_TDEST_rdata = 0;
    logic [ID_WIDTH -1:0] inj_TID_rdata = 0;

    // wdata
    wire [DATA_WIDTH-1:0] log_TDATA_wdata;
    wire log_TLAST_wdata;
    wire [DATA_WIDTH/8 -1:0] log_TKEEP_wdata;
    wire [DEST_WIDTH -1:0] log_TDEST_wdata;
    wire [ID_WIDTH -1:0] log_TID_wdata;
    wire log_TREADY_wdata;
    wire log_TVALID_wdata;
    wire inj_TVALID_wdata;
    wire inj_TREADY_wdata;
    
    logic [DATA_WIDTH -1:0] inj_TDATA_wdata = 0; 
    logic inj_TLAST_wdata = 0; 
    logic [DATA_WIDTH/8 -1:0] inj_TKEEP_wdata = 0;
    logic [DEST_WIDTH -1:0] inj_TDEST_wdata = 0;
    logic [ID_WIDTH -1:0] inj_TID_wdata = 0;

    // raddr
    wire [DATA_WIDTH-1:0] log_TDATA_raddr;
    wire log_TLAST_raddr;
    wire [DATA_WIDTH/8 -1:0] log_TKEEP_raddr;
    wire [DEST_WIDTH -1:0] log_TDEST_raddr;
    wire [ID_WIDTH -1:0] log_TID_raddr;
    wire log_TREADY_raddr;
    wire log_TVALID_raddr;
    wire inj_TVALID_raddr;
    wire inj_TREADY_raddr;
    
    logic [DATA_WIDTH -1:0] inj_TDATA_raddr = 0; 
    logic inj_TLAST_raddr = 0; 
    logic [DATA_WIDTH/8 -1:0] inj_TKEEP_raddr = 0;
    logic [DEST_WIDTH -1:0] inj_TDEST_raddr = 0;
    logic [ID_WIDTH -1:0] inj_TID_raddr = 0;

    // waddr
    wire [DATA_WIDTH-1:0] log_TDATA_awaddr;
    wire log_TLAST_waddr;
    wire [DATA_WIDTH/8 -1:0] log_TKEEP_awaddr;
    wire [DEST_WIDTH -1:0] log_TDEST_awaddr;
    wire [ID_WIDTH -1:0] log_TID_awaddr;
    wire log_TREADY_waddr;
    wire log_TVALID_waddr;
    wire inj_TVALID_waddr;
    wire inj_TREADY_waddr;
    
    logic [DATA_WIDTH -1:0] inj_TDATA_awaddr = 0; 
    logic inj_TLAST_waddr = 0; 
    logic [DATA_WIDTH/8 -1:0] inj_TKEEP_awaddr = 0;
    logic [DEST_WIDTH -1:0] inj_TDEST_awaddr = 0;
    logic [ID_WIDTH -1:0] inj_TID_awaddr = 0;

    // resp
    wire [DATA_WIDTH-1:0] log_TDATA_resp;
    wire log_TLAST_resp;
    wire [DATA_WIDTH/8-1:0] log_TKEEP_resp;
    wire [DEST_WIDTH -1:0] log_TDEST_resp;
    wire [ID_WIDTH -1:0] log_TID_resp;
    wire log_TREADY_resp;
    wire log_TVALID_resp;
    wire inj_TVALID_resp;
    wire inj_TREADY_resp;
    
    logic [DATA_WIDTH -1:0] inj_TDATA_resp = 0; 
    logic inj_TLAST_resp = 0; 
    logic [DATA_WIDTH/8-1:0] inj_TKEEP_resp = 0;
    logic [DEST_WIDTH -1:0] inj_TDEST_resp = 0;
    logic [ID_WIDTH -1:0] inj_TID_resp = 0;

    /////////////////////////////
    //assert operation signals //
    /////////////////////////////
    wire pause; // will replace later with rdata subnames
    wire drop;
    wire log_en;
    
    wire pause_wdata;
    wire drop_wdata;
    wire log_en_wdata;
   
    wire pause_rdata; 
    wire drop_rdata;
    wire log_en_rdata;

    wire pause_raddr; 
    wire drop_raddr;
    wire log_en_raddr;

    wire pause_awaddr; 
    wire drop_awaddr;
    wire log_en_awaddr;

    wire pause_resp; 
    wire drop_resp;
    wire log_en_resp;

    ////////////////
    //HELPER WIRES//
    ////////////////
    wire inj_success_rdata;
    wire inj_success_wdata;
    //wire inj_success_raddr;
    //wire inj_success_awaddr;
    wire inj_success_resp;

    // only inject values when this is true (!inj_failed || inj_TVALID_r == 0)
    wire [DEST_WIDTH -1:0] dout_TDEST_internal_rdata;
    wire [ID_WIDTH -1:0] dout_TID_internal_rdata;

    wire [DEST_WIDTH -1:0] dout_TDEST_internal_wdata;
    wire [ID_WIDTH -1:0] dout_TID_internal_wdata;
    wire [DEST_WIDTH -1:0] dout_TDEST_internal_raddr;
    wire [ID_WIDTH -1:0] dout_TID_internal_raddr;
    wire [DEST_WIDTH -1:0] dout_TDEST_internal_awaddr;
    wire [ID_WIDTH -1:0] dout_TID_internal_awaddr;
    wire [DEST_WIDTH -1:0] dout_TDEST_internal_resp;
    wire [ID_WIDTH -1:0] dout_TID_internal_resp;
    
    ///////////////////////////////////////////////////////////////////
    //Also need to treat situations when TLAST or TKEEP are not given//
    ///////////////////////////////////////////////////////////////////
    localparam KEEP_WIDTH = DATA_WIDTH/8 -1;
    wire [KEEP_WIDTH:0] din_TKEEP_internal_rdata;
    wire [KEEP_WIDTH:0] din_TKEEP_internal_raddr;
    wire [KEEP_WIDTH:0] din_TKEEP_internal_wdata;
    wire [KEEP_WIDTH:0] din_TKEEP_internal_awaddr;
    wire [KEEP_WIDTH:0] din_TKEEP_internal_resp;

    //assign din_TKEEP_internal = {KEEP_WIDTH{1'b1}};
    wire din_TLAST_internal_rdata;
    wire din_TLAST_internal_raddr;
    wire din_TLAST_internal_wdata;
    wire din_TLAST_internal_awaddr;
    wire din_TLAST_internal_resp;
    
    /////////////////
    //reg variables//
    /////////////////
    logic inj_TVALID_r = 0; 
    logic log_TREADY_r = 0;

    logic pause_enable_rdata = 0; 
    logic log_enable_rdata = 0;
    logic drop_enable_rdata = 0;
    logic inject_enable_rdata = 0;

    logic pause_enable_wdata = 0; 
    logic log_enable_wdata = 0;
    logic drop_enable_wdata = 0;
    logic inject_enable_wdata = 0;

    logic pause_enable_raddr = 0; 
    logic log_enable_raddr = 0;
    logic drop_enable_raddr = 0;
    logic inject_enable_raddr = 0;

    logic pause_enable_awaddr = 0; 
    logic log_enable_awaddr = 0;
    logic drop_enable_awaddr = 0;
    logic inject_enable_awaddr = 0;

    logic pause_enable_resp = 0; 
    logic log_enable_resp = 0;
    logic drop_enable_resp = 0;
    logic inject_enable_resp = 0;

    //logic TDATA_r = cmd_in_TDATA;
    logic [15:0] data_r = 0;
    logic [5:0] command_r = 0;
    logic [9:0] state = 0;

    logic done_START = 0;
    logic done_DROP = 0;
    logic done_INJECT = 0;
    logic done_WAIT = 0;
    logic done_LOG = 0;
    logic done_PAUSE = 0;
    logic done_DONE_DROP = 0;
    logic done_DONE_LOG = 0;
    logic done_DONE_INJECT = 0;
    logic done_DONE_PAUSE = 0;

    // rdata assignments
    assign dout_TDEST_rdata = dout_TDEST_internal_rdata;
    assign inj_success_rdata = inj_TVALID_rdata && inj_TREADY_rdata; //NOTE NOT !inj_TREADY_rdata
    assign dout_TID_rdata = dout_TID_internal_rdata;
    assign din_TLAST_internal_rdata = din_TLAST_rdata;
    assign din_TKEEP_internal_rdata = din_TKEEP_rdata;

    // wdata assignments
    assign dout_TDEST_wdata = dout_TDEST_internal_wdata;
    assign inj_success_wdata = inj_TVALID_wdata && inj_TREADY_wdata;
    assign dout_TID_wdata = dout_TID_internal_wdata;
    assign din_TLAST_internal_wdata = din_TLAST_wdata;
    assign din_TKEEP_internal_wdata = din_TKEEP_wdata;

    // raddr assignments
    assign dout_TDEST_raddr = dout_TDEST_internal_raddr;
    ////assign inj_success_raddr = inj_TVALID_raddr && !inj_TREADY_raddr; // not used
    assign dout_TID_raddr = dout_TID_internal_raddr;
    assign din_TLAST_internal_raddr = din_TLAST_raddr;
    assign din_TKEEP_internal_raddr = din_TKEEP_raddr;

    // awaddr assignments
    assign dout_TDEST_awaddr = dout_TDEST_internal_awaddr;    
    ////assign inj_success_awaddr = inj_TVALID_awaddr && !inj_TREADY_awaddr; // not used
    assign dout_TID_awaddr = dout_TID_internal_awaddr;
    assign din_TLAST_internal_awaddr = din_TLAST_awaddr;
    assign din_TKEEP_internal_awaddr = din_TKEEP_awaddr;

    // rdata assignments
    assign dout_TDEST_resp = dout_TDEST_internal_resp;
    assign inj_success_resp = inj_TVALID_resp && inj_TREADY_resp;
    assign dout_TID_resp = dout_TID_internal_resp;
    assign din_TLAST_internal_resp = din_TLAST_resp;
    assign din_TKEEP_internal_resp = din_TKEEP_resp;

    // assign TREADY values (we reuse the log_TREADY register)
    assign log_TREADY_rdata = log_TREADY_r;
    assign log_TREADY_wdata = log_TREADY_r;
    assign log_TREADY_raddr = log_TREADY_r;
    assign log_TREADY_awaddr = log_TREADY_r;
    assign log_TREADY_resp = log_TREADY_r;

    // pause, log, drop, and inject for rdata
    assign pause_rdata = pause_enable_rdata;
    assign drop_rdata = drop_enable_rdata;
    assign log_en_rdata = log_enable_rdata;

    // pause, log, drop, and inject for wdata
    assign pause_wdata = pause_enable_wdata;
    assign drop_wdata = drop_enable_wdata;
    assign log_en_wdata = log_enable_wdata;

    // pause, log, drop, and inject for araddr
    assign pause_raddr = pause_enable_raddr;
    assign drop_raddr = drop_enable_raddr;
    assign log_en_raddr = log_enable_raddr;

    // pause, log, drop, and inject for awaddr
    assign pause_awaddr = pause_enable_awaddr;
    assign drop_awaddr = drop_enable_awaddr;
    assign log_en_awaddr = log_enable_awaddr;

    // pause, log, drop, and inject for resp
    assign pause_resp = pause_enable_resp;
    assign drop_resp = drop_enable_resp;
    assign log_en_resp = log_enable_resp;

    // inj_TVALID signals
    assign inj_TVALID_rdata = inj_TVALID_r;
    assign inj_TVALID_wdata = inj_TVALID_r;
    assign inj_TVALID_raddr = inj_TVALID_r;
    assign inj_TVALID_awaddr = inj_TVALID_r;
    assign inj_TVALID_resp = inj_TVALID_r;

    ///////////////////////////////////////////////
    ///////////   INITIALIZE SIGNALS   ////////////
    ///////////////////////////////////////////////

    assign w_done_START = done_START;
    assign w_done_DROP = done_DROP;
    assign w_done_INJECT = done_INJECT;
    assign w_done_WAIT = done_WAIT;
    assign w_done_LOG = done_LOG;
    assign w_done_PAUSE = done_PAUSE;
    assign w_done_DONE_DROP = done_DONE_DROP;
    assign w_done_DONE_LOG = done_DONE_LOG;
    assign w_done_DONE_INJECT = done_DONE_INJECT;
    assign w_done_DONE_PAUSE = done_DONE_PAUSE;

    localparam START = 6'd0;
    localparam DROP = 6'd1; 
    localparam INJECT = 6'd2; 
    localparam WAIT = 6'd3;
    localparam LOG = 6'd4;
    localparam PAUSE = 6'd5;
    localparam DONE_DROP = 6'd6;
    localparam DONE_LOG = 6'd7;
    localparam DONE_INJECT = 6'd8;
    localparam DONE_PAUSE = 6'd9;
                
    // depend on the control path to bring us to the DONE state
 

    //////// Available functions/operations /////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////
    ///////  pause: rdata (0), wdata (1)                                     ////////
    ///////  drop: rdata (2), wdata (3)                                      ////////
    ///////  inject: rdata (4), wdata (5), resp(11)                          ////////
    ///////  log: rdata (6), wdata (7), raddress (8), waddress (9), resp(10) ////////
    /////////////////////////////////////////////////////////////////////////////////
     
    ///////////// OP CODE VISUAL ////////////////
    /////////////////////////////////////////////
    //// ################ || %%%%%%%%%%%% || $ ////
    /////////////////////////////////////////////

    // OP code: 16bits for data (#), 12bits for operation (%), 1bit for enable/disable for continuous operation ($)

    always @(posedge clk) begin

        if(rst) begin 
            // rdata
            pause_enable_rdata = 0; 
            log_enable_rdata = 0;
            drop_enable_rdata = 0;
            inject_enable_rdata = 0;

            // wdata
            pause_enable_wdata = 0; 
            log_enable_wdata = 0;
            drop_enable_wdata = 0;
            inject_enable_wdata = 0;

            // raddr
            pause_enable_raddr = 0; 
            log_enable_raddr = 0;
            drop_enable_raddr = 0;

            // awaddr
            pause_enable_awaddr = 0; 
            log_enable_awaddr = 0;
            drop_enable_awaddr = 0;

            // resp
            pause_enable_resp = 0; // will not use
            log_enable_resp = 0;
            drop_enable_resp = 0; // will not use
            inject_enable_resp = 0;

            // done signals
            done_START = 0;
            done_DROP = 0;
            done_INJECT = 0;
            done_WAIT = 0;
            done_LOG = 0;
            done_PAUSE = 0;
            done_DONE_DROP = 0;
            done_DONE_LOG = 0;
            done_DONE_INJECT = 0;
            done_DONE_PAUSE = 0;

            inj_TVALID_r = 0;
            log_TREADY_r = 0;
            data_r = 0;
        // note to self: might have to check for valid streams here
        end else begin
            // update current state
            state = state_current;
            
            // reset done signals back to 0
            done_START = 0;
            done_DROP = 0;
            done_INJECT = 0;
            done_WAIT = 0;
            done_LOG = 0;
            done_PAUSE = 0;
            done_DONE_DROP = 0;
            done_DONE_LOG = 0;
            done_DONE_INJECT = 0;
            done_DONE_PAUSE = 0;

            // double check blocking and non blocking for sv
            // As of 7/24 three states might suffice
            case (state)
                START: begin
                    // select the states with the controlpath
                    done_START = 1;
                    // in the control we need to check the command to determine the next state 
                end

                DROP: begin
                    if(cmd_in_TDATA[3] == 1 || master_drop_enable_rdata) 
                        drop_enable_rdata = 1; //this should automatically assign to the wire

                    else if(cmd_in_TDATA[4] == 1 || master_drop_enable_wdata) 
                        drop_enable_wdata = 1;

                    done_DROP = 1;
                end

                INJECT: begin

                    // extract data information
                    data_r = cmd_in_TDATA[28:12];

                    if(cmd_in_TDATA[5] || master_inject_enable_rdata) begin
                        inject_enable_rdata = 1;
                        inj_TVALID_r = 1;
                        inj_TDATA_rdata = data_r; // use side channels?
                    end

                    else if(cmd_in_TDATA[6]) begin // NOTE: i don't think we inject to write although we can
                        inject_enable_wdata = 1;
                        inj_TVALID_r = 1;
                        inj_TDATA_wdata = data_r; // use side channels?
                    end

                    else if(cmd_in_TDATA[12] || master_inject_enable_resp) begin
                        inject_enable_resp = 1;
                        inj_TVALID_r = 1;
                        inj_TDATA_resp = data_r; // use side channels?
                    end

                    done_INJECT = 1;
                end

                WAIT: begin
                
                    // wait for the handshake, only send out the done signal when we have the handshake
                    if(cmd_in_TDATA[7]) 
                        done_WAIT = log_enable_rdata && log_TREADY_rdata;

                    else if(cmd_in_TDATA[8]) 
                        done_WAIT = log_enable_wdata && log_TREADY_wdata;
                        
                    else if(cmd_in_TDATA[9]) 
                        done_WAIT = log_enable_raddr && log_TREADY_raddr;
                    
                    else if(cmd_in_TDATA[10]) 
                        done_WAIT = log_enable_awaddr && log_TREADY_awaddr;
                        
                    else if(cmd_in_TDATA[5] || master_inject_enable_rdata) 
                        done_WAIT = inj_success_rdata;

                    else if(cmd_in_TDATA[6]) 
                        done_WAIT = inj_success_wdata;

                    else if(cmd_in_TDATA[12] || master_inject_enable_resp) 
                        done_WAIT = inj_success_resp;
                    else
                        done_WAIT = 0;
                    // NOTE: i don't need wait for DROP or PAUSE beause they don't depend on a handshake(?)
                    
                end

                LOG: begin

                    if(cmd_in_TDATA[7]) begin
                        log_enable_rdata = 1;
                        // log_TREADY_r = 1; --> WAIT needs to wait for this value and valid
                        // handshake is being done with external module and axis governor
                        // need to rename log_TREADY to log_TREADY_rdata later!
                    end

                    else if(cmd_in_TDATA[8]) 
                        log_enable_wdata = 1;
                        
                    else if(cmd_in_TDATA[9]) 
                        log_enable_raddr = 1;
                    
                    else if(cmd_in_TDATA[10]) 
                        log_enable_awaddr = 1;

                    else if(cmd_in_TDATA[11])
                        log_enable_resp = 1;

                    done_LOG = 1;
                end

                PAUSE: begin

                    if(cmd_in_TDATA[1]) 
                        pause_enable_rdata = 1;
                    
                    else if(cmd_in_TDATA[2]) 
                        pause_enable_wdata = 1;

                    done_PAUSE = 1;
                end

                DONE_DROP: begin
                
                    drop_enable_rdata = 0; //this should automatically assign to the wire
                    drop_enable_wdata = 0;

                    done_DONE_DROP = 1;
                end

                DONE_LOG: begin

                    log_enable_rdata = 0;
                    log_enable_wdata = 0;
                    log_enable_raddr = 0;
                    log_enable_awaddr = 0;
                    log_enable_resp = 0;

                    done_DONE_LOG = 1;
                end

                DONE_INJECT: begin
                    
                    inject_enable_rdata = 0;
                    inject_enable_wdata = 0;
                    inject_enable_resp = 0;

                    inj_TVALID_r = 0;
                    inj_TDATA_rdata = 0;
                    inj_TDATA_resp = 0;
                    inj_TDATA_wdata = 0;

                    done_DONE_INJECT = 1;
                    
                end

                DONE_PAUSE: begin
                    
                    pause_enable_rdata = 0;
                    pause_enable_wdata = 0;

                    done_DONE_PAUSE = 1;
                end

                // TODO: make sure that the module has proper input/output ports
                // TODO: make sure that the axis_governor has everything connected
                // TODO: if everything seems ok, make datapath testbench to test functionality
            endcase
        end 
    end
    /////////////////////////////////////////////////////////////////
    ////////////////// INSTANTIATE 5 AXIS GUVS //////////////////////
    /////////////////////////////////////////////////////////////////

    axis_governor #(
            .DATA_WIDTH(DATA_WIDTH),
            .DEST_WIDTH(`SAFE_DEST_WIDTH),
            .ID_WIDTH(`SAFE_ID_WIDTH)
    ) guv_rdata (    
            .clk(clk),
            
            //Input AXI Stream.
            .in_TDATA(din_TDATA_rdata),
            .in_TVALID(din_TVALID_rdata),
            .in_TREADY(din_TREADY_rdata),
            .in_TKEEP(din_TKEEP_internal_rdata),
            .in_TDEST(din_TDEST_rdata),
            .in_TID(din_TID_rdata),
            .in_TLAST(din_TLAST_internal_rdata),
            
            //Inject AXI Stream. 
            .inj_TDATA(inj_TDATA_rdata),
            .inj_TVALID(inj_TVALID_rdata),
            .inj_TREADY(inj_TREADY_rdata),
            .inj_TKEEP(inj_TKEEP_rdata),
            .inj_TDEST(inj_TDEST_rdata),
            .inj_TID(inj_TID_rdata),
            .inj_TLAST(inj_TLAST_rdata),
            
            //Output AXI Stream.
            .out_TDATA(dout_TDATA_rdata),
            .out_TVALID(dout_TVALID_rdata),
            .out_TREADY(dout_TREADY_rdata),
            .out_TKEEP(dout_TKEEP_rdata),
            .out_TDEST(dout_TDEST_internal_rdata),
            .out_TID(dout_TID_internal_rdata),
            .out_TLAST(dout_TLAST_rdata),
            
            //Log AXI Stream. 
            .log_TDATA(log_TDATA_rdata),
            .log_TVALID(log_TVALID_rdata),
            .log_TREADY(log_TREADY_rdata),
            .log_TKEEP(log_TKEEP_rdata),
            .log_TDEST(log_TDEST_rdata),
            .log_TID(log_TID_rdata),
            .log_TLAST(log_TLAST_rdata),
            
            //Control signals
            .pause(pause_rdata),
            .drop(drop_rdata),
            .log_en(log_en_rdata)
        );    

    
    axis_governor #(
            .DATA_WIDTH(DATA_WIDTH),
            .DEST_WIDTH(`SAFE_DEST_WIDTH),
            .ID_WIDTH(`SAFE_ID_WIDTH)
    ) guv_wdata (    
            .clk(clk),
            
            //Input AXI Stream.
            .in_TDATA(din_TDATA_wdata),
            .in_TVALID(din_TVALID_wdata),
            .in_TREADY(din_TREADY_wdata),
            .in_TKEEP(din_TKEEP_internal_wdata),
            .in_TDEST(din_TDEST_wdata),
            .in_TID(din_TID_wdata),
            .in_TLAST(din_TLAST_internal_wdata),
            
            //Inject AXI Stream. 
            .inj_TDATA(inj_TDATA_wdata),
            .inj_TVALID(inj_TVALID_wdata),
            .inj_TREADY(inj_TREADY_wdata),
            .inj_TKEEP(inj_TKEEP_wdata),
            .inj_TDEST(inj_TDEST_wdata),
            .inj_TID(inj_TID_wdata),
            .inj_TLAST(inj_TLAST_wdata),
            
            //Output AXI Stream.
            .out_TDATA(dout_TDATA_wdata),
            .out_TVALID(dout_TVALID_wdata),
            .out_TREADY(dout_TREADY_wdata),
            .out_TKEEP(dout_TKEEP_wdata),
            .out_TDEST(dout_TDEST_internal_wdata),
            .out_TID(dout_TID_internal_wdata),
            .out_TLAST(dout_TLAST_wdata),
            
            //Log AXI Stream. 
            .log_TDATA(log_TDATA_wdata),
            .log_TVALID(log_TVALID_wdata),
            .log_TREADY(log_TREADY_wdata),
            .log_TKEEP(log_TKEEP_wdata),
            .log_TDEST(log_TDEST_wdata),
            .log_TID(log_TID_wdata),
            .log_TLAST(log_TLAST_wdata),
            
            //Control signals
            .pause(pause_wdata),
            .drop(drop_wdata),
            .log_en(log_en_wdata)
        );    

    axis_governor #(
            .DATA_WIDTH(DATA_WIDTH),
            .DEST_WIDTH(`SAFE_DEST_WIDTH),
            .ID_WIDTH(`SAFE_ID_WIDTH)
    ) guv_raddr (    
            .clk(clk),
            
            //Input AXI Stream.
            .in_TDATA(din_TDATA_raddr),
            .in_TVALID(din_TVALID_raddr),
            .in_TREADY(din_TREADY_raddr),
            .in_TKEEP(din_TKEEP_internal_raddr),
            .in_TDEST(din_TDEST_raddr),
            .in_TID(din_TID_raddr),
            .in_TLAST(din_TLAST_internal_raddr),
            
            //Inject AXI Stream. 
            .inj_TDATA(inj_TDATA_raddr),
            .inj_TVALID(inj_TVALID_raddr),
            .inj_TREADY(inj_TREADY_raddr),
            .inj_TKEEP(inj_TKEEP_raddr),
            .inj_TDEST(inj_TDEST_raddr),
            .inj_TID(inj_TID_raddr),
            .inj_TLAST(inj_TLAST_raddr),
            
            //Output AXI Stream.
            .out_TDATA(dout_TDATA_raddr),
            .out_TVALID(dout_TVALID_raddr),
            .out_TREADY(dout_TREADY_raddr),
            .out_TKEEP(dout_TKEEP_raddr),
            .out_TDEST(dout_TDEST_internal_raddr),
            .out_TID(dout_TID_internal_raddr),
            .out_TLAST(dout_TLAST_raddr),
            
            //Log AXI Stream. 
            .log_TDATA(log_TDATA_raddr),
            .log_TVALID(log_TVALID_raddr),
            .log_TREADY(log_TREADY_raddr),
            .log_TKEEP(log_TKEEP_raddr),
            .log_TDEST(log_TDEST_raddr),
            .log_TID(log_TID_raddr),
            .log_TLAST(log_TLAST_raddr),
            
            //Control signals
            .pause(pause_raddr),
            .drop(drop_raddr),
            .log_en(log_en_raddr)
        );    

    axis_governor #(
            .DATA_WIDTH(DATA_WIDTH),
            .DEST_WIDTH(`SAFE_DEST_WIDTH),
            .ID_WIDTH(`SAFE_ID_WIDTH)
    ) guv_awaddr (    
            .clk(clk),
            
            //Input AXI Stream.
            .in_TDATA(din_TDATA_awaddr),
            .in_TVALID(din_TVALID_awaddr),
            .in_TREADY(din_TREADY_awaddr),
            .in_TKEEP(din_TKEEP_internal_awaddr),
            .in_TDEST(din_TDEST_awaddr),
            .in_TID(din_TID_awaddr),
            .in_TLAST(din_TLAST_internal_awaddr),
            
            //Inject AXI Stream. 
            .inj_TDATA(inj_TDATA_awaddr),
            .inj_TVALID(inj_TVALID_awaddr),
            .inj_TREADY(inj_TREADY_awaddr),
            .inj_TKEEP(inj_TKEEP_awaddr),
            .inj_TDEST(inj_TDEST_awaddr),
            .inj_TID(inj_TID_awaddr),
            .inj_TLAST(inj_TLAST_awaddr),
            
            //Output AXI Stream.
            .out_TDATA(dout_TDATA_awaddr),
            .out_TVALID(dout_TVALID_awaddr),
            .out_TREADY(dout_TREADY_awaddr),
            .out_TKEEP(dout_TKEEP_awaddr),
            .out_TDEST(dout_TDEST_internal_awaddr),
            .out_TID(dout_TID_internal_awaddr),
            .out_TLAST(dout_TLAST_awaddr),
            
            //Log AXI Stream. 
            .log_TDATA(log_TDATA_awaddr),
            .log_TVALID(log_TVALID_awaddr),
            .log_TREADY(log_TREADY_awaddr),
            .log_TKEEP(log_TKEEP_awaddr),
            .log_TDEST(log_TDEST_awaddr),
            .log_TID(log_TID_awaddr),
            .log_TLAST(log_TLAST_awaddr),
            
            //Control signals
            .pause(pause_awaddr),
            .drop(drop_awaddr),
            .log_en(log_en_awaddr)
        );    

    axis_governor #(
            .DATA_WIDTH(DATA_WIDTH),
            .DEST_WIDTH(`SAFE_DEST_WIDTH),
            .ID_WIDTH(`SAFE_ID_WIDTH)
    ) guv_resp (    
            .clk(clk),
            
            //Input AXI Stream.
            .in_TDATA(din_TDATA_resp),
            .in_TVALID(din_TVALID_resp),
            .in_TREADY(din_TREADY_resp),
            .in_TKEEP(din_TKEEP_internal_resp),
            .in_TDEST(din_TDEST_resp),
            .in_TID(din_TID_resp),
            .in_TLAST(din_TLAST_internal_resp),
            
            //Inject AXI Stream. 
            .inj_TDATA(inj_TDATA_resp),
            .inj_TVALID(inj_TVALID_resp),
            .inj_TREADY(inj_TREADY_resp),
            .inj_TKEEP(inj_TKEEP_resp),
            .inj_TDEST(inj_TDEST_resp),
            .inj_TID(inj_TID_resp),
            .inj_TLAST(inj_TLAST_resp),
            
            //Output AXI Stream.
            .out_TDATA(dout_TDATA_resp),
            .out_TVALID(dout_TVALID_resp),
            .out_TREADY(dout_TREADY_resp),
            .out_TKEEP(dout_TKEEP_resp),
            .out_TDEST(dout_TDEST_internal_resp),
            .out_TID(dout_TID_internal_resp),
            .out_TLAST(dout_TLAST_resp),
            
            //Log AXI Stream. 
            .log_TDATA(log_TDATA_resp),
            .log_TVALID(log_TVALID_resp),
            .log_TREADY(log_TREADY_resp),
            .log_TKEEP(log_TKEEP_resp),
            .log_TDEST(log_TDEST_resp),
            .log_TID(log_TID_resp),
            .log_TLAST(log_TLAST_resp),
            
            //Control signals
            .pause(pause_resp),
            .drop(drop_resp),
            .log_en(log_en_resp)
        );    
    
endmodule