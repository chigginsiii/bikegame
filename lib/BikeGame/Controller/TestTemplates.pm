package BikeGame::Controller::TestTemplates;

use strict;
use base qw(BikeGame::Controller);

sub setup {
    my $self = shift;
    $self->run_modes( 'player_forms' => 'test_player_forms' );
    $self->start_mode('player_forms');
}

sub test_player_forms {

    my $self = shift;

    require BikeGame::Model::Player;
    my $player = BikeGame::Model::Player->retrieve( name => 'test' );
    $self->tt_process('forms/player.tt', { player => $player,
                                           errors => ['testing error 1', 'testing error 2']
                                         });

}


# true
1;
