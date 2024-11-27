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
my @notes;
for my $i (1 .. @$phrase) {
    push @notes, $d->note->roll;
}
# print ddc \@notes;
my @x;
for my $i (0 .. $#$phrase) {
    my $x = $notes[$i];
    if ($chords[$i] ne 'custom' && $qualities[$i] eq 'm7b5') {
        $x .= " $qualities[$i]";
    }
    else {
        if ($chords[$i] eq 'custom') {
            my @custom;
            my $n = unique_note([ $notes[$i] ], \@notes);
            push @custom, $n;
            push @custom, unique_note([ $notes[$i], $n ], \@notes);
            $x .= " @custom $qualities[$i]";
        }
        else {
            $x .= " $chords[$i] $qualities[$i]";
        }
    }
    $x .= " | $phrase->[$i]";
    push @x, $x;
}
print ddc \@x;


sub unique_note {
    my ($excludes, $notes) = @_;
    my $note = '';
    while (!$note || grep { $_ eq $note } @$excludes) {
        $note = $notes->[ int rand @$notes ];
    }
    return $note;
}
