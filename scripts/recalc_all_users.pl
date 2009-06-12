#!/usr/bin/perl

use lib qw(../lib);
use BikeGame::Model::Player;

my @players = BikeGame::Model::Player->retrieve_all();

foreach my $player ( @players ) {
    my $player_name = $player->name();
    my $player_id   = $player->id();
    my $rides = $player->recalc_rides();
    print "Recalculated $rides rides for player '$player_name' (id: $player_id)\n";
}

print "Done.\n";
