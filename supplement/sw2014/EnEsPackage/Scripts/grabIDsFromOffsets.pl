#!/usr/bin/perl

# Elizabeth Blair

use strict;
use warnings;
use v5.10.1;

my ($in,$out) = @ARGV;

open(my $inHan,'<:encoding(utf8)',$in) or die;
open(my $outHan,'>:encoding(utf8)',$out) or die;

my %ids;
while(<$inHan>)
{
	chomp;
	if ($_ =~ /^\s*$/) { next; }
	my @parts = split(/\t/,$_);
	$ids{$parts[0]} = 1;
}

foreach(sort { $a <=> $b } keys(%ids))
{
	say $outHan $_;
}

close($inHan) or die;
close($outHan) or die;
