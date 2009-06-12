package BikeGame::Constant;

use strict;

# ridetype is also used for charclass types
our $RIDETYPE_ROAD = 'road';
our $RIDETYPE_MTB  = 'mtb';

# metric types
#our $METRICTYPE_ = '';
our $METRICTYPE_DISTANCE = 'distance';
our $METRICTYPE_CLIMB    = 'climb';

# template configs
our $TEMPLATES = 
{
 entry            => 'entry.tpl',
 dashboard        => 'dashboard.tpl',
 dashboard_error  => 'dashboard_error.tpl',
 create_player    => 'create_player.tpl',
 add_ride         => 'add_ride.tpl',
 # Util::HTML
 util_html_level_table => 'util_html/level_table.tpl',
};

#true
1;
