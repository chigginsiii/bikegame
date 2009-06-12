package BikeGame::Model::Metric::Distance;
use strict;
use base qw(BikeGame::Model::Metric::Tracker);
use BikeGame::Model::Score;
use DateTime;

__PACKAGE__->table('metric_distance');
__PACKAGE__->columns(All   => qw(
                                 metric_type_id
                                 metric
                                 total_distance
                                 current_distance
                                )
                    );
__PACKAGE__->has_a( metric => 'BikeGame::Model::Metric' );

# XXX: a lot of this needs to be in a superclass, perhaps BikeGame::Model::Metric::Tracker
sub visit_ride {
    my ($self,$ride) = @_;
    my $ride_d;
    if ( $ride->ride_ref ) {
        $ride_d = $ride->ride_ref->distance;
    } else {
        $ride_d = $ride->distance();
    }

    # update total distance
    $self->total_distance( $self->total_distance() + $ride_d );

    # update current distance
    $self->current_distance( $self->current_distance() + $ride_d );
    # check to see if we're over the distance required to get a point
    my $d_per_point = $self->distance_per_point($self->ride_type());
    my $score;
    if ( $self->current_distance >= $d_per_point ) {
        # get: points, modulo, miles to score
        my $points = sprintf("%i", ($self->current_distance / $d_per_point));
        # scoring distance is the cumulative total of how many scoring miles
        my $scoring_distance = sprintf("%i", ($self->total_distance - ($self->total_distance() % $d_per_point)) );
        my $points_distance  = $points * $d_per_point;
        $self->current_distance( $self->current_distance - $points_distance );
        # score it: record and metric, how many points, log message, 
        my $point_word = $points > 1 ? 'point' : 'point';
        $score = $self->create_score( $points, "$points_distance miles for $points $point_word (milestone: $scoring_distance mi.)", $ride->date );
    }
    $self->update();
    return $score;
}

my $_dpp_config = BikeGame::Config->get('MetricDistance');
sub distance_per_point {
    my ($self, $ride_type) = @_;
    $ride_type ||= $self->ride_type;
    # get from Config for now, check player prefs at some point
    return _fmt($_dpp_config->{$ride_type}->{distance_per_point});
}
sub distance_to_next_point {
  my ($self) = @_;
  return _fmt( ($self->distance_per_point - $self->current_distance) );
}
#
# clear: start everything over again from zip
#
sub clear {
    my ($self) = @_;
    $self->set( total_distance => '0.00', current_distance => '0.00' );
    $self->update;
}

# summary: all metric trackers should know how to give a human readable summary of what they're tracking.
sub summary {
    my $self = shift;
    my $dpp = $self->distance_per_point($self->ride_type());
    return 'Distance (total|towards next point|until next point) ' 
           . join(' | ', map { "$_ mi" } (
                                           ($self->total_distance || 0),
                                           ($self->current_distance || 0),
                                           (($dpp - $self->current_distance) || 0)
                                          )
                 );
}

sub _fmt {
    return sprintf("%.2f", $_[0]);
}

=head1 BikeGame::Model::Metric::Distance

  Distance metric tracker class

=head1 insert (constructors)

  metric           => $metric_instance,
  total_distance   => $accumulated_dist,
  current_distance => $dist_towards_next_point

=head1 HAS A

  metric => parent BikeGame::Model::Metric instance

=head1 convenience

  ride_type => $dist->metric->ride_record

  current_level => $dist->metric->ride_record->current_level

=head1 Other Methods of Interest

=head2 visit_ride

  takes a ride object, extracts the distance, and:
  - adds to the accumulated distance for that ride record
  - check to see if it scores a point and rolls over the current distance total
    - if so, creates and records the score in ride_record->scores
  - returns undef or the score object

=head2 distance_per_point

  checks the configs for the distance per point for this ride record ride type

=head2 summary

  returns a string with the distace total, total towards next point, and total until the next point

=cut

# true
1;
