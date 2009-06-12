#!/usr/bin/perl -w
use strict;
use CGI;
my $c = CGI->new;

my @first_vals = qw(0 3 6 9 C F);
my @second_vals = qw(6 9 F);
my @hexvals;
foreach my $first (@first_vals ) {
    foreach my $second (@second_vals ) {
        push @hexvals, $first.$second;
    }
}
$| = 1;

print $c->header();
print $c->start_html("Colors");
$c->print("<style>
.swatchline { height:50px; display:block; }
.swatch { float:left; height: 50px; width: 60px; font-size:10px; text-align:middle; display:inline;}
</style>");

my $floor = $c->param('floor') || 0;
my $ceiling = $c->param('ceiling') || 255;
my $step = $c->param('step') || 16;

my @level_colors;
# start with green, increase the red to make yellow
for ( my $i = $floor; $i <= $ceiling; $i += $step ) {
    push@level_colors, "$i,$ceiling,$floor";
}
# decrease the green: turn yellow to red
for (my $i = ($ceiling - $step); $i >= $floor; $i -= $step ) {
    push@level_colors, "$ceiling,$i,$floor";
}
# increase the blue, turn the red to violet
for ( my $i = ($floor + $step); $i <= $ceiling; $i += $step ) {
    push@level_colors, "$ceiling,$floor,$i";
}
# decrease the red, turn the violet to blue
for ( my $i = ($ceiling - $step); $i >= $floor; $i -= $step ) {
    push@level_colors, "$i,$floor,$ceiling";
}
my $num = scalar(@level_colors);
print $c->p("Floor: $floor, Ceiling: $ceiling, Step: $step");
print $c->p("Colors: $num (x2:" . ($num * 2) . ", x3:" . ($num * 3) . ")");
# 06FF06 09FF06 0FFF06 36FF06
$c->print('<div class="swatchline">');
my $counter = 1;
foreach my $color ( @level_colors ) {
    $c->print(qq(<div class="swatch" style="background-color:rgb($color)">$color</div>));
    unless ( $counter % 10) {
        $c->print('<div style="clear:both"></div>');
    }
    $counter++;
}
$c->print('</div>');
$c->print('<div style="clear:both"></div>');

$c->print('<div class="swatchline">');
my $counter = 1;
foreach my $color ( @level_colors ) {
    my $level = ( $counter * 2 ) - 1;
    $c->print(qq(<div class="swatch" style="background-color:rgb($color)">Level: $level</div>));
    unless ( $counter % 10 ) {
        $c->print('<div style="clear:both"></div>');
    }
    $counter++;
}
$c->print('</div>');
$c->print('<div style="clear:both"></div>');
$c->print('<div>[' . join(', ', map { qq('$_') } @level_colors ) . ']</div>');

# for ( my $i = 0; $i < @hexvals; $i++ ) {
#     my $green = $hexvals[$i];
    
#     $c->print(qq{<div class="swatchblock">});
#     for ( my $j = 0; $j < @hexvals; $j++ ) {
        
#         my $blue = $hexvals[$#hexvals - $j];
#         $c->print(qq{<div class="swatchline">});
#         for ( my $k = 0; $k < @hexvals; $k++ ) {
            
#             my $red = $hexvals[$#hexvals - $k];
#             $c->print(qq{<div class="swatch" style="background-color:#$red$green$blue">$red$green$blue</div>});
            
#         }
#         $c->print(qq{</div>});
        
#     }
#     print $c->print(qq{<div style="clear:both;"></div>});
#     $c->print(qq{</div>});
# }

print $c->end_html();
