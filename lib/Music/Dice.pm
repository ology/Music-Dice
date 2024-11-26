package Music::Dice;

# ABSTRACT: Define and Play Musical Dice Games

our $VERSION = '0.0100';

use Moo;
use strictures 2;
use Carp qw(croak);
use Games::Dice::Advanced ();
use List::Util::WeightedChoice qw( choose_weighted);
use namespace::clean;

=head1 SYNOPSIS

  use Music::Dice ();

  my $md = Music::Dice->new(verbose => 1);

=head1 DESCRIPTION

C<Music::Dice> defines and plays musical dice games.

=head1 ATTRIBUTES

=head2 notes

  $notes = $md->notes;

The user-definable named pitches from which to choose.

Default: C<[C Df D Ef E F Gf G Af A Bf B]>

Any scale may be given in the constructor. For accidentals, either
sharps (C<s>, C<#>, etc.) or flats (C<f>, C<b>, etc.) may be provided.

=cut

has notes => (
    is      => 'lazy',
    isa     => sub { croak "$_[0] is not an array" unless ref $_[0] eq 'ARRAY' },
    default => sub { [qw( C Df D Ef E F Gf G Af A Bf B )] },
);

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
        choose_weighted($self->notes, [ (1) x @{ $self->notes } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 intervals

  $intervals = $md->intervals;

The available intervals to choose.

Default: 12 C<1>s

=cut

has intervals => (
    is      => 'lazy',
    isa     => sub { croak "$_[0] is not an array" unless ref $_[0] eq 'ARRAY' },
    default => sub { [ (1) x 12 ] },
);

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
        choose_weighted($self->intervals, [ (1) x @{ $self->intervals } ])
    };
    return Games::Dice::Advanced->new($d);
}

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

=head2 d_note_chromatic

  $result = $md->d_note_chromatic->roll;

Returns one of the chromatic scale notes with equal probability.

=cut

has d_note_chromatic => (
    is => 'lazy',
);

sub _build_d_note_chromatic {
    my ($self) = @_;
    my $d = sub {
        my $choices = [qw( C Df D Ef E F Gf G Af A Bf B )];
        choose_weighted($choices, [ (1) x @$choices ])
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
        choose_weighted($self->chord_voices_nums, [ (1) x @{ $self->chord_voices_nums } ])
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
        choose_weighted($choices, [ (1) x @$choices ])
    };
    return Games::Dice::Advanced->new($d);
}

=head1 METHODS

=head2 new

  $md = Music::Dice->new(verbose => 1);

Create a new C<Music::Dice> object.

=for Pod::Coverage BUILD

=cut

1;
__END__

=head1 SEE ALSO

L<Moo>

L<http://somewhere.el.se>

=cut
