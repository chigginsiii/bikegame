package BikeGame::Model::Bike;
use strict;
use base qw(BikeGame::DBI);

__PACKAGE__->table('player_bike');
__PACKAGE__->columns(Primary   => qw(bike_id));
__PACKAGE__->columns(Essential => qw(name));
__PACKAGE__->columns(Others    => qw(player));
__PACKAGE__->has_a( 'player' => 'BikeGame::Model::Player' );


# true;
1;
