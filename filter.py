#!/usr/bin/env python

# simulates %pylab inline
# as per here: https://stackoverflow.com/questions/20961287/what-is-pylab
import numpy
import matplotlib
from matplotlib import pylab, mlab, pyplot
np = numpy
plt = pyplot
from IPython.core.pylabtools import figsize, getfigs
from pylab import *
from numpy import *

# Parsing mbox file guide from here:
#  https://pysd-cookbook.readthedocs.io/en/latest/data/Emails/Email_Data_Formatter.html

mboxfile = open('gmail.mbox', 'r')
label_filter = 'people-'
filtered_lines = []
current_message = []

prev_newline = False
save_message = False
num_messages = 0
saved_num_messages = 0

for line in mboxfile:
    if (line.startswith('From:') and prev_newline):
        # This is the start of a new message.
        print("Processed #", num_messages)
        print("Saved #", saved_num_messages)
        num_messages += 1
        if save_message:
            filtered_lines += current_message
        current_message = []
        save_message = False

    if (line.startswith("\n")):
        prev_newline = True
    else:
        prev_newline = False

    if (line.startswith("X-Gmail-Labels:")):
        if label_filter in line.lower():
            save_message = True
            saved_num_messages += 1

    current_message.append(line)

print("Done reading, writing new file.")
f = open(label_filter + ".mbox", "w")
for line in filtered_lines:
    f.write(line)
f.close()

