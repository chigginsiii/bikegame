package BikeGame::EventManager;

use strict;
use BikeGame::Config;
use BikeGame::Model::Ride;
use BikeGame::Model::RideRef;
use BikeGame::Model::Score;
use BikeGame::Model::Level;

sub load_events {
    my $class = shift;
    my $self = bless {}, (ref($class) || $class);

    # start with a target number of events for each round of loading
    my $target_num = shift || BikeGame::Config->get('DefaultLoadEvents');

    # the idea is:
    #
    # PREPARE: (some of this goes in an init statement)
    #
    # 1. do a SELECT COUNT(*), <date turned into week> AS week_num from each event stream
    # 2. create a grid like this when combined:
    #    $grid->{week_num}->{<event_type>} = count;
    # 3. starting with the highest week_num working backwords, establish 
    #    the "chunks" of date ranges that will give us somewhere around the
    #    target number of events with each successive load_next()
    #
    # EXECUTE: 
    #
    # 4. now load the first round of events, keep track of each one's stream (offset and step)
    #    as they've been loaded individually, and also create an index that tracks
    #    the whole event stream's order and position.
}

sub load_next_chunk {

}

# this returns a slice of events by type or all, starting at offset:0, step:<step>,
# and keeping track of that stream's position
sub nextpage {
    
}

# this returns the slice of events that came before the current, cur - step
sub prevpage {

}

