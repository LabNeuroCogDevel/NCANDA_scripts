#!/usr/bin/env perl
use strict; use warnings;
use feature 'say';

#20161019 -- task synced with scanner than 6 second fixation cross then 'Procedure' and trigger onset
#            so start at 6 seconds then count up
my $starttime=6; 

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

my $totaltime=$starttime;
my $trial=0;

while(<STDIN>) {
 chomp while chomp;
 s/\r//g;
 next unless m/Procedure: (fix|(reward|neutral)([0-9]+|Catch[12]))/;
 my $trialtype = $1;
 $trialtype =~ s/\d{3}$//;

 $trial++ if $trialtype =~ m/(reward|neutral)$/;

 my $thisdur   = $dur{$trialtype};
 say join "\t",$totaltime,$trial,$thisdur,$trialtype if $trialtype !~ /fix/;
 #say join "\t",$totaltime,$thisdur,$trialtype if $trialtype =~ m/catch/i;
 $totaltime+=$thisdur;
}

print STDERR "$totaltime\n";

#### EXAMPLE USAGE
# cd ~/Documents/Research/NCANDA/script
# for  r in {1..4}; do ./timing_from_eprimelog.pl <  /Users/ncanda/Documents/Research/NCANDA/data_eye/A095/*_y2_Eprime_run$r.txt|grep catch |sed  "s/^/$r	/"; done > timetest/timetest_A095_y2

# or for 1d file
# for  r in {1..4}; do ./timing_from_eprimelog.pl <  /Users/ncanda/Documents/Research/NCANDA/data_eye/A095/*_y2_Eprime_run$r.txt|awk  '(/catch/){print $1":"$2}'|tr '\n' ' '; echo; done

# and if you wanted only long trials
# | perl -slane 'print join " ", grep {m/:3/} @F'  

