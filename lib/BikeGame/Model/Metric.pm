package BikeGame::Model::Metric;
#
# Metric class: connects specific metric types (actual ride visitors) to ride_records, points, and scoring
#
use strict;
use base qw(BikeGame::DBI);
use BikeGame::Model::Ride;
use BikeGame::Model::Score;

__PACKAGE__->table('metric');
__PACKAGE__->columns(All => qw/
                     metric_id
                     ride_record
                     metric_type metric_type_id
                     /);
__PACKAGE__->columns(TEMP => qw/tracker/);
__PACKAGE__->has_a(ride_record => 'BikeGame::Model::RideRecord');
__PACKAGE__->add_trigger( after_create => \&initialize_tracker );
sub ride_type {
    return $_[0]->ride_record->ride_type;
}

sub initialize_tracker {
    my ($self) = @_;
    # check to see if we've loaded our ride visitor
    if ( ! $self->metric_type ) {
        Carp::confess "Could not initialize metric without a metric_type to create ride visitor";
    } elsif ( ! $self->metric_type_id ) {
        my $tracker = $self->metric_type()->insert({ metric => $self->id });
        $self->metric_type_id( $tracker->id );
        $self->update();
    }
}

# the ride visitor is the metric_type instance created from metric_type and metric_type_id,
# which does the work of collecting ride data and turning it into scoring opportunities
sub get_tracker {
    my $self = shift;
    if ( ! $self->tracker ) {
        my ($metric_type, $metric_type_id) = $self->get('metric_type', 'metric_type_id');
        my $tracker;
        eval { $tracker = $metric_type->retrieve($metric_type_id) };
        if ( $@ ) {
            Carp::confess("Could not load metric tracker of class '$metric_type' with id '$metric_type_id': $@");
        }
        $self->tracker( $tracker );
    }
    return $self->tracker();
}
sub clear_tracker {
    my $self = shift;
    $self->tracker()->clear();
}
sub visit_ride {
    my ($self,$ride) = @_;
    $self->tracker()->visit_ride($ride);
    return $ride;
}

#
# some basic reporting methods
#
sub summary {
    my $self = shift;
    my $summary = $self->get_tracker()->summary();
}

=pod

=head1 BikeGame::Model::Metric

  the generic wrapper that connects a ride record to various metric trackers.

=head1 insert (constructors)

  ride_record    => $parent_ride_record,
  metric_type    => $metric_tracker_class,
  metric_type_id => $metric_tracker_instance_id

=head1 HAS A

=head2 ride_record

  parent, BikeGame::Model::RideRecord

=head1 Other methods of interest

=head2 get_tracker

  provides the metric tracker instance (eg: the BikeGame::Metric::Distance object belonging to this ride record)

  Tracker classes currently implemented: BikeGame::Metric::Distance, BikeGame::Metric::Climb

=head2 visit_ride

  calls visit_ride($ride) on the tracker instance

=head2 summary

  calls summary() on the tracker instance

=cut

# true
1;
