#!/usr/bin/python3
# -*- coding: ascii -*-

# --------1---------2---------3---------4---------5---------6---------7-
# ======================================================================
#                               mmhc.py
# ======================================================================

# Author: Cong Chen (chencong@188.com)

import sys
import os.path
import glob
import multiprocessing
import subprocess

def load_RscriptTemplate():
    f = open("mmhc.t.R")
    s = f.read()
    f.close()
    return s

def create_Rscript(file_name, template):
    s = template.format(file_name=file_name)
    file_name_R = file_name + ".R"
    f = open(file_name_R, "w")
    f.write(s)
    f.close()
    return file_name_R

def run_Rscript(file_name_R):
    command = ["Rscript", file_name_R]
    print(" ".join(command))
    subprocess.call(["Rscript", file_name_R])

def run_Rscripts(file_name_Rs):
    cpuCount = multiprocessing.cpu_count()
    pool = multiprocessing.Pool(cpuCount - 2)
    pool.map(run_Rscript, file_name_Rs)
    pool.close()
    pool.join()    

def create_Rscripts():
    template = load_RscriptTemplate()
    files_in = glob.glob("in/*")
    file_name_Rs = []
    for file_in in files_in:
        file_name = os.path.basename(file_in)
        file_name_R = create_Rscript(file_name, template)
        file_name_Rs.append(file_name_R)
    return file_name_Rs
        
def main():
    file_name_Rs = create_Rscripts()
    run_Rscripts(file_name_Rs)


if __name__ == "__main__":
    main()

# ======================================================================
# Copyright (c) 2014 Cong Chen. All rights reserved.
# ======================================================================
# --------1---------2---------3---------4---------5---------6---------7-