#!/usr/bin/env perl
use strict;
use warnings;

use constant MARKDOWN => (
    'markdown', '-f', 'autolink,fencedcode,footnote,links',
);

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
Usage: $0 CMD ARG...

Commands:

    simple ARG...
    css ARG...
    hugo ARG...
EOF
}

sub css {
    print <<'EOF'
<style>
    body {
        max-width: 60ch;
        margin-left: auto;
        margin-right: auto;
        background-color: black;
        color: white;
    }
    body, a {
        color: #a0a0a0;
    }
    a:visited {
        color: #606060;
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
    $s =~ s/
        ^(\ *)\{\{<\s+highlight\s+.*?>\}\}$
        \n*
        ((?:.|\n)*?)
        \n*
        ^\ *\{\{<\s+\/\s*highlight\s+.*?>\}\}$
    /
        format_code($1, $2)
    /egmx;
    $s =~ s/^\{\{<\s+alert\s+.*?color="warning".*?>\}\}/<b>\nWarning: /gm;
    $s =~ s/^\{\{<\s+alert\s+.*?>\}\}/<b>\nNote: /gm;
    $s =~ s,^\{\{<\s+/\s*alert\s+.*>\}\},</b>,gm;
    $s =~ s/\{\{<\s+(?:rel)?ref "([^"]+?)"\s+>\}\}/$1/gm;
    print $s;
    close $md or die "failed to close `markdown` pipe: $!";
    0
}

sub format_code {
    my ($pre, $text) = @_;
    $text =~ s/^/$pre    /mg;
    $text
}

exit main @ARGV
