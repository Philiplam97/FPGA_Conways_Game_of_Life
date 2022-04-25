# -*- coding: utf-8 -*-
"""
Parse the .lif files to generate the data to initialise the BRAM
"""

import numpy as np
import argparse


def parse_lif_file(fn, frame_height, frame_width):
    init_grid = np.zeros((frame_height, frame_width), dtype=np.ubyte)
    centre_x = frame_width // 2
    centre_y = frame_height // 2
    cell_block_x = 0
    cell_block_y = 0

    with open(fn, "r") as file:
        for line in file:
            skip_header_pat = ["#L", "#D", "#N", "#R"]
            first_two_char = line[0:2]
            if first_two_char in skip_header_pat:
                continue
            # Start of a new cell block
            if first_two_char == "#P":
                cell_block_x = centre_x + int(line.split()[1])
                cell_block_y = centre_y + int(line.split()[2])
            else:  # Parse the cell states
                for i, cell in enumerate(line):
                    if cell == "*":
                        # cell starts alive
                        init_grid[cell_block_y, cell_block_x + i] = 1
                cell_block_y = cell_block_y + 1
    return init_grid


def save_bram_init(init_grid, frame_height, frame_width, output_path):
    # TODO
    # For now, just remove top line + 2 elements. These should actually be stored in the top two shift
    # registers/line buffers.
    data_mem = init_grid[1:, :].flatten()
    data_mem = data_mem[3:]
    np.savetxt(output_path, data_mem, fmt="%d")


def parse_arguments():

    parser = argparse.ArgumentParser(
        description="Generate initialisation memory file for BRAM"
    )

    parser.add_argument(
        "--mode",
        dest="mode",
        choices=["random", "file"],
        default="random",
        help="Choose to generate from .lif file or random values",
        required=True,
    )

    parser.add_argument(
        "--height",
        dest="frame_height",
        type=int,
        help="Frame height in number of pixels",
        required=True,
    )

    parser.add_argument(
        "--width",
        dest="frame_width",
        type=int,
        help="Frame width in number of pixels",
        required=True,
    )
    
    parser.add_argument(
        "--in_fn",
        dest="file_path",
        help="Path of the .lif file",
    )
    parser.add_argument(
        "--out_fn",
        dest="out_path",
        help="Path to save the memory file",
    )


    args = parser.parse_args()

    return args


if __name__ == "__main__":

    args = parse_arguments()
    
    # frame_height = 480
    # frame_width = 640
    # test_pattern_path = "test_patterns/oscspn3.lif"
    # out_path = "./bram_init.txt"
    # args="--mode file --height 480 --width 640 --in_fn test_patterns/oscspn3.lif --out_fn ./bram_init.txt")
    
    if args.mode == "file":
        init_grid = parse_lif_file(args.file_path, args.frame_height, args.frame_width)
        save_bram_init(init_grid, args.frame_height, args.frame_width, args.out_path )

    # from PIL import Image
    # im = Image.fromarray(init_grid*255)
    # im.save("test.jpeg")
    elif args.mode == "random":            
        rng = np.random.default_rng(0)
        init_grid = rng.choice(a=[False, True], size=(args.frame_height, args.frame_width))
        save_bram_init(init_grid, args.frame_height, args.frame_width, args.out_path)
        
    # with open("C:\Projects\Conways_Game_Of_Life\src/sim_output.txt") as file:
    #     lines = [int(line.rstrip()) for line in file]
    #     test_output = np.array(lines, dtype=np.uint8).reshape(10,480, 640)
    #     from PIL import Image
    #     for i in range(test_output.shape[0]):
    #         im = Image.fromarray(test_output[i,...]*255)
    #         im.save("test_output{}.jpeg".format(i))