package BikeGame::Config;
use strict;
use Carp qw(confess);
use BikeGame::Constant;
use Template::Namespace::Constants;

my $db_name = 'bikegame';
my $ride_types = [ $BikeGame::Constant::RIDETYPE_ROAD,
                   $BikeGame::Constant::RIDETYPE_MTB
                 ];


our $_CONFIG = 
{
 #
 # APPLICATION CONFIGS
 #
 db => 
 {
  db_name => $db_name,
  db_user => 'bguser',
  db_pass => '!eZzE8',
  # for CGI::Application::Plugin::DBH
  dbi_dsn => "dbi:mysql:database=${db_name}:host=localhost",
 },
 Session =>
 {
  session_dsn    => 'driver:mysql;serializer:storable',
  expire_default => '+1d',
  
 },
 Auth =>
 {
  cdbi_class    => 'BikeGame::Model::Player',
  cdbi_name_col => 'name',
  cdbi_pass_col => 'password',
 },
 TemplateConfigs =>
 {
  construct => {
                INCLUDE_PATH => '/www/chiggins/bikegame.chiggins.com/templates',
                POST_CHOMP => 1,
                NAMESPACE => {
                              app_cfg => Template::Namespace::Constants->new({
                                                                              jquery_path       => '/js/jquery.pack.js',
                                                                              thickbox_path     => '/js/thickbox-compressed.js',
                                                                              thickbox_css_path => '/css/thickbox.css',
                                                                             }),
                              tpl_cfg => Template::Namespace::Constants->new({
                                                                              
                                                                             }),
                             },
                VARIABLES => {
                              ride_types        => $ride_types,
                             },
               },
 },
 #
 # GAME CONFIGS
 #
 # some global single entry configs:
 DollarsPerPoint => "10",
 DefaultTimezone => 'America/New_York',


 # ride types
 RideTypes => $ride_types,
 #
 # metric configs
 #
 RideRecordMetrics =>
 { $BikeGame::Constant::RIDETYPE_ROAD =>
   ['BikeGame::Model::Metric::Distance',
    'BikeGame::Model::Metric::Climb',
    # 'BikeGame::Model::Metric::SingleRide',
    # 'BikeGame::Model::Metric::Achievement',
   ],
   $BikeGame::Constant::RIDETYPE_MTB =>
   ['BikeGame::Model::Metric::Distance',
    'BikeGame::Model::Metric::Climb',
    # 'BikeGame::Model::Metric::SingleRide',
    # 'BikeGame::Model::Metric::Achievement',
   ],
 },

 TrackerTypes => 
 [
  'BikeGame::Model::Metric::Distance',
  'BikeGame::Model::Metric::Climb'
 ],
 TrackerTypeNames => 
 {
  'BikeGame::Model::Metric::Distance' => $BikeGame::Constant::METRICTYPE_DISTANCE,
  'BikeGame::Model::Metric::Climb'    => $BikeGame::Constant::METRICTYPE_CLIMB,
 },

 #
 # metric tracker configs
 # 
 
 # distance
 MetricDistance =>
 {
  $BikeGame::Constant::RIDETYPE_ROAD => 
  {
   distance_per_point => 50,
  },
  $BikeGame::Constant::RIDETYPE_MTB => 
  {
   distance_per_point => 50,
  },
 },
 
# climb
 MetricClimb =>
 {
  $BikeGame::Constant::RIDETYPE_ROAD => 
  {
   climb_per_point => 5000,
  },
  $BikeGame::Constant::RIDETYPE_MTB => 
  {
   climb_per_point => 5000,
  },
 },

 #
 # Levels -> { $ride_type }
 #
 Levels =>
  {
  # points to complete, starting at level 0 for convenience:
   $BikeGame::Constant::RIDETYPE_ROAD =>  #  (total 450 at level 19, nice place to just go 50 from there)
   #    0  1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21
   [qw/ 0  4   6   8  10  13  16  19  22  26  30  34  38  43  48  53  58  64  70  74  78  80/ ],
   $BikeGame::Constant::RIDETYPE_MTB =>
   #     0  1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21
   [ qw/ 0  4   6   8  10  13  16  19  22  26  30  34  38  43  48  53  58  64  70  74  78  80/ ],
 },
 LevelColors => ['36,255,36', '100,255,36', '164,255,36', '228,255,36', '255,191,36',
                 '255,127,36','255,95,36', '255,63,36', '255,36,68', '255,36,100',
                 '255,36,132', '255,36,164', '255,36,196', '255,36,228', '223,36,255',
                 '191,36,255', '159,36,255', '127,36,255', '95,36,255', '63,36,255'],

};

sub get {
    shift if $_[0] eq __PACKAGE__;
    unless ( $_CONFIG->{$_[0]} ) {
        confess "Could not find config entry for $_[0]";
    }
    return $_CONFIG->{$_[0]};
}
# true
1;
