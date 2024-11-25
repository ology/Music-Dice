#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::Dice';

new_ok 'Music::Dice';

my $obj = new_ok 'Music::Dice' => [
    verbose => 1,
];

is $obj->verbose, 1, 'verbose';

done_testing();
