use strict;
use warnings;

use Test::More;

use_ok 'Music::Dice';

subtest defaults => sub {
    my $obj = new_ok 'Music::Dice';
    is $obj->verbose, 0, 'verbose';
    is_deeply $obj->chord_voices, [3,4], 'chord_voices';
    my $got = $obj->d_chord_voices->roll;
    ok defined $got, "d_chord_voices: $got";
    $got = $obj->d_remove_chord->roll;
    ok defined $got, "d_remove_chord: $got";
    is_deeply $obj->notes, [qw(C Df D Ef E F Gf G Af A Bf B)], 'notes';
    $got = $obj->d_note->roll;
    ok defined $got, "d_note: $got";
};

done_testing();
