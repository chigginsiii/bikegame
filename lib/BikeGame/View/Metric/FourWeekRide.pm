package BikeGame::View::Metric::FourWeekRide;

use strict;
use base qw(BikeGame::View::Metric);
use BikeGame::Model::Ride;
use DateTime;

sub render_dashboard_meter {
    my ($self, $player, $ride_type) = @_;
    return ->wrap_meter('') if ( ! $player );
    my $ride_record = $player->ride_record( $ride_type ) || return $self->wrap_meter('');

    # DATE: today
    my $today =  DateTime->today( time_zone => $player->timezone() );
    my ($cur_year,$cur_weeknum) = $today->week();
    my @this_week = fixup_rdc( get_rdc_by_week( $cur_year, $cur_weeknum, $ride_record ) );

    # DATE: one week ago
    my $week_ago = $today->clone();
    $week_ago->subtract( DateTime::Duration->new( weeks => 1 ) );
    my ($lastweek_year,$lastweek_weeknum) = $week_ago->week();
    my @last_week = fixup_rdc( get_rdc_by_week( $lastweek_year, $lastweek_weeknum, $ride_record ) );
    
    # DATE: this month:
    my $cur_month      = $today->strftime("%m");
    my $cur_month_abbr = $today->month_abbr();
    my @this_month = BikeGame::Model::Ride->rdc_by_yearmonth($cur_year, $cur_month, $ride_record);
    @this_month = fixup_rdc( @this_month );

    # DATE: this month:
    my $month_ago       = $today->clone();
    $month_ago->subtract( DateTime::Duration->new( months => 1 ) );
    my $last_month_year = $month_ago->year();
    my $last_month      = $month_ago->strftime("%m");
    my $last_month_abbr = $month_ago->month_abbr();
    my @last_month = BikeGame::Model::Ride->rdc_by_yearmonth($last_month_year, $last_month, $ride_record);
    @last_month = fixup_rdc( @last_month );

    # DATE: all time
    my @all_time = fixup_rdc( BikeGame::Model::Ride->rdc($ride_record) );

    my $content = qq{<h3>Rides</h3><small style="color:#666">rides/distance/climb</small>\n};
    my @stats = ( 'This Week:'                    => join(' / ', @this_week),
                  'Last Week:'                    => join(' / ', @last_week),
                  "This Month (${cur_month_abbr}-${cur_year}):"         => join(' / ', @this_month),
                  "Last Month (${last_month_abbr}-${last_month_year}):" => join(' / ', @last_month),
                  'All Time:'                     => join(' / ', @all_time),
                );

    while ( @stats ) {
        my $label = shift @stats;
        my $value = shift @stats;
        $content .= qq{<div class="stat_label">$label</div><div class="stat_value">$value</div>\n};
        $content .= qq{<div class="clear dottedbottom"></div>\n} if @stats;
    }
    return $self->wrap_meter($content);
}

# rdc == Ride/Distance/Climb
sub get_rdc_by_week {
    my ($year,$week,$ride_record) = @_;
    my @rdc = BikeGame::Model::Ride->rdc_by_yearweek($year, $week, $ride_record );
    return @rdc;
}
sub fixup_rdc {
    my ($r, $d, $c) = @_;
    return ( ($r || 0), sprintf("%.2f", $d), ($c || 0));
}

# true!
1; 
