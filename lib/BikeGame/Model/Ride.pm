package BikeGame::Model::Ride;
use strict;
use base qw(BikeGame::DBI);
use Class::DBI::Pager;
use BikeGame::Util;
use BikeGame::Util::DateTime;

__PACKAGE__->table('ride');
__PACKAGE__->columns(All  => qw(
                                ride_id
                                player ride_record date week_number
                                distance climb avg_speed ride_time
                                ride_ref ride_notes ride_url
                                bike
                                )
                    );
__PACKAGE__->has_a( player      => 'BikeGame::Model::Player');
__PACKAGE__->has_a( ride_record => 'BikeGame::Model::RideRecord' );
__PACKAGE__->has_a( ride_ref    => 'BikeGame::Model::RideRef' );
__PACKAGE__->has_a( bike        => 'BikeGame::Model::Bike' );
__PACKAGE__->has_a( date    => 'DateTime', 
                    inflate => \&from_mysql,
                    deflate => \&to_mysql
                  );

# inflate/deflate routines for date objects
sub from_mysql {
    my ($date_str,$self) = @_;
    return BikeGame::Util::DateTime->from_mysql( $date_str, $self->player->timezone );
}
sub to_mysql {
    my ($dt, $self) = @_;
    return BikeGame::Util::DateTime->to_mysql( $dt );
}

# get the ride record's ride type
sub ride_type {
    my $self = shift;
    return $self->ride_record->ride_type;
}

# check to see if the ride has a ride ref to provide values
sub checkref {
    my ($self,$param_name) = @_;
    my $ret = undef;
    if ( ref($self->ride_ref) ) {
        $ret = $self->ride_ref->get($param_name);
    } else {
        $ret = $self->get($param_name);
    }
    return $ret;
}

# overriding avg speed
sub avg_speed {
    my ($self,$speed) = @_;
    my $retval;
    my $avg_spd;
    if ( $speed ) {
        # poss 1: we're setting this value
        $retval = $self->set( avg_speed => $speed );
    } elsif ( $avg_spd = $self->get('avg_speed') ) {
        # poss 2: we have this value already
        $retval = $avg_spd;
    } elsif ( my $time = $self->get('ride_time') ) {
        # poss 3: we don't have it, but we have ride_time
        my $distance = $self->checkref('distance');
        $retval = sprintf("%.1f", ( BikeGame::Util::calc_speed_from_time_and_distance( $time, $distance )));
    }
    # poss 4: this wasn't meant to be measured, in which case it's already empty
    return $retval;
}

# overriding ride_time, just like avg_speed
sub ride_time {
    my ($self,$time) = @_;
    my $retval;
    if ( $time ) {
        # poss 1: we're setting this value
        $retval = $self->set( ride_time => $time );
    } elsif ( my $ride_time = $self->get('ride_time') ) {
        # poss 2: we have this value already
        $retval = $ride_time;
    } elsif ( my $spd = $self->get('avg_speed') ) {
        # poss 3: we don't have it, but we have avg_speed
        my $distance = $self->checkref('distance');
        $retval = BikeGame::Util::calc_time_from_speed_and_distance( $spd, $distance );
    }
    # poss 4: this wasn't meant to be measured, in which case it's already empty
    return $retval;
}
sub find_by_player {
    my ($class, $player_id) = @_;
    return $class->search( player => $player_id, { order_by => 'date DESC' } );
}

sub search_date_range {
    my ($class, %params) = @_;
    my $where_clause = "WHERE 1\n";
    # where conditions
    if ( my $min = $params{min} ) {
        $where_clause .= " AND date > $min\n";
    }
    if ( my $max = $params{max} ) {
        $where_clause .= " AND date < $max\n";
    }
    # ordering, limits
    my $order_clause = "ORDER BY date " . ( $params{asc} ? 'ASC' : 'DESC' ) . "\n";
    if ( my $limit = $params{limit} ) {
        $order_clause .= " LIMIT $limit";
    }
    return __PACKAGE__->retrieve_from_sql( $where_clause.$order_clause );
}


__PACKAGE__->set_sql( rcd_by_week => '
SELECT count(*), 
       sum( IF (ride.ride_ref, ride_ref.distance, ride.distance) ),
       sum( IF (ride.ride_ref, ride_ref.climb,    ride.climb) )
FROM   ride LEFT JOIN ride_ref ON ( ride.ride_ref = ride_ref.ride_ref_id )
WHERE  ride.ride_record = ?
  AND  YEARWEEK(date,3) = ?
');
sub rdc_by_yearweek {
    my ($class,$year,$week,$ride_record) = @_;
    $class = ref($class) || $class;
    my $yearweek = $year . sprintf("%02i", $week);
    my $sth = $class->sql_rcd_by_week();
    $sth->execute($ride_record->id, $yearweek);
    my @rdc = @{ $sth->fetchrow_arrayref() };
    $sth->finish();
    return @rdc;
}

__PACKAGE__->set_sql( rcd_by_yearmonth => '
SELECT count(*), 
       sum( IF (ride.ride_ref, ride_ref.distance, ride.distance) ),
       sum( IF (ride.ride_ref, ride_ref.climb,    ride.climb) )
FROM   ride LEFT JOIN ride_ref ON ( ride.ride_ref = ride_ref.ride_ref_id )
WHERE  ride.ride_record = ?
  AND  DATE_FORMAT(ride.date, "%Y") = ?
  AND  DATE_FORMAT(ride.date, "%m") = ?
');
sub rdc_by_yearmonth {
    my ($class,$year,$month,$ride_record) = @_;
    $class = ref($class) || $class;
    my $sth = $class->sql_rcd_by_yearmonth();
    $sth->execute($ride_record->id, $year, $month);
    my @rdc = @{ $sth->fetchrow_arrayref() };
    $sth->finish();
    return @rdc;
}


__PACKAGE__->set_sql( rcd => '
SELECT COUNT(*),
       SUM( IF (ride.ride_ref, ride_ref.distance, ride.distance) ),
       SUM( IF (ride.ride_ref, ride_ref.climb, ride.climb) )
FROM   ride LEFT JOIN ride_ref ON ( ride.ride_ref = ride_ref.ride_ref_id )
WHERE  ride.ride_record = ?
');
sub rdc {
    my ($class,$ride_record) = @_;
    $class = ref($class) || $class;
    my $sth = $class->sql_rcd();
    $sth->execute($ride_record->id);
    my @rdc = @{ $sth->fetchrow_arrayref() };
    $sth->finish();
    return @rdc;
}

__PACKAGE__->set_sql( count_by_record => 'SELECT COUNT(*) FROM __TABLE__ WHERE ride_record = ?' );
sub count_by_record {
    my ($self,$ride_record) = @_;
    my $ride_record_id = $ride_record->id();
    return $self->sql_count_by_record()->select_val($ride_record_id);
}

=head1 BikeGame::Model::Ride

  ride object that records the date, distance, climb, speed and type of a ride

=head1 insert (constructor)

  player      => $player_instance,
  ride_record => $ride_record_instance,
  date        => $datetime_instance,
  week_number => $number_0_53,
  distance    => $decimal_000_00,
  climb       => $int_00000,
  avg_speed   => $decimal_00_0,
  ride_time   => $ride_time,         # eg: '01:34:30' => 1 hr 34 m 30 s
  ride_ref    => $ride_ref_instance, # BikeGame::Model::RideRef
  ride_notes  => $text,
  ride_url    => $url

=head1 Ride Refs

  Instead of providing the ride_record, distance, climb, notes, and url,
  you may instead provide a ride_ref object, which is a set of saved ride
  attributes.  If at some point you remap a common ride, this would allow
  all rides linked to that reference to re-record, re-score, and re-level

=cut

# true
1;
