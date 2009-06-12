package BikeGame::Model::Metric::Climb;
use strict;
use base qw(BikeGame::Model::Metric::Tracker);
use BikeGame::Config;
use DateTime;

__PACKAGE__->table('metric_climb');
__PACKAGE__->columns(All   => qw(
                                 metric_type_id
                                 metric
                                 total_climb
                                 current_climb
                                )
                    );
__PACKAGE__->has_a( metric => 'BikeGame::Model::Metric' );

sub visit_ride {
    my ($self,$ride) = @_;
    my $ride_d = $ride->ride_ref ? $ride->ride_ref->climb() : $ride->climb();

    # update total climb
    $self->total_climb( $self->total_climb() + $ride_d );

    # update current climb
    $self->current_climb( $self->current_climb() + $ride_d );
    # check to see if we're over the climb required to get a point
    my $d_per_point = $self->climb_per_point($self->ride_type(), $self->current_level()->level_number);
    my $score;
    if ( $self->current_climb >= $d_per_point ) {
        # get: points, modulo, miles to score
        my $points = sprintf("%i", ($self->current_climb / $d_per_point));
        my $scoring_climb = sprintf("%i", ($self->total_climb() / $d_per_point));
        my $points_climb  = $points * $d_per_point;
        $self->current_climb( $self->current_climb - $points_climb );
        # score it: record and metric, how many points, log message, 
        my $points_word = $points > 1 ? 'point' : 'point';
        $score = $self->create_score( $points, "$points_climb feet for $points $points_word (milestone: $scoring_climb feet)", $ride->date );
    }
    $self->update();
    return $score;
}

my $_climb_per_point_cfg = BikeGame::Config->get('MetricClimb'); 
sub climb_per_point {
    my ($self, $ride_type) = @_;
    $ride_type ||= $self->ride_type();
    # get from Config for now, check player prefs at some point (also, for now, level doesn't matter)
    return $_climb_per_point_cfg->{$ride_type}->{climb_per_point};
}
sub climb_to_next_point {
    my ($self) = @_;
    # get from Config for now, check player prefs at some point (also, for now, level doesn't matter)
    return  $self->climb_per_point() - $self->current_climb();
}
# clear: start from scratch
sub clear {
    my $self = shift;
    $self->set( total_climb => '0', current_climb => '0' );
    $self->update();
}
# summary: all metric trackers should know how to give a human readable summary of what they're tracking.
sub summary {
    my $self = shift;
    my $cpp = $self->climb_per_point($self->ride_type());
    return 'Climb (total|towards next point|until next point) ' 
           . join(' | ', map { "$_ ft." } (
                                           ($self->total_climb || 0),
                                           ($self->current_climb || 0),
                                           (($cpp - $self->current_climb) || 0)
                                          )
                 );
}




=head1 BikeGame::Model::Metric::Climb

  Climb metric tracker class

=head1 insert (constructors)

  metric        => $metric_instance,
  total_climb   => $accumulated_climb,
  current_climb => $climb_towards_next_point

=head1 HAS A

  metric => parent BikeGame::Model::Metric instance

=head1 convenience

  ride_type => $dist->metric->ride_record

  current_level => $dist->metric->ride_record->current_level

=head1 Other Methods of Interest

=head2 visit_ride

  takes a ride object, extracts the climb, and:
  - adds to the accumulated climb for that ride record
  - check to see if it scores a point and rolls over the current climb total
    - if so, creates and records the score in ride_record->scores
  - returns undef or the score object

=head2 climb_per_point

  checks the configs for the climb per point for this ride record ride type

=head2 summary

  returns a string with the climb total, current towards next point, and total until the next point

=cut


# true
1;
