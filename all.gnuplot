set term wxt size 600,600

#set term svg size 1000,1000 fsize 16 lw 2
#set output "all.svg"

#set term pngcairo size 700,700 lw 2
#set output "all.png"


mp_startx=0.18                  # Left edge of col 0 plot area
mp_starty=0.15                  # Top of row 0 plot area
mp_width=0.8                    # Total width of plot area
mp_height=0.75                  # Total height of plot area
mp_colgap=0.04                  # Gap between columns
mp_rowgap=0.04                  # Gap between rows
mp_labelheight=0.03             # Height of row/col labels
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
    sprintf('set object 1 rect center screen mp_left(mp_nplot%%mp_ncols)+mp_cwidth/2,screen 0.88 size screen mp_cwidth, char 1 back fc rgb "grey" lw 0; set label 1 "%s" at screen mp_left(mp_nplot%%mp_ncols)+mp_cwidth/2,screen 0.88 center front',lbl)
mpRowSpanLabel(depth, row1, row2, lbl) = \
    sprintf('set object %d rect from screen %g, screen %g to screen %g, screen %g back fc rgb "grey" lw 0;', depth+100, mp_labelheight*depth, mp_top(row1), mp_labelheight*(depth+0.9), mp_top(row2)+mp_cheight) . \
    sprintf('set label %d "%s" at screen %g, screen %g center rotate front', depth+100, lbl, mp_labelheight*(depth+0.45), (mp_top(row1)+mp_top(row2)+mp_cheight)/2)
mpRowLabel(depth, lbl) = mpRowSpanLabel(depth, mp_nplot/mp_ncols, mp_nplot/mp_ncols, lbl)
mpRowTopLabel(depth, lbl) = mpRowSpanLabel(depth, mp_nplot/mp_ncols, mp_nplot/mp_ncols-0.5, lbl)
mpRowBotLabel(depth, lbl) = mpRowSpanLabel(depth, mp_nplot/mp_ncols+0.5, mp_nplot/mp_ncols, lbl)


#
# Plots
#

GB = 1024*1024*1024
set style data lines
set style fill solid 0.25 noborder;
set tics nomirror
set key off
set offsets 0, 0, graph 0.1, graph 0.1

eval mpSetup(3, 3)
w_true="0.0125"
#eval mpSetup(3, 9)  # Full range of w_true
#do for [w_true in "0.00625 0.0125 0.25"] {
do for [pointerScanNS in "1 10 20"] {
    do for [allocPeriodNS in "10 100 1000"] {
        idx=sprintf("h_g=1 w_true=%s pointerScanTime=%sns allocPeriod=%sns", w_true, pointerScanNS, allocPeriodNS)

        eval mpNextTop

        # Top labels
        if (mp_nplot < mp_ncols) {
            eval mpColLabel(sprintf("allocPeriod %sns", allocPeriodNS))
        }
        # Left labels
        if (mp_nplot%9 == 0) {
            eval mpRowSpanLabel(0, mp_nplot/mp_ncols, mp_nplot/mp_ncols+2, sprintf("w_true %s", w_true))
        }
        if (mp_nplot%mp_ncols == 0) {
            eval mpRowLabel(1, sprintf("pointerScan %sns", pointerScanNS))
        }

        set xtics 5 format ""
        set xlabel ""

        # set yrange [0:1*GB]
        # set ytics format "% g" (0, "1GB" 1*GB, "2GB" 2*GB, "3GB" 3*GB)
        # if (mp_nplot%mp_ncols != 0) { set ytics format "" (0, 1*GB, 2*GB, 3*GB) }

        # plot 'all.dat' index idx using 'H_m(n-1)', \
        #      '' index idx using 'H_T', \
        #      '' index idx using 'H_a', \
        #      '' index idx using 'H_g'

        if (mp_nplot%mp_ncols == 0) { eval mpRowTopLabel(2, "heap") }

        set yrange [0:1.3]
        set ytics format "%.1f" (0, 1, 2)
        if (mp_nplot%mp_ncols != 0) { set ytics format "" (0, 1, 2) }

        plot 'all.dat' index idx using (column('H_a')/column('H_m(n-1)')-1) title "actual", \
             '' index idx using (column('H_g')/column('H_m(n-1)')-1) title "goal", \
             '' index idx using (column('H_T')/column('H_m(n-1)')-1) title "trigger"


        eval mpNextBot

        if (mp_nplot%mp_ncols == 0) { eval mpRowBotLabel(2, "CPU") }

        if (mp_nplot/mp_ncols == mp_nrows-1) { set xtics 5 format "% g"; set xlabel "cycle" }

        set yrange [0:1]
        set ytics format "% g" ("0%%" 0, "100%%" 1)
        if (mp_nplot%mp_ncols != 0) { set ytics format "" (0, 1) }

        plot 'all.dat' index idx using 1:(column('u_bg')+column('u_assist')+column('u_idle')) title 'u_idle' w filledcurves x1 lt 2, \
             '' index idx using 1:(column('u_bg')+column('u_assist')) title 'u_assist' w filledcurves x1 lt 1, \
             '' index idx using 1:(column('u_bg')) title 'u_bg' w filledcurves x1 lt 3, \
             '' index idx using 1:'u_a' lt 1, \
             '' index idx using 1:'u_g' lt 2
    }
}
#}

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

plot NaN lt 1 title 'achieved', \
     NaN w filledcurves lt 3 title 'u_assist', \
     NaN lt 2 title 'goal', \
     NaN w filledcurves lt 2 title 'u_bg', \
     NaN lt 3 title 'trigger', \
     NaN w filledcurves lt 1 title 'u_idle'

unset multiplot
