#!/usr/bin/env perl
use strict;
use warnings;

use File::HomeDir;
use File::Copy;
use Log::Minimal;
use Mac::PropertyList 'parse_plist_file';
use Path::Class 'dir';
use Time::Piece;
use Time::Seconds;

my $threashold = ONE_MONTH;

my $dir = dir(File::HomeDir->my_home)->subdir('Dropbox', 'Journal.dayone', 'entries');
while (my $file = $dir->next) {
    next if $file->is_dir;

    my $parsed = parse_plist_file($file->stringify);
    my $date = localtime(Time::Piece->strptime($parsed->value('Creation Date'), '%Y-%m-%dT%H:%M:%SZ'));
    $date = $date + $date->tzoffset;
    if ($date < localtime() - $threashold) {
        my $des = $dir->subdir('..', 'archives', $date->year, sprintf('%02d', $date->mon));
        $des->mkpath;
        if (move($file->stringify, $des)) {
            infof('%s moved to %s.', $file->basename, $des);
        }
        else {
            critf('move failed. %s', $file);
        }
    }
}
