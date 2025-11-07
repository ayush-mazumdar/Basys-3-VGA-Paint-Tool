## Overview

This is an FPGA-based VGA drawing canvas. The design features a real-time graphics system with a button-controlled cursor. Implemented in SystemVerilog for Xilinx FPGAs.

## Features

- **VGA Output**: Standard 640x480@60Hz resolution with a 25 MHz clock frequency
- **Frame Buffer**: 80x60 pixel memory with 8x hardware upscaling (4,800 pixels, 12-bit color)
- **16-Color Palette**: Switch-selectable colors including RGB primaries, secondaries, and custom shades
- **Button-Controlled Cursor**: 
  - Four-direction movement (up/down/left/right)
  - Boundary checking to prevent off-screen positioning
  - Cross-shaped cursor with colour inversion for cursor visibility
- **Draw Enable Toggle**: Switch-controlled drawing mode and cursor mode
- **Persistent Canvas**: Drawn pixels remain in frame buffer memory
- **Hardware-Optimized**: Parallel memory read/write operations and efficient resource usage

  
## Getting Started

### Prerequisites
- Xilinx Vivado 2025.1 or compatible version
- Basys3 or compatible Xilinx FPGA board
- VGA monitor with 640x480@60Hz support

### Usage

**Controls:**
- **BTNU/BTND/BTNL/BTNR**: Move cursor up/down/left/right
- **Switches[3:0]**: Select drawing color (16 color options)
- **Switches[15]**: Toggle between drawing mode and cursor mode
- **BTNC**: Reset canvas to white and center cursor

**Color Palette (SW[3:0]):**
- 0000: Black
- 0001: Red
- 0010: Green
- 0011: Blue
- 0100: Yellow
- 0101: Magenta
- 0110: Cyan
- 0111: Orange
- 1000: Dark Red
- 1001: Dark Green
- 1010: Dark Blue
- 1011: Brown
- 1100: Purple
- 1101: Teal
- 1110: Gray
- 1111: White


## Project Structure

### VGA_TOP.sv
Includes all instantiations and a divide-by-four clock divider.
### VGA_Controller.sv
Generates standard VGA timing signals (HSync, VSync) and provides pixel coordinates for the current scan position.

### Pixel_Memory.sv
Memory controller managing the 80×60 frame buffer. Features:
- Sequential initialization to white background
- Initialization complete flag to prevent reading uninitialized memory
- Simultaneous read (for VGA scanning) and write (for user drawing) operations
- Address scaling for 8x upscaling
- Bounds checking for safe memory access

### Button_Canvas.sv
Input controller and drawing logic. Features:
- Button debouncing via two-stage synchronizer
- Cursor initialization, position management (with boundary checking), and colour inversion
- Movement rate limiter (17-bit cycle counter for controlled speed)
- 16-color palette selection
- Draw enable toggle to switch between move-only and draw modes

## Design Decisions

### Memory Optimization
To fit within FPGA block RAM constraints, the frame buffer uses 80×60 resolution with 8× hardware upscaling and 1-dimensional addressing. This reduces memory requirements while maintaining adequate visual quality for a drawing application. The upscaling is done in hardware using simple bit-shift operations (divide by 8) for address calculation.

### Cursor Movement Rate
Cursor updates every 131072 clock cycles (~5.2ms at 25MHz) to provide smooth, controlled movement without being too fast for precise drawing. This creates a comfortable drawing experience where users can easily position the cursor.

### Sequential Memory Initialization
The frame buffer initializes sequentially (one pixel per clock cycle) rather than all at once. This prevents generating massive combinational logic and allows the design to meet timing constraints, at the cost of latency. The `init_done` flag ensures the VGA controller doesn't read from memory until initialization completes.

## Future Enhancements

- [ ] Mouse-controlled cursor
- [ ] Circle and shape tools
- [ ] Adjustable brush size
- [ ] Undo/redo functionality using dual-buffer
- [ ] Fill tool with flood-fill algorithm

