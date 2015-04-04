set for [lt=1:10] linetype lt lw 2
set style fill solid 0.25 noborder
set multiplot layout 2, 1
set lmargin at screen 0.15
set style data lines
set xlabel ''
set xtics format ''
set ylabel 'Heap size'
plot filename using 1:'H_a' lt 1, \
     '' using 1:'H_g' lt 2, \
     '' using 1:'H_T', \
     '' using 1:'H_m(n-1)', \
     '' using 1:'W_a', \
     '' using 1:'W_e'
set xlabel 'GC cycle'
set xtics format '% g'
set ylabel 'CPU'
set yrange [0:1]
plot [*:*] filename using 1:(column('u_bg')+column('u_assist')+column('u_idle')) title 'u_idle' w filledcurves y1=0 lt 2, \
     '' using 1:(column('u_bg')+column('u_assist')) title 'u_assist' w filledcurves y1=0 lt 1, \
     '' using 1:(column('u_bg')) title 'u_bg' w filledcurves y1=0 lt 3, \
     '' using 1:'u_a' lt 1, \
     '' using 1:'u_g' lt 2
unset multiplot
