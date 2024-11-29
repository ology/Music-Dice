#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper::Compact qw(ddc);
use Getopt::Long qw(GetOptions);
use MIDI::Util qw(setup_score midi_format);
use Music::Chord::Note ();
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

my $score = setup_score();

my $cn = Music::Chord::Note->new;

my $phrase = $d->rhythmic_phrase->roll;
# print ddc $phrase;
my @notes = map { $d->note->roll } 1 .. @$phrase;
# print ddc \@notes;
my @triads = map { $d->chord_triad->roll } 1 .. @$phrase;
# print ddc \@triads;
my @named;
my @to_play;
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
    push @to_play, [ $phrase->[$i], "$notes[$i]$quality" ];
}
print join("\n", @named), "\n";
# print ddc \@to_play;

for my $spec (@to_play) {
    my @tones = $cn->chord($spec->[1]);
    $score->n($spec->[0], midi_format(@tones))
}

$score->write_score("$0.mid");

