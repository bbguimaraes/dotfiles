#!/usr/bin/env perl
use strict;
use warnings;

use constant MARKDOWN => ('markdown', '-f', 'fencedcode,footnote,links');

sub main {
    my $cmd = shift;
    if(!$cmd || $cmd eq 'simple') {
        system(MARKDOWN, @_ || ())
    } elsif($cmd eq 'css') {
        css(@_) and system(MARKDOWN, @_ || ())
    } elsif($cmd eq 'hugo') {
        hugo(@_)
    } else {
        usage()
    }
}

sub usage {
    print STDERR <<EOF
Usage: $0 CMD ARGS...

Commands:

    simple ARGS...
    css ARGS...
    hugo ARGS...
EOF
}

sub css {
    print <<'EOF'
<style>
    body {
        max-width: 60ch;
        margin-left: auto;
        margin-right: auto;
    }
    pre {
        overflow: auto;
    }
</style>
EOF
}

sub hugo {
    css(@_) or return;
    open(my $md, '|-', MARKDOWN) or die "failed to execute `markdown`: $!";
    select $md;
    local $/;
    my $s = <STDIN>;
    $s =~ s/^---$ (.|\n)*? ^---$ \n\n//gmx;
    $s =~ s,
        ^\{\{<\s+highlight\s+.*?>\}\}$
        \n*
        ((?:.|\n)*?)
        \n*
        ^\{\{<\s+/\s*highlight\s+.*?>\}\}$
    ,
        format_code($1)
    ,egmx;
    $s =~ s/^\{\{<\s+alert\s+.*?color="warning".*?>\}\}/<b>\nWarning: /gm;
    $s =~ s/^\{\{<\s+alert\s+.*?>\}\}/<b>\nNote: /gm;
    $s =~ s,^\{\{<\s+/\s+alert\s+.*>\}\},</b>,gm;
    $s =~ s/\{\{<\s+(?:rel)?ref "([^"]+?)"\s+>\}\}/$1/gm;
    print $s;
    close $md or die "failed to close `markdown` pipe: $!";
    0
}

sub format_code {
    $_ = shift;
    s/^/    /mg;
    $_
}

exit main @ARGV
