use strict;
use warnings;

use Test::More;

use_ok 'Music::Dice';

subtest defaults => sub {
    my $obj = new_ok 'Music::Dice';
    is $obj->flats, 1, 'flats';
    is_deeply $obj->chord_voices_nums, [3,4], 'chord_voices_nums';
    is_deeply $obj->notes, [qw(C Df D Ef E F Gf G Af A Bf B)], 'notes';
    is_deeply $obj->intervals, [ (1) x 12 ], 'intervals';
};

subtest rolls => sub {
    my $obj = new_ok 'Music::Dice';
    my $got = $obj->d_chord_voices_nums->roll;
    ok defined $got, "d_chord_voices_nums: $got";
    $got = $obj->d_remove_chord_num->roll;
    ok defined $got, "d_remove_chord_num: $got";
    $got = $obj->d_note->roll;
    ok defined $got, "d_note: $got";
    $got = $obj->d_interval->roll;
    ok defined $got, "d_interval $got";
    $got = $obj->d_note_chromatic->roll;
    ok defined $got, "d_note_chromatic: $got";
    $got = $obj->d_interval_chromatic->roll;
    ok defined $got, "d_interval_chromatic $got";
    $got = $obj->d_note_major->roll;
    ok defined $got, "d_note_major: $got";
    $got = $obj->d_interval_major->roll;
    ok defined $got, "d_interval_major $got";
    $got = $obj->d_note_minor->roll;
    ok defined $got, "d_note_minor: $got";
    $got = $obj->d_interval_minor->roll;
    ok defined $got, "d_interval_minor $got";
};

done_testing();
