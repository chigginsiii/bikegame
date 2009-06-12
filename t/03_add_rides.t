#!/usr/bin/perl

use strict;
use Test::More qw(no_plan);
use lib qw(../lib);
use DateTime;

BEGIN {
      use_ok("BikeGame::Model::Player");
      use_ok("BikeGame::Model::Ride");
      use_ok("BikeGame::Model::RideRef");
}

#require Data::Dumper;
#require BikeGame::Model::RideRecord;
#print STDERR Data::Dumper::Dumper(BikeGame::Model::RideRecord->meta_info);


{
    my @p = BikeGame::Model::Player->search({name => 'test'});
    $_->delete() foreach @p;
}

diag("CHECKING PLAYER");
my $player = BikeGame::Model::Player->insert({name => 'test', password => 'testy', timezone => "America/Los_Angeles"});

##
## POPULATING TEST RIDER:
##
# my $player = BikeGame::Model::Player->retrieve(name => 'test');
#$player->initialize_player();
isa_ok($player, 'BikeGame::Model::Player');
ok($player->id, 'player id after insert: ' . $player->id);

#
# Here's the scenario:
# 1. we create 2 ride refs
#    - are they ride refs?
# 2. we create 6 rides, 3 using the two ride refs
#    - test the distance, climb, notes, and url methods on the rides that have refs
# 3. we add them to the player, checking the distance, climb, speed metrics, and level along the way
#

diag("CREATING RIDE REFS");
my $ref_ctr = 1;
my %refs;
foreach my $args ( { player => $player, ride_type => 'road', title => 'ride ref 1: road 13 300', 
                     distance => '25.00', climb => 300, ride_notes => 'first ride ref, road, 13 miles, 300 feet' },
                   { player => $player, ride_type => 'road', title => 'ride ref 2: mtb 19 900', 
                     distance => '100.00', climb => 900, ride_notes => 'second ride ref, mtb, 19 miles, 900 feet' },
                   { player => $player, ride_type => 'road', title => 'ride ref 3: road 25 800', 
                     distance => '65.00', climb => 800, ride_notes => 'third ride ref, road, 25 miles, 800 feet' }
                 ) {
    $refs{$ref_ctr} = BikeGame::Model::RideRef->insert( $args );
    # isa_ok($refs{$ref_ctr}, 'BikeGame::Model::RideRef');
    #foreach my $key ( keys %$args) {
        # is($refs{$ref_ctr}->get($key), $args->{$key}, "red ref $ref_ctr: $key");
    #}
    $ref_ctr++;
}

diag("CREATING RIDES");
# create a ride:
# need:        player
# need either: ride ref
#              ride_type distance climb ride_notes ride_url
# can have:    avg_speed || ride_time || both, really
my @ride_args = ( { player => $player, ride_type => 'road', distance => '15.74', climb => 450,
                    ride_notes => 'test test 1', ride_url => 'http://example.com/1', avg_speed => 15.8 },
                  { player => $player, ride_type => 'mtb', distance => '21.32', climb => 940,
                    ride_notes => 'test test 2', ride_url => 'http://example.com/2', ride_time => '02:14:43' },
                  { player => $player, ride_ref => $refs{2}, ride_time => '01:43:43' },
                  { player => $player, ride_type => 'road', distance => '31.85', climb => 653,
                    ride_notes => 'test test 4', ride_url => 'http://example.com/4', ride_time => '02:02:15' },
                  { player => $player, ride_ref => $refs{3}, ride_time => '01:31:10' },
                  { player => $player, ride_type => 'road', distance => '8.42', climb => 106,
                    ride_notes => 'test test 6', ride_url => 'http://example.com/6', ride_time => '00:35:56' },
                  { player => $player, ride_ref => $refs{1}, ride_time => '00:48:34' },
                );

# start the rides on 7/1/2008
my $datetime = DateTime->new( year => 2008, month => 07, day => 01, hour => 10, minute => 30, second => 0, time_zone => $player->timezone );
my $counter = 1;
for ( my $i = 1; $i <= 52; $i++ ) {            # week number 52
    for ( my $j = 0; $j <= $#ride_args; $j++ ) # rides that week
    {
        my $iteration = $counter++;
        my $add_ride_args = $ride_args[$j];

        $add_ride_args->{date} = $datetime;
        if ( $add_ride_args->{ride_notes} ) {
            $add_ride_args->{ride_note} = $add_ride_args->{ride_notes} . " iteration: $iteration";
        }
        my $ride = $player->add_ride( $add_ride_args );
        # isa_ok($ride, 'BikeGame::Model::Ride', (" ride number: $iteration, week:ride => " . ($i +1) . ':' . ($j + 1)) );
        if ( $j == $#ride_args ) {
            # check levels
            my $summary = '';
            my $records = $player->ride_records;
            while ( my $rec = $records->next ) {
                $summary .= level_summary($rec);
            }
            diag("Level check for week $iteration: \n$summary\n");
        }
    }
    $datetime->add( days => 1 );
}

diag("Player total points: " . $player->total_points . ", total cash: \$" . $player->total_cash );

sub level_summary {
    my $rec = shift;
    my $dist  = $rec->find_tracker($BikeGame::Constant::METRICTYPE_DISTANCE);
    # isa_ok($dist, 'BikeGame::Model::Metric::Distance');
    my $climb = $rec->find_tracker($BikeGame::Constant::METRICTYPE_CLIMB);
    # isa_ok($climb, 'BikeGame::Model::Metric::Climb');
    my $summary .= 'Level:Ride Type: (' . $rec->current_level->level_number . ':' . $rec->ride_type . ') ' 
    . ' total points | dollars: ' . $rec->total_points . ' | $' . $rec->cash . "\n"
    . ' - dist (total/cur): (' . $dist->total_distance . '/' . $dist->current_distance . ")\n"
    . ' - climb (total/cur): (' . $climb->total_climb . '/' . $climb->current_climb . ")\n";
    return $summary;            
}
