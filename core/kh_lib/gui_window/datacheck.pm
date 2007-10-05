package gui_window::datacheck;
use base qw(gui_window);

use strict;
use Tk;

#------------------#
#   Windowを開く   #
#------------------#

sub _new{
	my $self             = shift;
	$self->{dacheck_obj} = shift;

	my $mw = $self->win_obj;

	$mw->title( $self->gui_jchar('分析対象ファイルのチェックと修正','euc') );

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
		-scrollbars => 'osoe',
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
		gui_window->gui_jchar( '■■'.$self->{dacheck_obj}->{repo_sum}."\n", 'euc' )
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
		-text => $self->gui_jchar('見つかった問題点の詳細：'),
	)->pack(-anchor=>'w', -side => 'left');

	$fr_act0->Button(
		-text => $self->gui_jchar('画面に表示'),
		-font => "TKFN",
		-command => sub{ $mw->after
			(
				10,
				sub {
					$text_widget->insert(
						'end',
						gui_window->gui_jchar(
							'■■'.$self->{dacheck_obj}->{repo_full}."\n",
							'euc'
						)
					);
					$text_widget->yview(moveto => 1);
				}
			);
		}
	)->pack(-anchor=>'w', -side => 'left',-padx => 1);

	$fr_act0->Button(
		-text => $self->gui_jchar('ファイルに保存'),
		-font => "TKFN",
		#-width => 8,
		-command => sub{ $mw->after
			(
				10,
				sub {
					$self->save();
				}
			);
		}
	)->pack(-anchor=>'w', -side => 'left', -padx => 1);

	$fr_act0->Label(
		-text => $self->gui_jchar('　　分析対象ファイルの自動修正：'),
	)->pack(-anchor=>'w', -side => 'left');

	$self->{bt_exec} = $fr_act0->Button(
		-text => $self->gui_jchar('実行'),
		-font => "TKFN",
		#-width => 8,
		-state => 'disabled',
		-command => sub{ $mw->after
			(
				10,
				sub {
					$self->edit();
				}
			);
		}
	)->pack(-anchor=>'w', -side => 'left');

	$mw->Button(
		-text => $self->gui_jchar('閉じる'),
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after
			(
				10,
				sub {
					$self->close();
				}
			);
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
			$self->gui_jchar('分析対象ファイル内に見つかった問題点の詳細を保存'),
		-initialdir       => $::config_obj->cwd
	);
	unless ($path){
		return 0;
	}

	# 保存
	$self->{dacheck_obj}->save($path);

	# 結果表示
	$path = Jcode->new($path)->euc;
	$self->{text_widget}->insert(
		'end',
		gui_window->gui_jchar(
			"●見つかった問題点の詳細を次のファイルに保存しました：\n　$path\n\n",
			'euc'
		)
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
	my $path  = Jcode->new( $self->{dacheck_obj}->{file_backup} )->euc;
	my $path2 = Jcode->new( $self->{dacheck_obj}->{file_diff} )->euc;
	$msg .= "●自動修正を行いました。\n\n";
	$msg .= "○修正前の分析対象ファイルを次の場所にバックアップしました：\n";
	$msg .= "　$path\n\n";
	
	$msg .= "○修正箇所のリスト（diff）を次のファイルに保存しました：\n";
	$msg .= "　$path2\n\n";
	
	if ($self->{dacheck_obj}->{auto_ng}){
		$msg .= "○自動的に修正できない箇所が残っています。分析対象ファイルを直接修正して下さい。\n\n";
	} else {
		$msg .= "○分析対象ファイル内に発見された既知の問題点はすべて修正されました。\n\n";
	}
	
	$self->{text_widget}->insert(
		'end',
		gui_window->gui_jchar(
			$msg,
			'euc'
		)
	);
	$self->{text_widget}->yview(moveto => 1);

	$self->{bt_exec}->configure(-state => 'disable');

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
