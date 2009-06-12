package BikeGame::Controller::Welcome;

use strict;
use base qw(BikeGame::Controller);

# okay, well. I guess it's time to put up or shut up...
sub setup {
    my $self = shift;
    $self->start_mode('start');
    $self->run_modes(
                     'news'   => 'news',
                     'login'  => 'login',
                     'logout' => 'logout',
                    );
}

sub news {
    my $self = shift;
    my $redirect = $self->auth_player();
    return $redirect if $redirect;
    my $player = $self->param('player');
    my $tpl_vars = { player_name => $player->name };
    return $self->tt_process('news.tt', $tpl_vars);
}


# true
1;
