gap = 2 * pi / 150;
range = 1.5;

arrow_perc = ( \
    int(system( \
        "h=$(printf '%(%k)T') && m=$(printf '%(%M)T')" \
            . "&& echo $((60 * $h + ${m##0}))")) \
    / 24.0 / 60.0);
arrow_a = -2 * pi * (arrow_perc - 0.25);

set arrow \
    from 0, 0 \
    to 0.7 * cos(arrow_a), 0.7 * sin(arrow_a) \
    linewidth 4 linecolor rgb "dark-gray" front;

set terminal png \
    background rgb "black" \
    font "Palatino, 20" \
    size 1920, 1080;
set margin 32, 32;
set border 0;
set polar;
set theta top cw;
set xrange [-range:range];
set yrange [-range:range];
set size 1;
unset key;
unset raxis;
unset tics;

fmod(x, y) = (x < y) ? x : x - (y * (floor(x) / y));
perc(x) = x / 60 / 24;
start(x) = 2 * pi * perc(x) + gap;
rot(x) = -2 * pi * (0.25 + perc(x)) + 180;
end(b, e) = ( \
    pb = perc(b), \
    pe = perc(e), \
    2 * pi * (((pe <= 1) ? pe - pb : 1 - pb)) \
) - gap;
dist(x, t) = ( \
    a = abs(fmod(2 * (0.25 + perc(x) / 2), 1) - 0.5), \
    1.2 \
    + 0.25 * a * a * a \
    + 0.002 * strlen(t) \
);
label(x) = sprintf("%s\n%s", strcol(3), strcol(4));

plot \
    $d using (start($1)):(0.75):(end($1, $2)):(0.25):5 \
        with sectors \
        linecolor rgb variable \
        fill solid, \
    '' using (start($1)):(0.75):(end($1, $2)):(0.25) \
        with sectors \
        linewidth 1 \
        linecolor "gray30", \
    '' using (start($1)):(dist($1, strcol(4))):(label(0)) \
        with labels \
        textcolor rgb "white";
