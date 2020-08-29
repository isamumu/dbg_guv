`timescale 1ns / 1ps
`define CYCLE @(posedge CLOCK_50)

module testbench();
    parameter DATA_WIDTH = 64;
    parameter DEST_WIDTH = 16; 
    parameter ID_WIDTH = 16;
    parameter CLOCK_PERIOD = 20;

    logic clk;
    logic rst;
    wire [9:0] state_next;
    reg CLOCK_50;

    //Input command stream
    wire logic [26:0] cmd_in_TDATA;


    //Input AXI Stream.
    wire [DATA_WIDTH-1:0] din_TDATA;
    wire din_TLAST;
    wire [DATA_WIDTH/8-1:0] din_TKEEP;
    wire [DEST_WIDTH -1:0] din_TDEST;
    wire [ID_WIDTH -1:0] din_TID;
    wire din_TVALID;
    wire din_TREADY;
    
    //Output AXI Stream.
    wire [DATA_WIDTH-1:0] dout_TDATA;
    wire [DATA_WIDTH/8-1:0]dout_TKEEP;
    wire [DEST_WIDTH -1:0] dout_TDEST;
    wire [ID_WIDTH -1:0] dout_TID;
    wire dout_TVALID;
    wire dout_TREADY;

    wire w_done_START;
    wire w_done_DROP;
    wire w_done_INJECT;
    wire w_done_WAIT;
    wire w_done_LOG;
    wire w_done_PAUSE;
    wire w_done_DONE_DROP;
    wire w_done_DONE_LOG;
    wire w_done_DONE_INJECT;
    wire w_done_DONE_PAUSE;

    wire w_cont_enable;
    logic [26:0] data = 0;
    logic [9:0] next_state_r = 0;
    wire [5:0] command;
    wire [5:0] current_state;
    wire drop_enable;
    wire inject_enable;
    wire inject_valid;
    wire [15:0] inject_data;

    logic enable = 1;

    assign state_next = next_state_r;

    initial begin
        CLOCK_50 = 1'b0;
    end

    always @ (*) begin: Clock_Generator
        #((CLOCK_PERIOD) / 2) CLOCK_50 <= ~CLOCK_50;

    end

    assign cmd_in_TDATA = data;

    // we should consider the posedge signals bc
    // currently idk if the positive clock edge is 
    // being used.

    // OP code: 16bits for data (#), 10bits for operation (%), 1bit for enable/disable for continuous operation ($)

    ///////////// OP CODE VISUAL ////////////////
    /////////////////////////////////////////////
    //// ################ || %%%%%%%%%% || $ ////
    /////////////////////////////////////////////

    // TODO: see art of writing test benches
    initial begin

        // initial reset
        next_state_r = 0;
        rst = 1;  
        data = -1;
        #100; 
        rst = 0;  

        // START STATE
        next_state_r = 0;
        #100;
        // ...
        
        // DROP STATE (1)
        // (enter drop state on next cycle && check for high drop enable)
     
        data = 26'b000000000000000000000001000;
        #100;

        next_state_r = 0;

        //data = -1;
        #100;
        
        // WAIT STATE(3)
        // (enter wait state, check for one skipped cycle)
        
        next_state_r = 6'd3;
        #100;
        
        data = -1;
        next_state_r = 0;
        #100;
        
        // (send out done signal. Check for low drop enable) (6)
        next_state_r = 6'd6;
        #100;
        
        data = -1;
        next_state_r = 0;

        
        
        // INJECT STATE (2)
        // (enter inject state. Check for high enable, high valid, and check for data)
        data = 26'b010101010101010100000100000;
        #100;
        
        data = -1;
        next_state_r = 0;
        #100;

        // (send out done signal. Check for low inject enable and valid)
        next_state_r = 6'd8;
        #100;
        
        next_state_r = 0;

        // LOG STATE (4)
        data = 26'b000000000000000000010000000;
        #100;

    
        next_state_r = 0;

        // PAUSE STATE (5)
        data = 26'b000000000000000000000000001;
        #10000;

    end
    

    always @ (posedge CLOCK_50) begin
        // Add here a methodology similar to behavior of control FSM
        // the if statements predict the next state based on the command
        // for now we manually enter the START, DONE(s) and WAIT state
        
        if(command == 0) 
            next_state_r = 6'd5;
        
        else if(command == 1) 
            next_state_r = 6'd5;
        
        else if(command == 2) 
            next_state_r = 6'd1;
        
        else if(command == 3) 
            next_state_r = 6'd1;
        
        else if(command == 4) 
            next_state_r = 6'd2;
        
        else if(command == 5) 
            next_state_r = 6'd2;
        
        else if(command == 6) 
            next_state_r = 6'd4;
        
        else if(command == 7) 
            next_state_r = 6'd4;
        
        else if(command == 8) 
            next_state_r = 6'd4;
        
        else if(command == 9) 
            next_state_r = 6'd4;
       
        
    end

    // init module
    datapath U1 (
        CLOCK_50,
        rst,
        state_next,
        cmd_in_TDATA,
        din_TDATA,
        din_TLAST,
        din_TKEEP,
        din_TDEST,
        din_TID,
        din_TVALID,
        din_TREADY,
        dout_TDATA,
        dout_TKEEP,
        dout_TDEST,
        dout_TID,
        dout_TVALID,
        dout_TREADY,
        w_done_START,
        w_done_DROP,
        w_done_INJECT,
        w_done_WAIT,
        w_done_LOG,
        w_done_PAUSE,
        w_done_DONE_DROP,
        w_done_DONE_LOG,
        w_done_DONE_INJECT,
        w_done_DONE_PAUSE,
        w_cont_enable,
        command,
        current_state,
        drop_enable,
        inject_enable,
        inject_valid,
        inject_data
    );
endmodule