package BikeGame::Controller;

use strict;
use base qw(CGI::Application);
use BikeGame::Config;
use Authen::Simple::CDBI;
use CGI::Application::Plugin::TT;
use CGI::Application::Plugin::DBH qw/dbh_config dbh/;
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Redirect;
use CGI::Application::Plugin::Forward;
#use CGI::Application::Plugin::DevPopup;
#use CGI::Application::Plugin::DevPopup::HTTPHeaders;
#use CGI::Application::Plugin::DevPopup::Timing;

#
# commonly used throughout...
#
use BikeGame::Model::Player;

#
# Initialization
#

# Template Toolkit config: doing this as a class method creates a singleton template
__PACKAGE__->tt_config( TEMPLATE_OPTIONS => BikeGame::Config->get('TemplateConfigs')->{construct} );

# db and session configs
my $db_cfg      = BikeGame::Config->get('db');
my $session_cfg = BikeGame::Config->get('Session');
my $auth_cfg    = BikeGame::Config->get('Auth');

sub cgiapp_init {
    my $self = shift;
    # set up db
    $self->dbh_config( $db_cfg->{dbi_dsn}, @{$db_cfg}{qw/db_user db_pass/} );
    $self->session_config(
                          CGI_SESSION_OPTIONS => [ $session_cfg->{session_dsn},
                                                   $self->query(),
                                                   { Handle => $self->dbh },
                                                 ],
                          DEFAULT_EXPIRY => $session_cfg->{expire_default},
                          COOKIE_PARAMS  => {
                                             -expires => '+1d',
                                             -path    => '/',
                                            }
                         );
}

#
# RUN MODES
#

# NOTE: hm, if I just call this as $self->login() from protected modes, 
#       $self->get_current_runmode will return the correct runmode...
sub login {
    my $self = shift;
    my $q = $self->query;
    my $user = $q->param('username');
    my $pass = $q->param('password');
    
    if ( $user && $pass ) {
        my $auth = Authen::Simple::CDBI->new( class    => $auth_cfg->{cdbi_class},
                                              username => $auth_cfg->{cdbi_name_col},
                                              password => $auth_cfg->{cdbi_pass_col},
                                            );
        if ( $auth->authenticate( $user, $pass ) ) {
            my $player = BikeGame::Model::Player->retrieve(name => $user);
            # $self->session();
            $self->session->param('__LOGGED_IN', 1);
            $self->session->param('player_id', $player->id);
            
            # go to redirect or default
            if ( my $fwm = $self->session->param('on_login_redirect') ) {
                $self->redirect($fwm);
            } elsif ( $self->get_current_runmode ne 'login' )  {
                $self->forward( $self->get_current_runmode );
            } else {
                $self->redirect('/app/dashboard/');
            }
        } else {
            $self->tt_process('login.tt', { error => "Invalid User/Pass" });
        }
    } else {
        $self->tt_process('login.tt');
    }
}

sub logout {
    my $self = shift;
    $self->session_delete();
    return $self->forward('login');
}

#
# placeholder page for modes in development
#
sub display_dummy {
    my $self = shift;
    my $msg = shift;
    require Data::Dumper;
    $Data::Dumper::Maxdepth = 1;
    $self->tt_process('dummy.tt', {
                                   class => ref($self),
                                   rm => $self->get_current_runmode(),
                                   cgi_app => Data::Dumper::Dumper($self),
                                   page_title => 'Dummy Page for ' . ref($self) . ':' . $self->get_current_runmode(),
                                   message => $msg,
                                  });
}

#
# Utility functions
#

# boolean to determine whether or not we're logged in yet
sub is_logged_in {
    my $self = shift;
    my $session = $self->session();
    return $session->param('__LOGGED_IN') ? 1 : 0;
}

# utility: get the template object
sub get_template {
    return __PACKAGE__->tt_obj();
}

sub auth_player {
    my $self = shift;
    my $session = $self->session();
    if ( ! $self->is_logged_in() ) {
        return $self->forward('login');
    }
    # need the player
    my $player = BikeGame::Model::Player->retrieve( $session->param('player_id') );
    if ( ! $player ) {
        # no player? can't go on. logout and go back to login page
        return $self->forward('logout');
    }
    # load the player into the stash
    $self->param('player_id', $player->id);
    $self->param('player', $player);
    return;
}


#true
1;
