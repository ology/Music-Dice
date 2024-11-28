package Music::Dice;

# ABSTRACT: Define and roll musical dice

our $VERSION = '0.0100';

use Moo;
use strictures 2;
use Carp qw(croak);
use Games::Dice::Advanced ();
use List::Util::WeightedChoice qw(choose_weighted); # because we may weight in the future
use MIDI::Util qw(midi_dump);
use Music::Duration::Partition ();
use Music::Scales qw(get_scale_notes get_scale_nums);
use Types::Standard qw(ArrayRef Int Str);
use namespace::clean;

=encoding utf8

=head1 SYNOPSIS

  use Music::Dice ();
  my $md = Music::Dice->new;
  # basics
  my $roll = $md->note->roll;
  $roll = $md->interval->roll;
  $roll = $md->note_chromatic->roll;
  $roll = $md->interval_chromatic->roll;
  $roll = $md->note_major->roll;
  $roll = $md->interval_major->roll;
  $roll = $md->note_minor->roll;
  $roll = $md->interval_minor->roll;
  $roll = $md->chord_triad->roll;
  $roll = $md->chord_quality->roll;
  $roll = $md->mode->roll;
  $roll = $md->tonnetz3->roll;
  $roll = $md->tonnetz4->roll;
  $roll = $md->rhythm->roll;
  $roll = $md->rhythmic_phrase->roll;
  # gameplay
  $roll = $md->chord_voices_nums->roll;
  $roll = $md->remove_chord_num->roll;
};

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

The (lowecase) name of the scale.

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

Returns the note B<intervals>.

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

=head2 chord_qualities

  $chord_qualities = $md->chord_qualities;

The user-definable named chord qualities, from which to choose.

Default:

  sus4
  b5 #5
  6 69
  maj7 minmaj7
  7 m7
  add9 b9 9 #9
  b11 11 #11
  b13 13 #13
  m7b5

Where C<m7b5> is the half-diminished chord ("ø"). If this quality is
rolled, it should replace the triad it "modifies."

=cut

has chord_qualities => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub {
        no warnings 'qw';
        [qw(
            sus4
            b5 #5
            6 69
            maj7 minmaj7
            7 m7
            add9 b9 9 #9
            b11 11 #11
            b13 13 #13
            m7b5
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

=head2 tonnetzen3

  $tonnetzen3 = $md->tonnetzen3;

The named tonnetz values for triad transformations.

Default:

  P  # Parallel
  R  # Relative
  L  # Leittonwechsel
  N  # Nebenverwandt (RLP)
  S  # Slide (LPR)
  H  # "hexatonic pole exchange" (LPL)

=cut

has tonnetzen3 => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub { [qw(P R L N S H)],
    },
);

=head2 tonnetzen4

  $tonnetzen4 = $md->tonnetzen4;

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

has tonnetzen4 => (
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
    scale_note          => $note,
    scale_name          => $name,
    flats               => $bool,
    beats               => $beats,
    pool                => \@pool, # or 'all'
    notes               => \@notes,
    intervals           => \@intervals,
    chord_triads        => \@triads,
    chord_triad_weights => \@triad_weights,
    modes               => \@modes,
    tonnetzen3          => \@tonnetzen3,
    tonnetzen4          => \@tonnetzen4,
    chord_qualities     => \@qualities,
    chord_voices_nums   => \@voices,
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

Returns an octave number.

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

Returns one of the B<notes>, with equal probability.

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

Returns one of the note B<intervals>, with equal probability.

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

Returns one of the chromatic scale notes, based on the given
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

Returns one of the chromatic intervals (12 C<1>s), with equal
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

Returns one of the major scale notes, based on the given
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

Returns one of the major intervals, with equal probability.

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

Returns one of the natural minor scale notes, based on the given
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

Returns one of the minor intervals, with equal probability.

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

Returns a chord triad. If C<custom> is rolled, then three C<notes>
must be rolled for, separately.

=cut

sub chord_triad {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->chord_triads, $self->chord_triad_weights)
    };
    return Games::Dice::Advanced->new($d);
}

=head2 chord_quality

  $result = $md->chord_quality->roll;

Returns a chord quality to modify a chord triad.

=cut

sub chord_quality {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->chord_qualities, [ (1) x @{ $self->chord_qualities } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 mode

  $result = $md->mode->roll;

Returns a mode.

=cut

sub mode {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->modes, [ (1) x @{ $self->modes } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 tonnetz3

  $result = $md->tonnetz3->roll;

Returns one of the B<tonnetzen3>, with equal probability.

=cut

sub tonnetz3 {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->tonnetzen3, [ (1) x @{ $self->tonnetzen3 } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 tonnetz4

  $result = $md->tonnetz4->roll;

Returns one of the B<tonnetzen4>, with equal probability.

=cut

sub tonnetz4 {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->tonnetzen4, [ (1) x @{ $self->tonnetzen4 } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 rhythmic_value

  $result = $md->rhythmic_value->roll;

Returns a single rhythmic value.

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

Returns a rhythmic phrase, given the number of B<beats>.

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

Returns a constrained rhythmic phrase, given the
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

=head2 chord_voices_nums

  $result = $md->chord_voices_nums->roll;

Returns one of the B<chord_voices_nums> with equal probability.

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

Returns a value between C<1> and the last B<chord_voices_num> entry
(e.g. C<4>).

=cut

sub remove_chord_num {
    my ($self) = @_;
    my $d = sub {
        my $choices = [ 1 .. $self->chord_voices_nums->[-1] ];
        return choose_weighted($choices, [ (1) x @$choices ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 unique_note

  $unique_note = $mb->unique_note(\@excludes, \@notes);

Return a note from the B<notes> list, that is not in the B<excludes>
list.

=cut

sub unique_note {
    my ($self, $excludes, $notes) = @_;
    $notes ||= $self->notes;
    my $note = '';
    while (!$note || grep { $_ eq $note } @$excludes) {
        $note = $notes->[ int rand @$notes ];
    }
    return $note;
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
