#!/usr/bin/env perl
# Translates `digraph` output to DOT.
#
# https://pkg.go.dev/golang.org/x/tools/cmd/digraph
#
# `digraph` has one line per node in the format:
#
#     $dst $src0 $src1 […]
#
# DOT requires some surrounding content and each line describes an edge in the
# format:
#
#     $src -> dst
#
# Positional arguments to the script are passed unchanged to the underlying
# `dot` process used to generate the output.
use warnings;
use strict;

open(my $dot, '|-', join(' ', 'dot', splice @ARGV))
    or die "failed to execute `dot`: $!";
select $dot;
$\ = "\n";
print "digraph test {";
print "rankdir = RL;";
foreach(grep { !m/INFO|WARN/ } <>) {
    my ($src, @dst) = split;
    print map { qq/"$src" -> "$_"/ } @dst;
}
print "}";
