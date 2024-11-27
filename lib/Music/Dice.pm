package Music::Dice;

# ABSTRACT: Define Musical Dice

our $VERSION = '0.0100';

use Moo;
use strictures 2;
use Carp qw(croak);
use Games::Dice::Advanced ();
use List::Util::WeightedChoice qw(choose_weighted); # because we may weight in the future
use MIDI::Util qw(midi_dump);
use Music::Scales qw(get_scale_notes get_scale_nums);
use namespace::clean;

=head1 SYNOPSIS

  use Music::Dice ();
  my $md = Music::Dice->new;
  # basics
  my $roll = $md->d_note->roll;
  $roll = $md->d_interval->roll;
  $roll = $md->d_note_chromatic->roll;
  $roll = $md->d_interval_chromatic->roll;
  $roll = $md->d_note_major->roll;
  $roll = $md->d_interval_major->roll;
  $roll = $md->d_note_minor->roll;
  $roll = $md->d_interval_minor->roll;
  $roll = $md->d_chord_triad->roll;
  $roll = $md->d_chord_quality->roll;
  $roll = $md->d_mode->roll;
  # gameplay
  $roll = $md->d_chord_voices_nums->roll;
  $roll = $md->d_remove_chord_num->roll;
};

=head1 DESCRIPTION

C<Music::Dice> defines musical dice.

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

=head2 notes

  $notes = $md->notes;

The user-definable named pitches from which to choose.

Default: C<[C Db D Eb E F Gb G Ab A Bb B]> (the chromatic scale)

Any scale may be given in the constructor. For accidentals, either
sharps (C<#>) or flats (C<b>) may be provided.

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

=head2 d_note

  $result = $md->d_note->roll;

Returns one of the B<notes>, with equal probability.

=cut

has d_note => (
    is => 'lazy',
);

sub _build_d_note {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->notes, [ (1) x @{ $self->notes } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 intervals

  $intervals = $md->intervals;

Returns the note B<intervals>.

Default: 12 C<1>s

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

=head2 d_interval

  $result = $md->d_interval->roll;

Returns one of the note B<intervals>, with equal probability.

=cut

has d_interval => (
    is => 'lazy',
);

sub _build_d_interval {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->intervals, [ (1) x @{ $self->intervals } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 d_note_chromatic

  $result = $md->d_note_chromatic->roll;

Returns one of the chromatic scale notes, based on the given
B<scale_note>, with equal probability.

=cut

has d_note_chromatic => (
    is => 'lazy',
);

sub _build_d_note_chromatic {
    my ($self) = @_;
    no warnings 'qw';
    my $d = sub {
        my $keypref = $self->flats ? 'b' : '#';
        my $choices = [ get_scale_notes($self->scale_note, 'chromatic', 0, $keypref) ];
        return choose_weighted($choices, [ (1) x @$choices ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 d_interval_chromatic

  $result = $md->d_interval_chromatic->roll;

Returns one of the chromatic intervals (12 C<1>s), with equal
probability.

=cut

has d_interval_chromatic => (
    is => 'lazy',
);

sub _build_d_interval_chromatic {
    my ($self) = @_;
    my $d = sub {
        my $choices = [ (1) x 12 ];
        return choose_weighted($choices, $choices);
    };
    return Games::Dice::Advanced->new($d);
}

=head2 d_note_major

  $result = $md->d_note_major->roll;

Returns one of the major scale notes, based on the given
B<scale_note>, with equal probability.

=cut

has d_note_major => (
    is => 'lazy',
);

sub _build_d_note_major {
    my ($self) = @_;
    my $d = sub {
        my $keypref = $self->flats ? 'b' : '#';
        my $choices = [ get_scale_notes($self->scale_note, 'major', 0, $keypref) ];
        return choose_weighted($choices, [ (1) x @$choices ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 d_interval_major

  $result = $md->d_interval_major->roll;

Returns one of the major intervals, with equal
probability.

=cut

has d_interval_major => (
    is => 'lazy',
);

sub _build_d_interval_major {
    my ($self) = @_;
    my $d = sub {
        my $choices = [qw(2 2 1 2 2 2 1)];
        return choose_weighted($choices, [ (1) x @$choices ]);
    };
    return Games::Dice::Advanced->new($d);
}

=head2 d_note_minor

  $result = $md->d_note_minor->roll;

Returns one of the natural minor scale notes, based on the given
B<scale_note>, with equal probability.

=cut

has d_note_minor => (
    is => 'lazy',
);

sub _build_d_note_minor {
    my ($self) = @_;
    my $d = sub {
        my $keypref = $self->flats ? 'b' : '#';
        my $choices = [ get_scale_notes($self->scale_note, 'minor', 0, $keypref) ];
        return choose_weighted($choices, [ (1) x @$choices ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 d_interval_minor

  $result = $md->d_interval_minor->roll;

Returns one of the minor intervals, with equal
probability.

=cut

has d_interval_minor => (
    is => 'lazy',
);

sub _build_d_interval_minor {
    my ($self) = @_;
    my $d = sub {
        my $choices = [qw(2 1 2 2 1 2 2)];
        return choose_weighted($choices, [ (1) x @$choices ]);
    };
    return Games::Dice::Advanced->new($d);
}

=head2 chord_triads

  $chord_triads = $md->chord_triads;

The user-definable named chord triads, from which to choose.

Default:

  major
  minor
  diminished
  augmented
  custom
  
=cut

has chord_triads => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not an array" unless ref $_[0] eq 'ARRAY' },
    default => sub {
        [qw(
            major
            minor
            diminished
            augmented
            custom
        )]
    },
);

=head2 d_chord_triad

  $result = $md->d_chord_triad->roll;

Returns a chord triad. If C<custom> is rolled, then three C<notes>
must be rolled for, separately.

=cut

has d_chord_triad => (
    is => 'lazy',
);

sub _build_d_chord_triad {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->chord_triads, [ (1) x @{ $self->chord_triads } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 chord_qualities

  $chord_qualities = $md->chord_qualities;

The user-definable named chord qualities, from which to choose.

Default:

  sus4
  b5 #5
  6 69
  maj7 minmaj7
  7 min7
  add9 b9 9 #9
  b11 11 #11
  b13 13 #13
  ø

Where "ø" is the "half-diminished" chord.

=cut

has chord_qualities => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not an array" unless ref $_[0] eq 'ARRAY' },
    default => sub {
        no warnings 'qw';
        [qw(
            sus4
            b5 #5
            6 69
            maj7 minmaj7
            7 min7
            add9 b9 9 #9
            b11 11 #11
            b13 13 #13
            ø
        )]
    },
);

=head2 d_chord_quality

  $result = $md->d_chord_quality->roll;

Returns a chord quality to modify a chord triad.

=cut

has d_chord_quality => (
    is => 'lazy',
);

sub _build_d_chord_quality {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->chord_qualities, [ (1) x @{ $self->chord_qualities } ])
    };
    return Games::Dice::Advanced->new($d);
}

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
    isa     => sub { croak "$_[0] is not an array" unless ref $_[0] eq 'ARRAY' },
    default => sub {
        [qw(
            ionian
            dorian
            phrygian
            lydian
            mixolydian
            aeolian
            locrian
        )]
    },
);

=head2 d_mode

  $result = $md->d_mode->roll;

Returns a mode, from which to choose.

=cut

has d_mode => (
    is => 'lazy',
);

sub _build_d_mode {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->modes, [ (1) x @{ $self->modes } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 rhythms

  $rhythms = $md->rhythms;

The named rhythms, from which to choose.

Default:

=cut

has rhythms => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not an array" unless ref $_[0] eq 'ARRAY' },
    default => sub { [ sort keys %{ midi_dump('length') } ] },
);

=head2 chord_voices_nums

  $chord_voices = $md->chord_voices_nums;

The number of voices in a chord given as an array reference.

Default: C<[3,4]>

=cut

has chord_voices_nums => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not an array" unless ref $_[0] eq 'ARRAY' },
    default => sub { [ 3, 4 ] },
);

=head2 d_chord_voices_nums

  $result = $md->d_chord_voices_nums->roll;

Returns one of the B<chord_voices_nums> with equal probability.

=cut

has d_chord_voices_nums => (
    is => 'lazy',
);

sub _build_d_chord_voices_nums {
    my ($self) = @_;
    my $d = sub {
        return choose_weighted($self->chord_voices_nums, [ (1) x @{ $self->chord_voices_nums } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 d_remove_chord_num

  $result = $md->d_remove_chord_num->roll;

Returns a value between C<1> and the last B<chord_voices_num> entry (e.g. C<4>).

=cut

has d_remove_chord_num => (
    is => 'lazy',
);

sub _build_d_remove_chord_num {
    my ($self) = @_;
    my $d = sub {
        my $choices = [ 1 .. $self->chord_voices_nums->[-1] ];
        return choose_weighted($choices, [ (1) x @$choices ])
    };
    return Games::Dice::Advanced->new($d);
}

=head1 METHODS

=head2 new

  $md = Music::Dice->new(
    scale_note        => $note,
    scale_name        => $name,
    flats             => $bool,
    notes             => \@notes,
    intervals         => \@intervals,
    chord_triads      => \@triads,
    chord_qualities   => \@qualities,
    chord_voices_nums => \@voices,
  );

Create a new C<Music::Dice> object.

=cut

1;
__END__

=head1 SEE ALSO

The F<t/01-methods.t> file

L<Games::Dice::Advanced>

L<List::Util::WeightedChoice>

L<Moo>

L<Music::Scales>

=cut
