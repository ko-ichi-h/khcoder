package gui_widget::tani;
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
	my @list0 = ("bun","dan","h5","h4","h3","h2","h1");

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

	$self->{win_obj} = $self->parent->Menubutton(
		-text        => '',
		-tearoff     => 'no',
		-relief      => 'raised',
		-indicator   => 'yes',
		-font        => "TKFN",
		-width       => 4,
		-borderwidth => 1,
	)->pack();
	foreach my $i (@list1){
		$self->{win_obj}->radiobutton(
			-label     => " $i",
			-variable => \$self->{raw_opt},
			-value    => "$i",
			-font     => "TKFN",
			-command  => sub{$self->mb_refresh}
		);
	}

	$self->{raw_opt} = Jcode->new($name{$::project_obj->last_tani})->sjis;

	return $self;
}

sub tani{
	my $self = shift;
	my $opt = Jcode->new($self->{raw_opt})->euc;
	return $value{$opt};
}
sub start{
	my $self = shift;
	$self->mb_refresh;
}
sub mb_refresh{
	my $self = shift;
	$self->{win_obj}->configure(-text,Jcode->new("$self->{raw_opt}")->sjis);
	$self->{win_obj}->update;
	$::project_obj->last_tani($value{Jcode->new($self->{raw_opt})->euc});
	if ( defined($self->{command}) && $_[0] != 5){
		&{$self->{command}};
	}
}

1;
