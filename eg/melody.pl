#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper::Compact qw(ddc);
use Getopt::Long qw(GetOptions);
use MIDI::Util qw(setup_score set_chan_patch midi_format);
use Music::Chord::Note ();
use Music::Dice ();
use Music::Scales qw(get_scale_notes);

my %opt = (
    tonic  => 'C',
    scale  => 'major',
    octave => 4,
);
GetOptions(\%opt,
    'tonic=s',
    'scale=s',
    'octave=i',
);

my $d = Music::Dice->new(
    scale_note => $opt{tonic},
    scale_name => $opt{scale},
);

my $score = setup_score(bpm => 80);

my $cn = Music::Chord::Note->new;

my $c_phrase = $d->rhythmic_phrase->roll; # harmony
my $m_phrase = $d->rhythmic_phrase->roll; # melody
my $tonic    = $d->note->roll;
my $mode     = $d->mode->roll;
my @scale    = get_scale_notes($tonic, $mode);
print "$tonic $mode: @scale\n";

my $x = Music::Dice->new(
    scale_note => $tonic,
    scale_name => $mode,
);

$score->synch(
    \&harmony,
    \&melody,
    \&bass,
) for 1 .. 8;
$score->write_score("$0.mid");

sub harmony {
    set_chan_patch($score, 0, 4);
    for my $i (0 .. $#$c_phrase) {
        my ($degree, $triad) = $d->mode_degree_triad_roll($mode);
        my $index = $degree - 1;
        my $type = $triad eq 'diminished' ? 'dim' : $triad eq 'minor' ? 'm' : '';
        my $chord = "$scale[$index]$type";
        print "Degree: $degree => $chord | $c_phrase->[$i]\n";
        my @tones = $cn->chord_with_octave($chord, $opt{octave});
        $score->n($c_phrase->[$i], midi_format(@tones))
    }
}

sub melody {
    set_chan_patch($score, 1, 5);
    my $x = Music::Dice->new(
        scale_note => $tonic,
        scale_name => $mode,
    );
    for my $i (0 .. $#$m_phrase) {
        my $note = $x->note->roll . ($opt{octave} + 1);
        $score->n($m_phrase->[$i], midi_format($note))
    }
}

sub bass {
    set_chan_patch($score, 2, 33);
    for my $i (0 .. $#$m_phrase) {
        my $note = $x->note->roll . ($opt{octave} - 1);
        $score->n($m_phrase->[$i], midi_format($note))
    }
}
