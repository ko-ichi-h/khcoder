package gui_errormsg::print;
use strict;

use gui_errormsg::print::gui_tk;
use gui_errormsg::print::cmdline;

sub new{
	my $class = shift;
	my %args = @_;
	my $self = \%args;
	
	my $mw;
	eval{ $mw = $::main_gui->mw; };

	my $type;
	if ( $mw ){
		$type = "gui_tk";
	} else {
		$type = "cmdline";
	}
	
	bless $self, "$class"."::"."$type";
	$self->print;
}
1;
