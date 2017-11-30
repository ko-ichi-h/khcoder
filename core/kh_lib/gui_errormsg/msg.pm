package gui_errormsg::msg;
use strict;
use base qw(gui_errormsg);

sub get_msg{
	my $self = shift;
	#return Jcode->new($self->{msg},'euc')->sjis;
	return $self->{msg};
}

1;