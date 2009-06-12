package BikeGame::Controller::Rides;
use strict;
use base qw(BikeGame::Controller);

use BikeGame::Model::Player;
use BikeGame::Model::Ride;
use BikeGame::Model::RideRef;
use BikeGame::Model::Score;
use BikeGame::Model::Level;

use BikeGame::Util::DateTime;

sub setup {
    my $self = shift;
    $self->run_modes(
                     # list, add, edit, remove rides
                     'ride_list'       => 'display_ride_list',
                     'add_ride'        => 'add_ride',
                     'remove_ride'     => 'remove_ride',
                     'edit_ride'       => 'edit_ride',
                     'update_ride'     => 'update_ride',
                     # list, edit, remove bookmarks
                     'list_bookmarks'  => 'list_bookmarks',
                     # login, logout
                     'login'           => 'login',
                     'logout'          => 'logout',
                    );
    $self->start_mode('ride_list');
    $self->error_mode('display_dummy');
}

sub display_saved_ride_list {
    my $self = shift;
    $self->display_dummy();
}

sub display_ride_list {

    my $self = shift;
    my $redirect = $self->auth_player();
    return $redirect if $redirect;

    my $player = $self->param('player');
    my $session = $self->session();
    my $q = $self->query;

    # got it, get the scores for each ride_record
    my $tpl_vars = { player_name => $player->name, selected_site_menu => 'ridelog' };
    my $limit  = $self->get_ridelist_limit();
    # 1. page as requested, 2. last page, 3. 1
    my $page =  $self->param('page') || $q->param('page') || $session->param('ridelog_page') || 1;
    $session->param('ridelog_page', $page);

    # get the rides
    my $pager = BikeGame::Model::Ride->pager( $limit, $page);
    my @rides = $pager->find_by_player( $player->id );
    $tpl_vars->{pager} = $pager;

    # get any scoring or levelling events that fall between the first and last ride
    my $latest   = $rides[0]->date;
    $latest = $latest ? BikeGame::Util::DateTime->to_mysql( $latest ) : '';
    my $earliest = $rides[$#rides]->date;
    $earliest = $earliest ? BikeGame::Util::DateTime->to_mysql( $earliest ) : '';
    my @scores = BikeGame::Model::Score->find_by_player_and_date($player, $earliest, $latest);


    my @levels = BikeGame::Model::Level->find_by_player_and_date_begun($player, $earliest, $latest);
    # setting the last param to 'true' sorts with most recent dates first
    my @events = $self->sort_events_by_date( \@rides, \@scores, \@levels, 1 );

    # if we came here from adding a ride, there'll be a highlighted ride param
    if ( my $highlight = $self->param('highlighted') ) {
        $tpl_vars->{highlighted_ride} = $highlight;
    }

    # OTHER ELEMENTS:
    # I think what has to happen to bring the other events into the list is to get the min/max dates of
    # the ride list and then query Score and Level on those values
    my $events_by_date = {};
    foreach my $event ( @events ) {
        my $event_type = ref($event);
        my $tpl_event;
        if ( $event_type eq 'BikeGame::Model::Ride' ) {
            $tpl_event = $self->prepare_ride_event( $event );
        } elsif ( $event_type eq 'BikeGame::Model::Score' ) {
            $tpl_event = $self->prepare_score_event( $event );
        } elsif ( $event_type eq 'BikeGame::Model::Level' ) {
            $tpl_event = $self->prepare_level_event( $event );
        } else {
            print STDERR "Shouldn't have ended up here... event type: $event_type\n";
            next();
        }
        # get the sort date, check to see if there's an array in $events_by_date
        if ( ! $events_by_date->{ $tpl_event->{sort_date} } ) {
            $events_by_date->{ $tpl_event->{ sort_date } } = { sort_date    => $tpl_event->{sort_date},
                                                               display_date => $tpl_event->{display_date},
                                                               events       => [],
                                                             };
        }
        push @{ $events_by_date->{ $tpl_event->{ sort_date } }->{events} }, $tpl_event;
    }
    $tpl_vars->{events_by_date} = $events_by_date;    
    $self->tt_process('ride_list.tt', $tpl_vars);
}


my %sort_by_refs = ( 'BikeGame::Model::Ride'  => 3,
                     'BikeGame::Model::Score' => 2,
                     'BikeGame::Model::Level' => 1,
                   );
sub sort_events_by_date {
    my ($self,$rides, $scores, $levels, $latest_first) = @_;
    # if there's other event types to be sorted, they need to be listed here
    # this is going to put all the events in a list with the earliest event first,
    # unless 'latest_first' is true.
    my @events = @$rides;
    push @events, @$scores if scalar(@$scores);
    push @events, @$levels if scalar(@$levels);

    my @sorted_events = 
    map { $_->[0] }
    sort { 
        # try by date, then use the type index
        ( $latest_first 
          ? $b->[1] cmp $a->[1] 
          : $a->[1] cmp $b->[1] 
        ) || 
        # now by type: ride, then score, then level
        $a->[2] <=> $b->[2]
    } 
    map { 
        my $ref      = ref($_);
        my $datetime = 
          ( $ref eq 'BikeGame::Model::Ride' || $ref eq 'BikeGame::Model::Score' )
          ? $_->date : $_->date_begun;
        [ $_, $datetime, ( $sort_by_refs{$ref} || 999 ) ];
    } @events;
    return @sorted_events;
}

sub prepare_ride_event {
    my ($self,$ride) = @_;
    my $bike         = $ride->bike();
    my $ride_ref     = $ride->ride_ref();
    my $sort_date    = $ride->date->ymd('');
    my $display_date = $ride->date->strftime("%B %d, %Y");

    my $this_ride = 
    { 
     # identify the event
     event_type   => 'ride',
     sort_date    => $sort_date,
     display_date => $display_date,

     ride_id    => $ride->id(),
     ride_type  => $ride->ride_type,
     ride_date  => BikeGame::Util::DateTime->display_ridelog( $ride->date ),
     ride_time  => $ride->ride_time,
     avg_speed  => $ride->avg_speed,
     bike       => $bike ? $bike->name : '',
     ride_notes => $ride->ride_notes,
         
     # these can all come from the ride ref, use appropriate accessors
     ride_url   => $ride->checkref('ride_url'),
     distance   => $ride->checkref('distance'),
     climb      => $ride->checkref('climb'),
    };
    if ( $ride_ref ) {
        # ride ref title if there is one
        $this_ride->{ride_ref_title} = $ride_ref->title;
        $this_ride->{ride_ref_desc}  = $ride_ref->description;
    }
    return $this_ride;
}

my %metric_types = (
                    'BikeGame::Model::Metric::Distance' => 'distance',
                    'BikeGame::Model::Metric::Climb'    => 'climb',
                   );
sub prepare_score_event {
    my ($self, $score) = @_;
    my $sort_date     = $score->date->ymd('');
    my $display_date  = $score->date->strftime("%B %d, %Y");
    my $record        = $score->ride_record();
    my $ride_type     = $record->ride_type();
    my $metric        = $score->metric();
    my $metric_class  = $metric->metric_type;
    my $metric_type   = $metric_types{ $metric_class };

    my $tpl_score = 
    { 
     # identify the event
     event_type   => 'score',
     sort_date    => $sort_date,
     display_date => $display_date,
     # particular to scoring events...
     ride_type    => $ride_type,
     metric       => $metric_type,
     message      => $score->message,
     points       => $score->points,
    };
    return $tpl_score;
}

sub prepare_level_event {
    my ($self, $level) = @_;
    my $sort_date    = $level->date_begun->ymd('');
    my $display_date = $level->date_begun->strftime("%B %d, %Y");

    my $tpl_level = 
    { 
     # identify the event
     event_type   => 'level',
     sort_date    => $sort_date,
     display_date => $display_date,
     # particular to level obj
     level_number       => $level->level_number(),
     points_to_complete => $level->points_to_complete(),
     ride_type          => $level->ride_type(),
    };
    return $tpl_level;
}

# XXX: this should look at user preferences
sub get_ridelist_limit {
    return 20;
}

sub add_ride {

    my $self = shift;
    my $redirect = $self->auth_player();
    return $redirect if $redirect;
    my $player = $self->param('player');

    my $q = $self->query;
    # XXX: this is the second time i've had to set up this way, should
    #      look into generalizing it...
    my $tpl_vars = { player_name        => $player->name,
                     selected_site_menu => 'addride',
                     selected_ride_type => $self->param('ride_type'),
                   };

    # submitting?
    if ( $q->param('add_new_ride') || $q->param('add_bookmarked_ride') ) {
        my %ride_params;

        my $ride_url = $q->param('ride_url');
        $ride_url = '' if $ride_url eq 'http://';

        if ( $q->param('add_new_ride') ) {
            if ( $q->param('save_ride_as_bookmark') )
            {   # this ride is to be saved as a bookmark, make the ref and attach it to the ride
                my $ride_ref = BikeGame::Model::RideRef->insert( { player      => $player,
                                                                   ride_type   => $q->param('ride_type'),
                                                                   title       => $q->param('bookmark_title'),
                                                                   description => $q->param('bookmark_desc'),
                                                                   distance    => $q->param('distance'),
                                                                   climb       => $q->param('climb'),
                                                                   ride_url    => $ride_url,
                                                                 });
                $ride_params{ride_ref} = $ride_ref;
            } else 
            {   # ride added without saving bookmark
                %ride_params = ( ride_type  => $q->param('ride_type'),
                                 distance   => $q->param('distance'),
                                 climb      => $q->param('climb'),
                                 ride_url   => $ride_url,
                               );
            }
        } elsif ( $q->param('add_bookmarked_ride') ) {
            my $ref_id = $q->param('bookmark_id');
            return $self->display_dummy("Could not determine bookmark id") unless $ref_id;
            my $ref = BikeGame::Model::RideRef->retrieve($ref_id);
            return $self->display_dummy("Could not retrieve bookmark") unless $ref;
            $ride_params{ride_ref} = $ref;
        }
        # ride notes:
        $ride_params{ride_notes} = $q->param('ride_notes');
        # date
        $ride_params{date} = BikeGame::Util::DateTime::from_mysql( $q->param('date') . ' ' . $q->param('time') );
        # time/speed
        if ( ( $q->param('elapsed_hours') + $q->param('elapsed_minutes') + $q->param('elapsed_seconds') ) > 0 ) {
            $ride_params{ride_time} = join(':', ($q->param('elapsed_hours'),$q->param('elapsed_minutes'),$q->param('elapsed_seconds')));
        } elsif ( $q->param('avg_speed') &&  ( $q->param('avg_speed') + 0 ) != 0 ) {
            $ride_params{avg_speed} = $q->param('avg_speed');
        }
        # bike?
        if ( my $bike_id = $q->param('bike_id') ) {
            my $bike = BikeGame::Model::Bike->retrieve( $bike_id );
            $ride_params{bike} = $bike if $bike;
        }
        
        my $new_ride = $player->add_ride( \%ride_params );
        # redirect to new ride's page
        return $self->redirect_to_ride_page( $new_ride );
    } elsif ( $q->param('add_imported_rides') ) {
        # IMPORT A WHOLE SHITLOAD OF RIDES
    } else {
        # here for the first time?
        my @bikes = $player->bikes;
        $tpl_vars->{bikes} = \@bikes;
        # load the saved rides
        $tpl_vars->{ride_refs} = [];
        my @ride_refs = $player->ride_refs;
       foreach my $ref ( @ride_refs ) {
           push @{ $tpl_vars->{ride_refs} }, { id        => $ref->id,
                                               title     => $ref->title,
                                               ride_type => $ref->ride_type,
                                               distance  => $ref->distance,
                                               climb     => $ref->climb,
                                             };
       }      
       $self->tt_process('add_ride.tt', $tpl_vars);
   }
}

sub remove_ride {
    my $self = shift;
    # check for logged-in-ness
    my $redirect = $self->auth_player();
    return $redirect if $redirect;
    my $player = $self->param('player');
    my $ride = BikeGame::Model::Ride->retrieve( $self->param('delete_ride_id') );
    if ( $ride ) {
        # delete the ride, recalc the ride record
        my $ride_record_id = $ride->ride_record()->id();
        $ride->delete();
        my $ride_record = BikeGame::Model::RideRecord->retrieve($ride_record_id);
        $ride_record->recalc_rides();
    }
    if ( my $page = $self->param('cur_page') ) {
        return $self->redirect("/app/rides/page/$page");
    } else {
        return $self->redirect('/app/rides/page/1');
    }
}

sub edit_ride {
    my $self = shift;
    # check for logged-in-ness
    my $redirect = $self->auth_player();

    # return blank for now, not sure what to do with this, maybe implement a 'auth_player_ajax' that returns a redirect
    return if $redirect;

    # again, returning nothing here isn't good, perhaps an error component for thickbox windows?
    my $player = $self->param('player');
    my $ride = BikeGame::Model::Ride->retrieve($self->param('ride_id'));
    return unless $ride;

    my $ride_date_obj = $ride->date;
    my @bikes         = $player->bikes;
    my @ride_refs     = $player->ride_refs;
    my ($ride_date,$ride_time) = $ride_date_obj ? split(' ', BikeGame::Util::DateTime::to_mysql( $ride_date_obj )) : (undef,undef);
    my $tpl_vars = { player_id          => $player->id(),
                     ride_id            => $ride->id,
                     selected_ride_type => $ride->ride_type,
                     selected_date      => $ride_date,
                     ride_time          => $ride_time,
                     avg_speed          => $ride->avg_speed,
                     bikes              => \@bikes,
                     selected_bike      => $ride->bike ? $ride->bike->id : '',
                     ride_refs          => \@ride_refs,
                     selected_ride_ref  => $ride->ride_ref ? $ride->ride_ref->id : '',
                     distance           => $ride->distance,
                     climb              => $ride->climb,
                     ride_url           => $ride->ride_url,
                     ride_notes         => $ride->ride_notes,
                   };
    @{$tpl_vars}{ qw/elapsed_hours elapsed_minutes elapsed_seconds/ } = split(':', $ride->ride_time);
    return $self->tt_process('edit_ride.tt', $tpl_vars);
}

# may as well have the edit_ride screen call back to a
# separate run-mode, no sense in cramming it into edit_ride
sub update_ride {
    my $self = shift;
    # check for logged-in-ness
    my $redirect = $self->auth_player();
    return $redirect if $redirect;
    
    # again, returning nothing here isn't good, perhaps an error component for thickbox windows?
    my $player = $self->param('player');
    my $ride = BikeGame::Model::Ride->retrieve($self->param('ride_id'));
    return unless $ride;
    
    my $q = $self->query();
    # only update the things that require it, then rebuild the player's score/level stack
    
    # universals: check date, elapsed_hours/minutes/seconds, bike, avg_speed (take elapsed over speed, but require a change), ride notes

    # RIDE -> RIDE NOTES always gets checked
    if ( $ride->ride_notes ne $q->param('ride_notes') ) {
        $ride->ride_notes( $q->param('ride_notes') );
    }
    # RIDE -> DATETIME
    my $form_datetime = $q->param('date') . ' ' . $q->param('time');
    if ( BikeGame::Util::DateTime::to_mysql( $ride->date ) ne $form_datetime ) {
        $ride->date( BikeGame::Util::DateTime::from_mysql( $form_datetime, $player->timezone ) );
    }
    # RIDE -> BIKE
    if ( $q->param('bike_id') ) {
        # either the ride has a bike and the id's don't match
        # or the ride didn't have a bike before, either way we set it
        if ( ( $ride->bike && $ride->bike->id() ne $q->param('bike_id') )
             || ( ( ! $ride->bike ) && $q->param('bike_id') )
           ) {
            my $bike = BikeGame::Model::Bike->retrieve($q->param('bike_id'));
            $ride->bike( $bike ) if $bike;
        }
    } elsif ( $ride->bike ) { # form has no bike id, check to see if the ride has a bike
        $ride->set('bike', undef);
    }
    # RIDE -> AVG_SPEED/ELAPSED TIME (prefer a change in elapsed time over avg speed
    if ( List::Util::sum( $q->param('elapsed_hours'),$q->param('elapsed_minutes'),$q->param('elapsed_seconds') ) != 0 ) {
        my $form_elapsed = join(':', map { sprintf( "%02i", $_ ) } ( $q->param('elapsed_hours'),$q->param('elapsed_minutes'),$q->param('elapsed_seconds') ) );
        if ( $ride->ride_time ne $form_elapsed ) {
            $ride->ride_time( $form_elapsed );
        }
    } elsif ($q->param('avg_speed') > 0 && $ride->avg_speed != $q->param('avg_speed') ) {
        $ride->avg_speed( $q->param('avg_speed') );
    }
    
    # IF bookmark_toggle and bookmark id
    my $ride_ref;
    if ( $q->param('bookmark_toggle') && $q->param('bookmark_id') ) {
        # if the ride's got a ref, check it's id against the form's 
        # or if the ride doesn't have a ref, but the form does
        # - set the ride ref
        if (    ( $ride->ride_ref && $ride->ride_ref->id() != $q->param('bookmark_id') ) 
                || ( (!$ride->ride_ref) && $q->param('bookmark_id') )
           ) {
            $ride_ref = BikeGame::Model::RideRef->retrieve( $q->param('bookmark_id') );
            $ride->ride_ref( $ride_ref );
        }
    } else  { # check the other values manually
        # - check ride_type, distance, climb, ride_url, ride_notes
        if ($ride->ride_type ne $q->param('ride_type')) {
            $ride->ride_record( $ride->player->ride_record( $q->param('ride_type') ) );
        }
        foreach my $field ( qw/distance climb/ ) {
            if ( $ride->get($field) ne $q->param($field) ) {
                $ride->set( $field => $q->param($field) ) ;
            }
        }
        if ( $q->param('ride_url') && $q->param('ride_url') ne 'http://' ) {
            $ride->set( ride_url => $q->param('ride_url') );
        }
        
    }
    # update, recalc score/level stacks, redirect to the ride's page in the page list
    # actually, if there's any error along the way, we can redirect to the ride's
    # log page with an error message
    $ride->update();
    $player->recalc_rides();
    return $self->redirect_to_ride_page($ride);
}

sub list_bookmarks {
    my $self = shift;
    my $redirect = $self->auth_player();
    return $redirect if $redirect;
    my $player = $self->param('player');

    my $q = $self->query;
    my $tpl_vars = { player_name => $player->name };
    
    my @bookmarks = BikeGame::Model::RideRef->search( player => $player, {order_by => 'title' } );
    my %bookmarks_by_ridetype;
    foreach my $b ( @bookmarks ) {
        $bookmarks_by_ridetype{ $b->ride_type } = [] unless ref( $bookmarks_by_ridetype{ $b->ride_type } );
        push @{ $bookmarks_by_ridetype{$b->ride_type} }, $b;
    }
    $tpl_vars->{bookmarks_by_ridetype} = \%bookmarks_by_ridetype;

    # need a debug dump
    require Data::Dumper;
    $Data::Dumper::Maxdepth = 2;
    $tpl_vars->{bookmark_dump} = '<pre>' . Data::Dumper::Dumper(\%bookmarks_by_ridetype) . '</pre>';

    return $self->tt_process('list_bookmarks.tt', $tpl_vars);
}

sub display_edit_bookmark {
    my $self = shift;
    my $redirect = $self->auth_player();
    return $redirect if $redirect;
    my $player = $self->param('player');

    my $q = $self->query;
    my $tpl_vars = { player_name => $player->name };

    # 1. list the bookmarks, grouped by ride type, with a link to edit

}
sub process_edit_bookmark {
    my $self = shift;
    my $redirect = $self->auth_player();
    return $redirect if $redirect;
    my $player = $self->param('player');

    my $q = $self->query;
    my $tpl_vars = { player_name => $player->name };
}

#
# utility
#
sub find_ride_page {
    my ($self, $ride) = @_;
    my $pager = BikeGame::Model::Ride->pager( $self->get_ridelist_limit() );
    my @rides = $pager->find_by_player( $ride->player()->id );
    my $ride_page = undef;
    my $cur_page = 1;
    while ( ! $ride_page && $cur_page <= $pager->last_page ) {
        foreach my $this_ride ( @rides ) {
            if ( $this_ride->id == $ride->id ) {
                $ride_page = $cur_page;
                last;
            }
        }
        $cur_page++;
    }
    return $ride_page || 1;
}
sub redirect_to_ride_page {
    my ($self,$ride) = @_;
    my $ride_page = $self->find_ride_page( $ride );
    my $ride_id = $ride->id();
    return $self->redirect("/app/rides/page/$ride_page/$ride_id");
}
# true
1;
