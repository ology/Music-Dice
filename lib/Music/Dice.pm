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

=head2 chord_voices

  $chord_voices = $md->chord_voices;
  $md->chord_voices($n);

The number of voices in a chord given as an array reference.

Default: C<[3,4]>

=cut

has chord_voices => (
    is      => 'lazy',
    isa     => sub { croak "$_[0] is not an array" unless ref $_[0] eq 'ARRAY' },
    default => sub { [ 3, 4 ] },
);

=head2 d_chord_voices

  $result = $md->d_chord_voices->roll;

Returns one of the B<chord_voices> with equal probability.

=cut

has d_chord_voices => (
    is => 'lazy',
);

sub _build_d_chord_voices {
    my ($self) = @_;
    my $d = sub {
        choose_weighted($self->chord_voices, [ (1) x @{ $self->chord_voices } ])
    };
    return Games::Dice::Advanced->new($d);
}

=head2 verbose

  $verbose = $md->verbose;

Show progress.

=cut

has verbose => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);

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
