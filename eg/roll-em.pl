#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper::Compact qw(ddc);
use Getopt::Long qw(GetOptions);
use Music::Dice ();

my %opt = (
    tonic     => 'C',
    scale     => 'major',
    # flats     => 1,
    # beats     => 4,
    # pool      => 'wn dhn hn dqn qn den en',
    # notes     => 'C D E F G A B',
    # intervals => '2 2 1 2 2 2 1',
    # triads    => 'major minor diminished',
    # qualities => 'sus4 b5 #5 6 69 maj7 minmaj7 7 min7 add9 b9 9 #9 b11 11 #11 b13 13 #13 ø',
    # voices    => '3 4',
);
GetOptions(\%opt,
    'tonic=s',
    'scale=s',
    # 'flats=i',
    # 'beats=i',
    # 'pool=s',
    # 'notes=s',
    # 'intervals=s',
    # 'triads=s',
    # 'qualities=s',
    # 'voices=s',
);


my $d = Music::Dice->new(
    scale_note   => $opt{tonic},
    scale_name   => $opt{scale},
    # chord_triads => [ split ' ', $opt{triads} ],
);

my $phrase = $d->rhythmic_phrase->roll;
# print ddc $phrase;
my @notes;
for my $i (1 .. @$phrase) {
    push @notes, $d->note->roll;
}
# print ddc \@notes;
my @chords;
for my $i (1 .. @$phrase) {
    push @chords, $d->chord_triad->roll;
}
# print ddc \@chords;
my @qualities;
for my $i (1 .. @$phrase) {
    push @qualities, $d->chord_quality->roll;
}
# print ddc \@qualities;
my @named;
for my $i (0 .. $#$phrase) {
    my $named = $notes[$i];
    if ($qualities[$i] ne 'm7b5') {
        if ($chords[$i] eq 'custom') {
            my @custom;
            my $n = $d->unique_note([ $notes[$i] ]);
            push @custom, $n;
            push @custom, $d->unique_note([ $notes[$i], $n ]);
            $named .= " @custom";
        }
        else {
            $named .= " $chords[$i]";
        }
    }
    $named .= " $qualities[$i] | $phrase->[$i]";
    push @named, $named;
}
print ddc \@named;
