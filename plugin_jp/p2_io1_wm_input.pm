package p2_io1_wm_input;
use strict;
use utf8;

#----------------------#
#   プラグインの設定   #

sub plugin_config{
	return {
		name     => '新規プロジェクト - 無記入・空白の行に対応',
		menu_cnf => 0,
		menu_grp => '入出力',
	};
}

#----------------------------------------#
#   メニュー選択時に実行されるルーチン   #

sub exec{
	gui_window::wm_input->open; # GUIを起動
}

#-------------------------------#
#   GUI操作のためのルーチン群   #

package gui_window::wm_input;
use base qw(gui_window::project_new); # gui_window::project_newをカスタマイズ
use strict;
use Tk;

# 新規プロジェクト作成のためのルーチン
sub _make_new{
	my $self = shift;

	$::config_obj->last_method( $self->{method} );
	$::config_obj->last_lang(   $self->{lang}   );

	my $t = $::config_obj->os_path(
		$self->gui_jg(
			$self->e1->get
		)
	);

	# Excel / CSV (1)
	my $file_vars;
	if ($t =~ /(.+)\.(xls|xlsx|csv)$/i){
		# name of the new text file
		my $n = 0;
		while (-e $1."_txt$n.txt"){
			++$n;
		}
		my $file_text = $1."_txt$n.txt";
		
		# name of the new variable file
		$n = 0;
		while (-e $1."_var$n.txt"){
			++$n;
		}
		$file_vars = $1."_var$n.txt";

		# make files
		my $sheet_obj = kh_spreadsheet->new($t);
		$sheet_obj->save_files(
			filet    => $file_text,
			filev    => $file_vars,
			selected => $self->{column},
			#icode    => $self->{icode},
		);

		$t = $file_text;
	
	# テキストファイルの場合
	} else {
		# 空行に「---無記入・空白---」を挿入した分析用ファイルを作成
		use File::Basename;                                     # ファイル名を決定
		my $new_file      = $t;
		my $new_file_dir  = dirname($new_file);
		my $new_file_base = basename($new_file, qw/.txt .htm .html/);
		my $n = 0;
		while (-e $new_file){
			$new_file =
				$new_file_dir
				.'/'
				.$new_file_base
				."_ed$n.txt"
			;
			++$n;
		}
		open (ORGF,$t) or          # ファイル作成
			gui_errormsg->open(
				type    => 'file',
				thefile => $t
			);
		open (NEWF,">$new_file") or 
			gui_errormsg->open(
				type    => 'file',
				thefile => $new_file
			);
		while (<ORGF>){
			chomp;
			if ( length($_) ){
				print NEWF "$_\n";
			} else {
				print NEWF "---MISSING---\n";
			}
		}
		close (ORGF);
		close (NEWF);
		$t = $new_file;
	}
	
	# 作成した分析用ファイルをKH Coderに登録
	my $new = kh_project->new(
		target  => $t,
		comment => $self->gui_jg($self->e2->get),
		#icode   => $self->gui_jg($self->{icode}),
	) or return 0;
	kh_projects->read->add_new($new) or return 0;
	$self->close;

	$new->{target} = $::config_obj->uni_path($t);

	$new->open or die;
	$::project_obj->morpho_analyzer( $self->{method} );
	$::project_obj->morpho_analyzer_lang( $self->{lang} );
	$::project_obj->read_hinshi_setting;

	$::main_gui->close_all;
	$::main_gui->menu->refresh;
	$::main_gui->inner->refresh;
	
	# 「---無記入・空白---」という語を無視するように設定
	my $conf = kh_dictio->readin;
	$conf->words_mk( ['---MISSING---'] );
	$conf->words_st( ['---MISSING---'] );
	$conf->save;

	# Excel / CSV (2)
	if (-e $file_vars){
		# read variables
		mysql_outvar::read::tab->new(
			file        => $file_vars,
			tani        => 'h5',
			skip_checks => 1,
		)->read;

		# ignoring the separator string
		mysql_exec->do("
			INSERT INTO dmark (name) VALUES ('---cell---')
		",1);
		mysql_exec->do("
			INSERT INTO dstop (name) VALUES ('---cell---')
		",1);
		
		# some configurations
		$new->last_tani('h5');
	}
	return 1;
}

sub win_name{
	return 'w_wm_input';
}

1;