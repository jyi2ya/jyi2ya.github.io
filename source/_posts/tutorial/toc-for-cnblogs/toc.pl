use v5.12;
use utf8;
use open ':utf8';
use open ':std', ':utf8';

my @title_count;
say "# 目录";
while (<>) {
    next if /^```/ ... /^```/;
    if (/^(#+)\s*(.*?)\s*$/) {
        my ($level, $title) = (length($1), $2);
        my $indent = "  " x $level;
        my $url = $title;
        $url =~ s/[^_[:^punct:]]//g;
        $url =~ s/[[:space:]]/-/g;
        $url = lc $url;
        @title_count = splice @title_count, 0, $level;
        $title_count[$level - 1] += 1;
        my $index = join ".", @title_count;
        say "$indent+ $index [$title](#$url)";
    }
}
say "";
