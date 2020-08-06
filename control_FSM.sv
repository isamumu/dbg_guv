`timescale 1ns / 1ps

`include "axis_governor.v"
`include "dbg_guv_width_adapter.v"
`include "tkeep_to_len.v"
`endif


//////////////////////////////////////////////////////
/////////// Step 1: Make Control  FSM ////////////////
//////////////////////////////////////////////////////

module control_FSM(
    input logic clk,
    input logic rst,

    //Input command stream
    input wire [28:0] cmd_in_TDATA, 
    input logic cmd_in_TVALID, 
    output logic cmd_in_TREADY, 

    input wire done_START, 
    input wire done_DROP, 
    input wire done_INJECT, 
    input wire done_WAIT, 
    input wire done_LOG, 
    input wire done_PAUSE, 
    input wire done_DONE_DROP, 
    input wire done_DONE_LOG, 
    input wire done_DONE_INJECT, 
    input wire done_DONE_PAUSE, 

    output wire [9:0] curr_state,
    output wire master_inject_enable_resp,
    output wire master_inject_enable_rdata,
    output wire master_drop_enable_rdata,
    output wire master_drop_enable_wdata

);

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

    // TODO: must add more states after i draft the FSMs 
    // i think each function will have its own FSM

    logic [9:0] state_next = 0; // to be determined in the state, not reset
    logic [9:0] state = 0;

    logic master_inject_resp = 0;
    logic master_inject_rdata = 0;
    logic master_drop_rdata = 0;
    logic master_drop_wdata = 0;

    logic cont_enable = 0;
    logic [28:0] data_in = 0;

    // will this throw an error if state doesnt have a value?
    assign curr_state = state;

    assign master_inject_enable_resp = master_inject_resp;
    assign master_inject_enable_rdata = master_inject_rdata;
    assign master_drop_enable_resp = master_drop_rdata;
    assign master_drop_enable_rdata = master_drop_wdata;

    //cmd_in_TREADY = (state == START); // ADDED

    always@(posedge clk or posedge rst) begin 
        if(rst) 
            state <= START;
        else
            state <= state_next;
    end

    always_comb begin
        
        master_inject_resp = 0;
        master_inject_rdata = 0;
        master_drop_rdata = 0;
        master_drop_wdata = 0;
        cont_enable = 0;
        // cmd_in_TREADY = 0; // might infer a latch

        case (state)
            START: begin
                master_inject_resp = 0;
                master_inject_rdata = 0;
                master_drop_rdata = 0;
                master_drop_wdata = 0;
                
                data_in = cmd_in_TDATA; // we use data_in because we want to reset data to 0 after the operation is complete in _DONE state
                cont_enable = data_in[0];
                cmd_in_TREADY = 1; // show the user that we are READY for an input command
                
                if(data_in == 0 || cmd_in_TVALID == 0) 
                    state_next = START;

                else if((data_in[1] || data_in[2]) && done_START && cont_enable)
                    state_next = PAUSE; // rdata // wdata

                else if((data_in[3] || data_in[4]) && done_START && cont_enable)
                    state_next = DROP; // rdata // wdata

                else if((data_in[5] || data_in[6]) && done_START && cont_enable)
                    state_next = DROP; // inj rdata // inj wdata

                else if(data_in[12] && done_START && cont_enable)
                    state_next = INJECT;  // resp

                else if((data_in[7] || data_in[8] || data_in[9] || data_in[10] || data_in[11]) && done_START && cont_enable)
                    state_next = LOG; // rdata // wdata // raddr // awaddr // resp

                else if(!cont_enable && (data_in[1] || data_in[2]))
                    state_next = DONE_PAUSE;

                else if(!cont_enable && (data_in[3] || data_in[4]))
                    state_next = DONE_DROP;

                else if(!cont_enable && (data_in[5] || data_in[6] || data_in[12]))
                    state_next = DONE_INJECT;

                else if(!cont_enable && (data_in[7] || data_in[8] || data_in[9] || data_in[10] || data_in[11]))
                    state_next = DONE_LOG;
                
            end

            DROP: begin
                if((data_in[3] || data_in[4]) && done_DROP)
                    state_next = INJECT; // rdata // wdata
                    
                else if(data_in[5] && done_DROP) begin
                    master_drop_rdata = 1;
                    state_next = INJECT; // for inject rdata
                end

                else if(data_in[6] && done_DROP) begin
                    master_drop_wdata = 1;
                    state_next = INJECT; // for inject wdata
                end

                cmd_in_TREADY = 0;

            end

            INJECT: begin
                if(data_in[3] && done_INJECT) begin
                    state_next = WAIT; // for drop rdata
                    master_inject_rdata = 1;
                end

                else if(data_in[4] && done_INJECT) begin
                    state_next = WAIT; // for drop wdata
                    master_inject_resp = 1;
                end

                else if(data_in[5] && done_INJECT) begin
                    state_next = WAIT; // for inject rdata
                end

                else if(data_in[6] && done_INJECT) begin
                    state_next = WAIT; // for inject wdata
                end

                else if(data_in[12] && done_INJECT) begin
                    state_next = WAIT; // inject resp
                end

                cmd_in_TREADY = 0;
            end

            WAIT: begin
                if(done_WAIT)
                    state_next = START;
                cmd_in_TREADY = 0;
            end

            LOG: begin
                if(done_LOG)
                    state_next = WAIT;
                cmd_in_TREADY = 0;
            end

            PAUSE: begin
                if(done_PAUSE)
                    state_next = START;
                cmd_in_TREADY = 0;
            end

            DONE_DROP: begin
                if(done_DONE_DROP) 
                    state_next = START;
                cmd_in_TREADY = 0;
            end

            DONE_LOG: begin
                if(done_DONE_LOG) 
                    state_next = START;
                cmd_in_TREADY = 0;
            end

            DONE_INJECT: begin
                if(done_DONE_INJECT) 
                    state_next = START;
                cmd_in_TREADY = 0;
            end

            DONE_PAUSE: begin
                if(done_DONE_PAUSE)
                    state_next = START;
                cmd_in_TREADY = 0;
            end

        endcase
    end 

endmodule