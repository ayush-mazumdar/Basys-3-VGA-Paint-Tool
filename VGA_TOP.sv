module VGA_TOP(
    input logic clk,            // 100 MHz system clock
    
    // VGA outputs
    output logic vga_hsync,
    output logic vga_vsync,
    output logic [3:0] vga_red,
    output logic [3:0] vga_green,
    output logic [3:0] vga_blue,
    
    // Button inputs for cursor control
    input logic btnu,           // Move up
    input logic btnd,           // Move down
    input logic btnl,           // Move left
    input logic btnr,           // Move right
    input logic btnc,           // Reset
    
    // Switches for color and draw control
    input logic [15:0] sw,       // Switches for color selection and draw toggle
    output logic [15:0] led
    
);
    
    
    // Clock generation - convert 100MHz to 25MHz
    logic pixel_clk_25;
    logic [1:0] clk_divider = 0;
    
    always_ff @(posedge clk) begin
        clk_divider <= clk_divider + 1;
    end
    
    assign pixel_clk_25 = clk_divider[1]; // Divide by 4: 100MHz -> 25MHz
    
    
    // VGA controller signals
    logic [9:0] vga_x, vga_y;
    logic vid_active;
    
    // Instantiate VGA controller
    VGA_Controller VGA_CONTROLLER(
        .pixel_clk_25(pixel_clk_25),
        .reset(btnc),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .x_pos(vga_x),
        .y_pos(vga_y),
        .vid_active(vid_active)
    );
    
    // Instantiate button-controlled canvas
    Button_Canvas CANVAS(
        .pixel_clk_25(pixel_clk_25),
        .reset(btnc),
        .vga_x(vga_x),
        .vga_y(vga_y),
        .vid_active(vid_active),
        .vga_red(vga_red),
        .vga_green(vga_green),
        .vga_blue(vga_blue),
        .btnu(btnu),
        .btnd(btnd),
        .btnl(btnl),
        .btnr(btnr),
        .color_sw(sw[3:0]),     // Switches 0-3 for color selection
        .draw_enable(sw[15])     // Switch 15 for draw on/off
    );
    
    assign led = sw;
    
endmodule