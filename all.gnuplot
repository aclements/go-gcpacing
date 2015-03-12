set term wxt size 600,600
#set term svg size 1000,1000 fsize 16 lw 2
#set output "all.svg"


mp_startx=0.15                  # Left edge of col 0 plot area
mp_starty=0.1                   # Top of row 0 plot area
mp_width=0.825                  # Total width of plot area
mp_height=0.8                   # Total height of plot area
mp_colgap=0.04                  # Gap between columns
mp_rowgap=0.04                  # Gap between rows
# The screen coordinate of the left edge of column col
mp_left(col)=mp_startx + col*((mp_width+mp_colgap)/real(mp_ncols))
# The screen coordinate of the top edge of row row
mp_top(row)=1 - (mp_starty + row*((mp_height+mp_rowgap)/real(mp_nrows)))

# Set up a multiplot with w columns and h rows
mpSetup(w,h) = sprintf('\
    mp_nplot=-1; \
    mp_ncols=%d; \
    mp_nrows=%d; \
    mp_cwidth=mp_left(1)-mp_left(0)-mp_colgap; \
    mp_cheight=mp_top(1)-mp_top(0)+mp_rowgap; \
    set multiplot', w, h)
# XXX mp_cheight is negative
# Start the next graph in the multiplot
mpNextTop = '\
    mp_nplot=mp_nplot+1; \
    unset label; unset object; \
    set lmargin at screen mp_left(mp_nplot%mp_ncols); \
    set rmargin at screen mp_left(mp_nplot%mp_ncols)+mp_cwidth; \
    set tmargin at screen mp_top(mp_nplot/mp_ncols); \
    set bmargin at screen mp_top(mp_nplot/mp_ncols)+mp_cheight/2'
mpNextBot = '\
    unset label; unset object; \
    set lmargin at screen mp_left(mp_nplot%mp_ncols); \
    set rmargin at screen mp_left(mp_nplot%mp_ncols)+mp_cwidth; \
    set tmargin at screen mp_top(mp_nplot/mp_ncols)+mp_cheight/2; \
    set bmargin at screen mp_top(mp_nplot/mp_ncols)+mp_cheight'

mpColLabel(lbl) = \
    sprintf('set object 1 rect center screen mp_left(mp_nplot%%mp_ncols)+mp_cwidth/2,screen 0.93 size screen mp_cwidth, char 1 back fc rgb "grey" lw 0; set label 1 "%s" at screen mp_left(mp_nplot%%mp_ncols)+mp_cwidth/2,screen 0.93 center front',lbl)
mpRowLabel(lbl) = \
    sprintf('set object 2 rect center screen 0.02,screen mp_top(mp_nplot/mp_ncols)+mp_cheight/2 size char 2, screen -mp_cheight back fc rgb "grey" lw 0; set label 2 "%s" at screen 0.02,screen mp_top(mp_nplot/mp_ncols)+mp_cheight/2 center rotate front',lbl)
mpRowTopLabel(lbl) = \
    sprintf('set object 3 rect center screen 0.05,screen mp_top(mp_nplot/mp_ncols)+mp_cheight/4 size char 2, screen -mp_cheight*0.48 back fc rgb "grey" lw 0; set label 3 "%s" at screen 0.05,screen mp_top(mp_nplot/mp_ncols)+mp_cheight/4 center rotate front',lbl)
mpRowBotLabel(lbl) = \
    sprintf('set object 3 rect center screen 0.05,screen mp_top(mp_nplot/mp_ncols)+mp_cheight*3/4 size char 2, screen -mp_cheight*0.48 back fc rgb "grey" lw 0; set label 3 "%s" at screen 0.05,screen mp_top(mp_nplot/mp_ncols)+mp_cheight*3/4 center rotate front',lbl)


#
# Plots
#

GB = 1024*1024*1024
set style data lines
set tics nomirror
set key off
set offsets 0, 0, graph 0.1, graph 0.1

eval mpSetup(3, 3)
do for [pointerScanNS in "1 10 20"] {
    do for [allocPeriodNS in "10 100 1000"] {
        idx=sprintf("h_g=1 w_true=0.0125 pointerScanTime=%sns allocPeriod=%sns", pointerScanNS, allocPeriodNS)

        eval mpNextTop

        # Top labels
        if (mp_nplot < mp_ncols) {
            eval mpColLabel(sprintf("allocPeriod %sns", allocPeriodNS))
        }
        # Left labels
        if (mp_nplot%mp_ncols == 0) {
            eval mpRowLabel(sprintf("pointerScan %sns", pointerScanNS))
        }

        set xtics 5 format ""
        set xlabel ""

        # set yrange [0:1*GB]
        # set ytics format "% g" (0, "1GB" 1*GB, "2GB" 2*GB, "3GB" 3*GB)
        # if (mp_nplot%mp_ncols != 0) { set ytics format "" (0, 1*GB, 2*GB, 3*GB) }

        # plot 'all.dat' index idx using 'H_m(n-1)', \
        #      '' index idx using 'H_t', \
        #      '' index idx using 'H_a', \
        #      '' index idx using 'H_g'

        if (mp_nplot%mp_ncols == 0) { eval mpRowTopLabel("heap") }

        set yrange [0:1.3]
        set ytics format "%.1f" (0, 1, 2)
        if (mp_nplot%mp_ncols != 0) { set ytics format "" (0, 1, 2) }

        plot 'all.dat' index idx using (column('H_a')/column('H_m(n-1)')-1) title "actual", \
             '' index idx using (column('H_g')/column('H_m(n-1)')-1) title "goal", \
             '' index idx using (column('H_t')/column('H_m(n-1)')-1) title "trigger"


        eval mpNextBot

        if (mp_nplot%mp_ncols == 0) { eval mpRowBotLabel("CPU") }

        if (mp_nplot/mp_ncols == mp_nrows-1) { set xtics 5 format "% g"; set xlabel "cycle" }

        set yrange [0:1]
        set ytics format "% g" ("0%%" 0, "100%%" 1)
        if (mp_nplot%mp_ncols != 0) { set ytics format "" (0, 1) }

        plot 'all.dat' index idx using 'u_a', \
             '' index idx using 'u_g'
    }
}

# null key plot
unset origin
unset border
unset tics
unset label
unset arrow
unset title
unset object

set lmargin at screen mp_startx
set rmargin at screen mp_startx+mp_width
set bmargin at screen 0
set tmargin at screen 1
set key on horizontal center top

plot NaN title 'achieved', NaN title 'goal', NaN title 'trigger'

unset multiplot
