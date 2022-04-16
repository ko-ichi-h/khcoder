package gui_window;

my $debug = 0;
my $icon;

my %char_code = ();
if (eval 'require Encode::EUCJPMS'){
	$char_code{euc}  = 'eucJP-ms';
	$char_code{sjis} = 'cp932';
} else {
	$char_code{euc}  = 'euc-jp';
	$char_code{sjis} = 'cp932';
}

use strict;
use utf8;

use Tk;
use Tk::ErrorDialog;
use Tk::LabFrame;
use Tk::ItemStyle;
use Tk::DropSite;

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
use gui_window::stop_words;
use gui_window::word_som;
use gui_window::cod_som;
use gui_window::word_search_opt;
use gui_window::import_folder;
use gui_window::topic_perplexity;
use gui_window::topic_fitting;
use gui_window::topic_result;
use gui_window::topic_stats;

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
		$self->{win_obj}->deiconify;
		$self->{win_obj}->raise;
		$self->{win_obj}->focus;
		$self->start_raise;
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
		return 0 unless $self;
		$::main_gui->opened($self->win_name,$self);

		# Windowを閉じる際のバインド
		$self->win_obj->bind(
			'<Control-Key-q>',
			sub{ $self->close; }
		);
		$self->win_obj->bind(
			'<Key-Escape>',
			sub{ $self->close; }
		);
		$self->win_obj->protocol('WM_DELETE_WINDOW', sub{ $self->close; });

		# メインWindowsへ戻るためのキー・バインド
		$self->win_obj->bind(
			'<Alt-Key-m>',
			sub { $::main_gui->{main_window}->win_obj->focus; }
		);
		$self->win_obj->bind(
			'<Control-Key-m>',
			sub { $::main_gui->{main_window}->win_obj->focus; }
		);

		# 特殊処理に対応
		$self->start;

		$self->check_viewable;
	}
	return $self;
}

# Window位置のチェック（スクリーンをはみ出していないか）
sub check_viewable{
	my $self = shift;
	
	$self->{no_geometry} = 0 unless $self->{no_geometry};
	my $g = $::config_obj->win_gmtry($self->win_name);
	
	#print "1\n";
	#print "-----------------\n";
	#print "g: $g\n";
	#print "ng: $self->{no_geometry}\n";
	#print "os: ".$::config_obj->os."\n";
	#print "wmc: ".$::config_obj->win32_monitor_chk."\n";
	#print "-----------------\n";
	
	if (
		   defined($g) && length($g)        # 位置を読み込んでいて
		&& $self->{no_geometry} == 0
		&& $::config_obj->os eq 'win32'     # なおかつWindowsで
		&& $::config_obj->win32_monitor_chk == 0
	) {
		#print "2\n";
		$::config_obj->win32_monitor_chk(1);

		$self->win_obj->update;
		require gui_checkgeo;
		my $r = gui_checkgeo::check(
			$self->win_obj->rootx,
			$self->win_obj->rooty
		);

		print "new window: ", $self->win_obj->rootx, ", ",$self->win_obj->rooty, "\n";
		unless ($r){
			print "The window geometry is modified: $g, ";
			$g =~ s/([0-9]+)x([0-9]+)\+.+/$1x$2+24+24/;
			print "$g\n";
			$self->win_obj->geometry($g);
		}
		
		$::config_obj->win32_monitor_chk(0);
	}


		#my $name   = $self->win_obj->screen;
		#my $height = $self->win_obj->screenheight;
		#my $width  = $self->win_obj->screenwidth;
		#my $if     = $self->win_obj->viewable;
		#my $h      = $self->win_obj->rooty;
		#my $w      = $self->win_obj->rootx;

		#require Win32::GUI;
		#my $hoge = Win32::GUI::GetDesktopWindow();
		#my $txt = Win32::GUI::GetClassName($hoge);
		#my $w2 = Win32::GUI::Width($hoge);
		#my $h2 = Win32::GUI::Height($hoge);
		#my $if2 = Win32::GUI::IsVisible($hoge); 
		
		#print "screen: $name, $height, $width, $h, $w, $if, $if2, $txt, $h2, $w2\n";

		#if (
		#	   $self->win_obj->rootx > $self->win_obj->screenwidth
		#	|| $self->win_obj->rooty > $self->win_obj->screenheight
		#){
		#	print "geometry modified: $g, ";
		#	$g =~ s/([0-9]+)x([0-9]+)\+.+/$1x$2+24+24/;
		#	print "$g\n";
		#	$self->win_obj->geometry($g);
		#}

	return $self;
}

sub position_icon{
	my $self = shift;
	my %arg = @_;
	$self->{no_geometry} = $arg{no_geometry};
	
	# Windowサイズと位置の指定
	my $g = $::config_obj->win_gmtry($self->win_name);
	if ($g and not $self->{no_geometry}){
		$self->win_obj->geometry($g);
	}

	# Windowアイコンのセット
	if ( $::config_obj->os eq 'win32' ) {
		if ( eval 'require Tk::Icon' ){
			require Tk::Icon;
			$self->win_obj->setIcon(-file => Tk->findINC('1.ico'));
		} else {
			unless ($icon){
				$icon = $self->win_obj->Photo('window_icon',
					-file =>   Tk->findINC('acre.gif')
				);
			}
			$self->win_obj->Icon(-image => $icon);
		}
	} else {
		unless ($icon){
			$icon = $self->win_obj->Photo('window_icon',
				-file =>   Tk->findINC('acre.gif')
			);
		}
		$self->win_obj->iconimage($icon);
	}
	
	return $self;
}


sub close{
	my $self = shift;
	$self->end; # 特殊処理に対応
	$::config_obj->win_gmtry($self->win_name,$self->win_obj->geometry);
	#$::config_obj->save_ini;
	$self->win_obj->destroy;
	$::main_gui->closed($self->win_name);
	undef $self;
}

sub withd{
	my $self = shift;
	$::config_obj->win_gmtry($self->win_name,$self->win_obj->geometry);
	#$::config_obj->save_ini;
	$self->{win_obj}->withdraw;
}

sub end{
	return 1;
}

sub win_obj{
	my $self = shift;
	return $self->{win_obj};
}

sub start{
	return 1;
}

sub start_raise{
	return 1;
}


#--------------------------#
#   日本語表示・入力関係   #
#--------------------------#

sub gui_bmp{ # Delete characters outside of BMP (Basic Multilingual Plane)
	my $t = $_[1];
	
	unless ( utf8::is_utf8($t) ){
		my $code = Jcode->new($t)->icode;
		$code = $char_code{euc}  if $code eq 'euc';
		$code = $char_code{sjis} if $code eq 'sjis';
		$code = $char_code{sjis} if $code eq 'shiftjis';
		$code = $char_code{euc}  unless length($code);
		
		$t = Encode::decode($code,$t);
		
		if ( $t =~ /[[:^ascii:]]/ ){
			my ($package, $filename, $line) = caller;
			print "Warn: Non-decoded string: $t,\n\t$code,\n\t$package, $filename, $line\n";
		}
	}

	$t = Encode::encode('UCS-2LE', $t, Encode::FB_DEFAULT);
	$t = Encode::decode('UCS-2LE', $t);
	$t  =~ s/\x{fffd}/?/g;

	return $t;
}

sub gui_jchar{ # GUI表示用の日本語
	my $char = $_[1];
	my $code = $_[2];

	if ( utf8::is_utf8($char) ){
		print "already decoded: $char\n"
			if $debug;
		return $char;
	}

	$code = Jcode->new($char)->icode unless $code;
	# print "$char : $code\n";
	$code = $char_code{euc}  if $code eq 'euc';
	$code = $char_code{sjis} if $code eq 'sjis';
	$code = $char_code{sjis} if $code eq 'shiftjis';
	$code = $char_code{euc}  unless length($code);
	$char = Encode::decode($code,$char);

	if ( $char =~ /[[:^ascii:]]/ ){
		my ($package, $filename, $line) = caller;
		print "Warn: Non-decoded string: $char,\n\t$code,\n\t$package, $filename, $line\n";
	}

	return $char;

}

*gui_window::gui_jm = *gui_window::gui_jt = \&gui_window::gui_jchar;

sub gui_jg_filename_win98{
	return $_[1];
}

sub gui_jg{ # 入力された文字列の変換
	my $char       = $_[1];
	my $reserve_rn = $_[2];

	if ( utf8::is_utf8($char) ){
		#print "utf8\n";
		unless ( $reserve_rn ){ # ATOK対策
			$char =~ s/\x0D|\x0A//go;
		}
		#if ($^O eq 'darwin'){   # Mac OS X
		#	$char = Text::Iconv->new('UTF-8-MAC','UTF-8')->convert($char);
		#	return $char;
		#}
		return $char;
	} else {
		#warn "No utf8 flag: $char\n";
		return $char;
	}
}

sub gui_jgn{ # 入力された数値の変換
	my $char       = $_[1];
	my $reserve_rn = $_[2];

	if ( utf8::is_utf8($char) ){
		#print "utf8\n";
		unless ( $reserve_rn ){ # ATOK対策
			$char =~ s/\x0D|\x0A//g;
		}
		$char =~ tr/。．、，,０-９ー－―/.....0-9\-\-\-/;
		$char =~ s/[[:cntrl:]]|\s//g;
		return $char;
	} else {
		#warn "No utf8 flag: $char\n";
		unless ( $reserve_rn ){ # ATOK対策
			$char =~ s/\x0D|\x0A//g;
		}
		return $char;
	}
}

sub to_clip{ # クリップボードへコピーするための変換
	my $char = $_[1];
	
	if ( $char =~ /[[:^ascii:]]/ and not utf8::is_utf8($char) ){

		my ($package, $filename, $line) = caller;
		print "to_clip Warn: Non-decoded string: $char,\n\t$package, $filename, $line\n";

		$char = Jcode->new($char)->utf8;
		$char = Encode::decode('UTF-8',$char);
	}

	return $char;
}

my %patchim_n = (
	'ᆨ' => 1,
	'ᆩ' => 2,
	'ᆪ' => 3,
	'ᆫ' => 4,
	'ᆬ' => 5,
	'ᆭ' => 6,
	'ᆮ' => 7,
	'ᆯ' => 8,
	'ᆰ' => 9,
	'ᆱ' => 10,
	'ᆲ' => 11,
	'ᆳ' => 12,
	'ᆴ' => 13,
	'ᆵ' => 14,
	'ᆶ' => 15,
	'ᆷ' => 16,
	'ᆸ' => 17,
	'ᆹ' => 18,
	'ᆺ' => 19,
	'ᆻ' => 20,
	'ᆼ' => 21,
	'ᆽ' => 22,
	'ᆾ' => 23,
	'ᆿ' => 24,
	'ᇀ' => 25,
	'ᇁ' => 26,
	'ᇂ' => 27,
);

sub kchar_patchim{
	my $t = $_[1];

	while ($t =~ /([^_])([ᆨᆩᆪᆫᆬᆭᆮᆯᆰᆱᆲᆳᆴᆵᆶᆷᆸᆹᆺᆻᆼᆽᆾᆿᇀᇁᇂ])/ ) {
		my $num   = int( unpack('U', $1) );
		$num = $num + $patchim_n{$2};
		my $conv = pack('U', $num );
		
		my $pos = index($t, "$1$2");
		# substr($t, $pos, 2) = "_$1"."_$2"."【$conv"."】"; # debug
		substr($t, $pos, 2) = $conv;
	}
	return $t;
}

#----------------#
#   共通の処理   #
#----------------#

sub check_entry_input{
	my $char = $_[1];
	# 改行文字が入っていれば削除（ExcelからのコピペやAtokに対応）
	$char =~ s/\x0D|\x0A//g;
	
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
			my $t = $ent->get;
			if ( length($t) ){
				$ent->selectionRange(0,'end');
			}
		}
	);
}

1;
