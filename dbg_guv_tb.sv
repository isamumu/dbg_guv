`timescale 1ns / 1ps
`define CYCLE @(posedge CLOCK_50)

module dbg_guv_tb();

    parameter DATA_WIDTH = 64;
    parameter DEST_WIDTH = 16; 
    parameter ID_WIDTH = 16;
    parameter CLOCK_PERIOD = 20;

    reg CLOCK_50;
    logic rst = 1;
    wire [31:0] cmd_in_TDATA;
    wire cmd_in_TVALID;
    wire cmd_in_TREADY;

    //Input AXI Stream rdata.
    wire [DATA_WIDTH-1:0] din_TDATA_rdata;
    wire [DEST_WIDTH -1:0] din_TDEST_rdata;
    wire din_TVALID_rdata;
    wire din_TREADY_rdata;

    //Input AXI Stream wdata.
    wire [DATA_WIDTH-1:0] din_TDATA_wdata;
    wire din_TVALID_wdata;
    wire din_TREADY_wdata;

    //Input AXI Stream raddr.
    wire [DATA_WIDTH-1:0] din_TDATA_raddr;
    wire din_TVALID_raddr;
    wire din_TREADY_raddr;

    //Input AXI Stream awaddr.
    wire [DATA_WIDTH-1:0] din_TDATA_awaddr;
    wire din_TVALID_awaddr;
    wire din_TREADY_awaddr;

    //Input AXI Stream resp.
    wire [DATA_WIDTH-1:0] din_TDATA_resp;
    wire din_TVALID_resp;
    wire din_TREADY_resp;

    /////////////////////////////////////////////////////////////////////////////////

    //Output AXI Stream rdata.
    wire [DATA_WIDTH-1:0] dout_TDATA_rdata;
    wire [DEST_WIDTH -1:0] dout_TDEST_rdata;
    wire dout_TVALID_rdata;
    wire dout_TREADY_rdata;

    //Output AXI Stream wdata.
    wire [DATA_WIDTH-1:0] dout_TDATA_wdata;
    wire dout_TVALID_wdata;
    wire dout_TREADY_wdata;

    //Output AXI Stream raddr.
    wire [DATA_WIDTH-1:0] dout_TDATA_raddr;
    wire dout_TVALID_raddr;
    wire dout_TREADY_raddr;

    //Output AXI Stream awaddr.
    wire [DATA_WIDTH-1:0] dout_TDATA_awaddr;
    wire dout_TVALID_awaddr;
    wire dout_TREADY_awaddr;

    //Output AXI Stream resp.
    wire [DATA_WIDTH-1:0] dout_TDATA_resp;
    wire dout_TVALID_resp;
    wire dout_TREADY_resp;

    initial begin
        CLOCK_50 = 1'b0;
    end
    
    // generate clock waves
    always @ (*) begin: Clock_Generator
        #((CLOCK_PERIOD) / 2) CLOCK_50 <= ~CLOCK_50;
    end

    reg [31:0] data_in = 0;
    assign cmd_in_TDATA = data_in;

    reg valid_rdata = 0;
    reg valid_wdata = 0;
    reg valid_awaddr = 0;
    reg valid_resp = 0;
    reg ready_rdata = 0;
    reg ready_wdata = 0;
    reg ready_awaddr = 0;
    reg ready_resp = 0;

    reg valid_araddr = 0;
    reg ready_araddr = 0;

    logic [10:0] current_state = 0;
    logic [10:0] next_state = 0;
    logic [31:0] cmd_i = 0;

    assign din_TVALID_rdata = valid_rdata;
    assign dout_TREADY_rdata = ready_rdata;
    assign din_TVALID_resp = valid_resp;
    assign dout_TREADY_resp = ready_resp;
    assign dout_TVALID_wdata = valid_wdata;
    assign din_TREADY_wdata = ready_wdata;
    assign dout_TVALID_awaddr = valid_wdata;
    assign din_TREADY_awaddr = ready_wdata;
    assign dout_TVALID_raddr = valid_araddr;
    assign din_TREADY_raddr = ready_araddr;

    logic VALID = 0;
    assign cmd_in_TVALID = VALID;

    task automatic doHandShake;
      
        begin
          
          VALID = 1;
          $display("set valid to 1");
          
          forever begin
            $display("hello %d", CLOCK_50);
            @(posedge CLOCK_50); //does not return value, it just waits
            
            if(cmd_in_TREADY)
                break;
            $display("no break");
          end
          
     
          VALID = 0;
          
          $display("set valid to %d", cmd_in_TVALID);
          
        end
        
    endtask

    initial begin
        rst = 0;  
        #100; 
        rst = 1;  
        #10
        
        /*
        //VALID = 1;
        valid_wdata = 1;
        ready_wdata = 0;
        #100;
        // for drop, log, and inject we need a sender/receiver interaction for valid and ready signals
        // we always stay at the WAIT state so the handshake occurs to allow the action to execute
        // inject wdata
        data_in = 26'b111111000000000000001000001;
        doHandShake();
        valid_resp = 1;
        #10;
        //VALID = 0;
        ready_wdata = 1;
        #10
        ready_wdata = 0;
        #100
        ready_wdata = 1;

        valid_awaddr = 1;
        ready_awaddr  = 0;
        #100; // HYPOTHESIS: POKE DPOKE happens too quickly
        #1000;
        
        valid_awaddr = 1;
        ready_awaddr  = 1;
        */
        /*
        valid_rdata = 1;
        ready_rdata = 0;
        #100;
        // drop rdata
        data_in = 26'b000011100000000000000001001;
        doHandShake();
        #1000;
        valid_rdata = 1; //must indicate that inject was successful here
        ready_rdata = 1;
        */
        /*
        VALID = 1;
        valid_resp = 1;
        ready_resp = 0;
        #100;
        // drop wdata
        data_in = 26'b000000000000000000000010001;
        #1000;
        valid_resp = 1; //must indicate that inject was successful here
        ready_resp = 1;
        VALID = 0;
        */
        
        /*
        valid_rdata = 1;
        ready_rdata = 0;
        valid_awaddr = 1;
        ready_awaddr  = 0;
        #100;
        // inject rdata
        data_in = 26'b000001111000000000000100001; 
        doHandShake();
        #1000;
        valid_rdata = 1; //must indicate that inject was successful here
        ready_rdata = 1;
        valid_awaddr = 1;
        ready_awaddr  = 1;
        */
        
        
        /*
        valid_rdata = 1;
        ready_rdata = 0;
        #100
        // log (will wait for a messenger sender interface)
        data_in = 26'b000000000000000000010000001;
        doHandShake();
        #10000;
        valid_rdata = 1; //must indicate that inject was successful here
        ready_rdata = 1;
        */
        
        
        // check for pausing
        
        #100;
        data_in = 26'b000000000000000000000000010; // keep in mind about the cont-enable bit
        doHandShake();
        #10;
        
        #1000;
        /*
        #10;
        data_in = 26'b000000000000000000000000011; // keep in mind about the cont-enable bit
        doHandShake();
        #10;
        */
        

    end

    dbg_guv U1 (

    CLOCK_50,
    rst,
    cmd_in_TDATA,
    cmd_in_TVALID,
    cmd_in_TREADY,

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

    current_state,
    next_state,
    cmd_i

);
endmodule