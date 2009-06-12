#!/usr/bin/perl

use strict;
use lib qw(../lib);
use Test::More qw(no_plan);

BEGIN {
    use_ok('BikeGame::Template');
}

my $tpl;
ok($tpl = BikeGame::Template->new(), 'new BikeGame::Template');
create_test_tpl();
my $tpl_var = { target => 'World' };
my $buffer;
ok($tpl->process('test.tpl', $tpl_var, \$buffer), 'process()');
is($buffer, 'Hello World!', 'buffer match');

END {
    destroy_test_tpl();
}

sub create_test_tpl {
    open(TPL, "> ../templates/test.tpl") || die "Could not write to test template file: $!";
    print TPL "Hello [% target %]!";
    close TPL;
}
sub destroy_test_tpl {
    unlink "../templates/test.tpl" || die "Could not remove test template: $!";
}
