package gui_window::outvar_detail;
use base qw(gui_window);
use strict;
use Tk;

use mysql_outvar;

#---------------------#
#   Window オープン   #
#---------------------#

sub _new{
	my $self = shift;
	my %args = @_;
	
	my $mw = $::main_gui->mw;
	my $wmw= $mw->Toplevel;
	#$wmw->focus;
	$wmw->title(Jcode->new("変数詳細： "."$args{name}")->sjis);

	my $fra4 = $wmw->LabFrame(
		-label => 'Variables',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill=>'both', -expand => 'yes');

	my $lis = $fra4->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 1,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => 3,
		-padx             => 2,
		-background       => 'white',
		-selectforeground => 'brown',
		-selectbackground => 'cyan',
		-selectmode       => 'none',
		-command          => sub {$self->_open_var;},
		-height           => 10,
	)->pack(-fill =>'both',-expand => 'yes');

	$lis->header('create',0,-text => Jcode->new('値')->sjis);
	$lis->header('create',1,-text => Jcode->new('ラベル')->sjis);
	$lis->header('create',2,-text => Jcode->new('度数')->sjis);

	$wmw->Button(
		-text => Jcode->new('キャンセル')->sjis,
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2);

	$wmw->Button(
		-text => Jcode->new('OK')->sjis,
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->_save;});}
	)->pack(-side => 'right');

	MainLoop;

	# 情報の取得と表示
	$self->{var_obj} = mysql_outvar::a_var->new($args{name});
	my $v = $self->{var_obj}->detail_tab;
	my $n = 0;
	my $right = $lis->ItemStyle('text',-anchor => 'e',-background => 'white');
	foreach my $i (@{$v}){
		$lis->add($n,-at => "$n");
		$lis->itemCreate($n,0,-text => Jcode->new($i->[0])->sjis,);
		$lis->itemCreate(
			$n,
			2,
			-text  => Jcode->new($i->[2])->sjis,
			-style => $right
		);
		
		my $c = $lis->Entry(
			-font  => "TKFN",
			-width => 15
		);
		$lis->itemCreate(
			$n,1,
			-itemtype  => 'window',
			-widget    => $c,
		);
		$c->insert(0,Jcode->new($i->[1])->sjis);
		$c->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$c]);
		
		$self->{entry}{$i->[0]} = $c;
		$self->{label}{$i->[0]} = Jcode->new($i->[1])->sjis;
		++$n;
	}
	$wmw->bind('Tk::Entry', '<Key-Delete>', \&gui_jchar::check_key_e_d);

	$self->{list}    = $lis;
	$self->{win_obj} = $wmw;
	$wmw->grab;
	return $self;
}

#--------------------#
#   ファンクション   #
#--------------------#

sub _save{
	my $self = shift;
	
	# 変更されたラベルを保存
	foreach my $i (keys %{$self->{label}}){
		if ($self->{label}{$i} eq $self->{entry}{$i}->get){
			next;
		}
		$self->{var_obj}->label_save(
			Jcode->new($i)->euc,
			Jcode->new($self->{entry}{$i}->get)->euc,
		);
	}
	
	$self->close;
}

#--------------#
#   アクセサ   #
#--------------#


sub win_name{
	return 'w_outvar_detail';
}


1;
