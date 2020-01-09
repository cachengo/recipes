#!/bin/python

import os, sys, stat, shutil, json
from subprocess import run
from pathlib import Path

# arg1 is the name of the folder to build.
arg1 = sys.argv[1]

st = os.stat("makeself-2.4.0.run")
os.chmod("makeself-2.4.0.run", st.st_mode | stat.S_IEXEC)
make_file = ["./makeself-2.4.0.run"]
run(make_file)
os.makedirs("build", exist_ok=True)

with open(os.path.join(arg1, "package.json")) as json_file:
    json_data = json.load(json_file)

description = json_data['description']
for dependency in json_data['dependencies']:
    parent_dir = os.path.join("build", dependency)
    path = Path(parent_dir)
    os.makedirs(path.parent, exist_ok=True)
    if os.path.isdir(dependency):
        shutil.copytree(dependency, os.path.join("build", dependency))
    elif os.path.isfile(dependency):
        shutil.copy2(dependency, os.path.join("build", dependency))
    else:
        raise Exception(f"{dependency} does not exists")

install_command = ["./makeself-2.4.0/makeself.sh", "./build", f"{arg1}.recipe", description, json_data['main']]
run(install_command)
shutil.rmtree("makeself-2.4.0")
shutil.rmtree("build")