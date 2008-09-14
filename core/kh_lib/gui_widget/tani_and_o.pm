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

#----------------#
#   Widget作成   #

sub _new{
	my $self = shift;
	
	$self->{win_obj} = $self->parent->Frame(
		-relief             => 'sunken',
		-borderwidth        => 2,
	);
	
	$self->{hlist} = $self->{win_obj}->Scrolled(
		'HList',
		-scrollbars         => 'osoe',
		-font               => 'TKFN',
		-selectmode         => 'none',
		-indicator          => 0,
		-highlightthickness => 0,
		-columns            => 2,
		-borderwidth        => 0,
		-height             => 6,
	)->pack();
	
	my @list0 = ("bun","dan","h5","h4","h3","h2","h1");
	my $row = 0;
	my $right = $self->{hlist}->ItemStyle('window',-anchor => 'w');
	foreach my $i (@list0){
		if (
			mysql_exec->select(
				"select status from status where name = \'$i\'",1
			)->hundle->fetch->[0]
		){
			my $c = $self->{hlist}->Checkbutton(
				-text     => gui_window->gui_jchar($name{$i}),
				-variable => \$self->{check}{$i},
				-command  => sub {$self->refresh;},
				-anchor   => 'w',
			);
			$self->{entry}{$i} = $self->{hlist}->Entry(
				-width => 3,
			);
			gui_window->config_entry_focusin($self->{entry}{$i});
			
			$self->{hlist}->add($row,-at => $row,);
			$self->{hlist}->itemCreate(
				$row,0,
				-itemtype  => 'window',
				-style => $right,
				-widget    => $c,
			);
			#$self->{hlist}->itemCreate(
			#	$row,1,
			#	-itemtype  => 'text',
			#	-text      => gui_window->gui_jchar($name{$i}.' 　'),
			#);
			$self->{hlist}->itemCreate(
				$row,1,
				-itemtype  => 'window',
				-widget    => $self->{entry}{$i},
			);
			
			$self->{entry}{$i}->insert(0,1);
			if ($i eq 'bun'){
				$c->select;
			}
			++$row;
		}
	}
	
	$self->refresh;
	return $self;
}

sub refresh{
	my $self = shift;
	foreach my $i (keys %{$self->{check}}){
		if ($self->{check}{$i}){
			$self->{entry}{$i}->configure(
				-state      => 'normal',
				-background => 'white'
			);
		} else {
			$self->{entry}{$i}->configure(
				-state      => 'disable',
				-background => 'gray'
			);
		}
	}
	
	return $self;
}

sub value{
	my $self = shift;
	my @list;
	foreach my $i (keys %{$self->{check}}){
		if ($self->{check}{$i}){
			push @list, [$i, gui_window->gui_jg($self->{entry}{$i}->get) ];
		}
	}
	return \@list;
}

1;
