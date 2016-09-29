#!/usr/bin/env perl
use strict; use warnings;
use feature 'say';

my   $fulldur=1.5*3;
my $catch1dur=1.5*2;
my $catch2dur=1.5;

my %dur= (
 fix           => 1.5,
 neutral       => $fulldur,
 reward        => $fulldur,
 neutralCatch1 => $catch1dur,
 neutralCatch2 => $catch2dur,
 rewardCatch1  => $catch1dur,
 rewardCatch2  => $catch2dur,
);

my $totaltime=0;

while(<STDIN>) {
 chomp while chomp;
 s/\r//g;
 next unless m/Procedure: (fix|(reward|neutral)([0-9]+|Catch[12]))/;
 my $trialtype = $1;
 $trialtype =~ s/\d{3}$//;
 my $thisdur   = $dur{$trialtype};
 #say join "\t",$totaltime,$thisdur,$trialtype;
 say join "\t",$totaltime,$thisdur,$trialtype if $trialtype =~ m/catch/i;
 $totaltime+=$thisdur;
}
