package BikeGame::DBI;

use strict;
use base 'Class::DBI';
use Carp qw(carp croak confess);

use BikeGame::Config;
use BikeGame::Constant;
use Class::DBI::AbstractSearch;

my $cfg = BikeGame::Config->get('db');
my ($db_name, $db_user, $db_pass) = @{$cfg}{'db_name', 'db_user', 'db_pass'};

my $connect_string = "dbi:mysql:$db_name";
BikeGame::DBI->connection($connect_string, $db_user, $db_pass);


1;
