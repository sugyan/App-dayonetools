#!/usr/bin/env perl
use strict;
use warnings;

use Config::Pit;
use Email::Sender::Simple 'sendmail';
use Email::MIME;
use Encode;
use File::HomeDir;
use List::Util 'shuffle';
use Log::Minimal;
use Mac::PropertyList 'parse_plist_file';
use Path::Class 'dir';
use Time::Piece;
use Time::Seconds;
use Try::Tiny;

my $mail = pit_get('dayone.mail', require => +{
    address => 'mail address',
});
my @contents = ({
    ago => ONE_DAY,
    num => 20,
}, {
    ago => ONE_WEEK,
    num => 10,
}, {
    ago => ONE_WEEK * 4,
    num => 5,
});

my $body = '';
{
    my $dict = +{};
    my $dir = dir(File::HomeDir->my_home)->subdir('Dropbox', 'Journal.dayone', 'entries');
    while (my $file = $dir->next) {
        next if $file->is_dir;

        infof('read: %s', $file->basename);
        my $parsed = parse_plist_file($file->stringify);
        my $date = localtime(Time::Piece->strptime($parsed->value('Creation Date'), '%Y-%m-%dT%H:%M:%SZ'));
        $date = $date + $date->tzoffset;
        push @{ $dict->{$date->ymd} }, +{
            time => $date->hms,
            text => $parsed->value('Entry Text') =~ s/\n//gr,
        };
    }

    for my $content (@contents) {
        my $ymd = (localtime() - $content->{ago})->ymd;
        my @entries = do {
            my @array = @{ $dict->{$ymd} || [] };
            if (my $num = $content->{num}) {
                @array = shuffle @array;
                @array = splice(@array, 0, $num);
            }
            sort { $a->{time} cmp $b->{time} } @array;
        };
        if (@entries) {
            $body .= "${ymd}:<br>";
            $body .= join "<br>", map {
                sprintf '%s: %s', $_->{time}, $_->{text};
            } @entries;
            $body .= "<br><br>";
        }
    }
}
if ($body) {
    for my $address (split /,/, $mail->{address}) {
        send_mail($address, decode_utf8($body));
    }
}

sub send_mail {
    my ($to, $body) = @_;

    my $email = Email::MIME->create(
        attributes => {
            content_type => 'text/html',
            encoding     => 'base64',
            charset      => 'ISO-2022-JP',
        },
        header => [
            From    => 'noreply@cron.dayonetools.com',
            To      => $to,
            Subject => 'DayOne archives',
        ],
        body => encode('iso-2022-jp', $body),
    );
    try {
        sendmail($email);
        infof('sendmail success: to %s', $to);
    } catch {
        critf('sendmail failed: to %s, %s', $to, $_);
    };
}
