#!perl -w
use strict;
use Test::More;

use App::dayonetools;

subtest '--date' => sub {
    subtest '-d with no value' => sub {
        my $app = App::dayonetools->new('-d');
        isnt $app->{getopt_failed}, undef, 'failed';
        is   $app->{date},          undef, 'no date';
    };

    subtest '--date with no value' => sub {
        my $app = App::dayonetools->new('--date');
        isnt $app->{getopt_failed}, undef, 'failed';
        is   $app->{date},          undef, 'no date';
    };

    subtest '-d with invalid date' => sub {
        my $app = App::dayonetools->new('-d', '2012-03-00');
        isnt $app->{getopt_failed}, undef, 'failed';
        is   $app->{date},          undef, 'no date';
    };

    subtest '-date with invalid date' => sub {
        my $app = App::dayonetools->new('--date=2012-03-32');
        isnt $app->{getopt_failed}, undef, 'failed';
        is   $app->{date},          undef, 'no date';
    };

    subtest 'japanese format' => sub {
        my $app = App::dayonetools->new('-d', '2012年 3月22日 木曜日 15時49分10秒 JST');
        isnt $app->{getopt_failed}, undef, 'failed';
        is   $app->{date},          undef, 'no date';
    };

    subtest 'english format' => sub {
        my $app = App::dayonetools->new('-d', 'Thu Mar 22 12:34:56 JST 2012');
        is $app->{getopt_failed}, undef, 'success';
        is $app->{date},          '2012-03-22T03:34:56Z', 'date';
    };

    subtest 'ISO 8601 format' => sub {
        my $app = App::dayonetools->new('--date=2012-03-22T12:34:56+0900');
        is $app->{getopt_failed}, undef, 'success';
        is $app->{date},          '2012-03-22T03:34:56Z', 'date';
    };

    subtest 'epoch time' => sub {
        my $app = App::dayonetools->new('--date', '1332387296');
        is $app->{getopt_failed}, undef, 'success';
        is $app->{date},          '2012-03-22T03:34:56Z', 'date';
    };
};

subtest '--star' => sub {
    subtest 'no args' => sub {
        my $app = App::dayonetools->new();
        is   $app->{star}, undef, 'no star';
    };

    subtest '-s' => sub {
        my $app = App::dayonetools->new('-s');
        isnt $app->{star}, undef, 'star';
    };

    subtest '--star' => sub {
        my $app = App::dayonetools->new('--star');
        isnt $app->{star}, undef, 'star';
    };
};

done_testing;
