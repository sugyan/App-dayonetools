#!/usr/bin/env perl
use strict;
use warnings;

use FindBin::libs;
use App::dayonetools;

use AnyEvent::Twitter::Stream;
use Config::Pit;
use Encode 'encode_utf8';
use Log::Minimal;
use Net::Twitter::Lite;
use Time::Piece;
use Try::Tiny;

my $config = pit_get('twitter.com', require => +{
    consumer_key        => 'consumer key',
    consumer_secret     => 'consumer secret',
    access_token        => 'access token',
    access_token_secret => 'access token secret',
});
my $profile = Net::Twitter::Lite->new(%$config)->verify_credentials;

my $cv = AE::cv;
my $listener = AnyEvent::Twitter::Stream->new(
    consumer_key    => $config->{consumer_key},
    consumer_secret => $config->{consumer_secret},
    token           => $config->{access_token},
    token_secret    => $config->{access_token_secret},
    method => 'filter',
    follow => $profile->{id_str},
    on_tweet => sub {
        my $tweet = shift;

        return unless $tweet->{user}{id_str} eq $profile->{id_str};
        return if     $tweet->{in_reply_to_user_id_str};

        try {
            my $date = localtime(
                Time::Piece->strptime($tweet->{created_at}, '%a %b %d %H:%M:%S %z %Y'),
            )->strftime('%Y-%m-%dT%H:%M:%SZ');
            my $text = sprintf '%s / <a href="https://twitter.com/#!/%s/status/%s">tweet</a> from %s', (
                $tweet->{text},
                $tweet->{retweeted_status}
                    ? $tweet->{retweeted_status}{user}{screen_name}
                    : $tweet->{user}{screen_name},
                $tweet->{id_str},
                $tweet->{source},
            );
            my $path = App::dayonetools->new('-d', $date)->save_journal(encode_utf8($text));
            infof('created: %s', $path);
        } catch {
            critf($_);
        };
    },
    on_connect => sub {
        infof("start following @%s's tweets.", $profile->{screen_name});
    },
    on_error => sub {
        critf('on_error');
        $cv->send;
    },
    on_eof => sub {
        warnf('on_eof');
        $cv->send;
    },
    on_keepalive => sub {
        infof('on_keepalive');
    },
);
$cv->recv;
