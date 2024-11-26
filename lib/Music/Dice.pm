package Music::Dice;

# ABSTRACT: Define Musical Dice

our $VERSION = '0.0100';

use Moo;
use strictures 2;
use Carp qw(croak);
use Games::Dice::Advanced ();
use List::Util::WeightedChoice qw(choose_weighted); # because we may weight in the future
use Music::Scales qw(get_scale_notes get_scale_nums);
use namespace::clean;

=head1 SYNOPSIS

  use Music::Dice ();
  my $md = Music::Dice->new;
  # basics
  my $roll = $md->d_interval->roll;
  $roll = $md->d_note_chromatic->roll;
  $roll = $md->d_interval_chromatic->roll;
  $roll = $md->d_note_major->roll;
  $roll = $md->d_interval_major->roll;
  $roll = $md->d_note_minor->roll;
  $roll = $md->d_interval_minor->roll;
  # gameplay
  $roll = $md->d_chord_voices_nums->roll;
  $roll = $md->d_remove_chord_num->roll;
};

=head1 DESCRIPTION

C<Music::Dice> defines musical dice.

=head1 ATTRIBUTES

=head2 scale_note

  $note = $md->scale_note;

The (uppercase) tonic of the scale, used for B<notes>.

Default: C<C>

=cut

has scale_note => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a valid note name" unless $_[0] =~ /^[A-G][b#]?$/ },
    default => sub { 'C' },
);

=head2 scale_name

  $note = $md->scale_name;

The (lowecase) name of the scale, used for B<notes>.

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

Returns one of the B<notes> with equal probability.

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

The available intervals to choose.

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

Returns one of the B<intervals> with equal probability.

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

Returns one of the chromatic scale notes, with equal probability.

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

Returns one of the major scale notes with equal probability.

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

Returns one of the natural minor scale notes, with equal probability.

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

=head2 chord_voices_nums

  $chord_voices = $md->chord_voices_nums;

The number of voices in a chord given as an array reference.

Default: C<[3,4]>

=cut

has chord_voices_nums => (
    is      => 'lazy',
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
    scale_note => $note,
    scale_name => $name,
    flats      => $bool,
    notes      => \@notes,
    intervals  => \@intervals,
  );

Create a new C<Music::Dice> object.

=for Pod::Coverage BUILD

=cut

1;
__END__

=head1 SEE ALSO

L<Moo>

L<http://somewhere.el.se>

=cut
