package BikeGame::Template;

use strict;
use BikeGame::Config;
use DateTime::TimeZone;
use CGI;
use Carp qw(confess);
use base qw(Template);

my $tpl_cfg = BikeGame::Config->get_config('template');
my $q = CGI->new();
my $_instance;

sub new {
    my $class = shift;
    unless ( $_instance ) {
        my $self = $class->SUPER::new({
                                       INCLUDE_PATH => $tpl_cfg->{include_path},
                                       CONSTANTS  => {
                                                      timezones => DateTime::TimeZone->names_in_country("US");
                                                     },
                                      }) || die "Could not create BikeGame::Template: " . $Template::ERROR . "\n";
        $_instance = $self;
    }
    return $_instance;
}
sub get_template {
    my $class = shift;
    return $class->new();
}
# should be able to call this as a class method...
sub process_template {
    my $class = shift;
    my $self;
    $self = ref($class) ? $class : $class->new();
    my ($template, $params) = @_;
    my $buffer;
    $self->process($template, $params, \$buffer) || confess "Could not process template: " . $self->error();
    return $buffer;
}

# takes a template file and param hash
# prints to STDOUT
sub display {
    my ($self, $tpl, $params) = @_;
    my $buffer;
    unless ( $self->process($tpl, $params, \$buffer) ) {
        print $q->header;
        print "Template Error: " . $self->error();
    } else {
        print $q->header;
        print $buffer;
    }
}
# true
1;
