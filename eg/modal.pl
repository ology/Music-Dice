#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper::Compact qw(ddc);
use Getopt::Long qw(GetOptions);
use MIDI::Util qw(setup_score midi_format);
use Music::Chord::Note ();
use Music::Dice ();
use Music::Scales qw(get_scale_notes);

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

my $score = setup_score(patch => 4);

my $cn = Music::Chord::Note->new;

my $phrase = $d->rhythmic_phrase->roll;
my $note   = $d->note->roll;
my $mode   = $d->mode->roll;
my @scale  = get_scale_notes($note, $mode);
print "@scale\n";

for my $i (0 .. $#$phrase) {
    my ($degree, $triad) = $d->mode_degree_triad_roll($mode);
    my $index = $degree - 1;
    my $type = $triad eq 'diminished' ? 'dim' : $triad eq 'minor' ? 'm' : '';
    print "$note $mode: $degree => $scale[$index]$type\n";
    my @tones = $cn->chord_with_octave("$scale[$index]$type", 4);
    $score->n($phrase->[$i], midi_format(@tones))
}
$score->write_score("$0.mid");
