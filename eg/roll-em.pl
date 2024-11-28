#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper::Compact qw(ddc);
use Getopt::Long qw(GetOptions);
use Music::Dice ();

my %opt = (
    tonic => 'C',
    scale => 'major',
);
GetOptions(\%opt,
    'tonic=s',
    'scale=s',
);

my $d = Music::Dice->new(
    scale_note => $opt{tonic},
    scale_name => $opt{scale},
);

my $phrase = $d->rhythmic_phrase->roll;
# print ddc $phrase;
my @notes = map { $d->note->roll } 1 .. @$phrase;
# print ddc \@notes;
my @triads = map { $d->chord_triad->roll } 1 .. @$phrase;
# print ddc \@triads;
my @qualities = map { $d->chord_quality->roll } 1 .. @$phrase; 
# print ddc \@qualities;
my @named;
for my $i (0 .. $#$phrase) {
    my $named = $i + 1 . ". $notes[$i]";
    if ($qualities[$i] ne 'm7b5') {
        if ($triads[$i] eq 'custom') {
            my @custom;
            my $n = $d->unique_note([ $notes[$i] ]);
            push @custom, $n;
            push @custom, $d->unique_note([ $notes[$i], $n ]);
            $named .= " @custom";
        }
        else {
            $named .= " $triads[$i]";
        }
    }
    $named .= " $qualities[$i] | $phrase->[$i]";
    push @named, $named;
}
# print ddc \@named;
print join("\n", @named), "\n";
