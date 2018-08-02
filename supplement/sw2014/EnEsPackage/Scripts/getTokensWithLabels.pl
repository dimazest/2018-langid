#!/usr/bin/perl

use strict;
use warnings;
use v5.10.1;

my ($lab,$tok,$out) = @ARGV;
open(my $labHan,'<:encoding(utf8)',$lab) or die;
open(my $tokHan,'<:encoding(utf8)',$tok) or die;
open(my $outHan,'>:encoding(utf8)',$out) or die;

binmode STDOUT, ':utf8';

my @labParts;
my @tokParts;
my %hash;
while(<$labHan>) {
    @labParts = split(/\t/,$_);
    $hash{$labParts[0]}{$labParts[2]} = $labParts[4];
}
while(<$tokHan>) {
    @tokParts = split(/\t/,$_);
    chomp $_;
    chomp $hash{$tokParts[0]}{$tokParts[2]};
    print $outHan $_."\t$hash{$tokParts[0]}{$tokParts[2]}\n";
}

close($labHan) or die;
close($tokHan) or die;
close($outHan) or die;