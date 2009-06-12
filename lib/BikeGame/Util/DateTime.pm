package BikeGame::Util::DateTime;
use strict;
use DateTime;

sub from_mysql {
    shift if $_[0] eq __PACKAGE__;
    my ($date_str,$tz) = (@_);
    return undef if $date_str eq '0000-00-00 00:00:00';

    $tz ||= BikeGame::Config->get("DefaultTimezone");
    my ($Y,$M,$D,$h,$m,$s) = ( $date_str =~ /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/o );
    return DateTime->new( year      => $Y,
                          month     => $M,
                          day       => $D,
                          hour      => $h,
                          minute    => $m,
                          second    => $s,
                          time_zone => $tz
                        );
}
sub to_mysql {
    shift if (!ref($_[0]) && ($_[0] eq __PACKAGE__));
    my $dt = shift;
    return $dt ? $dt->strftime("%F %T") : '0000-00-00 00:00:00';
}

sub display_ridelog {
    shift if (!ref($_[0]) && ($_[0] eq __PACKAGE__));
    my $dt = shift;
    return $dt ? $dt->strftime("%F %T") : '0000-00-00 00:00:00';
}

# true
1;

