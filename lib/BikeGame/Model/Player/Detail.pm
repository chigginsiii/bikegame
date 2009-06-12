package BikeGame::Model::Player::Detail;
use strict;
use base qw(BikeGame::DBI);

__PACKAGE__->table('player_detail');
__PACKAGE__->columns(All => qw(
                               player_id
                               first_name last_name email
                              )
                    );

# true
1;
