#!/usr/bin/env perl
use strict;
use warnings;

use constant {
    RESOLUTION => "1920x1080",
    RATE => "60",
};

sub main {
    my $arg = shift;
    if(!$arg or $arg eq "list") {
        cmd_list(@_)
    } elsif($arg eq "toggle") {
        cmd_toggle(@_)
    } elsif($arg eq "workspaces") {
        cmd_workspaces(@_)
    } elsif($arg eq "single") {
        cmd_single(@_)
    } elsif($arg eq "dual") {
        cmd_dual(@_)
    } elsif($arg eq "mirror") {
        cmd_mirror(@_)
    } elsif($arg eq "tv") {
        cmd_tv(@_)
    } elsif($arg eq "120hz") {
        cmd_120hz(@_)
    } elsif($arg eq "4k") {
        cmd_4k(@_)
    } else {
        usage()
    }
}

sub usage {
    print <<EOF;
Usage: $0 CMD [ARGS...]

Commands:

    list
    toggle
    single|mirror|dual|tv|120hz|4k
EOF
    1
}

sub cmd_list {
    return usage if scalar @_ != 0;
    foreach my $h (list()) {
        next if !$${h{"active"}};
        print($$h{"name"});
        print(" primary") if $$h{"primary"};
        print("\n");
    }
    0
}

sub cmd_toggle {
    return usage if scalar @_ != 0;
    my ($primary, $secondary, $active) = common();
    if($active == 1) {
        dual($secondary, $primary, "--mode", RESOLUTION, "--rate", RATE)
            or workspaces($secondary, $primary)
    } else {
        single($secondary, $primary)
    }
}

sub cmd_workspaces {
    return usage if scalar @_ != 0;
    my ($primary, $secondary, $active) = common();
    return 0 if $active == 1;
    workspaces($primary, $secondary)
}

sub cmd_single {
    my ($primary, $secondary, $active) = common();
    return 0 if $active == 1;
    single($secondary, $primary)
}

sub cmd_dual {
    my ($primary, $secondary, $active) = common();
    return 0 if $active == 2;
    dual($secondary, $primary, "--mode", RESOLUTION, "--rate", RATE)
        or workspaces($secondary, $primary)
}

sub cmd_mirror {
    my ($primary, $secondary, $active) = common();
    return 0 if $active == 2;
    ($primary, $secondary) = ($secondary, $primary);
    exec (
        "xrandr",
        "--output", $primary, "--auto", "--primary",
            "--mode", RESOLUTION, "--rate", RATE,
        "--output", $secondary, "--auto", "--same-as", $primary,
    )
}

sub cmd_tv {
    my ($primary, $secondary, $active) = common();
    return 0 if $active == 2;
    single($secondary, $primary, "--mode", RESOLUTION, "--rate", RATE)
}

sub cmd_120hz {;
    my ($primary, $secondary, $active) = common();
    return 0 if $active == 2;
    single($secondary, $primary, "--mode", RESOLUTION, "--rate", "120")
}

sub cmd_4k {
    my ($primary, $secondary, $active) = common();
    return 0 if $active == 2;
    single($secondary, $primary, "--mode", "4096x2160")
}

sub list {
    my (@ret, $cur);
    for(`xrandr --query`) {
        chomp;
        my @l = split;
        if($l[1] eq "connected") {
            push(@ret, $cur) if scalar keys %$cur;
            $cur = {
                name => $l[0],
                primary => $l[2] eq "primary"
            };
        } elsif(/\*/) {
            $$cur{"active"} = 1;
        }
    }
    push(@ret, $cur) if scalar keys %$cur;
    @ret
}

sub common {
    my @l = list();
    my ($primary, $secondary);
    my $active = 0;
    foreach my $h (@l) {
        $active += ($$h{"active"} or 0);
        if($$h{"primary"}) {
            $primary = $$h{"name"};
        } else {
            $secondary = $$h{"name"};
        }
    }
    ($primary, $secondary, $active)
}

sub single {
    my ($primary, $secondary, @args) = @_;
    exec (
        "xrandr",
        "--output", $secondary, "--off",
        "--output", $primary, "--auto", "--primary", @args,
    )
}

sub dual {
    my ($primary, $secondary, @args) = @_;
    @args = (
        "xrandr",
        "--output", $secondary, "--auto",
        "--output", $primary, "--auto", "--primary", "--above", $secondary,
        @args,
    );
    exec_cmd(@args)
}

sub workspaces {
    my ($primary, $secondary) = @_;
    foreach my $args((
        ["i3-msg", "workspace", "1"],
        ["i3-msg", "move", "workspace", "to", "output", $primary],
        ["i3-msg", "workspace", "2"],
        ["i3-msg", "move", "workspace", "to", "output", $primary],
        ["i3-msg", "workspace", "3"],
        ["i3-msg", "move", "workspace", "to", "output", $secondary],
        ["i3-msg", "workspace", "4"],
        ["i3-msg", "move", "workspace", "to", "output", $primary],
        ["i3-msg", "workspace", "4"],
        ["i3-msg", "workspace", "1"],
    )) {
        return 1 if exec_cmd(@$args)
    }
    0
}

sub exec_cmd {
    my $ret = system(@_);
    print STDERR "system(@_) failed: $!" if $ret;
    $ret
}

exit main(@ARGV);
