package BikeGame::Model::RideRecord;
use strict;
use base qw(BikeGame::DBI);

use BikeGame::Config;
use BikeGame::Constant;
use BikeGame::Util;
use List::Util;
use List::MoreUtils;

# no sense in having to reach into the config every time we need this
my $_ride_types = BikeGame::Config->get("RideTypes");
die "Could not get ride types from config 'RideTypes'!" unless $_ride_types;

BEGIN {
    my @ride_types = @{ BikeGame::Config->get("RideTypes") };
    foreach my $ride_type ( @ride_types ) {
        my @trackers = @{ BikeGame::Config->get("RideRecordMetrics")->{$ride_type} };
        foreach my $tracker ( @trackers ) {
            eval("use $tracker;");
        }
    }
}

__PACKAGE__->table('ride_record');
__PACKAGE__->columns(All   => qw(
                                 ride_record_id
                                 player
                                 ride_type
                                )
                    );
__PACKAGE__->columns( TEMP => qw/curlvl/ );
__PACKAGE__->has_a(player => 'BikeGame::Model::Player');
# XXX: 'ride-metrics' doesn't convey what they are. They're metric containers,
#      the actual metric trackers get loaded later.
__PACKAGE__->has_many(ride_metrics => 'BikeGame::Model::Metric');
__PACKAGE__->has_many(levels       => 'BikeGame::Model::Level', {order_by => 'level_number'});
__PACKAGE__->has_many(scores       => 'BikeGame::Model::Score', {order_by => 'date DESC'});
__PACKAGE__->has_many(rides        => 'BikeGame::Model::Ride', {order_by => 'date'});
__PACKAGE__->might_have(cash_mgr   => 'BikeGame::Model::CashManager' => qw/cash/ );

# initialize all the little children
__PACKAGE__->add_trigger(after_create => \&initialize_ride_record);

# add a constraint to make sure the ride_type is in the configs
__PACKAGE__->constrain_column( ride_type => \&BikeGame::Util::is_valid_ride_type );

# this one's a pointer to a Class and ID, BikeGame::Model::Metric::<ride_type>
# XXX: i think this one's going to need to be manual...
sub trackers {
    my $self = shift;
    my @ride_metrics = $self->ride_metrics;
    return map { $_->get_tracker } @ride_metrics;
}

# pass it a name (found in BikeGame::Constant), or a class
my %tracker_name_by_class = %{ BikeGame::Config->get('TrackerTypeNames') };
my %tracker_class_by_name = reverse( %tracker_name_by_class );
sub find_tracker {
    my ($self,$name) = @_;
    my @ride_metrics = $self->ride_metrics;
    my $tracker = 
      List::Util::first { $_->[1] eq $name 
                          || $_->[1] eq $tracker_class_by_name{$name}
                      }
        map { [ $_, ref($_) ] } 
        map { $_->get_tracker }
        @ride_metrics;
    return $tracker ? $tracker->[0] : undef;
}

#
# initialize the ride record
#
sub initialize_ride_record {
    my $self = shift;
    $self->initialize_metrics();
    $self->initialize_levels();
    $self->initialize_cash();
    $self->clear_record();
    # rides and scores should be fine, they're just lists
}
sub initialize_metrics {
    my $self = shift;
    return undef unless $self->id();
    foreach my $tracker_type ( @{ BikeGame::Config->get('RideRecordMetrics')->{$self->ride_type} } ) {
        my $metric = BikeGame::Model::Metric->insert({ ride_record => $self, metric_type => $tracker_type });
    }
}
sub initialize_levels {
    my $self  = shift;
    # check to see if this player has any rides on this record, then any at all
    # to see what the original date is since we don't track when the player was created (duh)
    my ( $rec_ride )  = BikeGame::Model::Ride->search( ride_record => $self, { order_by => 'date ASC' } );
    my ( $plyr_ride ) = BikeGame::Model::Ride->search( player => $self->player(), { order_by => 'date ASC' } );
    my $init_date = $rec_ride 
                    ? $rec_ride->date 
                    : $plyr_ride
                      ? $plyr_ride->date
                      : DateTime->now( time_zone => $self->player->timezone() );
    my $level = BikeGame::Model::Level->insert({ ride_record => $self, date_begun => $init_date });
}
sub initialize_cash {
    my $self     = shift;
    my $cash_mgr = BikeGame::Model::CashManager->insert({ ride_record_id => $self, cash => '0' });
}

#
# Level/Metric utils
#
sub current_level {
    my $self = shift;
    # this should be a ref to a ref
    my $cur_level;
    unless ( $self->curlvl && ( $cur_level = ${ $self->curlvl() } ) ) {
        my @levels = $self->levels;
        if ( ! @levels ) {
            $self->initialize_levels();
            @levels = $self->levels();
        }
        $cur_level = $levels[$#levels];
        $self->curlvl( \$cur_level );
    }
    return $cur_level;
}
sub set_current_level {
    my ($self,$curlvl) = @_;
    $self->curlvl( \$curlvl );
}

sub total_points {
    my $self = shift;
    my @scores = $self->scores;
    return 0 unless @scores;
    return List::Util::sum map { $_->points } @scores;
}
sub scores_by_tracker_type {
    my ($self,$t_type) = @_;

    # quick type check
    if ( $t_type && ! BikeGame::Util::is_valid_tracker_type( $t_type ) ) {
        Carp::confess("Invalid metric tracker type name: $t_type");
    }

    my @scores = $self->scores;
    return unless @scores;
    
    my $names = BikeGame::Config->get('TrackerTypeNames');
    my %scores_by_tracker;
    foreach my $score ( @scores ) {
        my $tracker_name = $names->{$score->metric->metric_type};
        $scores_by_tracker{$tracker_name} ||= [];
        push @{ $scores_by_tracker{$tracker_name} }, $score;
    }

    if ( $t_type ) {
        return $scores_by_tracker{$t_type};
    } else {
        return \%scores_by_tracker;
    }
}

sub add_ride {
    my ($self,$ride) = @_;
    my @trackers = $self->trackers;
    # check to see:
    # - if this is the first ride of this record,
    # - if the ride date is earlier than the level's date_begun
    # in either case, set the date begun to the ride's datetime
    my $cur_level = $self->current_level;
    my $ride_count = BikeGame::Model::Ride->count_by_record( $self );
    if ( $ride_count <= 1 || $ride->date < $cur_level->date_begun  ) {
        $cur_level->date_begun( $ride->date );
        $cur_level->update();
    }
    # run it through the trackers and score/level up
    foreach my $tracker ( @trackers ) {
        my $score = $tracker->visit_ride( $ride );
        if ( $score ) {
            my $over = $cur_level->add_points( $score->points, $ride->date() );
            # if the current level completes, it will return 0 or more points
            # to create the next level. if there's enough points to level
            # immediately, this should create the next level.
            while ( defined( $over ) ) {
                my $init_points = $over;
                my $new_level = $cur_level->create_next_level(0,$ride->date);
                $over = $new_level->add_points($init_points);
                $cur_level = $new_level;
            }
            $self->set_current_level( $cur_level );
            $self->update();
            $self->cash_mgr->cash( $self->cash_mgr->calc_cash );
            $self->cash_mgr->update();
        }
    }
    return $ride;
}

sub clear_record {
    my $self = shift;

    # clear each of the metric trackers
    $_->clear() foreach $self->trackers();
    # clear the levels
    my $levels = BikeGame::Model::Level->search( ride_record => $self->id() );
    $levels->delete_all();
    # clear the scores
    my $scores = BikeGame::Model::Score->search( ride_record => $self->id() );
    $scores->delete_all();
    # clear the cash
    my $cash_mgr = $self->cash_mgr();
    $cash_mgr->clear() if $cash_mgr;

    return;
}

sub recalc_rides {
    my $self = shift;
    $self->clear_record();
    # call $self->add_ride( ) foreach of the rides
    my $rides = $self->rides();
    my $count = 0;
    my @rides = $self->rides();
    foreach my $ride ( @rides ) {
        $self->add_ride( $ride );
        $count++;
    }
    return $count;
}
=pod

=head1 BikeGame::Model::RideRecord

  A record of rides, ride metrics, scores, levels, and cash for a particular ride type (road, mtb, etc)

=head1 insert() (Constructor args)

  player    => $player_obj,
  ride_type => $valid_ride_type

  note: it should be mentioned that creation of these is handled automatically when a player is initialized

=head1 HAS A:

=head2 player

  returns the parent player obj

=head1 HAS MANY:

=head2 ride_metrics

  series of metric objects, each of which contains a metric tracker. A ride record will not have two metrics of the same type

  See BikeGame::Model::Metric for more details

=head2 levels

  array of level objects, see BikeGame::Model::Level for more details

  $player->current_level is a reference to the last level on the stack, and should always point to the current level.

=head2 scores

  array of score objects, ordered by date, see BikeGame::Model::Score for more details

=head2 rides

  array of rides from this ride record, sorted by dates descending (newest first),
  see BikeGame::Model::Ride for more details

=head1 MIGHT HAVE (imported accessors)

=head2 cash_mgr

  BikeGame::Model::CashManager, one per ride record. Imports the method 'cash' as an accessor,
  See BikeGame::Model::CashManager for more details.

=head1 Other Methods of Interest

=head2 trackers

  returns the metric trackers from the ride record metric objects

=head2 find_tracker

  takes a tracker name, returns that tracker object if it exists, undef if not.

=head2 current_level

  stored as a reference to a level object, calling this should always give you the current level

=head2 set_current_level

  takes a BikeGame::Model::Level object, and sets it as the ride record current level

=head2 total_points

  returns the ride record total points from all scores

=head2 scores_by_tracker_type

  given a tracker type name, returns a list of the scores from that metric;
  without args, returns an hashref of score lists keyed by tracker type

=head2 add_ride

  typically called from $player->add_ride(), this allows each of the metric trackers
  to "visit" the ride, where they add to the metric accumulated values, generate the score
  objects if the metric scores, and checks for level ups. Returns the ride object.

=cut

# true
1;
