#!/usr/bin/perl

use strict;
use Test::More qw(no_plan);
use lib qw(../lib);

BEGIN {
    use_ok("BikeGame::DBI");
    #
    # Player:
    # name password timezone
    # ride_records: record::$ridetype
    #               - metrics
    #               - scores
    #               - levels
    # rides (each of a type, belonging to a player)
    # riderefs (each of a type = belonging to a player)
    #
    use_ok("BikeGame::Model::Player");
    use_ok("BikeGame::Model::Player::Detail");
    #
    # name password timezone
    # ride_records
    # player has many ride records, UNIQUE(player|ridetype)
    #
    # each RideRecord gets configured with Metric classes by type in Config
    # each Level gets configured with a Level class by type in Config
    # scores are agnostic
    #
    use_ok("BikeGame::Model::RideRecord");
    use_ok("BikeGame::Model::CashManager");
    #
    # - riderecord is built from metrics, scores they produce, and the levels they make
    #
    # - Metric:
    #
    # Super class defines some methods to be subclassed:
    # - visit_ride($ride): should get whatever information it needs from the ride to add to
    #                      its accumulated stats, to score if necessary, to add that score
    #                      to the RideRecord's scores
    #
    # as a model, this stores the metric_type, which are particular metric objects that need
    # to be formed with their ride_record, metric, and ride_type
    #
    use_ok("BikeGame::Model::Metric");

    #
    # individual methods have their own tables, track their own metrics,
    # should know how to look up whether or not they can score for their ride_type
    #
    # with each of these, including a (might_have => 'BikeGame::Model::Metric' => qw/record ride_type/)
    # will give instant access to the metric's record and ride type
    #
    use_ok("BikeGame::Model::Metric::Distance");
    use_ok("BikeGame::Model::Metric::Climb");
    #use_ok("BikeGame::Model::Metric::SingleRide");
    #use_ok("BikeGame::Model::Metric::Achievement");

    #
    # - Score: riderecord scores, a series of which gives the total points for the riderecord
    #
    # scores are particular to ride_record, but should also have a player ID to get them by player/date
    # score should know: num points, date, the metric they came from, the ride_type, and the player
    #
    use_ok("BikeGame::Model::Score");

    #
    # - Level: should tell you what the current level is, how many points to the next one, 
    #          how many the player has towards the next one. should know how to level itself up
    #          and to use the final levelup points to continue past the last defined
    # class methods should use configs to tell it how to build levels, how to level up
    #
    # if the level knows it's type and level number, it should by okay...
    #
    use_ok("BikeGame::Model::Level");

    #
    # player has many rides, each of which may have a ride ref
    #
    # ride has: ride_id, player, ride_type, date
    #           distance, climb, avg_speed/time,
    #           ride_ref, ride_notes, ride_url
    #
    # when getting the distance, climb, url and notes from a ride, check
    # for ride-ref first. That way an update of a ride_ref will result in
    # accurate re-accounting of ride totals
    #
    use_ok("BikeGame::Model::Ride");

    #
    # ride_refs hold player, ride_type, title, distance, climb, ride_notes, ride_url
    # 
    use_ok("BikeGame::Model::RideRef");

    #
    # lookup tables
    #
    # right now, just using configs
    # use_ok("BikeGame::Lookup::RideType"); # Road, MTB, touring? cargo?

}
