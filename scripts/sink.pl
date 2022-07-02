#!/usr/bin/env perl
use strict;
use warnings;

sub main {
    my $sink = shift;
    my @sinks = `pactl list short sinks`;
    return print @sinks if !$sink;
    my $id = find_sink(map_sink_name($sink, `hostname`), \@sinks);
    die "sink $sink not found" if !$id;
    exec_cmd("pactl", "set-default-sink", "$id");
    foreach(`pactl list short sink-inputs`) {
        my @f = split;
        exec_cmd("pactl", "move-sink-input", $f[0], $id);
    }
}

sub exec_cmd {
    die "command failed: @_" if system(@_);
}

sub find_sink {
    my ($sink, $sinks) = @_;
    return $sink if $sink =~ m/^[0-9]+$/;
    foreach(@$sinks) {
        my @f = split;
        return $f[0] if $f[1] =~ $sink;
    }
}

sub map_sink_name {
    my ($sink, $host) = @_;
    if($host =~ /^rh/) {
        if($sink eq "analog-stereo") {
            return "sofhdadsp__sink";
        } elsif($sink eq "hdmi-stereo") {
            return "sofhdadsp_4__sink";
        }
    }
}

main @ARGV;
