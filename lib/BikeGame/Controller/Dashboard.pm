package BikeGame::Controller::Dashboard;

use strict;
use base qw(BikeGame::Controller);
use BikeGame::Constant;
use BikeGame::Config;
use BikeGame::Model::Player;
use BikeGame::View::Metric::Level;
use BikeGame::View::Metric::Distance;
use BikeGame::View::Metric::Climb;
use BikeGame::View::Metric::FourWeekRide;

sub setup {
    my $self = shift;
    $self->run_modes(
                     'start'                  => 'display_summary',
                     'summary'                => 'display_summary',
                     'dispatch_metric_detail' => 'dispatch_metric_detail',
                     'login'                  => 'login',
                    );
    $self->start_mode();
    $self->error_mode();
}

sub display_summary {
    my $self = shift;
    # check logged in
    if ( ! $self->is_logged_in() ) {
        return $self->forward('login');
    }
    # we're good, continue...
    my $session = $self->session();

    # need the player
    my $player = BikeGame::Model::Player->retrieve( $session->param('player_id') );
    if ( ! $player ) {
        # no player? can't go on. logout and go back to login page
        return $self->forward('logout');
    }
    my $q = $self->query;
    my $tpl_vars = { player_name => $player->name, selected_site_menu => 'dashboard' };
    
    # create a collection of metrics by passing the player through a chain
    # that returns an array of meters
    foreach my $ride_type ( @{ BikeGame::Config->get('RideTypes') } ) {
        my $record = $player->records_by_type()->{ $ride_type };
        my $cur       = $record->current_level()->level_number;
        my $bgcolor_i = sprintf("%i", ( ( $cur - 1 ) / 2 ) );
        my $bgcolor = BikeGame::Config->get('LevelColors')->[$bgcolor_i];
        $tpl_vars->{ride_records}->{$ride_type}->{current_level} = $cur;
        $tpl_vars->{ride_records}->{$ride_type}->{level_bgcolor} = $bgcolor;
        $tpl_vars->{ride_records}->{$ride_type}->{total_points} = $record->total_points;
        $tpl_vars->{ride_records}->{$ride_type}->{meters} = [ map { $_->render_dashboard_meter($player,$ride_type) } $self->get_meters() ];
    }
    # set the default active profile
    $tpl_vars->{selected_ride_type} = $self->get_selected_ride_type();
    # get the level meter colors
    my @levels;
    foreach my $i (1..40) {
        my $bgcolor_i = sprintf("%i", ( ( $i - 1 ) / 2 ) );
        my $bgcolor = BikeGame::Config->get('LevelColors')->[$bgcolor_i];
        my ($r,$g,$b) = split(',', $bgcolor);
        my $lum = ($r * 0.3) + ($g * 0.59) + ($b * 0.11);
        my $fgcolor = $lum < 128 ? 'light-type' : 'dark-type';
        push @levels, [$i, $bgcolor, $fgcolor];
    }
    $tpl_vars->{ level_meter_levels } = \@levels;

    return $self->tt_process('dashboard.tt', $tpl_vars);
}

sub get_meters {
    return map { $_->new() } qw( BikeGame::View::Metric::Level
                                 BikeGame::View::Metric::Distance
                                 BikeGame::View::Metric::Climb
                                 BikeGame::View::Metric::FourWeekRide
                               );
}
sub get_selected_ride_type {
    return $BikeGame::Constant::RIDETYPE_ROAD;
}

sub dispatch_metric_detail {
    my $self = shift;
    $self->display_dummy();
}

# true
1;
