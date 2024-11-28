use strict;
use warnings;

use Test::More;

use_ok 'Music::Dice';

subtest defaults => sub {
    no warnings 'qw';
    my $obj = new_ok 'Music::Dice';
    is $obj->flats, 1, 'flats';
    is $obj->beats, 4, 'beats';
    is_deeply $obj->pool, [qw(wn dhn hn dqn qn den en)], 'pool';
    is_deeply $obj->octaves, [2 .. 6], 'octaves';
    is_deeply $obj->notes, [qw(C Db D Eb E F Gb G Ab A Bb B)], 'notes';
    is_deeply $obj->intervals, [ (1) x 12 ], 'intervals';
    is_deeply $obj->chord_triads, [qw(major minor diminished augmented custom)], 'chord_triads';
    is_deeply $obj->chord_qualities, [qw(sus4 b5 #5 6 69 maj7 minmaj7 7 m7 add9 b9 9 #9 b11 11 #11 b13 13 #13 m7b5)], 'chord_qualities';
    is_deeply $obj->modes, [qw(ionian dorian phrygian lydian mixolydian aeolian locrian)], 'modes';
    is_deeply $obj->tonnetzen3, [qw(P R L N S H)], 'tonnetzen3';
    is_deeply $obj->tonnetzen4, [qw(S23 S32 S34 S43 S56 S65 C32 C34 C65)], 'tonnetzen4';
    is_deeply $obj->chord_voices_nums, [3,4], 'chord_voices_nums';
    is_deeply $obj->rhythmic_phrase_constraints, [3,4,5], 'rhythmic_phrase_constraints';
    $obj = new_ok 'Music::Dice' => [ pool => 'all' ];
    is_deeply $obj->pool, [qw(dden ddhn ddqn ddsn ddwn den dhn dqn dsn dwn en hn qn sn ten thn tqn tsn twn wn)], 'all pool';
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
    $obj = new_ok 'Music::Dice' => [ notes => [qw(C F)], intervals => [5] ];
    is_deeply $obj->notes, [qw(C F)], 'C-F only notes';
    is_deeply $obj->intervals, [5], 'C-F only interval';
    $obj = new_ok 'Music::Dice' => [ notes => [qw(60 62 64 65 67 69 71)] ];
    is_deeply $obj->notes, [qw(60 62 64 65 67 69 71)], 'midinum notes';
};

subtest rolls => sub {
    my $obj = new_ok 'Music::Dice' => [ rhythmic_phrase_constraints => [4] ];
    my $got = $obj->octave->roll;
    ok defined $got, "octave: $got";
    $got = $obj->note->roll;
    ok defined $got, "note: $got";
    $got = $obj->interval->roll;
    ok defined $got, "interval $got";
    $got = $obj->note_chromatic->roll;
    ok defined $got, "note_chromatic: $got";
    $got = $obj->interval_chromatic->roll;
    ok defined $got, "interval_chromatic $got";
    $got = $obj->note_major->roll;
    ok defined $got, "note_major: $got";
    $got = $obj->interval_major->roll;
    ok defined $got, "interval_major $got";
    $got = $obj->note_minor->roll;
    ok defined $got, "note_minor: $got";
    $got = $obj->interval_minor->roll;
    ok defined $got, "interval_minor: $got";
    $got = $obj->chord_triad->roll;
    ok defined $got, "chord_triad: $got";
    $got = $obj->chord_quality->roll;
    ok defined $got, "chord_quality: $got";
    $got = $obj->mode->roll;
    ok defined $got, "mode: $got";
    $got = $obj->tonnetz3->roll;
    ok defined $got, "tonnetz3: $got";
    $got = $obj->tonnetz4->roll;
    ok defined $got, "tonnetz4: $got";
    $got = $obj->rhythmic_value->roll;
    ok defined $got, "rhythmic_value: $got";
    $got = $obj->rhythmic_phrase->roll;
    ok defined $got, "rhythmic_phrase: @$got";
    ok @$got > 0, 'rhythmic_phrase: > 0';
    $got = $obj->rhythmic_phrase_constrained->roll;
    ok defined $got, "rhythmic_phrase_constrained: @$got";
    is @$got, 4, 'rhythmic_phrase_constrained: 4';
    # gameplay
    $got = $obj->chord_voices_num->roll;
    ok defined $got, "chord_voices_num: $got";
    $got = $obj->remove_chord_num->roll;
    ok defined $got, "remove_chord_num: $got";
};

subtest utility => sub {
    my $obj = new_ok 'Music::Dice';
    my $got = $obj->unique_note(['C']);
    isnt $got, 'C', 'unique_note';
};

done_testing();
