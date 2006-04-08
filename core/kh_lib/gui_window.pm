package gui_window;

use strict;
use Tk;
use Tk::LabFrame;
use Tk::ItemStyle;
use Tk::DropSite;
require Tk::ErrorDialog;

use gui_wait;
use gui_OtherWin;

use gui_window::main;
use gui_window::about;
use gui_window::project_new;
use gui_window::project_open;
use gui_window::project_edit;
use gui_window::sysconfig;
use gui_window::sql_select;
use gui_window::sql_do;
use gui_window::word_search;
use gui_window::dictionary;
use gui_window::word_ass_opt;
use gui_window::word_ass;
use gui_window::word_conc;
use gui_window::word_conc_opt;
use gui_window::word_conc_coloc;
use gui_window::word_conc_coloc_opt;
use gui_window::word_freq;
use gui_window::doc_view;
use gui_window::doc_search;
use gui_window::morpho_check;
use gui_window::morpho_detail;
use gui_window::cod_count;
use gui_window::cod_tab;
use gui_window::cod_outtab;
use gui_window::cod_jaccard;
use gui_window::cod_out;
use gui_window::txt_html2csv;
use gui_window::txt_pickup;
use gui_window::morpho_crossout;
use gui_window::outvar_read;
use gui_window::outvar_list;
use gui_window::outvar_detail;
use gui_window::force_color;
use gui_window::contxt_out;
#use gui_window::use_te;
#use gui_window::use_te_g;


BEGIN{
	if( $] > 5.008 ){
		require Encode;
	}
}

sub open{
	my $class = shift;
	my $self;
	my @arg = @_;
	$self->{dummy} = 1;
	bless $self, $class;

	my $check = 0;
	if ($::main_gui){
		$check = $::main_gui->if_opened($self->win_name);
	}

	if ( $check ){
		$self = $::main_gui->get($self->win_name);
	} else {
		
		# Windowオープン
		if ($self->win_name eq 'main_window'){
			$self->{win_obj} = MainWindow->new;
		} else {
			$self->{win_obj} = $::main_gui->mw->Toplevel;
			$self->win_obj->focus;
			# Windowサイズと位置の指定
			my $g = $::config_obj->win_gmtry($self->win_name);
			if ($g){
				$self->win_obj->geometry($g);
				#print "win_size: $g\n";
			}
			# Windowアイコンのセット
			my $icon = $self->win_obj->Photo(
				-file =>   Tk->findINC('acre.gif')
			);
			$self->win_obj->Icon(-image => $icon);
		}

		# Windowの中身作成
		$self = $self->_new(@arg);
		$::main_gui->opened($self->win_name,$self);

		# Windowを閉じる際のバインド
		$self->win_obj->bind(
			'<Control-Key-q>',
			sub{ $self->close; }
		);
		$self->win_obj->protocol('WM_DELETE_WINDOW', sub{ $self->close; });

		# メインWindowsへ戻るためのキー・バインド
		$self->win_obj->bind(
			'<Alt-Key-m>',
			sub { $::main_gui->{main_window}->win_obj->focus; }
		);

		# 特殊処理に対応
		$self->start;
	}
	return $self;
}


sub close{
	my $self = shift;
	$self->end; # 特殊処理に対応
	$::config_obj->win_gmtry($self->win_name,$self->win_obj->geometry);
	$::config_obj->save;
	$self->win_obj->destroy;
}

sub win_obj{
	my $self = shift;
	return $self->{win_obj};
}

sub end{
	return 1;
}

sub start{
	return 1;
}

#--------------------------#
#   日本語表示・入力関係   #
#--------------------------#

sub gui_jchar{ # GUI表示用の日本語
	my $char = $_[1];
	my $code = $_[2];
	
	if ( $] > 5.008 ) {
		$code = Jcode->new($char)->icode unless $code;
		$code = 'euc-jp'   if $code eq 'euc';
		$code = 'shiftjis' if $code eq 'sjis';
		$code = 'euc-jp' unless length($code);
		return Encode::decode($code,$char);
	} else {
		if ($code eq 'sjis'){
			return $char;
		} else {
			return Jcode->new($char,$code)->sjis;
		}
	}
}

sub gui_jm{ # メニューのトップ部分用日本語
	my $char = $_[1];
	my $code = $_[2];
	
	if ( $] > 5.008 && $::config_obj->os eq 'linux' ) {
		$code = Jcode->new($char)->icode unless $code;
		$code = 'euc-jp'   if $code eq 'euc';
		$code = 'shiftjis' if $code eq 'sjis';
		return Encode::decode($code,$char);
	}
	elsif ($] > 5.008){
		return Jcode->new($char,$code)->sjis;
	} else {
		if ($code eq 'sjis'){
			return $char;
		} else {
			return Jcode->new($char,$code)->sjis;
		}
	}
}

sub gui_jg{ # 入力された文字列の変換
	my $char = $_[1];
	
	if ($] > 5.008){
		return Encode::encode('shiftjis',$char);
	} else {
		return $char;
	}
}

#------------------------#
#   Tkのバージョン関係   #
#------------------------#

sub disabled_entry_configure{
	my $ent = $_[1];
	$ent->configure(
		-disabledbackground => 'gray',
		-disabledforeground => 'black',
	) if $Tk::VERSION >= 804;
}

1;
