#!/usr/bin/env python
import subprocess
import sys
from datetime import datetime

def gen_plot(dir_path, plot_type):
  command = f"./scripts/plot_{plot_type}.py {dir_path}/benchmark.json --output {dir_path}/plot_{plot_type}.png"
  return subprocess.run(command, shell=True, capture_output=True, text=True)

cli_args = sys.argv[1:]
timestamp_str = cli_args[0]
directory = cli_args[1]
cmd1 = cli_args[2]
cmd2 = cli_args[3]

# create parent directory
parent_dir_name = f"benchmark/{timestamp_str}"
command = f"mkdir -p {parent_dir_name}"
result = subprocess.run(command, shell=True, capture_output=True, text=True)

# create sub directory
sub_dir_name = f"{parent_dir_name}/{directory}"
command = f"mkdir -p {sub_dir_name}"
result = subprocess.run(command, shell=True, capture_output=True, text=True)

# runs hyperfine
command = f"hyperfine --runs 1000 --warmup 3 '{cmd1}' '{cmd2}' --export-json {sub_dir_name}/benchmark.json"
result = subprocess.run(command, shell=True, capture_output=True, text=True)

# generates perf reports
gen_plot(sub_dir_name, "progression")
gen_plot(sub_dir_name, "histogram")
gen_plot(sub_dir_name, "whisker")

print("Perf reports generated successfully!")
