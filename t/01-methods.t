use strict;
use warnings;

use Test::More;

use_ok 'Music::Dice';

subtest defaults => sub {
    my $obj = new_ok 'Music::Dice';
    is $obj->flats, 1, 'flats';
    is $obj->beats, 4, 'beats';
    is_deeply $obj->pool, [qw(wn dhn hn dqn qn den en)], 'pool';
    is_deeply $obj->notes, [qw(C Db D Eb E F Gb G Ab A Bb B)], 'notes';
    is_deeply $obj->intervals, [ (1) x 12 ], 'intervals';
    is_deeply $obj->chord_triads, [qw(major minor diminished augmented custom)], 'chord_triads';
    is_deeply $obj->chord_qualities, [qw(sus4 b5 #5 6 69 maj7 minmaj7 7 min7 add9 b9 9 #9 b11 11 #11 b13 13 #13 ø)], 'chord_qualities';
    is_deeply $obj->modes, [qw(ionian dorian phrygian lydian mixolydian aeolian locrian)], 'modes';
    is_deeply $obj->chord_voices_nums, [3,4], 'chord_voices_nums';
    $obj = new_ok 'Music::Dice' => [ pool => 'all' ];
    is_deeply $obj->pool, [qw(dden ddhn ddqn ddsn ddwn den dhn dqn dsn dwn en hn qn sn ten thn tqn tsn twn wn)], 'all';
};

subtest scales => sub {
    no warnings 'qw';
    my $maj = [qw(2 2 1 2 2 2 1)];
    my $obj = new_ok 'Music::Dice' => [ scale_name => 'major' ];
    is_deeply $obj->notes, [qw(C D E F G A B)], 'C major notes';
    is_deeply $obj->intervals, $maj, 'C major intervals';
    $obj = new_ok 'Music::Dice' => [ scale_note => 'C#', scale_name => 'major' ];
    is_deeply $obj->notes, [qw(C# D# E# F# G# A# B#)], 'C# major notes';
    is_deeply $obj->intervals, $maj, 'C# major intervals';
    $obj = new_ok 'Music::Dice' => [ scale_note => 'Db', scale_name => 'major' ];
    is_deeply $obj->notes, [qw(Db Eb F Gb Ab Bb C)], 'Db major notes';
    is_deeply $obj->intervals, $maj, 'Db major intervals';
    $obj = new_ok 'Music::Dice' => [ scale_note => 'A', scale_name => 'minor' ];
    is_deeply $obj->notes, [qw(A B C D E F G)], 'A minor notes';
    is_deeply $obj->intervals, [2, 1, 2, 2, 1, 2, 2], 'A minor intervals';
    $obj = new_ok 'Music::Dice' => [ scale_name => 'chromatic', flats => 0 ];
    is_deeply $obj->notes, [qw(C C# D D# E F F# G G# A A# B)], 'C chromatic notes';
    is_deeply $obj->intervals, [ (1) x 12 ], 'C chromatic intervals';
};

subtest rolls => sub {
    my $obj = new_ok 'Music::Dice';
    my $got = $obj->d_note->roll;
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
    ok defined $got, "d_interval_minor: $got";
    $got = $obj->d_chord_triad->roll;
    ok defined $got, "d_chord_triad: $got";
    $got = $obj->d_chord_quality->roll;
    ok defined $got, "d_chord_quality: $got";
    $got = $obj->d_mode->roll;
    ok defined $got, "d_mode: $got";
    $got = $obj->d_rhythm->roll;
    ok defined $got, "d_rhythm: $got";
    $got = $obj->d_rhythmic_phrase->roll;
    ok defined $got, "d_rhythmic_phrase: @$got";
    # gameplay
    $got = $obj->d_chord_voices_nums->roll;
    ok defined $got, "d_chord_voices_nums: $got";
    $got = $obj->d_remove_chord_num->roll;
    ok defined $got, "d_remove_chord_num: $got";
};

done_testing();
