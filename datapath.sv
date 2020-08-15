`timescale 1ns / 1ps

`include "axis_governor.v"

`define SAFE_ID_WIDTH (ID_WIDTH < 1 ? 1 : ID_WIDTH)
`define SAFE_DEST_WIDTH (DEST_WIDTH < 1 ? 1 : DEST_WIDTH)

// direction of wires: input (going into the axis guv) and output (going out of axis guv)

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
    input wire [31:0] cmd_in_TDATA,

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
    input wire dout_TREADY_resp,

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
    wire [DEST_WIDTH -1:0] log_TDEST_rdata;
    wire log_TREADY_rdata; 
    wire log_TVALID_rdata;

    wire inj_TVALID_rdata;
    wire inj_TREADY_rdata;
    logic [DATA_WIDTH -1:0] inj_TDATA_rdata = 0; 
    logic [DEST_WIDTH -1:0] inj_TDEST_rdata = 0;

    // wdata
    wire [DATA_WIDTH-1:0] log_TDATA_wdata;
    wire log_TREADY_wdata;
    wire log_TVALID_wdata;
    wire inj_TVALID_wdata;
    wire inj_TREADY_wdata;
    
    logic [DATA_WIDTH -1:0] inj_TDATA_wdata = 0; 

    // raddr
    wire [DATA_WIDTH-1:0] log_TDATA_raddr;
    wire log_TREADY_raddr;
    wire log_TVALID_raddr;
    wire inj_TVALID_raddr;
    wire inj_TREADY_raddr;

    
    logic [DATA_WIDTH -1:0] inj_TDATA_raddr = 0; 

    // waddr
    wire [DATA_WIDTH-1:0] log_TDATA_awaddr;
    
    wire log_TREADY_awaddr;
    wire log_TVALID_awaddr;
    wire inj_TVALID_awaddr;
    wire inj_TREADY_awaddr;
    
    logic [DATA_WIDTH -1:0] inj_TDATA_awaddr = 0; 

    // resp
    wire [DATA_WIDTH-1:0] log_TDATA_resp;
    wire log_TREADY_resp;
    wire log_TVALID_resp;
    wire inj_TVALID_resp;
    wire inj_TREADY_resp;
    
    logic [DATA_WIDTH -1:0] inj_TDATA_resp = 0;

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
    
    
    ///////////////////////////////////////////////////////////////////
    //Also need to treat situations when TLAST or TKEEP are not given//
    ///////////////////////////////////////////////////////////////////
    localparam KEEP_WIDTH = DATA_WIDTH/8 -1;
    
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

    // wdata assignments
    assign inj_success_wdata = inj_TVALID_wdata && inj_TREADY_wdata;

    ////assign inj_success_raddr = inj_TVALID_raddr && !inj_TREADY_raddr; // not used

    // rdata assignments
    assign inj_success_resp = inj_TVALID_resp && inj_TREADY_resp;

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
            .DEST_WIDTH(2),
            .ID_WIDTH(`SAFE_ID_WIDTH)
    ) guv_rdata (    
            .clk(clk),
            
            //Input AXI Stream.
            .in_TDATA(din_TDATA_rdata),
            .in_TVALID(din_TVALID_rdata),
            .in_TREADY(din_TREADY_rdata),
            .in_TDEST(din_TDEST_rdata),
            
            //Inject AXI Stream. 
            .inj_TDATA(inj_TDATA_rdata),
            .inj_TVALID(inj_TVALID_rdata),
            .inj_TREADY(inj_TREADY_rdata),
            .inj_TDEST(inj_TDEST_rdata),
            
            //Output AXI Stream.
            .out_TDATA(dout_TDATA_rdata),
            .out_TVALID(dout_TVALID_rdata),
            .out_TREADY(dout_TREADY_rdata),
            .out_TDEST(dout_TDEST_internal_rdata),
            
            //Log AXI Stream. 
            .log_TDATA(log_TDATA_rdata),
            .log_TVALID(log_TVALID_rdata),
            .log_TREADY(log_TREADY_rdata),
            .log_TDEST(log_TDEST_rdata),
            
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
            .in_TDATA(dout_TDATA_wdata),
            .in_TVALID(dout_TVALID_wdata),
            .in_TREADY(dout_TREADY_wdata),
            
            //Inject AXI Stream. 
            .inj_TDATA(inj_TDATA_wdata),
            .inj_TVALID(inj_TVALID_wdata),
            .inj_TREADY(inj_TREADY_wdata),
            
            //Output AXI Stream.
            .out_TDATA(din_TDATA_wdata),
            .out_TVALID(din_TVALID_wdata),
            .out_TREADY(din_TREADY_wdata),
            
            //Log AXI Stream. 
            .log_TDATA(log_TDATA_wdata),
            .log_TVALID(log_TVALID_wdata),
            .log_TREADY(log_TREADY_wdata),
            
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
            .in_TDATA(dout_TDATA_raddr),
            .in_TVALID(dout_TVALID_raddr),
            .in_TREADY(dout_TREADY_raddr),
            
            //Inject AXI Stream. 
            .inj_TDATA(inj_TDATA_raddr),
            .inj_TVALID(inj_TVALID_raddr),
            .inj_TREADY(inj_TREADY_raddr),
            
            //Output AXI Stream.
            .out_TDATA(din_TDATA_raddr),
            .out_TVALID(din_TVALID_raddr),
            .out_TREADY(din_TREADY_raddr),
            
            //Log AXI Stream. 
            .log_TDATA(log_TDATA_raddr),
            .log_TVALID(log_TVALID_raddr),
            .log_TREADY(log_TREADY_raddr),
            
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
            .in_TDATA(dout_TDATA_awaddr),
            .in_TVALID(dout_TVALID_awaddr),
            .in_TREADY(dout_TREADY_awaddr),
            
            //Inject AXI Stream. 
            .inj_TDATA(inj_TDATA_awaddr),
            .inj_TVALID(inj_TVALID_awaddr),
            .inj_TREADY(inj_TREADY_awaddr),
            
            //Output AXI Stream.
            .out_TDATA(din_TDATA_awaddr),
            .out_TVALID(din_TVALID_awaddr),
            .out_TREADY(din_TREADY_awaddr),
            
            //Log AXI Stream. 
            .log_TDATA(log_TDATA_awaddr),
            .log_TVALID(log_TVALID_awaddr),
            .log_TREADY(log_TREADY_awaddr),
            
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

            //Inject AXI Stream. 
            .inj_TDATA(inj_TDATA_resp),
            .inj_TVALID(inj_TVALID_resp),
            .inj_TREADY(inj_TREADY_resp),
            
            //Output AXI Stream.
            .out_TDATA(dout_TDATA_resp),
            .out_TVALID(dout_TVALID_resp),
            .out_TREADY(dout_TREADY_resp),
            
            //Log AXI Stream. 
            .log_TDATA(log_TDATA_resp),
            .log_TVALID(log_TVALID_resp),
            .log_TREADY(log_TREADY_resp),
            
            //Control signals
            .pause(pause_resp),
            .drop(drop_resp),
            .log_en(log_en_resp)
        );    
    
endmodule