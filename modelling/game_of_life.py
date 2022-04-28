# -*- coding: utf-8 -*-
"""
Parse the .lif files to generate the data to initialise the BRAM
"""

import numpy as np
import sys
from PIL import Image


sys.path.append("../scripts")
from parse_test_pattern import parse_lif_file


def calc_next_grid(current_grid):
    next_grid = np.zeros_like(current_grid)
    sum_neighbours = np.zeros_like(current_grid)

    for y_offset in range(-1, 2):
        for x_offset in range(-1, 2):
            if y_offset == 0 and x_offset == 0:
                continue
            shifted_grid = np.roll(current_grid, (y_offset, x_offset), axis=(0, 1))
            if x_offset == -1:
                shifted_grid[:, -1] = 0
            elif x_offset == 1:
                shifted_grid[:, 0] = 0
            if y_offset == -1:
                shifted_grid[-1, :] = 0
            elif y_offset == 1:
                shifted_grid[0, :] = 0
            sum_neighbours += shifted_grid
    next_grid[
        np.logical_or(
            sum_neighbours == 3, np.logical_and(sum_neighbours == 2, current_grid == 1)
        )
    ] = 1

    return next_grid


if __name__ == "__main__":

    test_pattern_path = "../scripts/test_patterns/oscspn3.lif"
    test_pattern_path = "../scripts/test_patterns/aqua25b.lif"
    frame_height = 480
    frame_width = 640
    grid = parse_lif_file(test_pattern_path, frame_height, frame_width)
    num_frames = 5000
    for i in range(num_frames):
        im = Image.fromarray(grid * 255)
        im.save("test{:04}.jpeg".format(i))
        grid = calc_next_grid(grid)
