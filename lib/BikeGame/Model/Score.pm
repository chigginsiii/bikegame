package BikeGame::Model::Score;
use strict;
use base qw(BikeGame::DBI);

__PACKAGE__->table('score');
__PACKAGE__->columns(All => qw(
                               score_id
                               ride_record metric
                               points message date
                              )
                    );
__PACKAGE__->has_a(  ride_record => 'BikeGame::Model::RideRecord' );
__PACKAGE__->has_a(  metric      => 'BikeGame::Model::Metric' );
__PACKAGE__->has_a( date    => 'DateTime', 
                    inflate => \&from_mysql,
                    deflate => \&to_mysql
                  );

# inflate/deflate routines for date objects
sub from_mysql {
    my ($date_str,$self) = @_;
    return BikeGame::Util::DateTime->from_mysql( $date_str, $self->ride_record->player->timezone );
}
sub to_mysql {
    my ($dt, $self) = @_;
    return BikeGame::Util::DateTime->to_mysql( $dt );
}

sub find_by_player_and_date {
    my ($class,$player,$earliest,$latest) = @_;
    die "No player id!" unless ( $player && $player->id() );
    # get ride record id's
    my @records = $player->ride_records();
    my @record_ids = map { $_->id() } @records;

    my $where = "ride_record IN (" . join(',', map { qq{'$_'} } @record_ids) . ")\n";
    if ( $earliest && $latest ) {
        $where .= "AND date BETWEEN '$earliest' AND '$latest'";
    } elsif ( $earliest ) {
        $where = "AND date > '$earliest'";
    } elsif ( $latest ) {
        $where = "AND date < '$latest'";
    }
    return __PACKAGE__->retrieve_from_sql("$where\nORDER BY date");
}
=pod

=head1 BikeGame::Model::Score

  Score log class

=head1 insert (constructors)

  ride_record => $ride_record_instance,
  metric      => $metric_that_created_this_score,
  points      => $points_scored,
  message     => $note_from_tracker,
  date        => $datetime_instance

=head1 HAS A

=head2 ride_record

=head2 metric

=cut

# true
1;
