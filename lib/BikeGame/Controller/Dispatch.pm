package BikeGame::Controller::Dispatch;
use strict;
use base qw(CGI::Application::Dispatch);


sub dispatch_args {
    return {
            prefix => 'BikeGame::Controller',
            table  => [
                       # gonna do the login thing from player...
                       '/login'                 => { app => 'Player', rm => 'login'  },
                       '/logout'                => { app => 'Player', rm => 'logout' },

                       #
                       # player
                       #
                       # create player
                       '/player/create_player'  => { app => 'Player', rm => 'create_player' },

                       #
                       # Dashboard
                       #
                       # public landing page
                       '/dashboard'             => { app => 'Dashboard', rm => 'start' },
                       # list rides
                       '/rides/page/:page/:highlighted?'
                                                => { app => 'Rides', rm => 'ride_list' },
                       '/rides'                 => { app => 'Rides', rm => 'ride_list' },
                       # add ride
                       '/rides/add/:ride_type?' => { app => 'Rides', rm => 'add_ride' },
                       '/rides/add'             => { app => 'Rides', rm => 'add_ride' },
                       # edit ride displays the ajax form, update ride processes and redirects 
                       # to the ride's log page.
                       '/rides/edit/:ride_id'   => { app => 'Rides', rm => 'edit_ride' },
                       '/rides/update/:ride_id' => { app => 'Rides', rm => 'update_ride' },
                       # delete rides
                       '/rides/remove/:delete_ride_id/:cur_page?'
                                                => { app => 'Rides', rm => 'remove_ride' },
                       # bookmarks: list, edit, delete
                       '/bookmarks'             => { app => 'Rides', rm => 'list_bookmarks' },

                       # list ride refs
                       # '/rides/saved'           => { app => 'Rides', rm => 'saved_ride_list' },

                       
                       # seems like this is a gooda place's ehneh to put a default
                       '/news'                  => { app => 'Welcome', rm => 'news' },

                      ]
           };
}

# true
1;
