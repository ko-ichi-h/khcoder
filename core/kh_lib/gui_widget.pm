package gui_widget;
use strict;

use gui_widget::tani;
use gui_widget::tani2;
use gui_widget::codf;
use gui_widget::mail_config;
use gui_widget::hinshi;

sub open{
	my $class = shift;
	my %args = @_;
	my $self = \%args;
	bless $self, $class;
	
	$self->_new->win_obj->pack(%{$self->{pack}});
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