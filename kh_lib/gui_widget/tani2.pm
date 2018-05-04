package gui_widget::tani2;
use base qw(gui_widget);
use strict;
use Tk;
use Jcode;

my %name = (
	"bun" => kh_msg->gget('sentence'),
	"dan" => kh_msg->gget('paragraph'),
	"h5"  => "H5",
	"h4"  => "H4",
	"h3"  => "H3",
	"h2"  => "H2",
	"h1"  => "H1",
);

my %value = (
	kh_msg->gget('sentence') => "bun",
	kh_msg->gget('paragraph') => "dan",
	"H5"  => "h5",
	"H4"  => "h4",
	"H3"  => "h3",
	"H2"  => "h2",
	"H1"  => "h1",
);

sub _new{
	my $self = shift;
	my @list0 = ("bun","dan","h5","h4","h3","h2","h1");
	

	my (@list1, @list2_1, $width);
	foreach my $i (@list0){
		if (
			mysql_exec->select(
				"select status from status where name = \'$i\'",1
			)->hundle->fetch->[0]
		){
			push @list1, $name{$i};
			unless ($i eq 'bun'){
				push @list2_1, $name{$i};
			}
			$width = length( Encode::encode('euc-jp',$name{$i}) )
				if $width < length( Encode::encode('euc-jp',$name{$i}) );
		}
	}
	
	my $f1 = $self->parent->Frame()->pack(-expand => 'y', -fill => 'x');
	$self->{win_obj} = $f1;
	
	$f1->Label(
		-text => kh_msg->get('unit_c'), # コーディング単位：
		-font => "TKFN",
	)->pack(-side => 'left');
	
#	$f1->Optionmenu(
#		-options=> \@list1,
#		-font => "TKFN",
#		-borderwidth => '1',
#		-width => 4,
#		-command => sub{$self->check;},
#		-variable => \$self->{raw_opt},
#	)->pack(side=>'left',-pady => 2);

	$self->{mb} = $f1->Menubutton(
		-text        => '',
		-tearoff     => 'no',
		-relief      => 'raised',
		-indicator   => 'yes',
		-font        => "TKFN",
		-width       => $width,
		-borderwidth => 1,
	)->pack(-side=>'left',-pady => 2);
	foreach my $i (@list1){
		$self->{mb}->radiobutton(
			-label    => " $i",
			-variable => \$self->{raw_opt},
			-value    => "$i",
			-font     => "TKFN",
			-command  => sub{$self->check;},
		);
	}
	$self->{raw_opt} = gui_window->gui_jchar($name{$::project_obj->last_tani},'euc');

	$f1->Label(
		-text => kh_msg->get('unit_t'), #     集計単位：
		-font => "TKFN",
	)->pack(-side => 'left');

	@list2_1 = reverse @list2_1;
	$self->{opt2} = $f1->Optionmenu(
		-options=> \@list2_1,
		-font => "TKFN",
		-borderwidth => '1',
		#-width => 4,
		-variable => \$self->{raw_opt2},
	)->pack(-side=>'left');


	return $self;
}

sub start{
	my $self = shift;
	$self->check;
}

#-----------------------------#
#   2つ目のOptionmenuを調整   #

sub check{
	my $self = shift;
	
	$self->{mb}->configure(-text,$self->{raw_opt});
	$self->{mb}->update;
	$::project_obj->last_tani( $value{$self->{raw_opt}} );
	
	unless (Exists($self->opt2)){
		return 0;
	}
	
	my $old    = $self->{raw_opt2};
	my $old_ok = 0;
	
	$self->opt2->destroy;
	
	my ($flag, @list);
	foreach my $i ("bun","dan","h5","h4","h3","h2","h1"){
		if ($i eq $self->tani1){
			$flag = 1;
			next;
		}
		
		if (
			( $flag )
			&& (
				mysql_exec->select(
				"select status from status where name = \'$i\'",1
				)->hundle->fetch->[0]
			)
		){
			push @list, $name{$i};
			if ($old eq $name{$i}){
				$old_ok = 1;
			}
		}
	}
	
	@list = reverse( @list );
	
	$self->{raw_opt2} = '';
	$self->{raw_opt2} = $old if $old_ok;
	
	$self->{opt2} = $self->win_obj->Optionmenu(
		-options=> \@list,
		-font => "TKFN",
		-borderwidth => '1',
		-width => 4,
		-variable => \$self->{raw_opt2},
	)->pack(-side=>'left');
	
}


#--------------------------------#
#   選択された値を返すアクセサ   #

sub tani1{
	my $self = shift;
	my $opt = $self->{raw_opt};

	return $value{$opt};
}

sub tani2{
	my $self = shift;
	my $opt  = $self->{raw_opt2};

	return $value{$opt};
}

#----------------------#
#   その他のアクセサ   #

sub opt2{
	my $self = shift;
	return $self->{opt2};
}

1;
