`timescale 1ns / 1ps
`define CYCLE @(posedge CLOCK_50)

module control_datapath_tb();
    parameter DATA_WIDTH = 64;
    parameter DEST_WIDTH = 16; 
    parameter ID_WIDTH = 16;
    parameter CLOCK_PERIOD = 20;

    logic rst;
    reg CLOCK_50;

    // CONTROLPATH signals 
    wire [28:0] cmd_in_TDATA;
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

    // DATAPATH signals
    //Input AXI Stream rdata.
    wire [DATA_WIDTH-1:0] din_TDATA_rdata;
    wire din_TLAST_rdata;
    wire [DATA_WIDTH/8-1:0] din_TKEEP_rdata;
    wire [DEST_WIDTH -1:0] din_TDEST_rdata;
    wire [ID_WIDTH -1:0] din_TID_rdata;
    wire din_TVALID_rdata;
    wire din_TREADY_rdata;

    //Input AXI Stream wdata.
    wire [DATA_WIDTH-1:0] din_TDATA_wdata;
    wire din_TLAST_wdata;
    wire [DATA_WIDTH/8-1:0] din_TKEEP_wdata;
    wire [DEST_WIDTH -1:0] din_TDEST_wdata;
    wire [ID_WIDTH -1:0] din_TID_wdata;
    wire din_TVALID_wdata;
    wire din_TREADY_wdata;

    //Input AXI Stream raddr.
    wire [DATA_WIDTH-1:0] din_TDATA_raddr;
    wire din_TLAST_raddr;
    wire [DATA_WIDTH/8-1:0] din_TKEEP_raddr;
    wire [DEST_WIDTH -1:0] din_TDEST_raddr;
    wire [ID_WIDTH -1:0] din_TID_raddr;
    wire din_TVALID_raddr;
    wire din_TREADY_raddr;

    //Input AXI Stream awaddr.
    wire [DATA_WIDTH-1:0] din_TDATA_awaddr;
    wire din_TLAST_awaddr;
    wire [DATA_WIDTH/8-1:0] din_TKEEP_awaddr;
    wire [DEST_WIDTH -1:0] din_TDEST_awaddr;
    wire [ID_WIDTH -1:0] din_TID_awaddr;
    wire din_TVALID_awaddr;
    wire din_TREADY_awaddr;

    //Input AXI Stream resp.
    wire [DATA_WIDTH-1:0] din_TDATA_resp;
    wire din_TLAST_resp;
    wire [DATA_WIDTH/8-1:0] din_TKEEP_resp;
    wire [DEST_WIDTH -1:0] din_TDEST_resp;
    wire [ID_WIDTH -1:0] din_TID_resp;
    wire din_TVALID_resp;
    wire din_TREADY_resp;
    
    //Output AXI Stream rdata.
    wire [DATA_WIDTH-1:0] dout_TDATA_rdata;
    wire [DATA_WIDTH/8-1:0]dout_TKEEP_rdata;
    wire [DEST_WIDTH -1:0] dout_TDEST_rdata;
    wire [ID_WIDTH -1:0] dout_TID_rdata;
    wire dout_TVALID_rdata;
    wire dout_TREAD_rdata;

    //Output AXI Stream wdata.
    wire [DATA_WIDTH-1:0] dout_TDATA_wdata;
    wire [DATA_WIDTH/8-1:0]dout_TKEEP_wdata;
    wire [DEST_WIDTH -1:0] dout_TDEST_wdata;
    wire [ID_WIDTH -1:0] dout_TID_wdata;
    wire dout_TVALID_wdata;
    wire dout_TREADY_wdata;

    //Output AXI Stream raddr.
    wire [DATA_WIDTH-1:0] dout_TDATA_raddr;
    wire [DATA_WIDTH/8-1:0]dout_TKEEP_raddr;
    wire [DEST_WIDTH -1:0] dout_TDEST_raddr;
    wire [ID_WIDTH -1:0] dout_TID_raddr;
    wire dout_TVALID_raddr;
    wire dout_TREADY_raddr;

    //Output AXI Stream awaddr.
    wire [DATA_WIDTH-1:0] dout_TDATA_awaddr;
    wire [DATA_WIDTH/8-1:0]dout_TKEEP_awaddr;
    wire [DEST_WIDTH -1:0] dout_TDEST_awaddr;
    wire [ID_WIDTH -1:0] dout_TID_awaddr;
    wire dout_TVALID_awaddr;
    wire dout_TREADY_awaddr;

    //Output AXI Stream resp.
    wire [DATA_WIDTH-1:0] dout_TDATA_resp;
    wire [DATA_WIDTH/8-1:0]dout_TKEEP_resp;
    wire [DEST_WIDTH -1:0] dout_TDEST_resp;
    wire [ID_WIDTH -1:0] dout_TID_resp;
    wire dout_TVALID_resp;
    wire dout_TREADY_resp;

    wire [5:0] command;
    wire drop_enable;
    wire inject_enable;
    wire inject_valid;
    wire [15:0] inject_data;

    logic tready_rdata = 0;
    logic tready_resp = 0;
    logic tready_wdata = 0;
    logic log_ready = 0;
    wire in_log_tready;

    assign dout_TREADY_rdata = tready_rdata;
    assign dout_TREADY_resp = tready_resp;
    assign dout_TREADY_wdata = tready_wdata;
    assign in_log_tready = log_ready;


    initial begin
        CLOCK_50 = 1'b0;
    end
    
    // generate clock waves
    always @ (*) begin: Clock_Generator
        #((CLOCK_PERIOD) / 2) CLOCK_50 <= ~CLOCK_50;

    end

    assign cmd_in_TDATA = data;

    wire inj_success_rdata;
    // TODO (ideally): test each function and make sure they reach the right states (DONE)
    // TODO: investigate why we end at the start state... actually it makes sense right (DONE)
    // TODO: make sure the cont_enable signal works by enabling the _DONE signals (DONE)
    // TODO: hook up the datapath and see if the right done signals are sent out (DONE)
    // TODO: hook up the axis governors to the datapath and hook them up to the control path (DONE)
    // TODO: hook EVERYTHING up to the top module dbg_guv and see if everything works (fingers crossed) (DONE)
    // TODO: think about having a done signal so that we can reset the data to 0
    initial begin
        rst = 1;  
        #100; 
        rst = 0;  

        /*
        // check drop on rdata
        data = 26'b000000000000000000000001001;
        tready_rdata = 1;
        #60;
        data = 26'b000000000000000000000000000;
        #10;
        */ 

        /*
        // check drop on wdata
        data = 26'b000000000000000000000010001;
        tready_resp = 1;
        #60;
        data = 26'b000000000000000000000000000;
        #10;
        */

        /*
        // check inject rdata
        data = 26'b000000000000000000000100001; 
        tready_rdata = 1;
        #10000;
        data = 26'b000000000000000000000000000; 
        #20;
        */

        /*
        // check inject wdata
        data = 26'b000000000000000000001000001; // keep in mind about the cont-enable bit
        tready_wdata = 1;
        #10000;
        data = 26'b000000000000000000000000000; 
        #20;
        */

        /*
        // check logging (will wait for a messenger sender interface)
        data = 26'b000000000000000000010000001; // keep in mind about the cont-enable bit
        log_ready = 1;
        #100
        data = 26'b000000000000000000000000000; // this should fix controlpath to start state
        #20;
        */

        // check for pausing
        data = 26'b000000000000000000000000011; // keep in mind about the cont-enable bit
        #10000;
        data = 26'b000000000000000000000000010; // this should fix controlpath to start state
        #20;
        

    end

    control_FSM U2(
        CLOCK_50,
        rst,
        cmd_in_TDATA,
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
        master_drop_enable_wdata,
        state_next_o,
        data_in_o
    );

    // init module
    datapath U1 (
        CLOCK_50,
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
        din_TLAST_rdata,
        din_TKEEP_rdata,
        din_TDEST_rdata,
        din_TID_rdata,
        din_TVALID_rdata,
        din_TREADY_rdata,

        //Input AXI Stream wdata.
        din_TDATA_wdata,
        din_TLAST_wdata,
        din_TKEEP_wdata,
        din_TDEST_wdata,
        din_TID_wdata,
        din_TVALID_wdata,
        din_TREADY_wdata,

        //Input AXI Stream raddr.
        din_TDATA_raddr,
        din_TLAST_raddr,
        din_TKEEP_raddr,
        din_TDEST_raddr,
        din_TID_raddr,
        din_TVALID_raddr,
        din_TREADY_raddr,

        //Input AXI Stream awaddr.
        din_TDATA_awaddr,
        din_TLAST_awaddr,
        din_TKEEP_awaddr,
        din_TDEST_awaddr,
        din_TID_awaddr,
        din_TVALID_awaddr,
        din_TREADY_awaddr,

        //Input AXI Stream resp.
        din_TDATA_resp,
        din_TLAST_resp,
        din_TKEEP_resp,
        din_TDEST_resp,
        din_TID_resp,
        din_TVALID_resp,
        din_TREADY_resp,
        
        //Output AXI Stream rdata.
        dout_TDATA_rdata,
        dout_TKEEP_rdata,
        dout_TDEST_rdata,
        dout_TID_rdata,
        dout_TVALID_rdata,
        dout_TREADY_rdata,

        //Output AXI Stream wdata.
        dout_TDATA_wdata,
        dout_TKEEP_wdata,
        dout_TDEST_wdata,
        dout_TID_wdata,
        dout_TVALID_wdata,
        dout_TREADY_wdata,

        //Output AXI Stream raddr.
        dout_TDATA_raddr,
        dout_TKEEP_raddr,
        dout_TDEST_raddr,
        dout_TID_raddr,
        dout_TVALID_raddr,
        dout_TREADY_raddr,

        //Output AXI Stream awaddr.
        dout_TDATA_awaddr,
        dout_TKEEP_awaddr,
        dout_TDEST_awaddr,
        dout_TID_awaddr,
        dout_TVALID_awaddr,
        dout_TREADY_awaddr,

        //Output AXI Stream resp.
        dout_TDATA_resp,
        dout_TKEEP_resp,
        dout_TDEST_resp,
        dout_TID_resp,
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
        done_DONE_PAUSE,
        
        //below signals are meant for testbench purposes
        command,
        drop_enable,
        inject_enable,
        inject_valid,
        inject_data,
        inj_success_rdata,
        tvalid_check,
        tready_check
    );
endmodule