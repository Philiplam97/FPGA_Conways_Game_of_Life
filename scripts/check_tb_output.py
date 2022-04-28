# -*- coding: utf-8 -*-
"""
Check the output of the testbench with the reference output
"""

from PIL import Image
import numpy as np
import argparse
import sys
from pathlib import Path
import os

sys.path.append(os.path.dirname(__file__) + "/../modelling")
import game_of_life as gol


def parse_arguments():

    parser = argparse.ArgumentParser(description="Check simulation output")

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
        "--bram_init_path",
        dest="bram_init_path",
        help="",
    )
    parser.add_argument(
        "--sim_out_path",
        dest="sim_out_path",
        help="Path to save the memory file",
    )

    args = parser.parse_args()

    return args


def check(args):
    # Read in simulation output into array
    with open(args.sim_out_path) as file:
        sim_output = np.loadtxt(file, dtype=np.uint8).reshape(
            -1, args.frame_height, args.frame_width
        )
        num_frames = sim_output.shape[0]
        Path("./sim_frames").mkdir(parents=True, exist_ok=True)
        # Also dump the sim output to a picture for viewing
        for i in range(num_frames):
            im = Image.fromarray(sim_output[i, ...] * 255)
            im.save("./sim_frames/sim_output_{}.jpeg".format(i))
    # Read in the reference data from the bram init file.
    # From the BRAM init file, the top line and 3 elements of the frame are removed.
    # This is the becuase of the line stored in the shift register and the 3 registers
    # forming the bottom of the window, which are outside of the BRAM. We need to put this
    # back in the array
    ref_array = np.zeros_like(sim_output)
    with open(args.bram_init_path) as file:
        init_bram_data = np.loadtxt(file, dtype=np.uint8)
        num_pad_zeros = 3 + args.frame_width
        init_grid = np.pad(init_bram_data, (num_pad_zeros, 0), mode="constant").reshape(
            1, args.frame_height, args.frame_width
        )
        ref_array[0, :, :] = init_grid
    # Generate the rest of the reference data
    for i in range(1, num_frames):
        ref_array[i, :, :] = gol.calc_next_grid(ref_array[i - 1, :, :])
    diff = ref_array - sim_output
    if np.all(diff == 0):
        print("SIM PASSED")
    else:
        # For a failure, dump the diff
        abs_diff = np.abs(diff)
        for i in range(num_frames):
            im = Image.fromarray(abs_diff[i, ...] * 255)
            im.save("./sim_frames/diff_{}.jpeg".format(i))
        assert False, "SIM FAILED. Sim output does not match reference output!"


if __name__ == "__main__":
    args = parse_arguments()
    check(args)
