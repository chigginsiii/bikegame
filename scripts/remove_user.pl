#!/usr/bin/perl

use lib qw(../lib);
use BikeGame::Model::Player;

my $username = shift @ARGV;
my $user = BikeGame::Model::Player->retrieve(name => $username);

if ( ! $user ) {
    print "No user with name '$username' found, exiting.\n";
    exit(0);
}

$user->delete();
print "Deleted user: '$username', done.\n";
