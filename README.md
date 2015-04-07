This is a simulator for the Go 1.5
[garbage collector pacing algorithm](https://golang.org/s/go15gcpacing).

Run `./simulate --help` for simulation options. The simulator outputs
simple tab-separated tables. This repository includes various scripts
to plot these using [Gnuplot](http://www.gnuplot.info/).

Example
-------

The graphs below show the results of the `simulate-all` script, which
simulates a variety of allocation and scan rates. Each configuration
is represented by a pair of graphs showing heap growth ratios and CPU
utilization over time. Both graphs show the goal as well as the
achieved value for each cycle. The top graph also shows the heap
trigger, which is the primary variable directly adjusted by the
controller. The results are noisy as a result of Gaussian noise
injected into various parameters by the simulator.

![Simulation results](/all.png)

plot-real-time
--------------

The plot-real-time script depends on
[matplotlib](http://matplotlib.org/) and
[Seaborn](http://stanford.edu/~mwaskom/software/seaborn/). On Debian
and Ubuntu you can install these with

    apt-get install python3-matplotlib python3-scipy python3-pandas
    pip3 install seaborn

For general installation instructions, see [installing
Seaborn](http://stanford.edu/~mwaskom/software/seaborn/installing.html).
