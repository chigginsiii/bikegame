package BikeGame::Model::Level;

use strict;
use base qw(BikeGame::DBI);
use List::Util;
use DateTime;
use BikeGame::Config;
use BikeGame::Util::DateTime;
use BikeGame::Model::RideRecord;
use DateTime;
use Carp;

__PACKAGE__->table('level');
__PACKAGE__->columns(All => qw(
                               level_id
                               ride_record
                               level_number
                               points_current points_to_complete
                               date_begun date_completed
                              )
                    );
__PACKAGE__->has_a( ride_record => 'BikeGame::Model::RideRecord' );
__PACKAGE__->has_a( date_begun => 'DateTime',
                    inflate    => \&from_mysql,
                    deflate    => \&to_mysql,
                  );
__PACKAGE__->has_a( date_completed => 'DateTime',
                    inflate        => \&from_mysql,
                    deflate        => \&to_mysql,
                  );
#
# Triggers / trigger subs
#

# inflate/deflate routines for date objects
sub from_mysql {
    my ($date_str,$self) = @_;
    return BikeGame::Util::DateTime->from_mysql( $date_str, $self->timezone );
}
sub to_mysql {
    my ($dt, $self) = @_;
    return BikeGame::Util::DateTime->to_mysql( $dt );
}


# when we set the ride type, populate the level points
__PACKAGE__->add_trigger(select => \&load_level_points);
sub level_points {
    my ($self,$points_array) = @_;
    if ( $points_array ) {
        Carp::confess("Couldn't load level points for ride type: " . $self->ride_type) unless ref $points_array;
        $self->{__POINTS_ARRAY} = $points_array;
    }
    return $self->{__POINTS_ARRAY};
}
sub load_level_points {
    my $self = shift;
    my $level_points = BikeGame::Config->get('Levels')->{$self->ride_type};
    $self->level_points( $level_points );
    return;
}

# create trigger: set level number to 1, everything else to 0
__PACKAGE__->add_trigger(before_create => \&initialize_level);
sub initialize_level {
    my $self = shift;
    unless ( $self->level_number ) {
        $self->level_number(1);
        $self->points_to_complete( $self->lookup_points_to_complete( 1 ) );
    }
    $self->points_current(0) if ! defined $self->points_current;
    if ( ! defined $self->date_begun ) {
        my $begin_date = DateTime->now( time_zone => ( $self->ride_record->player->timezone() ) );
        $self->date_begun( $begin_date );
    }
}

#
# virtual accessors
#
sub ride_type {
    return $_[0]->ride_record->ride_type;
}
sub player {
    return $_[0]->ride_record->player;
}
sub timezone {
    return $_[0]->player->timezone;
}
sub points_to_levelup {
    my $self = shift;
    return $self->points_to_complete - $self->points_current;
}

#
# utility methods
#


# this typically gets called from the ride record's add_points($points) method
# return points over that required to complete if completed.
sub add_points {
    my ($self, $points, $date) = @_;
    $points ||= 0;
    my $retval = undef;
    if ( $points >= $self->points_to_levelup ) {
        # complete this level
        my $over = $points - $self->points_to_levelup;
        $self->points_current( $self->points_to_complete );
        $self->date_completed( $date || DateTime->now( time_zone => $self->timezone ) );
        $retval = $over;
    } else {
        # add to current points and continue...
        $self->points_current( $self->points_current + $points );
    }
    $self->update();
    return $retval;
}

sub create_next_level {
    my ($self, $init_pts, $date) = @_;
    my $next_level_num = ( $self->level_number + 1 );
    my $pts_to_comp    = $self->lookup_points_to_complete( $next_level_num );
    my $constructor = {
                       ride_record        => $self->ride_record,
                       level_number       => $next_level_num,
                       points_current     => ( $init_pts || 0 ),
                       points_to_complete => $pts_to_comp,
                       date_begun         => ( $date || DateTime->now( time_zone => $self->timezone ) ),
                      };
    my $next_level;
    eval { $next_level = __PACKAGE__->insert( $constructor ); };
    if ( $@ ) {
        Carp::confess("Could not create next level: $@\n");
    }
    return $next_level;
}

sub lookup_points_to_complete {
    my ($self,$level)      = @_;
    my $ride_type          = $self->ride_type;
    my @level_points       = @{ $self->level_points() };
    my $points_to_complete = $level_points[$level];
    # if we're out past the end of the defined levels, use the last one
    if ( ! $points_to_complete && $level > $#level_points ) {
        $points_to_complete = $level_points[ $#level_points ];
    }
    return $points_to_complete;
}
sub lookup_base_points {
    my ($self,$level) = @_;
    my $ride_type     = $self->ride_type;
    my $level_points  = $self->level_points();
    my $points_base   = List::Util::sum( @{ $level_points }[1..(( $level || $self->level_number) - 1)] );
    return $points_base;
}

#
# convenience methods for controllers
#
sub find_by_player_and_date_begun {
    my ($class,$player,$earliest,$latest) = @_;
    die "No player id!" unless ( $player && $player->id() );

    # get ride record id's
    my @records = $player->ride_records();
    my @record_ids = map { $_->id() } @records;
    my $where = "ride_record IN (" . join(',', map { qq{'$_'} } @record_ids) . ")\n";

    if ( $earliest && $latest ) {
        $where .= "AND date_begun BETWEEN '$earliest' AND '$latest'";
    } elsif ( $earliest ) {
        $where = "AND date_begun > '$earliest'";
    } elsif ( $latest ) {
        $where = "AND date_begun < '$latest'";
    }
    return __PACKAGE__->retrieve_from_sql("$where\nORDER BY date_begun");
}

=pod

=head1 BikeGame::Model::Level

  keeps track of level information for a ride record instance, including level number, 
  points required to advance, and points accumulated towards the next level

=head1 insert (constructors)

  ride_record        => $parent_ride_record,
  level_number       => $num,
  points_current     => $points_to_begin_with,
  points_to_complete => $points_required_to_level_up,
  date_begun         => $datetime_instance,
  date_completed     => $datetime_instance_too,

=head1 HAS A

=head2 ride_record

  the parent ride record instance

=head1 Other Methods of Interest

=head2 level_points

  returns an array with points required to complete each level for this ride type, indexes are aligned to levels.

=head2 ride_type

  convenience for $level->ride_record->ride_type

=head2 player

  convenience for $level->ride_record->player

=head2 timezone

  convenience for $level->ride_record->player->timezone

=head2 points_to_levelup

  convenience for $level->points_to_complete - $level->points_current

=head2 add_points

  - adds points to the level total
  - if the points finish the level
    - completes the current level
    - creates the next level and sets ride_record->current_level with it

=head2 create_next_level

  takes the points to begin the level with, gets the values for completing
  the level, creates the level in the db and returns the new level object.

=head2 lookup_points_to_complete

  takes a level number, uses the ride record ride type, and looks up the points
  required to complete that level number of that ride type from the 'Levels' entry
  in BikeGame::Config. If the level requested is higher than the levels defined
  in the config, it returns the values from the highest defined level.

=head2 lookup_base_points

  given a level number (n), attempts to return the sum of points required to
  complete all lower levels (in other words, the points is takes to get
  to level "n")

=cut

# true
1;
