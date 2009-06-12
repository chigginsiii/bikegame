package BikeGame::View::Metric::Distance;

use strict;
use base qw(BikeGame::View::Metric);

sub render_dashboard_meter {
    my ($self, $player, $ride_type) = @_;
    return $self->wrap_meter('') if ( ! $player );

    # start with total miles and miles to next point
    my $record       = $player->ride_record($ride_type) || return $self->wrap_meter('') ;
    my $dist_tracker = $record->find_tracker('distance');
    my $total        = $dist_tracker->total_distance();
    my $towards_next = $dist_tracker->current_distance();
    my $to_next      = $dist_tracker->distance_to_next_point();
    my $dpp          = $dist_tracker->distance_per_point();
    return $self->wrap_meter(qq{
<h3>Distance</h3>
<div class="stat_label">Distance/Point:</div><div class="stat_value">$dpp mi.</div>
<div class="clear dottedbottom"></div>
<div class="stat_label">Total Distance:</div><div class="stat_value">$total mi.</div>
<div class="clear dottedbottom"></div>
<div class="stat_label">Next point (earned/remaining):</div><div class="stat_value">$towards_next/$to_next mi.</div>
});
}

1;
