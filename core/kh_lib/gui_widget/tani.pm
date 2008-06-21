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
			push @list1, $i;
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
			-label    => gui_window->gui_jchar(" $name{$i}",'euc'),
			-variable => \$self->{raw_opt},
			-value    => "$i",
			-font     => "TKFN",
			-command  => sub{$self->mb_refresh}
		);
	}

	$self->{raw_opt} = $::project_obj->last_tani;

	return $self;
}

sub tani{
	my $self = shift;
	return gui_window->gui_jg( $self->{raw_opt} );
}
sub start{
	my $self = shift;
	$self->mb_refresh;
}
sub mb_refresh{
	my $self = shift;
	$self->{win_obj}->configure(-text,gui_window->gui_jchar($name{$self->{raw_opt}},'euc'));
	$self->{win_obj}->update;
	$::project_obj->last_tani($self->{raw_opt})
		unless $self->{dont_remember};
	if ( defined($self->{command}) and not (defined($_[0]) && $_[0] == 5) ){
		&{$self->{command}};
	}
}

1;
