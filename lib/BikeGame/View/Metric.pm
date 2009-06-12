package BikeGame::View::Metric;

use strict;
use BikeGame::Controller;
use Carp;

sub new { return bless {}, (ref $_[0] || $_[0] ) };

our $_meter_template = 'ui/dashboard_meter.tt';
sub wrap_meter {
    my $self = shift;
    my $content = shift;
    my $buffer;
    BikeGame::Controller->tt_obj()->process( $_meter_template, { content => $content }, \$buffer );
    return $buffer;
}

# must subclass these
sub render_dashboard_meter {
    Carp::croak("Must subclass method!");
}

# return true
1;
