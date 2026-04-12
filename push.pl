#!/usr/bin/env perl
use 5.036;
use utf8;
use warnings 'all';
use autodie ':all';
utf8::decode($_) for @ARGV;
binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

system qw#./mtime-save.pl#;
system qw/git add --all/;
system qw/git commit/;
system qw/git push/;
