// button_canvas.sv - Button-controlled drawing canvas
module Button_Canvas(
    input logic pixel_clk_25,
    input logic reset,
    input logic [9:0] vga_x, vga_y,
    input logic vid_active,
    input logic btnu, btnd, btnl, btnr,
    input logic [3:0] color_sw,     // Color selection switches
    input logic draw_enable,        // Draw on/off toggle
    output logic[3:0] vga_red, vga_green, vga_blue
);

    // Cursor position
    logic [9:0] cursor_x, cursor_y;
    
    // Button debouncing and edge detection
    logic [3:0] btn_sync1, btn_sync2;
    logic [3:0] btn_edges;
    
    // Movement timing (slow down cursor movement)
    logic [16:0] move_counter;
    logic move_tick;
    
    // Color selection
    logic [11:0] selected_color;
    
    // Memory interface signals
    logic [9:0] mem_write_x, mem_write_y;
    logic [11:0] mem_write_colour, mem_read_colour;
    logic write_en;
    logic cursor_visible;
    
    // Instantiate Pixel Memory
    Pixel_Memory PIXEL_MEMORY(
        .clk(pixel_clk_25),
        .reset(reset),
        .write_en(write_en),
        .write_x(mem_write_x),
        .write_y(mem_write_y),
        .write_colour(mem_write_colour),
        .read_x(vga_x),
        .read_y(vga_y),
        .read_colour(mem_read_colour)
    );
    
    // Button debouncer
    always_ff @(posedge pixel_clk_25) begin
        if (reset) begin
            btn_sync1 <= 0;
            btn_sync2 <= 0;
        end else begin
            btn_sync1 <= {btnu, btnd, btnl, btnr};
            btn_sync2 <= btn_sync1;
        end
    end
    
    
    // Movement timing counter
    always_ff @(posedge pixel_clk_25) begin
        if (reset) begin
            move_counter <= 0;
        end else begin
            move_counter <= move_counter + 1; // 16 - bit counter maxes out at 2^16 = 65536
        end
    end
    
    // Generate movement tick (slower cursor movement)
    assign move_tick = (move_counter == 0); // Move every 65536 cycles (~2.6ms at 25MHz)
    
    // Cursor position control
    always_ff @(posedge pixel_clk_25) begin
        if (reset) begin
            cursor_x <= 320;  // Center X
            cursor_y <= 240;  // Center Y
        end else if (move_tick) begin
            // Move cursor based on button presses (with bounds checking)
            if (btn_sync2[3] && cursor_y > 5)        cursor_y <= cursor_y - 1;  // Up
            if (btn_sync2[2] && cursor_y < 474)      cursor_y <= cursor_y + 1;  // Down  
            if (btn_sync2[1] && cursor_x > 5)        cursor_x <= cursor_x - 1;  // Left
            if (btn_sync2[0] && cursor_x < 634)      cursor_x <= cursor_x + 1;  // Right
        end
    end
    
    // Color selection based on switches
    always_comb begin
        case (color_sw)
            4'b0000: selected_color = 12'h000; // Black
            4'b0001: selected_color = 12'hF00; // Red
            4'b0010: selected_color = 12'h0F0; // Green  
            4'b0011: selected_color = 12'h00F; // Blue
            4'b0100: selected_color = 12'hFF0; // Yellow
            4'b0101: selected_color = 12'hF0F; // Magenta
            4'b0110: selected_color = 12'h0FF; // Cyan
            4'b0111: selected_color = 12'hF80; // Orange
            4'b1000: selected_color = 12'h800; // Dark Red
            4'b1001: selected_color = 12'h080; // Dark Green
            4'b1010: selected_color = 12'h008; // Dark Blue
            4'b1011: selected_color = 12'h880; // Brown
            4'b1100: selected_color = 12'h808; // Purple  
            4'b1101: selected_color = 12'h088; // Teal
            4'b1110: selected_color = 12'h888; // Gray
            4'b1111: selected_color = 12'hFFF; // White
        endcase
    end
    
    // Drawing logic
    always_ff @(posedge pixel_clk_25) begin
        write_en <= 0; // Default
        
        // Draw when draw_enable is on and cursor moves
        if (draw_enable && move_tick && (btn_sync2[3] | btn_sync2[2] | btn_sync2[1] | btn_sync2[0])) begin
            write_en <= 1;
            mem_write_x <= cursor_x;
            mem_write_y <= cursor_y;
            mem_write_colour <= selected_color;
        end
    end
    
    // Cursor visibility (cross-shaped cursor)
    always_comb begin
        cursor_visible = (vga_x == cursor_x && (vga_y >= cursor_y - 3 && vga_y <= cursor_y + 3)) ||
                        (vga_y == cursor_y && (vga_x >= cursor_x - 3 && vga_x <= cursor_x + 3));
    end
    
    // VGA output generation
    always_comb begin
        if (vid_active) begin
            if (cursor_visible) begin
                // Cursor color (inverse of selected color for visibility)
                if (selected_color == 12'h000) begin
                    // White cursor on black
                    vga_red = 4'hF;
                    vga_green = 4'hF;
                    vga_blue = 4'hF;
                end else begin
                    // Black cursor on other colors
                    vga_red = 4'h0;
                    vga_green = 4'h0;
                    vga_blue = 4'h0;
                end
            end else begin
                // Display memory contents
                vga_red = mem_read_colour[11:8];
                vga_green = mem_read_colour[7:4];
                vga_blue = mem_read_colour[3:0];
            end
        end else begin
            // Blank during sync
            vga_red = 4'h0;
            vga_green = 4'h0;
            vga_blue = 4'h0;
        end
    end
    
endmodule