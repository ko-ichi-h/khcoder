package gui_widget;
use strict;

use gui_widget::tani;

sub open{
	my $class = shift;
	my %args = @_;
	my $self = \%args;
	bless $self, $class;
	
	$self->_new;
	return $self;
}

sub parent{
	my $self = shift;
	return $self->{parent};
}
sub win_obj{
	my $self = shift;
	return $self->{win_obj};
}

1;