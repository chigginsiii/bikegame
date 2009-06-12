package BikeGame::View::Metric::Level;

use strict;
use base qw(BikeGame::View::Metric);
use DateTime;

sub render_dashboard_meter {
    my ($self, $player, $ride_type) = @_;
    return ->wrap_meter('') if ( ! $player );

    my $ride_record = $player->ride_record( $ride_type ) || return $self->wrap_meter('');
    # date level begun
    my $cur_level = $ride_record->current_level();
    # how many points does it take to clear this level
    # how many total points does the player have here
    # how many points to the next level
    # maybe do a graph?
    my $points_current  = $cur_level->points_current();
    my $lvl_num         = $cur_level->level_number();
    my $pts_to_complete = $cur_level->points_to_complete();
    my $pts_to_levelup  = $cur_level->points_to_levelup();
    # formatted: "Sun, Jan  1 2000", then strip out extra whitespace
    my ($date_begun, $days_since_date_begun);
    my $date_begun_obj = $cur_level->date_begun();
    if ( $date_begun_obj ) {
        $date_begun_obj->truncate(to => 'day');
        $date_begun = $date_begun_obj->strftime("%b %e, %Y");
        $date_begun =~ s/\s{2,}/ /go;
        my $today = DateTime->today();
        $days_since_date_begun = $today - $date_begun_obj;
        $days_since_date_begun = $days_since_date_begun->in_units('days');
    }

    my $content = "<h3>Level Info</h3>\n";
    my @stats = ( 'Started:'   => "$date_begun<br/>($days_since_date_begun days ago)",
                  'Points to Complete:' => $pts_to_complete,
                  'Earned/Remaining' => "$points_current/$pts_to_levelup",
                );

    while ( @stats ) {
        my $label = shift @stats;
        my $value = shift @stats;
        $content .= qq{<div class="stat_label">$label</div><div class="stat_value">$value</div>\n};
        $content .= qq{<div class="clear dottedbottom"></div>\n} if @stats;
    }
    return $self->wrap_meter($content);
}


# true!
1; 
