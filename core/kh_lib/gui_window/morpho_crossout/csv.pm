package gui_window::morpho_crossout::csv;
use base qw(gui_window::morpho_crossout);

use strict;

#----------#
#   実行   #

sub save{
	my $self = shift;
	
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => '品詞が1つも選択されていません。',
		);
		return 0;
	}
	
	# 保存先の参照
	my @types = (
		[ Jcode->new('CSV Files')->sjis,[qw/.csv/] ],
		#[ Jcode->new('タブ区切り')->sjis,[qw/.txt/] ],
		["All files",'*']
	);
	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.csv',
		-filetypes        => \@types,
		-title            =>
			Jcode->new('「文書ｘ抽出語」表：名前を付けて保存')->sjis,
		-initialdir       => $::config_obj->cwd
	);
	unless ($path){
		return 0;
	}
	
	my $ans = $self->win_obj->messageBox(
		-message => Jcode->new
			(
			   "この処理には時間がかかることがあります。\n".
			   "続行してよろしいですか？"
			)->sjis,
		-icon    => 'question',
		-type    => 'OKCancel',
		-title   => 'KH Coder'
	);
	unless ($ans =~ /ok/i){ return 0; }
	
	my $w = gui_wait->start;
	mysql_crossout::csv->new(
		tani   => $self->tani,
		hinshi => $self->hinshi,
		max    => $self->max,
		min    => $self->min,
		file   => $path,
	)->run;
	$w->end;
	
	$self->close;
}

#--------------#
#   アクセサ   #


sub label{
	return '「文書ｘ抽出語」表の出力： CSV';
}

sub win_name{
	return 'w_morpho_crossout_CSV';
}

1;
