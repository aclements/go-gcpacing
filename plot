#!/bin/sh

# Perform a single simulation and plots the results in Gnuplot

set -e

if [ "$1" = -h -o "$1" = --help ]; then
    python3 simulate.py "$@"
    exit
fi

python3 simulate.py "$@" > /tmp/gcpacing.dat
gnuplot --persist -e "\
set multiplot layout 2, 1;
set lmargin at screen 0.15;
set xlabel '';
set xtics format '';
set ylabel 'Heap size';
plot for [n=2:7] '/tmp/gcpacing.dat' using 1:n with lines lw 2 title col;
set xlabel 'GC cycle';
set xtics format '% g';
set ylabel 'CPU';
plot [*:*] [0:1] for [n=9:10] '' using 1:n with lines lw 2 title col;
unset multiplot"
