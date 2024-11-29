package Music::Dice;

# ABSTRACT: Define and roll musical dice

our $VERSION = '0.0100';

use Moo;
use strictures 2;
use Carp qw(croak);
use Games::Dice::Advanced ();
use List::Util::WeightedChoice qw(choose_weighted);
use MIDI::Util qw(midi_dump);
use Music::Duration::Partition ();
use Music::Scales qw(get_scale_notes get_scale_nums);
use Types::Standard qw(ArrayRef Int Str);
use namespace::clean;

=encoding utf8

=head1 SYNOPSIS

  use Music::Dice ();
  my $d = Music::Dice->new;
  # basics
  my $roll = $d->note->roll;
  $roll = $d->interval->roll;
  $roll = $d->note_chromatic->roll;
  $roll = $d->interval_chromatic->roll;
  $roll = $d->note_major->roll;
  $roll = $d->interval_major->roll;
  $roll = $d->note_minor->roll;
  $roll = $d->interval_minor->roll;
  $roll = $d->chord_triad->roll;
  $roll = $d->chord_quality_major->roll;
  $roll = $d->chord_quality_major_7->roll;
  $roll = $d->chord_quality_minor->roll;
  $roll = $d->chord_quality_minor_7->roll;
  $roll = $d->chord_quality_diminished->roll;
  $roll = $d->chord_quality_augmented->roll;
  $roll = $d->chord_quality_augmented_7->roll;
  $roll = $d->mode->roll;
  $roll = $d->tonnetz->roll;
  $roll = $d->tonnetz_7->roll;
  $roll = $d->rhythm->roll;
  $roll = $d->rhythmic_phrase->roll;
  # gameplay
  $roll = $d->chord_voices_nums->roll;
  $roll = $d->remove_chord_num->roll;
  $roll = $d->rhythmic_phrase_constrained->roll;

  # for example:
  my $phrase = $d->rhythmic_phrase->roll;
  my @notes  = map { $d->note->roll } 1 .. @$phrase;
  my @triads = map { $d->chord_triad->roll } 1 .. @$phrase;
  my @named  = map { "$notes[$_] $triads[$_] | $phrase->[$_]" } 0 .. $#$phrase;
  print join("\n", @named), "\n";

=head1 DESCRIPTION

C<Music::Dice> defines and rolls musical dice.

=head1 ATTRIBUTES

=head2 scale_note

  $note = $md->scale_note;

The (uppercase) tonic of the scale.

Default: C<C>

=cut

has scale_note => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid note name" unless $_[0] =~ /^[A-G][b#]?$/ },
    default => sub { 'C' },
);

=head2 scale_name

  $note = $md->scale_name;

The (lowercase) name of the scale.

Default: C<chromatic>

=cut

has scale_name => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid scale name" unless $_[0] =~ /^[a-z]+$/ },
    default => sub { 'chromatic' },
);

=head2 flats

  $flats = $md->flats;

Use either flats or sharps in the returned notes.

Default: C<1> (use flats not sharps)

=cut

has flats => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 1 },
);

=head2 beats

  $beats = $md->beats;

The number of quarter-note beats in a rhythmic phrase.

Default: C<4> (standard measure)

=cut

has beats => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a positive number" unless $_[0] =~ /^[1-9]\d*$/ },
    default => sub { 4 },
);

=head2 pool

  $pool = $md->pool;

The pool of durations in a rhythmic phrase.

Default: C<[wn dhn hn dqn qn den en]>

The keyword C<all> may also be given, which will use the keys of the
C<MIDI::Simple::Length> hash (all the known MIDI-Perl durations).

=cut

has pool => (
    is => 'rw',
);

=head2 octaves

  $octaves = $md->octaves;

The octaves to choose from.

Default: C<[2 3 4 5 6]>

=cut

has octaves => (
    is      => 'ro',
    isa     => ArrayRef[Int],
    default => sub { [ 2 .. 6 ] },
);

=head2 notes

  $notes = $md->notes;

The user-definable named pitches from which to choose.

This list is computed, if the B<scale_note> and B<scale_name> are
given, and the B<notes> are I<not> given in the object constructor.

Default: C<[C Db D Eb E F Gb G Ab A Bb B]> (the chromatic scale)

Any scale may be given in the constructor. For accidentals, either
sharps (C<#>) or flats (C<b>) may be provided.

Additionally, midi pitch numbers may be used.

=cut

has notes => (
    is => 'lazy',
);

sub _build_notes {
    my ($self) = @_;
    my $keypref = $self->flats ? 'b' : '#';
    my @notes = get_scale_notes($self->scale_note, $self->scale_name, 0, $keypref);
    return \@notes;
}

=head2 intervals

  $intervals = $md->intervals;

Return the note B<intervals>.

This list is computed, if the B<scale_name> is given, and the
B<intervals> are I<not> given in the object constructor.

Default: 12 C<1>s (for the chromatic scale)

=cut

has intervals => (
    is => 'lazy',
);

sub _build_intervals {
    my ($self) = @_;
    my @nums = get_scale_nums($self->scale_name);
    my @intervals = map { $nums[$_] - $nums[$_ - 1] } 1 .. $#nums;
    push @intervals, 12 - $nums[-1];
    return \@intervals;
}

=head2 chord_triads

  $chord_triads = $md->chord_triads;

The named chord triads, from which to choose. Rolling C<custom> means
that three individual notes, or two intervals must be chosen.

Default:

  major
  minor
  diminished
  augmented
  custom

=cut

has chord_triads => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub {
        [qw(
            major
            minor
            diminished
            augmented
            custom
        )],
    },
);

=head2 chord_triad_weights

  $chord_triad_weights = $md->chord_triad_weights;

The chord triad weights.

Default: C<[2 2 1 1 1]> (major and minor are twice as likely)

=cut

has chord_triad_weights => (
    is      => 'ro',
    isa     => ArrayRef[Int],
    default => sub { [qw(2 2 1 1 1)] },
);

=head2 chord_qualities_major

  $chord_qualities_major = $md->chord_qualities_major;

The named chord qualities that specify a single note addition or
transformation to major chords.

Please see L<Music::Chord::Note> for the known chords.

Default:

  add2 sus2
  add4 sus4
  -5
  -6 6
  M7 7
  add9

=cut

has chord_qualities_major => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub {
        [qw(
            add2 sus2
            add4 sus4
            -5
            -6 6
            M7 7
            add9
        )],
    },
);

=head2 chord_qualities_major_7

  $chord_qualities_major_7 = $md->chord_qualities_major_7;

The named chord qualities that specify additions or transformations to
7th chords.

Please see L<Music::Chord::Note> for the known chords.

Default:

  7b5 7#5
  69
  M79
  7b9 9 7#9
  7(b9,13) 7(9,13)
  9b5
  M11 11 7#11
  M13 13 7#13

=cut

has chord_qualities_major_7 => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub {
        no warnings 'qw';
        [qw(
            7b5 7#5
            69
            M79
            7b9 9 7#9
            7(b9,13) 7(9,13)
            9b5
            M11 11 7#11
            M13 13 7#13
        )],
    },
);

=head2 chord_qualities_minor

  $chord_qualities_minor = $md->chord_qualities_minor;

The named chord qualities that specify a single note addition or
transformation to minor chords.

Please see L<Music::Chord::Note> for the known chords.

Default:

  madd4
  m6
  mM7 m7

=cut

has chord_qualities_minor => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub {
        [qw(
            madd4
            m6
            mM7 m7
        )],
    },
);

=head2 chord_qualities_minor_7

  $chord_qualities_minor_7 = $md->chord_qualities_minor_7;

The named chord qualities that specify additions or transformations to
minor 7th chords.

Please see L<Music::Chord::Note> for the known chords.

Default:

  m7b5 m7#5
  m9
  m7(9,11)
  m11
  m13

=cut

has chord_qualities_minor_7 => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub {
        no warnings 'qw';
        [qw(
            m7b5 m7#5
            m9
            m7(9,11)
            m11
            m13
        )],
    },
);

=head2 chord_qualities_diminished

  $chord_qualities_diminished = $md->chord_qualities_diminished;

The named chord qualities that specify a single note addition or
transformation to diminished chords.

Please see L<Music::Chord::Note> for the known chords.

Default:

  dim6
  dim7

=cut

has chord_qualities_diminished => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub {
        [qw(
            dim6
            dim7
        )],
    },
);

=head2 chord_qualities_augmented

  $chord_qualities_augmented = $md->chord_qualities_augmented;

The named chord qualities that specify a single note addition or
transformation to augmented chords.

Please see L<Music::Chord::Note> for the known chords.

Default:

  augM7 aug7

=cut

has chord_qualities_augmented => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub {
        [qw(
            augM7 aug7
        )],
    },
);

=head2 chord_qualities_augmented_7

  $chord_qualities_augmented_7 = $md->chord_qualities_augmented_7;

The named chord qualities that specify additions or transformations to
augmented 7th chords.

Please see L<Music::Chord::Note> for the known chords.

Default:

  aug9

=cut

has chord_qualities_augmented_7 => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub {
        no warnings 'qw';
        [qw(
            aug9
        )],
    },
);

=head2 modes

  $modes = $md->modes;

The named modes, from which to choose.

Default:

  ionian
  dorian
  phrygian
  lydian
  mixolydian
  aeolian
  locrian

=cut

has modes => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub {
        [qw(
            ionian
            dorian
            phrygian
            lydian
            mixolydian
            aeolian
            locrian
        )],
    },
);

=head2 tonnetzen

  $tonnetzen = $md->tonnetzen;

The named tonnetz values for triad transformations.

Default:

  P  # Parallel
  R  # Relative
  L  # Leittonwechsel
  N  # Nebenverwandt (RLP)
  S  # Slide (LPR)
  H  # "hexatonic pole exchange" (LPL)

=cut

has tonnetzen => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub { [qw(P R L N S H)],
    },
);

=head2 tonnetzen_7

  $tonnetzen_7 = $md->tonnetzen_7;

The named tonnetz values for 7th chord transformations.

Default:

  S23
  S32
  S34
  S43
  S56
  S65
  C32
  C34
  C65

=cut

has tonnetzen_7 => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub { [qw(S23 S32 S34 S43 S56 S65 C32 C34 C65)],
    },
);

=head2 rhythmic_phrase_constraints

  $rhythmic_phrase_constraints = $md->rhythmic_phrase_constraints;

The number of rhythmic values in a phrase, given as an array reference.

Default: C<[3,4,5]>

=cut

has rhythmic_phrase_constraints => (
    is      => 'ro',
    isa     => ArrayRef[Int],
    default => sub { [ 3, 4, 5 ] },
);

=head2 chord_voices_nums

  $chord_voices = $md->chord_voices_nums;

The number of voices in a chord, given as an array reference.

Default: C<[3,4]>

=cut

has chord_voices_nums => (
    is      => 'ro',
    isa     => ArrayRef[Int],
    default => sub { [ 3, 4 ] },
);

=head2 mdp

  $mdp = $md->mdp;

The L<Music::Duration::Partition> object.

=cut

has mdp => (
    is => 'lazy',
);

sub _build_mdp {
    my ($self) = @_;
    my $mdp = Music::Duration::Partition->new(
        size => $self->beats,
        pool => $self->pool,
    );
    return $mdp;
}

=head1 METHODS

=head2 new

  $md = Music::Dice->new;
  $md = Music::Dice->new( # override defaults
    scale_note                  => $note,
    scale_name                  => $name,
    flats                       => $bool,
    beats                       => $beats,
    pool                        => \@pool, # or 'all'
    notes                       => \@notes,
    intervals                   => \@intervals,
    chord_triads                => \@triads,
    chord_triad_weights         => \@triad_weights,
    chord_qualities_major       => \@chord_qualities_major,
    chord_qualities_major_7     => \@chord_qualities_major_7,
    chord_qualities_minor       => \@chord_qualities_minor,
    chord_qualities_minor_7     => \@chord_qualities_minor_7,
    chord_qualities_diminished  => \@chord_qualities_diminished,
    chord_qualities_augmented   => \@chord_qualities_augmented,
    chord_qualities_augmented_7 => \@chord_qualities_augmented_7,
    modes                       => \@modes,
    tonnetzen                   => \@tonnetzen,
    tonnetzen_7                 => \@tonnetzen_7,
    chord_voices_nums           => \@voices,
    rhythmic_phrase_constraints => \@constraints,
  );

Create a new C<Music::Dice> object.

=for Pod::Coverage BUILD

=cut

sub BUILD {
    my ($self, $args) = @_;
    if (exists $args->{pool} && !ref $args->{pool} && $args->{pool} eq 'all') {
        $self->pool([ sort keys %{ midi_dump('length') } ]);
    }
    else {
        $self->pool([qw(wn dhn hn dqn qn den en)]);
    }
}

=head2 octave

  $result = $md->octave->roll;

Return an octave number.

=cut

sub octave {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->octaves, [ (1) x @{ $self->octaves } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 note

  $result = $md->note->roll;

Return one of the B<notes>, with equal probability.

=cut

sub note {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->notes, [ (1) x @{ $self->notes } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 interval

  $result = $md->interval->roll;

Return one of the note B<intervals>, with equal probability.

=cut

sub interval {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->intervals, [ (1) x @{ $self->intervals } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 note_chromatic

  $result = $md->note_chromatic->roll;

Return one of the chromatic scale notes, based on the given
B<scale_note>, with equal probability.

=cut

sub note_chromatic {
    my ($self) = @_;
    my $d = sub {
        my $keypref = $self->flats ? 'b' : '#';
        my $choices = [ get_scale_notes($self->scale_note, 'chromatic', 0, $keypref) ];
        return choose_weighted($choices, [ (1) x @$choices ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 interval_chromatic

  $result = $md->interval_chromatic->roll;

Return one of the chromatic intervals (12 C<1>s), with equal
probability.

=cut

sub interval_chromatic {
    my ($self) = @_;
    my $d = sub {
        my $choices = [ (1) x 12 ];
        return choose_weighted($choices, $choices);
    };
    return Games::Dice::Advanced->new($d);
}

=head2 note_major

  $result = $md->note_major->roll;

Return one of the major scale notes, based on the given
B<scale_note>, with equal probability.

=cut

sub note_major {
    my ($self) = @_;
    my $d = sub {
        my $keypref = $self->flats ? 'b' : '#';
        my $choices = [ get_scale_notes($self->scale_note, 'major', 0, $keypref) ];
        return choose_weighted($choices, [ (1) x @$choices ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 interval_major

  $result = $md->interval_major->roll;

Return one of the major intervals, with equal probability.

=cut

sub interval_major {
    my ($self) = @_;
    my $d = sub {
        my $choices = [qw(2 2 1 2 2 2 1)];
        return choose_weighted($choices, [ (1) x @$choices ]);
    };
    return Games::Dice::Advanced->new($d);
}

=head2 note_minor

  $result = $md->note_minor->roll;

Return one of the natural minor scale notes, based on the given
B<scale_note>, with equal probability.

=cut

sub note_minor {
    my ($self) = @_;
    my $d = sub {
        my $keypref = $self->flats ? 'b' : '#';
        my $choices = [ get_scale_notes($self->scale_note, 'minor', 0, $keypref) ];
        return choose_weighted($choices, [ (1) x @$choices ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 interval_minor

  $result = $md->interval_minor->roll;

Return one of the minor intervals, with equal probability.

=cut

sub interval_minor {
    my ($self) = @_;
    my $d = sub {
        my $choices = [qw(2 1 2 2 1 2 2)];
        return choose_weighted($choices, [ (1) x @$choices ]);
    };
    return Games::Dice::Advanced->new($d);
}

=head2 chord_triad

  $result = $md->chord_triad->roll;

Return a chord triad. If C<custom> is rolled, then three C<notes>
must be rolled for, separately.

=cut

sub chord_triad {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->chord_triads, $self->chord_triad_weights)
    };
    return Games::Dice::Advanced->new($d);
}

=head2 chord_quality_major

  $result = $md->chord_quality_major->roll;

Return a chord quality to modify a major chord triad.

=cut

sub chord_quality_major {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->chord_qualities_major, [ (1) x @{ $self->chord_qualities_major } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 chord_quality_major_7

  $result = $md->chord_quality_major_7->roll;

Return a chord quality to modify a 7th chord.

=cut

sub chord_quality_major_7 {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->chord_qualities_major_7, [ (1) x @{ $self->chord_qualities_major_7 } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 chord_quality_minor

  $result = $md->chord_quality_minor->roll;

Return a chord quality to modify a minor chord triad.

=cut

sub chord_quality_minor {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->chord_qualities_minor, [ (1) x @{ $self->chord_qualities_minor } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 chord_quality_minor_7

  $result = $md->chord_quality_minor_7->roll;

Return a chord quality to modify a minor 7th chord.

=cut

sub chord_quality_minor_7 {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->chord_qualities_minor_7, [ (1) x @{ $self->chord_qualities_minor_7 } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 chord_quality_diminished

  $result = $md->chord_quality_diminished->roll;

Return a chord quality to modify a diminished chord triad.

=cut

sub chord_quality_diminished {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->chord_qualities_diminished, [ (1) x @{ $self->chord_qualities_diminished } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 chord_quality_augmented

  $result = $md->chord_quality_augmented->roll;

Return a chord quality to modify an augmented chord triad.

=cut

sub chord_quality_augmented {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->chord_qualities_augmented, [ (1) x @{ $self->chord_qualities_augmented } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 chord_quality_augmented_7

  $result = $md->chord_quality_augmented_7->roll;

Return a chord quality to modify an augmented 7th chord.

=cut

sub chord_quality_augmented_7 {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->chord_qualities_augmented_7, [ (1) x @{ $self->chord_qualities_augmented_7 } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 mode

  $result = $md->mode->roll;

Return a mode.

=cut

sub mode {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->modes, [ (1) x @{ $self->modes } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 tonnetz

  $result = $md->tonnetz->roll;

Return one of the B<tonnetzen>, with equal probability.

=cut

sub tonnetz {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->tonnetzen, [ (1) x @{ $self->tonnetzen } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 tonnetz_7

  $result = $md->tonnetz_7->roll;

Return one of the B<tonnetzen_7>, with equal probability.

=cut

sub tonnetz_7 {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->tonnetzen_7, [ (1) x @{ $self->tonnetzen_7 } ])
    };
    return Games::Dice::Advanced->new($d);
}

## RHYTHMS ##

=head2 rhythmic_value

  $result = $md->rhythmic_value->roll;

Return a single rhythmic value.

=cut

sub rhythmic_value {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->pool, [ (1) x @{ $self->pool } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 rhythmic_phrase

  $result = $md->rhythmic_phrase->roll;

Return a rhythmic phrase, given the number of B<beats>.

=cut

sub rhythmic_phrase {
    my ($self) = @_;
    my $d = sub {
        return $self->mdp->motif;
    };
    return Games::Dice::Advanced->new($d);
}

=head2 rhythmic_phrase_constrained

  $result = $md->rhythmic_phrase_constrained->roll;

Return a constrained rhythmic phrase, given the
B<rhythmic_phrase_constraints> (number of rhythmic values).

=cut

sub rhythmic_phrase_constrained {
    my ($self) = @_;
    my $d = sub {
        my $motif;
        while (!$motif || !grep { $_ == @$motif } @{ $self->rhythmic_phrase_constraints }) {
            $motif = $self->mdp->motif;
        }
        return $motif;
    };
    return Games::Dice::Advanced->new($d);
}

## GAMEPLAY ##

=head2 chord_voices_nums

  $result = $md->chord_voices_nums->roll;

Return one of the B<chord_voices_nums> with equal probability.

=cut

sub chord_voices_num {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->chord_voices_nums, [ (1) x @{ $self->chord_voices_nums } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 remove_chord_num

  $result = $md->remove_chord_num->roll;

Return a value between C<0> and one less than the first
B<chord_voices_num> entry.

=cut

sub remove_chord_num {
    my ($self) = @_;
    my $d = sub {
        my $choices = [ 0 .. $self->chord_voices_nums->[0] - 1 ];
        return choose_weighted($choices, [ (1) x @$choices ])
    };
    return Games::Dice::Advanced->new($d);
}

## UTILITY ##

=head2 unique_item

  $item = $mb->unique_item(\@excludes);
  $item = $mb->unique_item(\@excludes, \@items);

Return an item from the B<items> list, that is not in the B<excludes>
list. If an item list is not given in the arguments, the object B<notes>
are used.

=cut

sub unique_item {
    my ($self, $excludes, $items) = @_;
    $items ||= $self->notes;
    my $item = '';
    while (!$item || grep { $_ eq $item } @$excludes) {
        $item = $items->[ int rand @$items ];
    }
    return $item;
}

1;
__END__

=head1 SEE ALSO

The F<t/01-methods.t> file

L<Games::Dice::Advanced>

L<List::Util::WeightedChoice>

L<MIDI::Util>

L<Moo>

L<Music::Duration::Partition>

L<Music::Scales>

L<Types::Standard>

=cut
