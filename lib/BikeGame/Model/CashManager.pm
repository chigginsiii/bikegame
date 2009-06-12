package BikeGame::Model::CashManager;
use strict;
use base qw(BikeGame::DBI);

use BikeGame::Config;
use BikeGame::Constant;

__PACKAGE__->table('cash_manager');
__PACKAGE__->columns(Primary => 'ride_record_id');
__PACKAGE__->columns(Essential => 'cash');

sub add_cash {
    my ($self,$cash) = @_;
    $self->cash( $self->cash() + $cash );
    $self->update();
    return $self->cash();
}
sub subtract_cash {
    my ($self,$cash) = @_;
    $self->cash( $self->cash() - $cash );
    $self->update();
    return $self->cash();
}
sub calc_cash {
    my $self = shift;
    my $ride_record       = BikeGame::Model::RideRecord->retrieve( $self->id );
    my $dollars_per_point = $ride_record->player->dollars_per_point();
    return ( $dollars_per_point * $ride_record->total_points );
}
sub clear {
    my $self = shift;
    $self->set('cash','0');
    $self->update();
}


=head1 BikeGame::Model::CashManager

  keeps track of winnings for a ride record

=head1 insert (constructors)

  ride_record_id => $ride_record_instance, # Class::DBI might_have knows how to handle this
  cash           => $cash_amt

=head2 note:

  the method 'cash' is imported into the ride record namespace, so
  only the other methods should be of interest.

=head1 Other Methods of Interest

=head2 add_cash

  add to the total cash amount and return the total

=head2 subtract_cash

  subtract frmo the cash total and return the total

=head2 calc_cash

  get the player dollar_per_point, and the parent ride record total_points,
  and return the resulting amount of cash. This is handy especially if the player
  should change the amount each point is worth

=cut

# true
1;
