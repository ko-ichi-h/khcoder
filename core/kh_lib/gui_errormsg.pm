package gui_errormsg;
use strict;

use kh_mailif;
use gui_errormsg::msg;
use gui_errormsg::file;
use gui_errormsg::mysql;
use gui_errormsg::print;

# usege: gui_errormsg->open
# options: 
#	msg
#	*window
#	type [msg,file,mysql]
#	*thefile
#   *sql
#	*icon

sub open{
	my $class = shift;
	my %args = @_;
	my $self = \%args;
	bless $self, "$class"."::"."$args{type}";
	
	kh_mailif->failure;
	
	$self->{msg} = $self->get_msg;
	$self->print;
	unless ($self->{type} eq 'msg'){
		exit;
	}
}

sub print{
	my $self = shift;
	my %args = %{$self};
	gui_errormsg::print->new(%args);
}



1;
