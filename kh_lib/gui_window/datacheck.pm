package gui_window::datacheck;
use base qw(gui_window);

use strict;
use Tk;

use utf8;

#------------------#
#   Windowを開く   #
#------------------#

sub _new{
	my $self             = shift;
	$self->{dacheck_obj} = shift;

	my $mw = $self->win_obj;

	$mw->title( $self->gui_jt( kh_msg->get('win_title') ) ); # '分析対象ファイルのチェックと修正','euc'

	my $fr_res = $mw->LabFrame(
		-label       => 'Results & Messages',
		-labelside   => 'acrosstop',
		-borderwidth => 2,
	)->pack(
		-fill   => 'both',
		-expand => 1,
		-anchor => 'n',
		#-side   => 'top'
	);

	my $text_widget = $fr_res->Scrolled(
		"ROText",
		-scrollbars => 'ose',
		-height     => 12,
		-width      => 80,
	)->pack(
		-padx   => 2,
		-fill   => 'both',
		-expand => 'yes'
	);
	$text_widget->bind("<Key>",[\&gui_jchar::check_key,Ev('K'),\$text_widget]);

	$text_widget->insert(
		'end',
		kh_msg->get('headmark') # ■■ 
		.$self->{dacheck_obj}->{repo_sum}
		."\n"
	);

	my $fr_act = $mw->LabFrame(
		-label       => 'Functions',
		-labelside   => 'acrosstop',
		-borderwidth => 2,
	)->pack(
		-fill   => 'x',
		-expand => 0,
		-anchor => 'n',
		#-side   => 'top'
	);

	my $fr_act0 = $fr_act->Frame()->pack(-fill => 'x');
	$fr_act0->Label(
		-text => kh_msg->get('details'),#gui_jchar('見つかった問題点の詳細：'),
	)->pack(-anchor=>'w', -side => 'left');

	$self->{bttn_details_print} = $fr_act0->Button(
		-text => kh_msg->get('print'),#$self->gui_jchar('画面に表示'),
		-font => "TKFN",
		-command => sub {
			$text_widget->insert(
				'end',
				kh_msg->get('headmark')
				.gui_window->gui_jchar(
					$self->{dacheck_obj}->{repo_full}."\n",
					'euc'
				)
			);
			$text_widget->yview(moveto => 1);
		}
	)->pack(-anchor=>'w', -side => 'left',-padx => 1);

	$self->{bttn_details_save} = $fr_act0->Button(
		-text => kh_msg->get('save_as'),#$self->gui_jchar('ファイルに保存'),
		-font => "TKFN",
		#-width => 8,
		-command => sub {
			$self->save();
		}
	)->pack(-anchor=>'w', -side => 'left', -padx => 1);

	$fr_act0->Label(
		-text => kh_msg->get('auto_correct'),#$self->gui_jchar('　　分析対象ファイルの自動修正：'),
	)->pack(-anchor=>'w', -side => 'left');

	$self->{bttn_auto_collect} = $self->{bt_exec} = $fr_act0->Button(
		-text => kh_msg->get('exec'),#$self->gui_jchar('実行'),
		-font => "TKFN",
		#-width => 8,
		-state => 'disabled',
		-command => sub {
			$self->edit();
		}
	)->pack(-anchor=>'w', -side => 'left');

	$mw->Button(
		-text => kh_msg->get('close'),#$self->gui_jchar('閉じる'),
		-font => "TKFN",
		-width => 8,
		-command => sub {
			$self->close();
		}
	)->pack(-anchor => 'c',-pady => '0');
	$self->{bt_exec}->configure(-state => 'normal')
		if $self->{dacheck_obj}->{auto_ok};

	$self->{text_widget} = $text_widget;
	return $self;
}

#----------------------#
#   結果の詳細を保存   #

sub save{
	my $self = shift;

	# ファイル名の取得
	my @types = (
		[ "text file",[qw/.txt/] ],
		["All files",'*']
	);
	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.txt',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt(
				kh_msg->get('save_as_win')#'分析対象ファイル内に見つかった問題点の詳細を保存'
			),
		-initialdir       => $self->gui_jchar($::config_obj->cwd),
	);
	unless ($path){
		return 0;
	}
	$path = gui_window->gui_jg_filename_win98($path);
	$path = gui_window->gui_jg($path);
	$path = $::config_obj->os_path($path);

	# 保存
	$self->{dacheck_obj}->save($path);

	# 結果表示
	$path = Jcode->new($path)->euc;
	$self->{text_widget}->insert(
		'end',
		kh_msg->get('saved')#"●見つかった問題点の詳細を次のファイルに保存しました："
		."\n　$path\n\n",
	);
	$self->{text_widget}->yview(moveto => 1);
}

#--------------#
#   自動修正   #

sub edit{
	my $self = shift;
	
	$self->{dacheck_obj}->edit;
	
	# 結果表示
	my $msg = '';
	my $path  = gui_window->gui_jchar( $self->{dacheck_obj}->{file_backup} );
	my $path2 = gui_window->gui_jchar( $self->{dacheck_obj}->{file_diff} );
	#$msg .= kh_msg->get('headmark');#"●自動修正を行いました。\n\n";
	$msg .= kh_msg->get('correction_done');
	$msg .= "\n\n";
	$msg .= kh_msg->get('file_backup');
	$msg .= "\n";
	#$msg .= "○修正前の分析対象ファイルを次の場所にバックアップしました：\n";
	$msg .= "　$path\n\n";
	
	if ($self->{dacheck_obj}->{diff}){
		$msg .= kh_msg->get('file_diff');
		$msg .= "\n";
		#$msg .= "○修正箇所のリスト（diff）を次のファイルに保存しました：\n";
		$msg .= "　$path2\n\n";
	}
	
	if ($self->{dacheck_obj}->{auto_ng}){
		$msg .= kh_msg->get('not_complete');
		#$msg .= "○自動的に修正できない箇所が残っています。分析対象ファイルを直接修正して下さい。\n\n";
		$msg .= "\n\n";
	} else {
		$msg .= kh_msg->get('looks_complete');
		#$msg .= "○分析対象ファイル内に発見された既知の問題点はすべて修正されました。\n\n";
		$msg .= "\n";
	}
	
	$self->{text_widget}->insert(
		'end',
		$msg,
	);
	$self->{text_widget}->yview(moveto => 1);

	$self->{bt_exec}->configure(-state => 'disable');
	
	return $self;

}

#--------------#
#   終了処理   #

sub end{
	my $self = shift;
	$self->{dacheck_obj}->clean_up;
}

#--------------#
#   Window名   #

sub win_name{
	return 'w_datacheck';
}

1;
