package gui_window::outvar_list;
use base qw(gui_window);
use strict;
use Tk;

use mysql_outvar;

#---------------------#
#   Window オープン   #
#---------------------#

sub _new{
	my $self = shift;
	
	my $mw = $::main_gui->mw;
	my $wmw= $mw->Toplevel;
	$wmw->focus;
	$wmw->title(Jcode->new('外部変数リスト')->sjis);

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
		-columns          => 2,
		-padx             => 2,
		-background       => 'white',
		-selectforeground => 'brown',
		-selectbackground => 'cyan',
		-selectmode       => 'extended',
		-command          => sub {$self->_open_var;},
		-height           => 10,
	)->pack(-fill =>'both',-expand => 'yes');

	$lis->header('create',0,-text => Jcode->new('集計単位')->sjis);
	$lis->header('create',1,-text => Jcode->new('変数名')->sjis);

	$wmw->Button(
		-text => Jcode->new('詳細')->sjis,
		-font => "TKFN",
#		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->_open_var;});}
	)->pack(-side => 'left');

	$wmw->Button(
		-text => Jcode->new('削除')->sjis,
		-font => "TKFN",
#		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->_delete;});}
	)->pack(-side => 'left',-padx => 2);

	$wmw->Button(
		-text => Jcode->new('閉じる')->sjis,
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2);

	MainLoop;
	
	$self->{list}    = $lis;
	$self->{win_obj} = $wmw;
	$self->_fill;
	return $self;
}

#--------------------#
#   ファンクション   #
#--------------------#

sub _fill{
	my $self = shift;
	
	my $h = mysql_outvar->get_list;
	
	$self->{list}->delete('all');
	my $n = 0;
	foreach my $i (@{$h}){
		if ($i->[0] eq 'dan'){$i->[0] = '段落';}
		if ($i->[0] eq 'bun'){$i->[0] = '文';}
		$self->{list}->add($n,-at => "$n");
		$self->{list}->itemCreate($n,0,-text => Jcode->new($i->[0])->sjis,);
		$self->{list}->itemCreate($n,1,-text => Jcode->new($i->[1])->sjis,);
		++$n;
	}
	$self->{var_list} = $h;
	return $self;
}

sub _delete{
	my $self = shift;
	
	# 選択確認
	my @selection = $self->{list}->info('selection');
	unless (@selection){
		return 0;
	}
	
	# 本当に削除するのか確認
	my $confirm = $self->{win_obj}->messageBox(
		-title   => 'KH Coder',
		-type    => 'OKCancel',
#		-default => 'OK',
		-icon    => 'question',
		-message => Jcode->new('選択されている変数を削除しますか？')->sjis,
	);
	unless ($confirm =~ /^OK$/i){
		return 0;
	}
	
	# 削除実行
	foreach my $i (@selection){
		mysql_outvar->delete(
			tani => $self->{var_list}[$i][0],
			name => $self->{var_list}[$i][1],
		);
	}
	
	$self->_fill;
}

sub _open_var{
	my $self = shift;
	
	my @selection = $self->{list}->info('selection');
	unless (@selection){
		return 0;
	}
	
	gui_window::outvar_detail->open(
		tani => $self->{var_list}[$selection[0]][0],
		name => $self->{var_list}[$selection[0]][1],
	);

}

#--------------#
#   アクセサ   #
#--------------#


sub win_name{
	return 'w_outvar_list';
}


1;
