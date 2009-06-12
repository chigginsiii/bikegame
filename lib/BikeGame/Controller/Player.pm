package BikeGame::Controller::Player;

use strict;
use base qw(BikeGame::Controller);
use BikeGame::Model::Player;
use BikeGame::Model::Player::Detail;
use BikeGame::Model::Bike;

sub setup {
    my $self = shift;
    $self->start_mode('login');
    $self->error_mode('error');
    $self->run_modes(
                     # universal login
                     'login'                 => 'login',
                     # universal login
                     'logout'                => 'logout',
                     # create a player
                     'create_player'         => 'create_player',

                    );
}

# create
sub create_player {
    my $self = shift;
    my $q = $self->query();
    my $s = $self->session();

    my $tpl_vars = {};
    if ( $q->param('create_player') ) {
        # new player, incoming data:
        my $new_player;

        # EARLY RETURN from creation errors
        if ( my $errors = $self->_validate_new_player_form() ) {
            $tpl_vars = { player => $self->_load_player_template_vars(undef, $q), error => join("</br>", @$errors) };
            return $self->tt_process( 'forms/player.tt', $tpl_vars );
        } else {
            # process the initial player
            $new_player = BikeGame::Model::Player->insert({
                                                           name     => $q->param('player_name'),
                                                           password => $q->param('player_password_new'),
                                                           timezone => ( $q->param('timezone') || 'America/New_York' ),
                                                          });
            # process the player details
            my $details = $new_player->details;
            $details->set( first_name => $q->param('player_fname'),
                           last_name  => $q->param('player_lname'),
                           email      => $q->param('player_email'),
                         );
            $details->update();

            # process the player bikes
            if ( my @bikes = $q->param('player_bikes') ) {
                foreach my $bike_name ( grep { $_ } @bikes ) {
                    my $bike = BikeGame::Model::Bike->insert({ player => $new_player, name => $bike_name });
                }
            }

            # that should do it, log us in
            $q->param('username', $new_player->name);
            $q->param('password', $new_player->password);
            $self->session->param('on_login_redirect', '/app/dashboard');
            return $self->login();
        }
        
    } elsif ( $q->param('save_player') ) {
        # updating player

    } else {
        # displaying initial
        return $self->tt_process('forms/player.tt');
    }
    return $self->display_dummy();
}

# this is for creating a new player only
sub _validate_new_player_form {
    my $self = shift;
    my $q = $self->query();
    my @errors;

    # gotta have a user name
    push @errors, "Must provide username" unless $q->param('player_name');

    # try to get the player by name (duplicate)
    my ( $player ) = BikeGame::Model::Player->search( name => $q->param('player_name') );
    if ( $player ) {
        push @errors, "Player name '" . $q->param('player_name') . "' already exists (id:" . $player->id . "), please pick a new name";
    }

    # must provide a password
    push @errors, "Must provide password" unless $q->param('player_password_new');

    # passwords must match
    push @errors, "Passwords do not match" unless $q->param('player_password_new') eq $q->param('player_password_confirm');

    # return errors if there are any
    return @errors ? \@errors : undef;
}

sub _load_player_template_vars {
    my ($self,$player) = @_;
    # if we haven't been passed a player, use a blank one
    $player ||= BikeGame::Model::Player->new();
    my $q = $self->query;
    my $q_params = { map { $_ => $q->param($_) } $q->param() };
    my @bikes = $player->bikes();
    return
    {
     name       => $q_params->{player_name}     || $player->name,
     first_name => $q_params->{player_fname}    || $player->detail->first_name,
     last_name  => $q_params->{player_lname}    || $player->detail->last_name,
     # we don't load passwords
     email             => $q_params->{player_email}    || $player->detail->email,
     timezone          => $q_params->{player_timezone} || $player->timezone,
     bikes             => $q_params->{player_bikes}    || \@bikes,
     dollars_per_point => $q_params->{player_dpp}      || $player->dollars_per_point,
    };
}

# edit
sub display_edit_player {
    my $self = shift;
    $self->display_dummy();
}
sub process_edit_player {
    my $self = shift;
    $self->display_dummy();
}

# delete
sub display_delete_player {
    my $self = shift;
    $self->display_dummy();
}
sub process_delete_player {
    my $self = shift;
    $self->display_dummy();
}

sub error {
    my $self = shift;
    my $error = shift;
    $self->display_dummy( $error );
}

# true
1;
