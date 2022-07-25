#!/usr/bin/env perl
use strict;
use warnings;

use IO::Handle;
use POSIX ":sys_wait_h";

use constant load_event => 0;
use constant cmd_started_event => 1;
use constant cmd_done_event => 2;
use constant signal_event => 3;

use constant min_load => 2;
use constant max_load => 4;

use constant state_cont => 0;
use constant state_stop => 1;

sub main {
    my ($host, @cmd) = @_;
    pipe(my $event_r, my $event_w) or die "pipe: $!";
    $event_w->autoflush();
    my $load_pid = fork();
    if(!$load_pid) {
        close $event_r;
        exec_load($event_w, $host);
    };
    my $cmd_pid = fork();
    if(!$cmd_pid) {
        close $event_r;
        exec_cmd($event_w, @cmd);
    };
    $SIG{INT} = sub { print $event_w signal_event, "\n" };
    my $ret = process_events($event_r);
    kill_pid('INT', $load_pid) if !$ret;
    waitpid($load_pid, 0);
    waitpid($cmd_pid, 0);
    $ret
}

sub exec_load {
    use constant load_cmd =>
        qw|'while :; do read x _ < /proc/loadavg; echo $x; sleep 5; done'|;
    my ($event_w, $host) = @_;
    open(my $p, '-|', 'ssh', $host, 'bash', '-c', load_cmd)
        or die "popen: $!\n";
    while(<$p>) {
        @_ = split;
        printf $event_w "%d %f\n", load_event, shift or die "printf: $!";
    }
    close $p;
    exit(0);
}

sub exec_cmd {
    my ($event_w, @cmd) = @_;
    my $pid = -1;
    $SIG{INT} = 'IGNORE';
    $pid = fork();
    if(!$pid) {
        $SIG{INT} = 'DEFAULT';
        $SIG{CHLD} = 'DEFAULT';
        exec @cmd or die "exec: $!";
    }
    printf $event_w "%d %d\n", cmd_started_event, $pid;
    waitpid($pid, 0) > 0 or die "waitpid: $!";
    printf $event_w "%d %d\n", cmd_done_event, $?;
    exit(0);
}

sub process_events {
    my ($event_r) = @_;
    my ($ret, $state, $cmd_pid) = (0, state_cont, -1);
    while(my $event = <$event_r>) {
        my @fields = split(/ /, $event);
        if($fields[0] == load_event) {
            $state = process_load($state, $cmd_pid, $fields[1]);
        } elsif($fields[0] == cmd_started_event) {
            $cmd_pid = $fields[1] + 0;
        } elsif($fields[0] == cmd_done_event) {
            return $fields[1];
        } elsif($fields[0] == signal_event) {
            kill_pid('CONT', $cmd_pid);
            $ret = 130;
        }
    }
}

sub process_load {
    my ($state, $cmd_pid, $load) = @_;
    if($state == state_cont) {
        if(max_load < $load) {
            kill_pid('STOP', $cmd_pid);
            return state_stop;
        }
    } elsif($state == state_stop) {
        if($load < min_load) {
            kill_pid('CONT', $cmd_pid);
            return state_cont;
        }
    }
    $state;
}

sub kill_pid {
    my ($sig, $pid) = @_;
    kill($sig, $pid) == 1 or die "kill($sig, $pid): $!";
}

exit main(@ARGV);
