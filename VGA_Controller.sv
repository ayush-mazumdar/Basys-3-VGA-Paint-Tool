module VGA_Controller(
    input logic pixel_clk_25, // 25M for 800 pixels/line * 525 lines/screen * 60 screeens/second
    input logic reset,
    output logic hsync,
    output logic vsync,
    output logic [9:0] x_pos, y_pos,
    output logic vid_active
    );
// Standard timing parameters of a 640 x 480 VGA display
    localparam H_VIS = 640;
    localparam H_FP = 16; 
    localparam H_SYNC = 96; 
    localparam H_BP = 48; 
    localparam H_TOTAL = 800; 
    localparam V_VIS = 480; 
    localparam V_FP = 10; 
    localparam V_SYNC = 2; 
    localparam V_BP = 33;  
    localparam V_TOTAL = 525; 
    
    logic [9:0] h_count, v_count;
    
// Vertical and horizontal counters
    always_ff @(posedge pixel_clk_25, posedge reset)begin
        if(reset)begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            if(h_count == H_TOTAL - 1)begin
                h_count <= 0;
                if(v_count == V_TOTAL - 1)begin
                    v_count <= 0;
                end else begin
                    v_count <= v_count + 1;
                end
            end else begin
                h_count <= h_count + 1;
            end
        end
    end
        
    always_comb begin
        // HSYNC is active low within the HSYNC region
        hsync = ~((h_count >= (H_VIS + H_FP)) && 
                  (h_count < (H_VIS + H_FP + H_SYNC)));
        
        // VSYNC is active low within the VSYNC region
        vsync = ~((v_count >= (V_VIS + V_FP)) && 
                  (v_count < (V_VIS + V_FP + V_SYNC)));
        
        // Video is active in visible area
        vid_active = (h_count < H_VIS) && (v_count < V_VIS);
        
        // Output current pixel position
        x_pos = h_count;
        y_pos = v_count;
    end  
        
endmodule
