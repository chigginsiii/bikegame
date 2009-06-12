#!/usr/bin/perl
use strict;

use CGI;

my $c = CGI->new();
print $c->header();
print "<html><body>Hello World!</body></html>";
