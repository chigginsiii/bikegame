#!/usr/bin/perl

use strict;
use Test::More qw(no_plan);
use lib qw(../lib);

BEGIN {
      use_ok("BikeGame::Model::Player");
}

{
    my @p = BikeGame::Model::Player->search({name => 'Testy McTest'});
    $_->delete() foreach @p;
}
diag("CHECKING PLAYER");
my $player = BikeGame::Model::Player->insert({name => 'Testy McTest'});
isa_ok($player, 'BikeGame::Model::Player');
ok($player->id, 'player id after insert: ' . $player->id);

# check to see what level this player is
foreach my $ride_record ( $player->ride_records ) {

    diag("CHECKING RIDE RECORD: ".$ride_record->ride_type);

    # do we have a road record type?
    my $type = $ride_record->ride_type;
    ok($type, 'ride_record: ride_type -> ' . $type );
    is($player->ride_record($type), $ride_record, 'player->ride_record(type) == ride_record');

    diag("CHECKING INITIAL LEVEL: ".$ride_record->ride_type);
    # do we have a real first level?
    ok($ride_record->cur_level,
       ( 'ride_record: level ' . $ride_record->cur_level->level_number . ' ' . $ride_record->ride_type ) );

    # points on this level? total?
    my $cur_level_pts = $ride_record->cur_level->points_current;
    is($cur_level_pts, 0, 'ride_record(type)->points_current: ' . $cur_level_pts);
    my $total_points = $ride_record->total_points;
    is($total_points, 0, 'ride_record(type)->total_points: ' . $total_points);

    diag("CHECKING INITIAL METRICS: ".$ride_record->ride_type);
    # metrics!
    my @metrics = $ride_record->metrics;
    foreach my $metric ( @metrics ) {
        # isa_ok($metric, 'BikeGame::Model::Metric');
        ok( $metric->summary, 'metric() summary: ' . $metric->summary );
    }
}

#
# alright! let's add some rides... in the next test.
#
