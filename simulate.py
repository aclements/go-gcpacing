#!/usr/bin/env python3
# -*- python -*-

# Copyright 2015 The Go Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

import sys
import argparse
import collections
import re
import numpy.random

NS = 1e-9
ptrSize = 8

class N(collections.namedtuple('N', 'mu sigma')):
    def val(self, state=numpy.random):
        return state.normal(self.mu, self.sigma)

    def __str__(self):
        return '%g±%g%%' % (self.mu, 100*self.sigma/self.mu)

    @classmethod
    def parser(cls, defaultPct):
        def parse(s):
            m = re.match(r'([-0-9.e]+)(?:(?:±|\+-?|-)([0-9.e]+)(%?))?', s)
            if not m:
                raise argparse.ArgumentTypeError('expected <float>[+-<float>[%]]')
            mu = float(m.group(1))
            if m.group(2) is not None:
                sigma = float(m.group(2))
                if m.group(3):
                    sigma = mu * (sigma / 100)
            else:
                sigma = mu * defaultPct
            return cls(mu, sigma)
        return parse

argp = argparse.ArgumentParser(
    epilog='''DIST arguments take a normal distribution in the form
    <float>[+-<float>[%]] where the first number gives the mean and
    the second gives the standard deviation, optionally as a
    percentage of the mean.  If the second is omitted, it uses the
    same percentage standard deviation as the default value.''')
argp.add_argument('--GOGC', metavar='PCT', type=float, default=100,
                  help='GOGC setting (default %(default)s)')
argp.add_argument('--pointerScanNS', metavar='NS', type=float, default=2,
                  help='Nanoseconds to scan a pointer (default %(default)s)')
argp.add_argument('--allocPeriodNS', metavar='DIST',
                  type=N.parser(0.2), default=N(100, 100 * 0.2),
                  help='Nanoseconds between allocations (default %(default)s)')
argp.add_argument('--w_true', metavar='DIST',
                  type=N.parser(0.01), default=N(0.1/ptrSize, 0.1/ptrSize*0.01),
                  help='True work ratio (default %(default)s)')
argp.add_argument('--u_mut', metavar='UTIL', type=float, default=1,
                  help='Mutator CPU utilization assuming no GC (default %(default)s)')
argp.add_argument('--seed', type=int, default=1,
                  help='Random seed')
args = argp.parse_args()
numpy.random.seed(args.seed)

#
# Simulation controls and state
#

# Constants
h_g = args.GOGC / 100
u_g = 0.25
K_T = 0.5
K_w = 0.75
u_mut = args.u_mut

# GC state variables carried between cycles
w = w_initial = 0.1 * 1/ptrSize
h_T = 7/8

# System state
# The actual heap size doesn't matter much, as long as it's much
# larger than the typical allocation.
H_m_prev = H_m_initial = 512*1024

# Simulation variables
pointerScanSecs = args.pointerScanNS * NS

def reachableBytes():
    """How many bytes of heap are reachable."""
    # Vary around initial size
    return max(0, int(H_m_initial * reachableBytes.state.normal(1, 0.1)))
    # Random walk
    #return max(0, int(H_m_prev * numpy.random.normal(1, 0.1)))
# Generate the same H_m sequence regardless of other things
reachableBytes.state = numpy.random.RandomState(numpy.random.randint(10000))

def workRatio():
    """Pointer/reachable byte ratio."""
    return max(0.001, args.w_true.val())

def allocBytes():
    """Bytes per allocation."""
    # TODO: This is a completely made up
    return int(numpy.random.lognormal(5, 0.5))

def allocPeriodSecs():
    """Seconds between allocations."""
    return max(0, args.allocPeriodNS.val() * NS)

#
# Simulator
#

def concurrentPhase():
    # How much of the heap is reachable?
    H_m = reachableBytes()

    # How much scan work do we need to do to scan all reachable pointers?
    W_a = H_m * workRatio()

    # Allocate and scan until we've done W_a scan work
    W_done = 0
    H_a = H_T
    now = gcTime = gcTime_idle = 0
    credit = 0
    allocDelay = allocPeriodSecs()
    while True:
        # Alternate between background scanning and mutator assists.
        if W_done >= W_a:
            break

        # Do background scanning until now+allocDelay, aim for u_g
        # utilization at now+allocDelay.
        if allocDelay > 0:
            u_background = (u_g * (now + allocDelay) - gcTime) / allocDelay
            u_background = max(u_background, 0)

            u_idle = ((1 - u_mut - u_background) * (now + allocDelay) - (gcTime + gcTime_idle)) / allocDelay

            if u_background > 0:
                W_background = allocDelay / pointerScanSecs * u_background
                W_done += W_background
                credit += W_background
                gcTime += allocDelay * u_background

            if u_idle > 0:
                W_idle = allocDelay / pointerScanSecs * u_idle
                W_done += W_idle
                credit += W_idle
                # Does *not* count against gcTime
                gcTime_idle += allocDelay * u_idle

            now += allocDelay

        if W_done >= W_a:
            break

        # Do allocation (assume this is instantaneous).
        alloc = allocBytes()
        H_a += alloc

        # Do assist work for allocation (assume this consumes 100% of
        # the CPU during the assist and that background GC doesn't
        # happen concurrently).
        A = W_e/(H_g - H_T) * alloc
        steal = min(A, credit)
        credit -= steal
        A -= steal
        W_done += A
        assistTime = pointerScanSecs * A
        gcTime += assistTime
        now += assistTime

        allocDelay = allocPeriodSecs()

    u_a = gcTime / now
    u_a_with_idle = (gcTime + gcTime_idle) / now
    return H_a, u_a, u_a_with_idle, W_a, H_m

print("# h_g=%g w_true=%g pointerScanTime=%gns allocPeriod=%gns u_mut=%g" % (h_g, args.w_true.mu, pointerScanSecs/NS, args.allocPeriodNS.mu, u_mut))
print("n\tH_m(n-1)\tH_t\tH_a\tH_g\tW_a\tW_e\tw\tu_a\tu_g\tu_a_with_idle")
for n in range(20):
    H_T = H_m_prev * (1 + h_T)
    H_g = H_m_prev * (1 + h_g)
    #W_e = w * H_g           # Old w definition
    W_e = w * H_m_prev            # New w definition

    # Simulate a concurrent cycle
    H_a, u_a, u_a_with_idle, W_a, H_m = concurrentPhase()

    print(n, H_m_prev, H_T, H_a, H_g, W_a*ptrSize, W_e*ptrSize, w, u_a, u_g, u_a_with_idle, sep='\t')
    sys.stdout.flush()

    # Update heap trigger
    h_a = H_a / H_m_prev - 1
    e = h_g - h_T - u_a/u_g*(h_a - h_T)
    h_T = max(0, h_T + K_T * e)

    # Update work estimate
    #w = K_w*W_a/H_a + (1 - K_w)*w # Old w definition
    w = K_w*W_a/H_m + (1 - K_w)*w # New w definition

    # Update H_m_prev
    H_m_prev = H_m
