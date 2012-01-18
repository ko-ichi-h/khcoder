package gui_window::morpho_crossout::tab;
use base qw(gui_window::morpho_crossout);

use strict;

#----------#
#   実行   #

sub save{
	my $self = shift;
	
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('gui_window::morpho_crossout::csv->er_no_pos'),
		);
		return 0;
	}
	
	# 保存先の参照
	my @types = (
		[ kh_msg->get('tabdel'),[qw/.txt/] ], # タブ区切り
		["All files",'*']
	);
	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.txt',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt(kh_msg->get('gui_window::morpho_crossout::csv->saving')),
		-initialdir       => $self->gui_jchar($::config_obj->cwd),
	);
	unless ($path){
		return 0;
	}
	$path = gui_window->gui_jg_filename_win98($path);
	$path = gui_window->gui_jg($path);
	$path = $::config_obj->os_path($path);
	
	$self->{words_obj}->settings_save;
	
	my $ans = $self->win_obj->messageBox(
		-message => kh_msg->gget('cont_big_pros'),
		-icon    => 'question',
		-type    => 'OKCancel',
		-title   => 'KH Coder'
	);
	unless ($ans =~ /ok/i){ return 0; }
	
	my $w = gui_wait->start;
	mysql_crossout::tab->new(
		tani   => $self->tani,
		hinshi => $self->hinshi,
		max    => $self->max,
		min    => $self->min,
		max_df => $self->max_df,
		min_df => $self->min_df,
		file   => $path,
	)->run;
	$w->end;
	
	$self->close;
}

#--------------#
#   アクセサ   #


sub label{
	return kh_msg->get('win_title'); # 「文書ｘ抽出語」表の出力： タブ区切り
}

sub win_name{
	return 'w_morpho_crossout_tab';
}

1;
