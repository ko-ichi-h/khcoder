package gui_widget::tani2;
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
	

	my (@list1, @list2_1);
	foreach my $i (@list0){
		if (
			mysql_exec->select(
				"select status from status where name = \'$i\'",1
			)->hundle->fetch->[0]
		){
			push @list1, Jcode->new($name{$i})->sjis;
			unless ($i eq 'bun'){
				push @list2_1, Jcode->new($name{$i})->sjis;
			}
		}
	}
	
	my $f1 = $self->parent->Frame()->pack(expand => 'y', fill => 'x');
	$self->{win_obj} = $f1;
	
	$f1->Label(
		text => Jcode->new('コーディング単位：')->sjis,
		font => "TKFN",
	)->pack(side => 'left');
	
#	$f1->Optionmenu(
#		-options=> \@list1,
#		-font => "TKFN",
#		-borderwidth => '1',
#		-width => 4,
#		-command => sub{$self->check;},
#		-variable => \$self->{raw_opt},
#	)->pack(side=>'left',-pady => 2);

	$self->{mb} = $f1->Menubutton(
		-text      => '',
		-tearoff   => 'no',
		-relief    => 'raised',
		-indicator => 'yes',
		-font      => "TKFN",
		-width     => 4,
	)->pack(side=>'left',-pady => 2);
	foreach my $i (@list1){
		$self->{mb}->radiobutton(
			-label    => " $i",
			-variable => \$self->{raw_opt},
			-value    => "$i",
			-font     => "TKFN",
			-command  => sub{$self->check;},
		);
	}
	$self->{raw_opt} = Jcode->new($name{$::project_obj->last_tani})->sjis;

	$f1->Label(
		text => Jcode->new('    集計単位：')->sjis,
		font => "TKFN",
	)->pack(side => 'left');

	$self->{opt2} = $f1->Optionmenu(
		-options=> \@list2_1,
		-font => "TKFN",
		-borderwidth => '1',
		-width => 4,
		-variable => \$self->{raw_opt2},
	)->pack(side=>'left');


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
	
	$self->{mb}->configure(-text,Jcode->new("$self->{raw_opt}")->sjis);
	$self->{mb}->update;
	$::project_obj->last_tani($value{Jcode->new($self->{raw_opt})->euc});
	
	unless (Exists($self->opt2)){
		return 0;
	}
	
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
			push @list, Jcode->new($name{$i})->sjis;
		}
	}
	
	$self->{raw_opt2} = '';
	$self->{opt2} = $self->win_obj->Optionmenu(
		-options=> \@list,
		-font => "TKFN",
		-borderwidth => '1',
		-width => 4,
		-variable => \$self->{raw_opt2},
	)->pack(side=>'left');
	
}


#--------------------------------#
#   選択された値を返すアクセサ   #

sub tani1{
	my $self = shift;
	my $opt = Jcode->new($self->{raw_opt})->euc;

	return $value{$opt};
}
sub tani2{
	my $self = shift;
	my $opt = Jcode->new($self->{raw_opt2})->euc;

	return $value{$opt};
}

#----------------------#
#   その他のアクセサ   #

sub opt2{
	my $self = shift;
	return $self->{opt2};
}

1;
