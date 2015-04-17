# Copyright 2015 The Go Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

import re

heapMinimum = 4<<20

def parse(fp, GOGC=None, omit_forced=True):
    """Parse gctrace output, yielding a series of Rec objects.

    If GOGC is not None, records will include a computed H_g."""

    r = re.compile(r'gc #(?P<n>[0-9]+) @(?P<end>[0-9.]+)s (?P<util>[0-9]+)%: '
                   r'(?P<clocks>[+0-9]+) ms clock, '
                   r'(?P<cpus>[+/0-9]+) ms cpu, '
                   r'(?P<H_T>[0-9]+)->(?P<H_a>[0-9]+)->(?P<H_m>[0-9]+) MB, '
                   r'(?P<gomaxprocs>[0-9]+) P')
    H_m_prev = None
    for line in fp:
        m = r.match(line)
        if not m:
            continue
        d = m.groupdict()
        d['forced'] = '(forced)' in line
        for k, v in list(d.items()):
            if k == 'clocks':
                v = list(map(_ms, v.split('+')))
                d['clocks'] = v
                d['clocksSTW'] = v[::2]
                d['clocksCon'] = v[1::2]
            elif k == 'cpus':
                phases = v.split('+')
                scan = phases[3]
                d['markPhase'] = 3
                if '/' in scan:
                    d['cpu_assist'], d['cpu_bg'], d['cpu_idle'] \
                        = map(_ms, scan.split('/'))
                    phases[3] = (d['cpu_assist'] + d['cpu_bg']) / 1e6
                else:
                    d['cpu_bg'] = _ms(scan)
                    d['cpu_assist'] = d['cpu_idle'] = 0
                v = list(map(_ms, phases))
                d['cpus'] = v
                d['cpusSTW'] = v[::2]
                d['cpusCon'] = v[1::2]
            elif k == 'end':
                d['end'] = _sec(v)
            else:
                v = int(v)
                if k.startswith('H_'):
                    v <<= 20
                d[k] = v
        d['start'] = d['end'] - sum(d['clocks'])
        if GOGC is not None:
            if H_m_prev is None:
                d['H_g'] = heapMinimum
            else:
                d['H_g'] = int(H_m_prev * (1 + GOGC/100))
            H_m_prev = d['H_m']
        if not omit_forced or not d['forced']:
            yield Rec(d)

def _num(x):
    if not isinstance(x, str):
        return x
    try:
        return int(x)
    except ValueError:
        return float(x)

def _ms(x):
    return _num(x) / 1e3

def _sec(x):
    return _num(x)

class Rec:
    def __init__(self, dct):
        for k, v in dct.items():
            setattr(self, k, v)
