package gui_widget::tani_and_o;
use base qw(gui_widget);
use strict;
use Tk;
use Jcode;

my %name = (
	"bun" => "文",
	"dan" => "段落",
	"h5"  => "H5",
	"h4"  => "H4",
	"h3"  => "H3",
	"h2"  => "H2",
	"h1"  => "H1",
);

my %value = (
	"文" => "bun",
	"段落" => "dan",
	"H5"  => "h5",
	"H4"  => "h4",
	"H3"  => "h3",
	"H2"  => "h2",
	"H1"  => "h1",
);


sub _new{
	my $self = shift;
	
	$self->{win_obj} = $self->parent->Frame();
	
	
	
	return $self;
}




1;
