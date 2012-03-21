package App::dayonetools;
use 5.014;
use strict;
use warnings;

use Data::UUID;
use Date::Parse 'str2time';
use File::HomeDir;
use Text::Xslate;
use Time::Piece;
use Try::Tiny;

our $VERSION = '0.01';

use Getopt::Long ();

sub getopt_spec {
    return(
        'version',
        '--help|h',
        '--date|d=s',
        '--star|s',
    );
}

sub getopt_parser {
    return Getopt::Long::Parser->new(
        config => [qw(
            no_ignore_case
            bundling
            no_auto_abbrev
        )],
    );
}

sub appname {
    my($self) = @_;
    require File::Basename;
    return File::Basename::basename($0);
}

sub new {
    my $class = shift;
    local @ARGV = @_;

    my %opts;
    my $success = $class->getopt_parser->getoptions(
        \%opts,
        $class->getopt_spec());

    if (my $date = delete $opts{date}) {
        # convert to epoch time
        $date = str2time($date) if $date =~ /[^\d]/;
        if ($date) {
            $opts{date} = gmtime($date)->strftime('%Y-%m-%dT%H:%M:%SZ');
        }
        else {
            $success = undef;
        }
    }

    if (!$success) {
        $opts{help}++;
        $opts{getopt_failed}++;
    }

    $opts{argv} = \@ARGV;

    return bless \%opts, $class;
}

sub run {
    my $self = shift;

    if($self->{help}) {
        $self->do_help();
    }
    elsif($self->{version}) {
        $self->do_version();
    }
    else {
        $self->dispatch(@ARGV);
    }

    return;
}

sub dispatch {
    my($self, @args) = @_;

    # read from stdin
    my $text = do {
        local $/ = undef;
        <STDIN>;
    };
    try {
        my $path = $self->save_journal($text);
        print "$path created\n";
    } catch {
        warn "fail: $_";
    };

    return;
}

sub do_help {
    my($self) = @_;
    if($self->{getopt_failed}) {
        die $self->help_message();
    }
    else {
        print $self->help_message();
    }
}

sub do_version {
    my($self) = @_;
    print $self->version_message();
}

sub help_message {
    my($self) = @_;
    require Pod::Usage;

    open my $fh, '>', \my $buffer;
    Pod::Usage::pod2usage(
        -message => $self->version_message(),
        -exitval => 'noexit',
        -output  => $fh,
        -input   => __FILE__,
    );
    close $fh;
    return $buffer;
}

sub version_message {
    my($self) = @_;

    require Config;
    return sprintf "%s\n" . "\t%s/%s\n" . "\tperl/%vd on %s\n",
        $self->appname(), ref($self), $VERSION,
        $^V, $Config::Config{archname};
}

sub save_journal {
    my ($self, $text) = @_;

    my $uuid  = Data::UUID->new->create_str =~ s/-//gr;
    my $entry = +{
        date => $self->{date} || gmtime->strftime('%Y-%m-%dT%H:%M:%SZ'),
        text => $text,
        star => $self->{star} ? 'true' : 'false',
        uuid => $uuid,
    };
    my $path = sprintf '%s/Dropbox/Journal.dayone/entries/%s.doentry', (
        File::HomeDir->my_home,
        $entry->{uuid},
    );

    open my $plist, ">", $path or die $!;
    print $plist Text::Xslate->new->render_string($self->journal_template, $entry);
    close $plist;

    return $path;
}

sub journal_template {
    my ($self) = @_;
    return <<'__TEMPLATE__'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Creation Date</key>
	<date><: $date :></date>
	<key>Entry Text</key>
	<string><: $text :></string>
	<key>Starred</key>
	<<: $star :>/>
	<key>UUID</key>
	<string><: $uuid :></string>
</dict>
</plist>
__TEMPLATE__
}

1;
__END__

=head1 NAME

App::dayonetools - Perl extention to do something

=head1 VERSION

This document describes App::dayonetools version 0.01.

=head1 SYNOPSIS

    $ dayone [-d=<date>] [-s] [-h]

=head1 OPTIONS

=over

=item -h, --help

Show this information.

=item -d, --date

New date of the entry.

=item -s, --star

New starred value.

=back

=head1 DESCRIPTION

# TODO

=head1 INTERFACE

=head2 Functions

=head3 C<< save_journal($text) >>

# TODO

=head1 DEPENDENCIES

Perl 5.14.0 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

sugyan E<lt>sugi1982@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, sugyan. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
