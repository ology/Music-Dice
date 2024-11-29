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
my @named;
for my $i (0 .. $#$phrase) {
    my $named = $i + 1 . ". $notes[$i]";
    my $quality = '';
    if ($triads[$i] eq 'major') {
        $quality = $d->chord_quality_major->roll;
    }
    elsif ($triads[$i] eq 'minor') {
        $quality = $d->chord_quality_minor->roll;
    }
    elsif ($triads[$i] eq 'diminished') {
        $quality = $d->chord_quality_diminished->roll;
    }
    elsif ($triads[$i] eq 'augmented') {
        $quality = $d->chord_quality_augmented->roll;
    }
    elsif ($triads[$i] eq 'custom') {
        my @custom;
        my $item = $d->unique_item([ $notes[$i] ]);
        push @custom, $item;
        push @custom, $d->unique_item([ $notes[$i], $item ]);
        $named .= " @custom";
    }
    $named .= "$quality | $phrase->[$i]";
    push @named, $named;
}
# print ddc \@named;
print join("\n", @named), "\n";
