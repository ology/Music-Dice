use strict;
use warnings;

use Test::More;

use_ok 'Music::Dice';

subtest defaults => sub {
    my $obj = new_ok 'Music::Dice';
    is $obj->verbose, 0, 'verbose';
    is_deeply $obj->chord_voices_num, [3,4], 'chord_voices_num';
    is_deeply $obj->notes, [qw(C D E F G A B)], 'notes';
    is_deeply $obj->intervals, [qw(2 2 1 2 2 2 1)], 'intervals';
};

subtest rolls => sub {
    my $obj = new_ok 'Music::Dice';
    my $got = $obj->d_chord_voices_num->roll;
    ok defined $got, "d_chord_voices_num: $got";
    $got = $obj->d_remove_chord_num->roll;
    ok defined $got, "d_remove_chord_num: $got";
    $got = $obj->d_note->roll;
    ok defined $got, "d_note: $got";
    $got = $obj->d_interval->roll;
    ok defined $got, "d_interval $got";
};

done_testing();
