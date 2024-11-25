#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::Dice';

subtest defaults => sub {
    my $obj = new_ok 'Music::Dice';
    is $obj->verbose, 0, 'verbose';
    is_deeply $obj->chord_voices, [3,4], 'chord_voices';
    ok defined $obj->d_chord_voices->roll, 'd_chord_voices';
};

done_testing();
