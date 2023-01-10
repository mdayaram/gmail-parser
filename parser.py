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

import mailbox
import pandas as pd

print('Opening file...')
mb = mailbox.mbox('gmail.mbox')
print('...done')

keys = ['Date', 'X-Gmail-Labels', 'X-GM-THRID']
print('Popping a random item...')
(key, message) = mb.popitem()
print('..done')
print('key: ', key)
print('message:')
print(message)
