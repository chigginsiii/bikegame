#!/usr/bin/perl

use strict;
use Test::More qw(no_plan);
use lib qw(../lib);

BEGIN {
    use_ok("BikeGame::Model::Player");
}

#
# create_player: the goal here is simply to create a player,
# - put in the player details
# - know that the metrics and first level are there
#   - know that everything's at 0
#
my $player;
my $p_name = 'testy';
my $p_pass = 'joopiter';
my $p_fname = 'Testy';
my $p_lname = 'McTest';
my $p_email = 'testy@example.com';

# try and create the player, if it exists, delete and do it again to
# make sure we're still creating with all the accessors.
eval{
    $player = BikeGame::Model::Player->insert({ name       => $p_name,
                                                password   => $p_pass,
                                                timezone   => 'America/New_York'
                                              });
};
if ( $@ ) {
    diag("Got an error trying to insert: '$@'");
    diag("attempting to delete...");
    ($player) = BikeGame::Model::Player->search(name => $p_name);
    $player->delete();
    $player = BikeGame::Model::Player->insert(
                                              { name       => $p_name,
                                                password   => $p_pass,
                                              });
}


isa_ok($player, 'BikeGame::Model::Player','insert player');
my $player_id = $player->id();

# should have a player detail object now...
$player->first_name( $p_fname );
$player->last_name( $p_lname);
$player->email($p_email);
$player->update();

# check accessors
ok($player_id, 'player id: ' . $player_id);
is($player->name, $p_name, 'name');
is($player->password, $p_pass, 'password');
is($player->first_name, $p_fname, 'first name');
is($player->last_name, $p_lname, 'last name');
is($player->email, $p_email, 'email');


#
# END
#
# if we're all good, delete the player
#
$player->delete;
