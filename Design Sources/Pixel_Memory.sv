module Pixel_Memory(
    input logic clk,
    input logic reset,
    input logic write_en,
    input logic [9:0] write_x, write_y,
    input logic [11:0] write_colour,
    input logic [9:0] read_x, read_y,
    output logic [11:0] read_colour
);
    
    // 80x60 resolution with 8x scaling instead of 160x120 with 4x scaling
    localparam MEM_WIDTH = 80;
    localparam MEM_HEIGHT = 60;
    localparam MEM_DEPTH = MEM_WIDTH * MEM_HEIGHT; // 4800 pixels
    

    logic [11:0] frame_buffer [0:MEM_DEPTH-1]; // Creates an array of 12-bit pixel data values 
    
    logic [12:0] write_addr, read_addr;
    logic [6:0] scaled_read_x, scaled_read_y;
    logic [6:0] scaled_write_x, scaled_write_y;
    
    logic [12:0] init_counter;
    logic init_done;          
    
    // Scale factors for 8x upscaling - divide by 8 (triple logical right shift)
    assign scaled_read_x = read_x[9:3];   
    assign scaled_read_y = read_y[9:3];  
    assign scaled_write_x = write_x[9:3];
    assign scaled_write_y = write_y[9:3];
    
    // Calculate addresses
    assign write_addr = scaled_write_y * MEM_WIDTH + scaled_write_x; // Pixel at (5,1) would have addr 85 -> 5th pixel in row 1
    assign read_addr = scaled_read_y * MEM_WIDTH + scaled_read_x;
    
    
    always_ff @(posedge clk) begin
        if (reset) begin
            init_counter <= 0;
            init_done <= 0;
        end else if (!init_done) begin
            // Initialize memory sequentially (one pixel per clock)
            frame_buffer[init_counter] <= 12'hFFF; // White
            
            if (init_counter == MEM_DEPTH - 1) begin
                init_done <= 1; // Flag used to allow the slow white screen init (4800*clk) to finish before reading from memory
                init_counter <= 0;
            end else begin
                init_counter <= init_counter + 1;
            end
        end else if (write_en && scaled_write_x < MEM_WIDTH && scaled_write_y < MEM_HEIGHT) begin
            frame_buffer[write_addr] <= write_colour; // Write operation
        end
    end
    
    // Read operation with bounds checking
    always_comb begin
        if (scaled_read_x < MEM_WIDTH && scaled_read_y < MEM_HEIGHT && init_done) begin
            read_colour = frame_buffer[read_addr];
        end else begin
            read_colour = init_done ? 12'h000 : 12'hFFF; // Black for out of bounds, white during init
        end
    end
    
endmodule
