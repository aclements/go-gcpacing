set for [lt=1:10] linetype lt lw 2
set style fill solid 0.25 noborder
set multiplot layout 2, 1
set lmargin at screen 0.15
set style data lines
set xlabel ''
set xtics format ''
set ylabel 'Heap ratio'
set yrange [0:*]
plot filename using (column('H_a')/column('H_m(n-1)')-1) title 'h_a', \
     '' using (column('H_g')/column('H_m(n-1)')-1) title 'h_g', \
     '' using (column('H_T')/column('H_m(n-1)')-1) title 'h_t'
set xlabel 'GC cycle'
set xtics format '% g'
set ylabel 'CPU'
set yrange [0:1]
plot [*:*] filename using 1:(column('u_assist')+column('u_bg')+column('u_idle')) title 'u_idle' w filledcurves y1=0, \
     '' using 1:(column('u_assist')+column('u_bg')) title 'u_bg' w filledcurves y1=0, \
     '' using 1:(column('u_assist')) title 'u_assist' w filledcurves y1=0, \
     '' using 1:'u_a' lt 1, \
     '' using 1:'u_g' lt 2
unset multiplot
