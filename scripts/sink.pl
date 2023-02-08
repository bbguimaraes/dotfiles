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
    set_profile($sink);
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
        } elsif($sink eq "bluez") {
            return "bluez_output.B8_F6_53_C4_6B_53.1";
        }
    } else {
        if($sink eq "bluez") {
            return "bluez_sink.B8_F6_53_C4_6B_53.a2dp_sink";
        }
    }
    return $sink;
}

sub set_profile {
    my $sink = shift;
    my $profile;
    if($sink eq "analog-stereo") {
        $profile = "output:analog-stereo+input:analog-stereo";
    } elsif($sink eq "hdmi-stereo") {
        $profile = "output:hdmi-stereo-extra1+input:analog-stereo";
    } else {
        return
    }
    my @cards = `pactl list short cards`;
    my $card = (split(" ", $cards[0]))[1];
    exec_cmd("pactl", "set-card-profile", $card, $profile);
}

main @ARGV;
