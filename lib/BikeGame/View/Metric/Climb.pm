package BikeGame::View::Metric::Climb;

use strict;
use base qw(BikeGame::View::Metric);

sub render_dashboard_meter {
    my ($self, $player, $ride_type) = @_;
    return $self->wrap_meter('') if ( ! $player );

    # start with total miles and miles to next point
    my $meter_content;
    my $record = $player->ride_record($ride_type) || return $self->wrap_meter('') ;
    my $climb_tracker = $record->find_tracker('climb');
    my $total = $climb_tracker->total_climb();
    my $towards_next = $climb_tracker->current_climb();
    my $to_next      = $climb_tracker->climb_to_next_point();
    my $cpp          = $climb_tracker->climb_per_point();
    return $self->wrap_meter(qq{
<h3>Climb</h3>
<div class="stat_label">Climb/Point:</div><div class="stat_value">$cpp ft.</div>
<div class="clear dottedbottom"></div>
<div class="stat_label">Total Climb:</div><div class="stat_value">$total ft.</div>
<div class="clear dottedbottom"></div>
<div class="stat_label">Next point (earned/remaining):</div><div class="stat_value">$towards_next/$to_next ft.</div>
                               });
}

1;
