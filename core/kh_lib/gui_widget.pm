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
	$self->start;
	return $self;
}
sub start{
	return 1;
}
sub parent{
	my $self = shift;
	return $self->{parent};
}
sub win_obj{
	my $self = shift;
	return $self->{win_obj};
}
sub normal{
	my $self = shift;
	$self->win_obj->configure(-state => 'normal');
}
sub disable{
	my $self = shift;
	$self->win_obj->configure(-state => 'disable');
}

1;