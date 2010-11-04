package gui_window;

my $debug = 0;

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
use gui_window::word_search;
use gui_window::dictionary;
use gui_window::word_ass_opt;
use gui_window::word_ass;
use gui_window::word_conc;
use gui_window::word_conc_opt;
use gui_window::word_conc_coloc;
use gui_window::word_conc_coloc_opt;
use gui_window::word_freq;
use gui_window::word_freq_plot;
use gui_window::word_df_freq;
use gui_window::word_df_freq_plot;
use gui_window::word_tf_df;
use gui_window::word_corresp;
use gui_window::word_cls;
use gui_window::word_mds;
use gui_window::word_netgraph;
use gui_window::word_list;
use gui_window::doc_view;
use gui_window::doc_search;
use gui_window::doc_cls;
use gui_window::doc_cls_res;
use gui_window::doc_cls_res_opt;
use gui_window::doc_cls_res_sav;
use gui_window::cls_height;
use gui_window::morpho_check;
use gui_window::morpho_detail;
use gui_window::cod_count;
use gui_window::cod_tab;
use gui_window::cod_outtab;
use gui_window::cod_jaccard;
use gui_window::cod_mds;
use gui_window::cod_netg;
use gui_window::cod_cls;
use gui_window::cod_corresp;
use gui_window::cod_out;
use gui_window::txt_html2csv;
use gui_window::txt_pickup;
use gui_window::morpho_crossout;
use gui_window::outvar_read;
use gui_window::outvar_list;
use gui_window::outvar_detail;
use gui_window::force_color;
use gui_window::contxt_out;
use gui_window::datacheck;
use gui_window::use_te;
use gui_window::use_te_g;
use gui_window::hukugo;
use gui_window::r_plot;
use gui_window::r_plot_opt;
use gui_window::bayes_learn;
use gui_window::bayes_predict;
use gui_window::bayes_view_log;
use gui_window::bayes_view_knb;

BEGIN{
	if( $] > 5.008 ){
		require Encode;
	}
	if ($^O eq 'darwin'){ # Mac OS X
		require Text::Iconv;
	}
}

sub open{
	my $class = shift;
	my $self;
	my %arg = @_;
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
			$self->{win_obj} = $::main_gui->mw->Toplevel();
			$self->win_obj->focus;
			$self->position_icon(@_);
		}

		# Windowの中身作成
		$self = $self->_new(@_);
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

sub position_icon{
	my $self = shift;
	my %arg = @_;
	
	# Windowサイズと位置の指定
	my $g = $::config_obj->win_gmtry($self->win_name);
	if ($g and not $arg{no_geometry}){
		$self->win_obj->geometry($g);
	}

	# Windowアイコンのセット
	my $icon = $self->win_obj->Photo(
		-file =>   Tk->findINC('acre.gif')
	);
	if ( $::config_obj->os eq 'win32' ) {
		$self->win_obj->Icon(-image => $icon);
	} else {
		$self->win_obj->iconimage($icon);
	}
}


sub close{
	my $self = shift;
	$self->end; # 特殊処理に対応
	$::config_obj->win_gmtry($self->win_name,$self->win_obj->geometry);
	$::config_obj->save_ini;
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
		if ( utf8::is_utf8($char) ){
			print "already decoded: ", Encode::encode('cp932',$char), "\n"
				if $debug;
			return $char;
		}
		
		$code = Jcode->new($char)->icode unless $code;
		# print "$char : $code\n";
		$code = 'eucJP-ms'   if $code eq 'euc';
		$code = 'cp932' if $code eq 'sjis';
		$code = 'cp932' if $code eq 'shiftjis';
		$code = 'eucJP-ms' unless length($code);
		return Encode::decode($code,$char);
	} else {
		if (defined($code) && $code eq 'sjis'){
			return $char;
		} else {
			# UTF-8フラグを落とさないと文字化け？
			if (Jcode->new($char)->icode eq 'utf8'){
				use Unicode::String qw(utf8);
				$char = utf8($char)->as_string;
			}

			return Jcode->new($char,$code)->sjis;
		}
	}
}

sub gui_jm{ # メニューのトップ部分用日本語
	my $char = $_[1];
	my $code = $_[2];
	
	if ( $] > 5.008 && $::config_obj->os eq 'linux' ) {
		$code = Jcode->new($char)->icode unless $code;
		$code = 'eucJP-ms'   if $code eq 'euc';
		$code = 'cp932' if $code eq 'sjis';
		return Encode::decode($code,$char);
	}
	elsif ($] > 5.008){
		return Jcode->new($char,$code)->sjis;
	} else {
		if (defined($code) && $code eq 'sjis'){
			return $char;
		} else {
			return Jcode->new($char,$code)->sjis;
		}
	}
}

sub gui_jt{ # Windowタイトル部分の日本語 （Win9x & Perl/Tk 804用の特殊処理）
	my $char = $_[1];
	my $code = $_[2];
	$code = '' unless defined($code);
	
	if ( $] > 5.008 ) {
		$code = Jcode->new($char)->icode unless $code;
		# print "$char : $code\n";
		$code = 'eucJP-ms'   if $code eq 'euc';
		$code = 'cp932' if $code eq 'sjis';
		$code = 'cp932' if $code eq 'shiftjis';
		$code = 'eucJP-ms' unless length($code);
		if ( ( $^O eq 'MSWin32' ) and not ( Win32::IsWinNT() ) ){
			if ($code eq 'sjis'){
				return $char;
			} else {
				return Jcode->new($char,$code)->sjis;
			}
		} else {
			if (utf8::is_utf8($char)){
				return $char;
			} else {
				return Encode::decode($code,$char);
			}
		}
	} else {
		if ($code eq 'sjis'){
			return $char;
		} else {
			# UTF-8フラグを落とさないと文字化け？
			if (Jcode->new($char)->icode eq 'utf8'){
				use Unicode::String qw(utf8);
				$char = utf8($char)->as_string;
			}

			return Jcode->new($char,$code)->sjis;
		}
	}
}


sub gui_jg_filename_win98{ # 全角文字を含むパスの処理 （Win9x & Perl/Tk 804用の特殊処理）
	my $char = $_[1];
	
	if (
		    ( $] > 5.008 )
		and ( $^O eq 'MSWin32' )
		and not ( Win32::IsWinNT() )
	){
		$char =~ s/\//\\/g;
		$char = Encode::decode('cp932',$char);
		$char = Encode::encode('cp932',$char);
	}
	
	return $char;
}

sub gui_jg{ # 入力された文字列の変換
	my $char = $_[1];
	
	if ($] > 5.008){
		if ( utf8::is_utf8($char) ){
			#print "utf8\n";
			if ($^O eq 'darwin'){ # Mac OS X
				$char = Text::Iconv->new('UTF-8-MAC','UTF-8')->convert($char);
				return Jcode->new($char,'utf8')->sjis;
			}

			return Encode::encode('cp932',$char);
		} else {
			#print "not utf8\n";
			return $char;
		}
	} else {
		return $char;
	}
}

#----------------#
#   共通の処理   #
#----------------#

sub check_entry_input{
	my $char = $_[1];
	# 末尾に改行文字が入っていれば削除（主にExcelからのコピペ対策）
	if ($char =~ /^([^\n]+)\n\Z/){
		$char = $1;
	}
	return $char;
}

sub disabled_entry_configure{
	my $ent = $_[1];
	$ent->configure(
		-disabledbackground => 'gray',
		-disabledforeground => 'black',
	) if $Tk::VERSION >= 804;
}

sub config_entry_focusin{
	my $ent = $_[1];
	$ent->configure(
		-validate => 'focusin',
		-validatecommand => sub{
			$ent->selectionRange(0,'end');
		}
	);
}

1;
