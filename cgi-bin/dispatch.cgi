#!/usr/bin/perl
use strict;
use lib qw(../lib);

use BikeGame::Controller::Dispatch;
BikeGame::Controller::Dispatch->dispatch();

#use BikeGame::Controller::Dispatch->dispatch;
#my $app = BikeGame::Controller::Dispatch->new();
#$app->dispatch();

#use BikeGame::Controller::Welcome;
#my $app = BikeGame::Controller::Welcome->new();
#$app->run();
