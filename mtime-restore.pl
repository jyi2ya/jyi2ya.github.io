#!/usr/bin/env perl
use 5.036;
use utf8;
use warnings 'all';
use autodie ':all';
utf8::decode($_) for @ARGV;
binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use JSON qw/decode_json/;

my $mtime_data = do {
    open(my $fh, '<', 'mtime.json');
    my $json = do { local $/; <$fh> };
    close($fh);
    decode_json($json);
};

foreach my $file_path (keys %$mtime_data) {
    my $mtime = $mtime_data->{$file_path};
    unless (-e $file_path) {
        warn "file '$file_path' not exist, skipping";
        next;
    }
    unless (utime($mtime, $mtime, $file_path)) {
        warn "cannot set mtime for '$file_path': $!\n";
    }
}
