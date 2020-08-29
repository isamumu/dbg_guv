`timescale 1ns / 1ps

//////////////////////////////////////////////////////
/////////// Step 1: Make Control  FSM ////////////////
//////////////////////////////////////////////////////

module control_FSM(

    input logic clk,
    input logic rst,

    //Input command stream

    input wire [31:0] cmd_in_TDATA, 
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
    input wire done_WAIT_NEXT,
    input wire done_UNPAUSE,
    input wire done_QUIT_DROP,
    input wire done_UNLOG,

    output wire [10:0] curr_state,
    output wire master_inject_resp,
    output wire master_inject_rdata,

    output wire newFlit,
    output logic [10:0] state_next_o,
    output logic [31:0] data_o

);

    localparam START = 6'd0;
    localparam DROP = 6'd1; 
    localparam INJECT = 6'd2; 
    localparam WAIT = 6'd3;
    localparam LOG= 6'd4;
    localparam PAUSE = 6'd5;
    localparam DONE_DROP = 6'd6;
    localparam DONE_LOG = 6'd7;
    localparam DONE_INJECT = 6'd8;
    localparam DONE_PAUSE = 6'd9;
    localparam WAIT_NEXT = 6'd10;   
    localparam UNPAUSE = 6'd11;
    localparam QUIT_DROP = 6'd12;
    localparam UNLOG = 6'd13;

    logic [10:0] state_next = 0; // to be determined in the state, not reset
    logic [10:0] state = 0;
    //logic [31:0] data = cmd_in_TDATA;

    assign data_o = cmd_in_TDATA;
    assign state_next_o = state_next;

    // we don't want to use this below
    assign master_inject_resp = cmd_in_TDATA[4]; // just make sure we have these
    assign master_inject_rdata = 0; //data[3];

    // will this throw an error if state doesnt have a value?
    assign curr_state = state;
    assign newFlit = cmd_in_TREADY && cmd_in_TVALID;
    
    always@(posedge clk or posedge rst) begin 
        if(rst) 
            state <= START;
        else 
            state <= state_next;
    end
    
    always_comb begin

        // cmd_in_TREADY = 0; // avoid a latch        

        case (state)
            START: begin

                cmd_in_TREADY = 1; // show the user that we are READY for an input command
                                   // has to be here bc, command should only update as we stall in the start state
                if(cmd_in_TREADY && cmd_in_TVALID) begin

                    if(((cmd_in_TDATA[1] && !cmd_in_TDATA[0]) || (cmd_in_TDATA[2] && !cmd_in_TDATA[0])) && done_START)
                        state_next = PAUSE; // pause rdata // wdata

                    else if(cmd_in_TDATA[3] && cmd_in_TDATA[0] && done_START)
                        state_next = QUIT_DROP;

                    else if((cmd_in_TDATA[3] || cmd_in_TDATA[4]) && done_START)
                        state_next = DROP; // drop rdata // wdata

                    else if((cmd_in_TDATA[5] || cmd_in_TDATA[6]) && done_START)
                        state_next = WAIT_NEXT;// inj rdata // inj wdata
                        
                    else if(cmd_in_TDATA[12] && done_START)
                        state_next = INJECT;  // resp

                    else if(((cmd_in_TDATA[7] && !cmd_in_TDATA[0]) || (cmd_in_TDATA[8] && !cmd_in_TDATA[0]) || (cmd_in_TDATA[9] && !cmd_in_TDATA[0]) || (cmd_in_TDATA[10] && !cmd_in_TDATA[0]) || (cmd_in_TDATA[11] && !cmd_in_TDATA[0])) && done_START)
                        state_next = LOG; // rdata // wdata // raddr // awaddr // resp

                    else if(((cmd_in_TDATA[7] && cmd_in_TDATA[0]) || (cmd_in_TDATA[8] && cmd_in_TDATA[0]) || (cmd_in_TDATA[9] && cmd_in_TDATA[0]) || (cmd_in_TDATA[10] && cmd_in_TDATA[0]) || (cmd_in_TDATA[11] && cmd_in_TDATA[0])) && done_START)
                        state_next = UNLOG; // rdata // wdata // raddr // awaddr // resp
                    
                    else if((cmd_in_TDATA[1] && cmd_in_TDATA[0]) || (cmd_in_TDATA[2] && cmd_in_TDATA[0]) && done_START)
                        state_next = UNPAUSE; // unpause rdata // wdata

                    else
                        state_next = START;
                end

                else 
                    state_next = START;
                
            end


            DROP: begin

                if(cmd_in_TDATA[3] && done_DROP) 
                    state_next = DONE_DROP; // rdata 

                else if(cmd_in_TDATA[4] && done_DROP) 
                    state_next = INJECT; // wdata

                else if(cmd_in_TDATA[6] && done_DROP)
                    state_next = INJECT; // inj wdata 

                else
                    state_next = DROP;

                cmd_in_TREADY = 0;

            end

            QUIT_DROP: begin
                
                state_next = START;
                cmd_in_TREADY = 0;

            end

            INJECT: begin
                
                if(cmd_in_TDATA[3] && done_INJECT) 
                    state_next = WAIT; // for drop rdata
                    
                else if(cmd_in_TDATA[4] && done_INJECT) 
                    state_next = DROP; // for drop wdata

                else if(cmd_in_TDATA[5] && done_INJECT) 
                    state_next = WAIT; // for inject rdata

                else if(cmd_in_TDATA[6] && done_INJECT) 
                    state_next = WAIT; // for inject wdata 

                else if(cmd_in_TDATA[12] && done_INJECT) 
                    state_next = WAIT; // inject resp

                else 
                    state_next = INJECT;      

                cmd_in_TREADY = 0;

            end
            
            WAIT: begin

                if((cmd_in_TDATA[3] || cmd_in_TDATA[4]) && done_WAIT)
                    state_next = DONE_DROP; // drop rdata // wdata

                else if((cmd_in_TDATA[5] || cmd_in_TDATA[12]) && done_WAIT)
                    state_next = DONE_INJECT;// inj rdata // inj resp
                
                else if(cmd_in_TDATA[6] && done_WAIT)
                    state_next = DONE_INJECT; // inj wdata 
                
                /*
                else if((cmd_in_TDATA[7] || cmd_in_TDATA[8] || cmd_in_TDATA[9] || cmd_in_TDATA[10] || cmd_in_TDATA[11]) && done_WAIT)
                    state_next = DONE_LOG; // rdata // wdata // raddr // awaddr // resp
                */
                else
                    state_next = WAIT;

                cmd_in_TREADY = 0;

            end

            WAIT_NEXT: begin

                if(cmd_in_TDATA[6] && done_WAIT_NEXT)
                    state_next = DROP; // inj wdata
                else if(cmd_in_TDATA[5] && done_WAIT_NEXT)
                    state_next = INJECT; // inj rdata
                else
                    state_next = WAIT_NEXT;

                cmd_in_TREADY = 0;
            end


            LOG: begin

                if(done_LOG)
                    state_next = WAIT;
                else
                    state_next = LOG;

                cmd_in_TREADY = 0;

            end

            UNLOG: begin
                if(done_UNLOG)
                    state_next = START;
                else
                    state_next = UNLOG;

                cmd_in_TREADY = 0;
            end

            PAUSE: begin

                if(done_PAUSE)
                    state_next = DONE_PAUSE;
                else
                    state_next = PAUSE;

                cmd_in_TREADY = 0;

            end

            UNPAUSE: begin
                
                if(done_UNPAUSE)
                    state_next = START;
                else
                    state_next = UNPAUSE;

                cmd_in_TREADY = 0;

            end 

            DONE_DROP: begin

                if(done_DONE_DROP) 
                    state_next = START;

                else
                    state_next = DONE_DROP;

                cmd_in_TREADY = 0;

            end

            DONE_LOG: begin

                if(done_DONE_LOG) 
                    state_next = START;

                else
                    state_next = DONE_LOG;

                cmd_in_TREADY = 0;

            end

            DONE_INJECT: begin

                if(done_DONE_INJECT) 
                    state_next = START;

                else
                    state_next = DONE_INJECT;

                cmd_in_TREADY = 0;

            end

            DONE_PAUSE: begin

                if(done_DONE_PAUSE) 
                    state_next = START;

                else
                    state_next = DONE_PAUSE;

                cmd_in_TREADY = 0;

            end

            default: begin
                cmd_in_TREADY = 0;
                state_next = START;
            end

        endcase
    end 
endmodule