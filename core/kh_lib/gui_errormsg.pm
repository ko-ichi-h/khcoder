package gui_errormsg;
use strict;

use kh_mailif;
use gui_errormsg::msg;
use gui_errormsg::file;
use gui_errormsg::mysql;
use gui_errormsg::print;

my $exiting = 0;

# usege: gui_errormsg->open
# options: 
#	msg
#	*window
#	type [msg,file,mysql]
#	*thefile
#   *sql
#	*icon [info,,, ]

sub open{
	my $class = shift;
	my %args = @_;
	my $self = \%args;
	bless $self, "$class"."::"."$args{type}";
	
	kh_mailif->failure;
	
	$self->{msg} = $self->get_msg;
	unless ($self->{type} eq 'msg') {
		#print "hoge!!!!\n";
		($self->{caller_pac}, $self->{caller_file}, $self->{caller_line}) = caller;
		$self->{msg} .= "\n\n";
		$self->{msg} .= "$self->{caller_file} line $self->{caller_line}";
	}
	
	$self->print;
	unless ($self->{type} eq 'msg'){
		if ($::main_gui){
			print "Exit (gui_errormsg.pm)\n";
			exit if $exiting;
			$exiting = 1;
			$::main_gui->close;
		} else {
			exit;
		}
	}
}

sub print{
	my $self = shift;
	my %args = %{$self};
	gui_errormsg::print->new(%args);
}

1;
