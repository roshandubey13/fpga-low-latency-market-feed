// =============================================================
//  parser_threshold_led_v1_0
//  Minimal AXIS 8-bit UDP payload parser:
//  Expected payload format (9 bytes exactly):
//    [0]     symbol_id
//    [1..4]  price_q16_16   (big-endian)
//    [5..8]  volume_u32     (big-endian)
// =============================================================

module parser_threshold_led_v1_0 #
(
    parameter integer C_AXIS_TDATA_WIDTH = 8
)
(
    //---------------------------------------------------------
    // AXIS Slave (from UDP/IP)
    //---------------------------------------------------------
    input  wire                           axis_aclk,
    input  wire                           axis_aresetn,

    input  wire [C_AXIS_TDATA_WIDTH-1:0]  s00_axis_tdata,
    input  wire                           s00_axis_tvalid,
    output wire                           s00_axis_tready,
    input  wire                           s00_axis_tlast,

    //---------------------------------------------------------
    // Thresholds (Q16.16 unsigned or signed; you choose)
    //---------------------------------------------------------
    input  wire [31:0]                    buy_thresh,
    input  wire [31:0]                    sell_thresh,

    //---------------------------------------------------------
    // LED outputs
    //---------------------------------------------------------
    output reg                            buy_led,
    output reg                            sell_led
);

    // Always ready (simple design)
    assign s00_axis_tready = 1'b1;

    //---------------------------------------------------------
    // FSM + Counters
    //---------------------------------------------------------
    reg [3:0] state;

    localparam S_SYM   = 4'd0;
    localparam S_P3    = 4'd1;
    localparam S_P2    = 4'd2;
    localparam S_P1    = 4'd3;
    localparam S_P0    = 4'd4;
    localparam S_V3    = 4'd5;
    localparam S_V2    = 4'd6;
    localparam S_V1    = 4'd7;
    localparam S_V0    = 4'd8;

    //---------------------------------------------------------
    // Data registers being built
    //---------------------------------------------------------
    reg [7:0]   symbol_reg;
    reg [31:0]  price_reg;
    reg [31:0]  volume_reg;

    // Valid strobe
    reg parsed_valid;

    //---------------------------------------------------------
    // Sequential logic
    //---------------------------------------------------------
    always @(posedge axis_aclk) begin
        if (!axis_aresetn) begin
            state        <= S_SYM;
            symbol_reg   <= 8'd0;
            price_reg    <= 32'd0;
            volume_reg   <= 32'd0;
            parsed_valid <= 1'b0;
        end else begin
            parsed_valid <= 1'b0;

            if (s00_axis_tvalid) begin
                case (state)

                    // SYMBOL (1 byte)
                    S_SYM: begin
                        symbol_reg <= s00_axis_tdata;
                        state <= S_P3;
                    end

                    // PRICE big-endian 4 bytes
                    S_P3: begin
                        price_reg[31:24] <= s00_axis_tdata;
                        state <= S_P2;
                    end

                    S_P2: begin
                        price_reg[23:16] <= s00_axis_tdata;
                        state <= S_P1;
                    end

                    S_P1: begin
                        price_reg[15:8] <= s00_axis_tdata;
                        state <= S_P0;
                    end

                    S_P0: begin
                        price_reg[7:0] <= s00_axis_tdata;
                        state <= S_V3;
                    end

                    // VOLUME big-endian 4 bytes
                    S_V3: begin
                        volume_reg[31:24] <= s00_axis_tdata;
                        state <= S_V2;
                    end

                    S_V2: begin
                        volume_reg[23:16] <= s00_axis_tdata;
                        state <= S_V1;
                    end

                    S_V1: begin
                        volume_reg[15:8] <= s00_axis_tdata;
                        state <= S_V0;
                    end

                    S_V0: begin
                        volume_reg[7:0] <= s00_axis_tdata;
                        parsed_valid <= 1'b1;
                        state <= S_SYM;     // ready for next packet
                    end

                    default: begin
                        state <= S_SYM;
                    end
                endcase
            end

            // Optional resync if UDP packet ends early
            if (s00_axis_tlast) begin
                state <= S_SYM;
            end
        end
    end

    //---------------------------------------------------------
    // Threshold comparator
    //---------------------------------------------------------
    wire buy_event  = parsed_valid && (price_reg > buy_thresh);
    wire sell_event = parsed_valid && (price_reg < sell_thresh);

    //---------------------------------------------------------
    // LED pulse stretcher for visibility
    //---------------------------------------------------------
    // Tune this for human-visible persistence
    localparam integer PULSE = 24'd6_000_000;  // ~60ms at 100 MHz

    reg [23:0] buy_cnt;
    reg [23:0] sell_cnt;

    always @(posedge axis_aclk) begin
        if (!axis_aresetn) begin
            buy_cnt  <= 0;
            sell_cnt <= 0;
            buy_led  <= 1'b0;
            sell_led <= 1'b0;
        end else begin

            // BUY pulse
            if (buy_event)
                buy_cnt <= PULSE;
            else if (buy_cnt != 0)
                buy_cnt <= buy_cnt - 1;

            // SELL pulse
            if (sell_event)
                sell_cnt <= PULSE;
            else if (sell_cnt != 0)
                sell_cnt <= sell_cnt - 1;

            // LED outputs reflect counters
            buy_led  <= (buy_cnt  != 0);
            sell_led <= (sell_cnt != 0);
        end
    end

endmodule
