#!/usr/bin/perl

use strict;
use lib qw(../lib);
use BikeGame::Model::Player;
use BikeGame::Model::Player::RideRef;
use BikeGame::Template;
use BikeGame::Constant;
use BikeGame::Util::HTML;

# XXX: need to subclass this to filter inputs and whatnot
use CGI;
use CGI::Carp qw(fatalsToBrowser);

my $cgi = new CGI;
my %params = $cgi->Vars();
my $tpl = BikeGame::Template->new();

my $player_detail_regex = qr|player_detail_(\d+)|o;
my ($player_detail_param) = grep { $_ =~ $player_detail_regex } keys %params;
if ( $player_detail_param ) {
    $params{going_to} = 'player_detail';
    $params{player_detail_param} = $player_detail_param;
    my ($player_id) = ($player_detail_param =~ $player_detail_regex);
    # look for the player name, if we don't have it, use the create player template
    my ($player) = BikeGame::Model::Player->retrieve($player_id);
    if ( ! $player ) {
        $params{player_id} = $player_id;
        display_error(\%params);
    }
    $params{player} = $player;
    display_dashboard(\%params);
} elsif ( $params{create_player} ) {
    $params{going_to} = 'create_player';
    display_create_player(\%params);
} elsif ( $params{create_player_submit}) {
    $params{coming_from} = 'create_player';
    process_create_player(\%params);
} elsif ($params{add_ride}) {
    $params{going_to} = 'add_ride';
    display_add_ride(\%params);
} elsif ($params{add_ride_from_ref}) {
    $params{going_to} = 'add_ride';
    $params{coming_from} = 'add_ride_from_ref';
    display_add_ride_from_ref(\%params);
} elsif ($params{add_ride_submit}) {
    $params{coming_from} = 'add_ride';
    process_add_ride(\%params);
} elsif ($params{player_id}) {
    $params{going_to} = 'dashboard (via player id)';
    $params{player} = BikeGame::Model::Player->retrieve($params{player_id});
    display_dashboard(\%params);
} else {
    display_error(\%params);
}


sub display_create_player {
    my $params = shift;
    my $tpl_vars = {};
    $tpl_vars->{player_name}        = $params->{player_name};
    $tpl_vars->{create_player_fail} = $params->{create_player_fail} || undef;
    $tpl_vars->{timezone_dropdown}    = BikeGame::Util::HTML->create_timezone_input();
    $tpl->display($BikeGame::Constant::TEMPLATES->{create_player}, $tpl_vars);
}

sub process_create_player {
    my $params = shift;
    my $player_name = $params->{player_name};
    my $player;
    my $tpl_vars = { player_name => $player_name };

    eval { 
        $player = BikeGame::Model::Player->insert({name => $player_name, timezone => $params->{timezone}});
    };
    if ( $@ ) {
        $params->{create_player_fail} = $@;
        display_create_player($params);
    } else {
        $player->initialize_record();
        $player->initialize_charclass($BikeGame::Constant::RIDETYPE_ROAD);
        $player->initialize_charclass($BikeGame::Constant::RIDETYPE_MTB);
        $params->{player} = $player;
        display_dashboard($params);
    }
}

sub display_dashboard {
    my $params = shift;
    my $player = $params->{player};

    # lazy typist
    my $type_road = $BikeGame::Constant::RIDETYPE_ROAD;
    my $type_mtb  = $BikeGame::Constant::RIDETYPE_MTB;

    # now!
    my $now = DateTime->now()->set_time_zone($player->timezone || 'America/New_York');

    # this will need automation...
    my $levels = { $type_road => $player->road_level(),
                   $type_mtb  => $player->mtb_level()
                 };
    my $record     = $player->record();

    # level_beguns
    my $level_begun = { 
                       $type_road => $levels->{$type_road}->first_ride ? $levels->{$type_road}->first_ride->ride_date->ymd : '',
                       $type_mtb => $levels->{$type_mtb}->first_ride ? $levels->{$type_mtb}->first_ride->ride_date->ymd : '',
                      };


    #
    # putting together the template vars...
    #

    # career mileage/climb/points
    my $level = { $type_road => {}, $type_mtb => {} };
    # career mileage/climb/points
    my $career = { $type_road => {}, $type_mtb => {} };
    # weekly stats
    my $week = { number => $now->week_number, $type_road => {}, $type_mtb => {}, };
    # monthly stats
    my $month = { name => $now->month_name, $type_road => {}, $type_mtb => {}, };
    # last ten rides
    my $last_ten = { $type_road => {}, $type_mtb => {} };
    #
    # get each of these for road and mtb
    #
    foreach my $type ( ($type_road, $type_mtb) ) {
        # this level
        $level->{$type} = {
                           begun              => $level_begun->{$type},
                           number             => $levels->{$type}->level_number,
                           total_distance     => $levels->{$type}->total_distance,
                           total_climb        => $levels->{$type}->total_climb,
                           total_points       => $levels->{$type}->total_points,
                           points_to_complete => $levels->{$type}->points_to_complete,
                           earnings           => $levels->{$type}->earnings,
                          };
                          
        # get the career stuff
        $career->{$type} = {
                            total_distance     => $record->total_distance($type),
                            total_climb        => $record->total_climb($type),
                            total_points       => $record->total_points($type),
                            total_earnings     => $record->total_earnings($type),
                           };
        
        # last ten rides
        $last_ten->{$type} = [ $record->get_last_ten_rides($type) ];

        # get the weekly/monthly ride stuff
        my @week_rides = $record->get_rides_by_week($now->week_number, $type);
        my @month_rides = $record->get_rides_by_month($now->month, $type);

        foreach my $time_unit ( ([$week, \@week_rides],[$month, \@month_rides]) ) {
            my ($hash,$rides) = @$time_unit;
            if ( ! scalar(@$rides) ) {
                $hash->{$type} = {rides => 0,
                                  distance => 0.0,
                                  avg_distance => 0.0,
                                  climb => 0,
                                  avg_climb => 0
                                 };
            } else {
                $hash->{$type} = {rides    => scalar(@$rides),
                                  distance => List::Util::sum( map { $_->distance } @$rides),
                                  climb    => List::Util::sum( map { $_->climb } @$rides)
                                 };
                $hash->{$type}->{avg_distance} = sprintf("%.1f", ($hash->{$type}->{distance} / $hash->{$type}->{rides}));
                $hash->{$type}->{avg_climb}    = sprintf("%i", ( $hash->{$type}->{climb} / $hash->{$type}->{rides}) );
            }
        }
        # that should do it, hand them to the template vars below.
    }

    my $tpl_vars = {
                    player_name => $player->name,
                    player => $player,
                    types => [ $type_road, $type_mtb ],
                    level => $level,
                    career => $career, 
                    week => $week,
                    month => $month,
                    last_ten_rides => $last_ten,
                    level_table => BikeGame::Util::HTML->create_player_level_table(),
                   };

    $tpl->display($BikeGame::Constant::TEMPLATES->{dashboard}, $tpl_vars);
}

sub display_add_ride {
    my $params = shift;
    my $player_id = $params->{player_id};

    my ($ride_ref_select, $ride);
    if ( ! $params->{add_ride_from_ref} ) {
        $ride_ref_select = BikeGame::Util::HTML->create_ride_ref_select($player_id,'ride_ref_id', 20);
        if ( $ride_ref_select ) {
            $ride_ref_select = 
                qq|<form method="POST" action="/cgi-bin/dashboard.cgi">
                <input type="hidden" name="player_id" value="$player_id" />
                $ride_ref_select <input type="submit" name="add_ride_from_ref" value="Add Ride"/>
                </form>
                |;
        }
    } else {
        $ride = $params->{ride};
    }  
    my $player = BikeGame::Model::Player->retrieve( $params->{player_id} );
    my $tpl_vars = {
        ridetype => {
            road => $BikeGame::Constant::RIDETYPE_ROAD,
            mtb  => $BikeGame::Constant::RIDETYPE_MTB,
        },
        player => $player,
        fail   => $params->{fail},
        date_form => BikeGame::Util::HTML::create_datetime_input(prefix => 'ride_date', minute_step => 5, timezone => ( $player->timezone || 'America/New_York') ),
        create_from_ref_select => $ride_ref_select,
        ride => $ride,
    };
    $tpl->display($BikeGame::Constant::TEMPLATES->{add_ride}, $tpl_vars);
}
sub display_add_ride_from_ref {
    my $params = shift;
    my $ref = BikeGame::Model::Player::RideRef->retrieve($params->{ride_ref_id});

    if ( $ref ) {
        # what params can we set...
        $params->{ride} = {
            ride_class => $ref->classtype,
            distance   => $ref->distance,
            climb      => $ref->climb,
            ride_notes => $ref->ride_notes,
            ride_url   => $ref->ride_url
            };
        $params->{made_from_ref} => 1;
    }
    display_add_ride($params);
}
sub process_add_ride {
    my $params = shift;
    my $player = BikeGame::Model::Player->retrieve($params->{player_id});
    unless ($player) {
        display_error($params);
        return;
    }
    # fix the ride time
    my ($r_h, $r_m, $r_s,
        $rd_y, $rd_m, $rd_d,
        $rd_h, $rd_min, $rd_ap) 
        = @{ $params }{ qw(ride_time_hours ride_time_minutes ride_time_seconds
                           ride_date_year ride_date_month ride_date_day
                           ride_date_hour ride_date_minute ride_date_ap
                           ) };
    # am/pm, zero padding...
    if ( $rd_ap eq 'pm' ) { $rd_h += 12; }
    foreach my $d ( ($r_h, $r_m, $r_s, $rd_m, $rd_d, $rd_h, $rd_min) ) { $d = sprintf("%02d", $d); }
    $rd_y = sprintf("%04d", $rd_y);

    # make the ride date and elapsed time
    my $ride_date = BikeGame::Model::Player::Ride::inflate_datetime(join("-",($rd_y,$rd_m,$rd_d)) . " $rd_h:$rd_min:00");
    # if avg_speed is non-zero, then we'll figure out the elapsed time ourselves.
    my $ride_time = ( $params->{avg_speed} && ( ($params->{avg_speed} + 0) != 0) ) ? undef : join(":",$r_h, $r_m, $r_s);
    
    my %ride_params = (
                       distance   => $params->{distance},
                       climb      => $params->{climb},
                       avg_speed  => $params->{avg_speed},
                       ride_time  => $ride_time,
                       ride_date  => $ride_date, 
                       ride_class => $params->{ride_class},
                       ride_notes => $params->{ride_notes},
                       ride_url   => $params->{ride_url},
                      );
    my $ride = $player->add_ride(%ride_params);
    # check to see if we're creating a ride ref from this
    if ( $params->{make_ref} ) {
        BikeGame::Model::Player::RideRef->create_from_ride($ride, $params->{ride_ref_title});
    }

    display_dashboard({player => $player});
}

sub display_error {
    my $params = shift;
    require Data::Dumper;
    my $dump = '<pre>' . Data::Dumper::Dumper($params) . '</pre>';
    $tpl->display($BikeGame::Constant::TEMPLATES->{dashboard_error}, {params => $dump});
}
