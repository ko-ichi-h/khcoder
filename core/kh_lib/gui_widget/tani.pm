package gui_widget::tani;
use base qw(gui_widget);
use strict;
use Tk;
use Jcode;

sub _new{
	my $self = shift;
	my @list0 = ("dan","bun","h5","h4","h3","h2","h1");
	my %name = (
		"bun" => "文",
		"dan" => "段落",
		"h5"  => "H5",
		"h4"  => "H4",
		"h3"  => "H3",
		"h2"  => "H2",
		"h1"  => "H1",
	);
	my @list1;
	foreach my $i (@list0){
		if (
			mysql_exec->select(
				"select status from status where name = \'$i\'",1
			)->hundle->fetch->[0]
		){
			push @list1, Jcode->new($name{$i})->sjis;
		}
	}
	
	$self->{win_obj} = $self->parent->Optionmenu(
		-options=> \@list1,
		-font => "TKFN",
		-borderwidth => '1',
		-width => 4,
		-variable => \$self->{raw_opt},
	);
}

sub tani{
	my $self = shift;
	my $opt = Jcode->new($self->{raw_opt})->euc;
	my %name = (
		"文" => "bun",
		"段落" => "dan",
		"H5"  => "h5",
		"H4"  => "h4",
		"H3"  => "h3",
		"H2"  => "h2",
		"H1"  => "h1",
	);
	return $name{$opt};
}
1;
