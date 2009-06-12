package BikeGame::Model::Player;
use strict;
use base qw(BikeGame::DBI);
use BikeGame::Constant;
use BikeGame::Config;
use BikeGame::Util;
use BikeGame::Model::Ride;
use BikeGame::Model::Bike;
use BikeGame::Model::Player::Detail;

__PACKAGE__->table('player');
__PACKAGE__->columns(All   => qw(
                                 player_id
                                 name password timezone
                                )
                    );
__PACKAGE__->columns(TEMP => 'records_by_type');

# player details
__PACKAGE__->might_have( details => 'BikeGame::Model::Player::Detail' => qw/first_name last_name email/ );

# rides: player|type
__PACKAGE__->has_many( bikes => 'BikeGame::Model::Bike' );

# unique(player|ride_type)
__PACKAGE__->has_many( ride_records => 'BikeGame::Model::RideRecord');

# rides: player|type
__PACKAGE__->has_many( rides => 'BikeGame::Model::Ride', {order_by => 'date'});

# riderefs: player|type
__PACKAGE__->has_many( ride_refs => 'BikeGame::Model::RideRef');

__PACKAGE__->add_trigger( after_create => \&initialize_player );
__PACKAGE__->add_trigger( select => \&load_ride_records );



# initialize player:
sub initialize_player {
    my ($self) = @_;
    my $player_id = $self->id();

    # make sure we have a detail object
    my $detail = BikeGame::Model::Player::Detail->insert({ player_id => $player_id });

    # initialize our ride_records
    foreach my $ride_type ( @{ BikeGame::Config->get('RideTypes') }) {
        my $ride_record = BikeGame::Model::RideRecord->insert({ player    => $self,
                                                                ride_type => $ride_type,
                                                              });
    }
    # rides and ride_refs should be okay, they're just lists...
}
sub load_ride_records {
    my $self = shift;
    my @records = $self->ride_records;
    my $rec_by_type = {};
    foreach my $rec ( @records ) {
        $rec_by_type->{ $rec->ride_type } = $rec;
    }
    $self->records_by_type($rec_by_type);
}

sub lastn_rides {
    my ($self,$num) = @_;
    return BikeGame::Model::Ride->lastn_rides($num, $self->id);
}
#
# someday, these will be prefs
#
sub dollars_per_point {
    my $self = shift;
    # XXX: $dpp = $self->prefs->dollars_per_point || $config
    my $dpp = BikeGame::Config->get('DollarsPerPoint');
    return $dpp;
}

#
# total from the records
#
sub total_points {
    my $self = shift;
    my @records = $self->ride_records;
    return List::Util::sum map { $_->total_points } @records;
}
sub total_cash {
    my $self = shift;
    my @records = $self->ride_records;
    return List::Util::sum map { $_->cash } @records;
}



#
# get ride_record by type
#
sub ride_record {
    my ($self,$ride_type) = @_;
    my $ride_record = $self->records_by_type()->{ $ride_type };
    Carp::confess("Couldn't find ride record of ride type '$ride_type'") unless $ride_record;
    return $ride_record;
}

#
# add a ride to the right player record
#
# args: date (datetime instance),
#       ride_ref || ( distance | climb | ride_type
#       avg_speed || ride_time
sub add_ride {
    my ($self,$ride_params) = @_;
    my $ride_type = ( ( ref($ride_params->{ride_ref}) ? $ride_params->{ride_ref}->ride_type : undef ) || $ride_params->{ride_type} );
    if ( ! BikeGame::Util::is_valid_ride_type( $ride_type ) ) {
        # require Data::Dumper;
        # $Data::Dumper::Maxdepth = 2;
        Carp::confess "Invalid ride type: " . $ride_type . "\n";
        #  . Data::Dumper::Dumper($ride_type, $ride_params);
        
    }
    my $ride_record = $self->ride_record( $ride_type );
    if ( ! $ride_record ) {
        Carp::confess "Could not find ride record for ride type: " . $ride_type;
    }
    
    # let's give it a shot....
    my %construct = ( player      => $self,
                      ride_record => $ride_record,
                      date        => $ride_params->{date},
                      avg_speed   => $ride_params->{avg_speed},
                      ride_time   => $ride_params->{ride_time},
                      bike        => $ride_params->{bike},
                      ride_notes  => $ride_params->{ride_notes},
                    );
    # this part will either be a ride ref or values
    if ( $ride_params->{ride_ref} ) {
        $construct{ride_ref} = $ride_params->{ride_ref};
    } else {
        my @single_ride_params = qw/distance climb ride_url/;
        @construct{@single_ride_params} = @{ $ride_params }{@single_ride_params};
    }
    my $ride = BikeGame::Model::Ride->insert( \%construct );
    $ride_record->add_ride( $ride );
    return $ride;
}

sub recalc_rides {
    my $self = shift;
    # get each of the ride records
    my @records = $self->ride_records();
    # call recalc on each one, return records recalced
    return ( List::Util::sum( map { $_->recalc_rides() } @records ) || 0 );
}

=pod

=head1 BikeGame::Model::Player

=item insert() params

  name, password, timezone (Olsen)

=item details()

  my $details = $player->details;
  $details->first_name( $fname );
  $details->last_name( $lname );
  $details->email( $email );

=head2 HAS MANY

=item ride_records()

  BikeGame::Model::RideRecord, one for each RideType

=item rides()

  BikeGame::Model::Ride

=item ride_refs()

  BikeGame::Model::RideRef

=head2 Other Methods Of Interest

=item dollar_per_point()

  return the number of dollars to award for each point

=item total_points()

  returns the sum of all the total points from all ride records

=item total_cash()

  returns the sum of cash totals from all ride records

=item ride_record()

  get a ride record of a specific type

  my $mtb_record = $player->ride_record('mtb');

=item add_ride()

  adds the ride to the correct ride record, which then handles scoring, leveling, and payouts, and returns the ride.

  $player->add_ride( $ride )

=head2 SEE ALSO

  BikeGame::Model::RideRecord, BikeGame::Model::Level, BikeGame::Model::Metric,
  BikeGame::Model::Ride, BikeGame::Model::RideRef, BikeGame::Model::CashManager

=cut

# true
1;
