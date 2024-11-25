package Music::Dice;

# ABSTRACT: Define and Play Musical Dice Games

our $VERSION = '0.0100';

use Moo;
use strictures 2;
use Carp qw(croak);
use namespace::clean;

=head1 SYNOPSIS

  use Music::Dice ();

  my $md = Music::Dice->new(verbose => 1);

=head1 DESCRIPTION

C<Music::Dice> defines and plays musical dice games.

=head1 ATTRIBUTES

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
