package gui_widget;
use strict;

use gui_widget::tani;
use gui_widget::tani2;
use gui_widget::tani_and_o;
use gui_widget::codf;
use gui_widget::mail_config;
use gui_widget::hinshi;
use gui_widget::chklist;
use gui_widget::url_lab;
use gui_widget::words;
use gui_widget::words_bayes;
use gui_widget::bubble;
use gui_widget::cls4mds;
use gui_widget::select_a_var;
use gui_widget::r_font;
use gui_widget::r_xy;
use gui_widget::r_mds;
use gui_widget::r_cls;
use gui_widget::r_net;
use gui_widget::r_som;
use gui_widget::sampling;
use gui_widget::r_margin;

sub open{
	my $class = shift;
	my %args = @_;
	my $self = \%args;
	bless $self, $class;
	
	if ($self->{grid}) {
		$self->_new->win_obj->grid(%{$self->{grid}});
	} else {
		$self->_new->win_obj->pack(%{$self->{pack}});
	}
	
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