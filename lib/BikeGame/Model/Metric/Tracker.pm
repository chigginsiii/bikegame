package BikeGame::Model::Metric::Tracker;

use strict;
use base qw(BikeGame::DBI);
use Carp qw(croak);
use BikeGame::Model::Score;

#
# These need to be overidden to create the table and accessors
#
#__PACKAGE__->table('metric_tracker_tablename');
#__PACKAGE__->columns( All => qw( metric_type_id metric statistic statistic2 ) );
#__PACKAGE__->has_a( metric => 'BikeGame::Model::Metric');
#
sub ride_type {
    return $_[0]->metric->ride_type();
}
sub current_level {
    return $_[0]->metric->ride_record->current_level();
}

#
# visit_ride( $ride ): return BikeGame::Model::Score or undef
#
sub visit_ride {
    croak "MUST SUBCLASS!";
}
#
# this should clear the whole metric
#
sub clear {
    croak "MUST SUBCLASS!";
}
#
# summary: return a string with the essential stats of the metric tracker
#
sub summary {
    croak "MUST SUBCLASS!";
}

sub create_score {
    my ($self, $points, $msg, $date) = @_;
    my $score = BikeGame::Model::Score->insert({
                                                ride_record => $self->metric->ride_record,
                                                metric      => $self->metric,
                                                points      => $points,
                                                message     => $msg,
                                                date        => ( $date || DateTime->now()->set_time_zone( $self->metric->ride_record->player->timezone ) )
                                               });
    return $score;
}


# true
1;
