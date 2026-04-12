#!/usr/bin/env perl
use 5.036;
use utf8;
use warnings 'all';
use autodie ':all';
utf8::decode($_) for @ARGV;
binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use JSON;
use File::Find;
use File::stat;

system qw#./mtime-restore.pl#;

my $JSON = JSON->new->utf8(1)->pretty(1)->canonical(1);

my @target_dir = qw/drafts logbook posts/;
my $output_file = 'mtime.json';

my %mtime_data;

find(sub {
    return if -d;
    my $file_path = $File::Find::name;
    utf8::decode($file_path);
    my $st = stat($_) or die "cannot stat $file_path: $!";
    $mtime_data{$file_path} = $st->mtime;
}, @target_dir);

open(my $fh, '>', $output_file);
print $fh $JSON->encode(\%mtime_data);
close($fh);
