#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper::Compact qw(ddc);
use List::Util qw(uniq);
use MIDI::Util qw(setup_score midi_format play_fluidsynth);
use Music::Dice ();
use Term::Choose ();

my $max = 4;
my $choices = [1 .. 4];

my @chords;

for my $i (1 .. $max) {
    my $prompt = "How many notes in chord $i?";
    my $tc = Term::Choose->new({ prompt => $prompt });
    my $n = $tc->choose($choices);

    my $d = Music::Dice->new(
        scale_note => 'C',
        scale_name => 'major',
    );

    my @notes;
    for my $i (1 .. $n) {
        my $note = $d->note->roll;
        push @notes, $note;
    }
    my @uniq = uniq(@notes);
    print ddc(\@uniq);
    push @chords, \@uniq;
}

my $score = setup_score(
    patch => 4,
    bpm   => 100,
);

$score->n('wn', midi_format(@$_)) for @chords;

play_fluidsynth($score, "$0.mid", $ENV{HOME} . '/Music/soundfont/FluidR3_GM.sf2');
