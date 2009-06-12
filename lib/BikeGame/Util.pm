package BikeGame::Util;

use strict;
use Carp;
use BikeGame::Constant;
use List::Util;

my $_ridetypes = BikeGame::Config->get('RideTypes');
sub is_valid_ride_type {
    my $type = shift;
    return (List::Util::first {$_ eq $type} @$_ridetypes) ? 1 : 0;
}
my $_trackertypes = BikeGame::Config->get('TrackerTypes');
sub is_valid_tracker_type {
    my $type = shift;
    return (List::Util::first {$_ eq $type} @$_ridetypes) ? 1 : 0;
}
my $_trackertypes = BikeGame::Config->get('TrackerTypeNames');
sub is_valid_tracker_type_name {
    my $type = shift;
    return (List::Util::first {$_ eq $type} @$_ridetypes) ? 1 : 0;
}

#
# speed/time/dist calculations
#
sub calc_time_from_speed_and_distance {
    my ($speed,$distance) = @_;
    # we're assuming mph and miles at this point, which means we're getting hours first
    my $hours   = sprintf("%.3f", ($distance / $speed));
    my $seconds = sprintf("%i", ($hours * 60 * 60)); # hr * min/hr * sec/min
    return BikeGame::Util::hms_from_seconds($seconds);
}
sub calc_speed_from_time_and_distance {
    my ($time,$distance) = @_;
    Carp::croak("Can't divide distance by no hours!") unless $time;
    # we're assuming time format hh:mm:ss, convert to seconds then to hours
    my $seconds = BikeGame::Util::seconds_from_hms( $time );
    my $hours   = $seconds / ( 60 * 60 );
    # converting to miles per hour, double precision
    return sprintf("%.2f", ($distance/$hours));
}

#
# Date formatting
#
sub hms_from_seconds {
    my $total_seconds = shift;
    my $hours   = sprintf("%03i", (($total_seconds || 0)/3600));
    my $minutes = sprintf("%02i", ((($total_seconds || 0) % 3600) / 60 ));
    my $seconds = sprintf("%02i", (($total_seconds || 0) % 60) );
    return join(":", ($hours,$minutes,$seconds));
}
sub seconds_from_hms {
    my $hms = shift;
    my ($h,$m,$s) = ($hms =~ /^(\d{1,3}):(\d{1,2}):(\d{1,2})/);
    unless ( defined($h) && defined($m) && defined($s) ) {
        Carp::croak("Could not parse hms! '$hms'");
    }
    return List::Util::sum( (($h || 0) * 60 * 60 ), (($m || 0) * 60 ), ($s || 0) );
}

#true
1;
