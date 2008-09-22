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
	my $wmw= $self->{win_obj};
	#$wmw->focus;
	$wmw->title($self->gui_jt('外部変数リスト'));

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
		-selectborderwidth=> 0,
		-selectmode       => 'extended',
		-command          => sub {$self->_open_var;},
		-height           => 10,
	)->pack(-fill =>'both',-expand => 'yes');

	$lis->header('create',0,-text => $self->gui_jchar('集計単位'));
	$lis->header('create',1,-text => $self->gui_jchar('変数名'));

	$wmw->Button(
		-text => $self->gui_jchar('詳細'),
		-font => "TKFN",
#		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->_open_var;});}
	)->pack(-side => 'left');

	$wmw->Button(
		-text => $self->gui_jchar('削除'),
		-font => "TKFN",
#		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->_delete;});}
	)->pack(-side => 'left',-padx => 2);

	$wmw->Button(
		-text => $self->gui_jchar('閉じる'),
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2);

	#MainLoop;
	
	$self->{list}    = $lis;
	#$self->{win_obj} = $wmw;
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
		$self->{list}->itemCreate($n,0,-text => $self->gui_jchar($i->[0]),);
		$self->{list}->itemCreate($n,1,-text => $self->gui_jchar($i->[1]),);
		++$n;
		# my $chk = Jcode->new($i->[1])->icode;
		# print "$chk, $i->[1]\n";
	}
	$self->{var_list} = $h;
	return $self;
}

sub _delete{
	my $self = shift;
	my %args = @_;
	
	# 選択確認
	my @selection = $self->{list}->info('selection');
	unless (@selection){
		return 0;
	}
	
	# 本当に削除するのか確認
	unless ( $args{no_conf} ){
		my $confirm = $self->{win_obj}->messageBox(
			-title   => 'KH Coder',
			-type    => 'OKCancel',
			#-default => 'OK',
			-icon    => 'question',
			-message => $self->gui_jchar('選択されている変数を削除しますか？'),
		);
		unless ($confirm =~ /^OK$/i){
			return 0;
		}
	}
	
	# 既に詳細Windowが開いている場合はいったん閉じる
	$::main_gui->get('w_outvar_detail')->close
		if $::main_gui->if_opened('w_outvar_detail');
	
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
	
	# 既に詳細Windowが開いている場合はいったん閉じる
	$::main_gui->get('w_outvar_detail')->close
		if $::main_gui->if_opened('w_outvar_detail');

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
