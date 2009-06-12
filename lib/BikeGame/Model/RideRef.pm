package BikeGame::Model::RideRef;
use strict;
use base qw(BikeGame::DBI);

__PACKAGE__->table('ride_ref');
__PACKAGE__->columns(All => qw(
                               ride_ref_id
                               player ride_type title
                               distance climb description ride_url
                              )
                    );

__PACKAGE__->has_a( player   => 'BikeGame::Model::Player' );




=head1 BikeGame::Model::RideRef

  A set of saved ride attributes, allowing many repeated rides to share the same data

=head1 insert (constructors)

  player      => $player_instance,
  ride_type   => $valid_ride_type,
  title       => $ride_name,
  distance    => $ride_distance,
  climb       => $ride_climb,
  description => $ride_notes,
  ride_url    => $ride_url

=head1 HAS A

=head2 player

BikeGame::Model::Player

=cut

# true
1;
