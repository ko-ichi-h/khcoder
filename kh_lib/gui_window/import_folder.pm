package gui_window::import_folder;
use base qw(gui_window);

use strict;
use utf8;
use Tk;

# Windowの作成
sub _new{
	my $self = shift;
	my $mw = $self->{win_obj};

	$mw->title(
		$self->gui_jt( kh_msg->get('win_title') )
	);

	$mw->Label(
		-text => kh_msg->get('description')
	)->pack(-anchor => 'w', -padx => 5);

	#-------------------#
	#   Unify options   #

	my $fra_lab = $mw->LabFrame(
		-label       => kh_msg->get('opt_unify'),
		-foreground  => 'blue',
		-labelside   => 'acrosstop',
		-borderwidth => 2
	)->pack(
		-expand => 'yes',
		-fill   => 'both'
	);

	# Folder
	my $fra1 = $fra_lab->Frame()->pack(
		-anchor => 'c',
		-fill   => 'x',
		-expand => 'x',
		-pady   => 2,
	);

	$fra1->Label(
		-text => kh_msg->get('folder'),
	)->grid(
		-row    => 0,
		-column => 0,
		-sticky => 'w',
		-pady=>2
	);

	my $fra1a = $fra1->Frame(
	)->grid(
		-row    => 0,
		-column => 1,
		-sticky => 'ew',
		-pady=>2
	);

	$self->{btn1} = $fra1a->Button(
		-text => kh_msg->gget('browse'),
		-font => 'TKFN',
		-borderwidth => 1,
		-command => sub{ $mw->after
			(10,
				sub { $self->_get_folder; }
			);
		}
	)->pack(-padx => '2',-side => 'left');

	$self->{entry_folder} = $fra1a->Entry(
		-background => 'white',
	)->pack(
		-side   => 'left',
		-fill   => 'x',
		-expand => 'x',
	);

	$self->{entry_folder}->DropSite(
		-dropcommand => sub{
			&Gui_DragDrop::get_filename_droped( $self->{entry_folder} );
			$self->_unified_default;
		},
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);

	# Unified file
	$fra1->Label(
		-text => kh_msg->get('unified'),
	)->grid(
		-row    => 1,
		-column => 0,
		-sticky => 'w',
		-pady=>2
	);
	
	my $fra1b = $fra1->Frame(
	)->grid(
		-row    => 1,
		-column => 1,
		-sticky => 'ew',
		-pady=>2
	);
	
	$fra1b->Button(
		-text => kh_msg->get('change'),
		-font => 'TKFN',
		-borderwidth => 1,
		-command => sub{ $mw->after
			(10,
				sub { $self->_browse_unified; }
			);
		}
	)->pack(-padx => '2',-side => 'left');
	
	$self->{entry_unified} = $fra1b->Entry(-background => 'gray')->pack(
		-side   => 'left',
		-fill   => 'x',
		-expand => 'x',
	);

	$self->{entry_unified}->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $self->{entry_unified},],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);
	
	$fra1->gridColumnconfigure(1, -weight => 1);

	# 見出しレベル選択用フレーム
	my $fra2 = $fra_lab->Frame()->pack(
		-anchor => 'c',
		-fill   => 'x',
		-expand => 'x',
	);

	$fra2->Label(
		-text => '    '.kh_msg->get('level'),#'ファイル名の見出しレベル：',
	)->pack(
		-side => 'left',
	);

	$self->{tani_obj} = gui_widget::optmenu->open(
		parent  => $fra2,
		pack    => {-side => 'left', -pady => 2},
		options =>
			[
				['H1', 'h1'],
				['H2', 'h2'],
				['H3', 'h3'],
				['H4', 'h4'],
				['H5', 'h5'],
			],
		variable => \$self->{tani},
	);
	$self->{tani_obj}->set_value('h2');

	# 文字コード選択用フレーム
	my $fra3 = $fra_lab->Frame()->pack(
		-anchor => 'c',
		-fill   => 'x',
		-expand => 'x',
	);

	$fra3->Label(
		-text => '    '.kh_msg->get('char_code'),
	)->pack(
		-side => 'left',
	);
	
	$self->{icode_obj} = gui_widget::optmenu->open(
		parent  => $fra3,
		pack    => {-side => 'left'},
		options =>
			[
				[kh_msg->get('auto'),    'auto'    ],
				[kh_msg->get('auto_jp'), 'jp_auto' ],
				[kh_msg->get('unicode'), 'utf8'    ],
				#['日本語（EUC）',       'eucjp'   ],
				#['日本語（Shift JIS）', 'cp932'   ],
				#['Latin1',              'latin1'  ],
			],
		variable => \$self->{icode},
	);
	
	if ( $::config_obj->msg_lang eq 'jp' ||  $::config_obj->last_lang eq 'jp' ){
		$self->{icode_obj}->set_value('jp_auto');
	} else {
		$self->{icode_obj}->set_value('auto');
	}
	
	# チェックボックス
	my $fra5 = $fra_lab->Frame()->pack(
		-fill   => 'x',
		-expand => 'x',
	);
	$fra5->Label(-text => '    ')->pack(-side => 'left');
	$self->{if_conv} = 1;
	$self->{check2} = $fra5->Checkbutton(
		-variable => \$self->{if_conv},
		-text     => kh_msg->get('conv'),#'データ内の半角山カッコ「<>」をスペースに変換する',
		-font     => "TKFN",
	)->pack(-anchor => 'w');

	#---------------------#
	#   Project options   #

	my $fra_lab2 = $mw->LabFrame(
		-label       => kh_msg->get('opt_project'),
		-foreground  => 'blue',
		-labelside   => 'acrosstop',
		-borderwidth => 2
	)->pack(
		-expand => 'yes',
		-fill   => 'both'
	);
	
	# language
	$fra_lab2->Label(
		-text => kh_msg->get('lang', 'gui_window::stop_words'), # 言語
		-font => "TKFN"
	)->grid(-row => 0, -column => 0, -sticky => 'w', -pady=>2);
	
	my $fra3a = $fra_lab2->Frame()->grid(-row => 0, -column => 1, -sticky => 'ew',-pady=>2);
	$self->{fra3a} = $fra3a;

	$self->{lang_menu} = gui_widget::optmenu->open(
		parent  => $fra3a,
		pack    => { -side => 'left', -padx => 2},
		options =>
			[
				[ kh_msg->get('l_jp', 'gui_window::sysconfig') => 'jp'],#'Japanese'
				[ kh_msg->get('l_en', 'gui_window::sysconfig') => 'en'],#'English'
				[ kh_msg->get('l_cn', 'gui_window::sysconfig') => 'cn'],#'Chinese'
				[ kh_msg->get('l_kr', 'gui_window::sysconfig') => 'kr'],#'Korean *'
				[ kh_msg->get('l_ca', 'gui_window::sysconfig') => 'ca'],#'Catalan *'
				[ kh_msg->get('l_nl', 'gui_window::sysconfig') => 'nl'],#'Dutch *'
				[ kh_msg->get('l_fr', 'gui_window::sysconfig') => 'fr'],#'French *'
				[ kh_msg->get('l_de', 'gui_window::sysconfig') => 'de'],#'German *'
				[ kh_msg->get('l_it', 'gui_window::sysconfig') => 'it'],#'Italian *'
				[ kh_msg->get('l_pt', 'gui_window::sysconfig') => 'pt'],#'Portuguese *'
				[ kh_msg->get('l_ru', 'gui_window::sysconfig') => 'ru'],#'Russian *'
				[ kh_msg->get('l_sl', 'gui_window::sysconfig') => 'sl'],#'Slovenian *'
				[ kh_msg->get('l_es', 'gui_window::sysconfig') => 'es'],#'Spanish *'
			],
		variable => \$self->{lang},
		command => sub {$self->refresh_method;},
	);
	$self->{lang_menu}->set_value( $::config_obj->last_lang );

	# method
	$self->refresh_method;
	
	# Memo
	$fra_lab2->Label(
		-text => kh_msg->get('memo', 'gui_window::project_new'),
	)->grid(
		-row    => 1,
		-column => 0,
		-sticky => 'w',
		-pady=>2
	);

	$self->{entry_memo} =$fra_lab2->Entry(
		-background => 'white',
	)->grid(
		-row    => 1,
		-column => 1,
		-sticky => 'we',
		-pady=>2
	);


	$fra_lab2->gridColumnconfigure(1, -weight => 1);

	# ボタン類の配置
	$mw->Button(
		-text    => kh_msg->gget('cancel'),
		-font    => "TKFN",
		-width   => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(
		-side => 'right',
		-padx => 2
	);
	$mw->Button(
		-text    => kh_msg->gget('ok'),
		-width   => 8,
		-font    => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->_exec;});}
	)->pack(
		-side => 'right'
	);

	return $self;
}

sub refresh_method{
	my $self = shift;
	$self->{method_menu}->destroy if $self->{method_menu};
	
	my @options;
	my %possbile;
	# Japanese
	if ($self->{lang} eq 'jp') {
		push @options, ['ChaSen', 'chasen'];
		$possbile{chasen} = 1;
		if (
			   ($::config_obj->os ne 'win32')
			|| ($::config_obj->os eq 'win32' && -e $::config_obj->os_path( $::config_obj->mecab_path) )
		) {
			push @options, ['MeCab', 'mecab'];
			$possbile{mecab} = 1;
		}
	}
	# Korean
	elsif ($self->{lang} eq 'kr') {
		push @options, ['MeCab & HanDic', 'mecab_k'];
		$possbile{mecab} = 1;
	}
	
	else {
		
		# add stanford pos tagger
		if (
				$self->{lang} eq 'cn'
			 || $self->{lang} eq 'en'
		) {
			push @options, ['Stanford POS Tagger', 'stanford'];
			$possbile{stanford} = 1;
		}

		# add FreeLing
		if (
			(
				$self->{lang} eq 'ca' ##
			 || $self->{lang} eq 'en'
			 || $self->{lang} eq 'fr'
			 || $self->{lang} eq 'it'
			 || $self->{lang} eq 'pt'
			 || $self->{lang} eq 'ru' ##
			 || $self->{lang} eq 'sl' ####
			 || $self->{lang} eq 'es'
			 || $self->{lang} eq 'de'
			)
			&& (
				   ($::config_obj->os ne 'win32')
				|| (
					$::config_obj->os eq 'win32'
					&& -d $::config_obj->freeling_dir
				)
			)
		) {
			push @options, ['FreeLing', 'freeling'];
			$possbile{freeling} = 1;
		}
		
		# add Snowball stemmer
		if (
			   $self->{lang} eq 'en'
			|| $self->{lang} eq 'nl'
			|| $self->{lang} eq 'fr'
			|| $self->{lang} eq 'de'
			|| $self->{lang} eq 'it'
			|| $self->{lang} eq 'pt'
			|| $self->{lang} eq 'es'
		) {
			push @options, ['Snowball stemmer', 'stemming'];
			$possbile{stemming} = 1;
		}
	}

	# Select last used method
	#my $last = $::config_obj->last_method;
	#if ($possbile{$last}) {
	#	$self->{method} = $last;
	#} else {
	#	$self->{method} = $options[0]->[1];
	#}
	$self->{method} = undef;

	$self->{method_menu} = gui_widget::optmenu->open(
		parent  => $self->{fra3a}, #$fra3,
		width   => 19,
		pack    => { -side => 'right', -padx => 2, -fill => 'x', -expand => 1},
		options => \@options,
		variable => \$self->{method},
		command => sub {}
	);
	
	#$lang = $self->{lang};
	return $self;
}

sub _get_folder{
	my $self = shift;

	# UTF8フラグはついているけど、中身はCP932というヘンなものが帰ってくるので、
	# 修正しておく（UTF8フラグを落としておく）
	my $path = $self->{win_obj}->chooseDirectory;
	use Encode;
	$path = Encode::decode($::config_obj->os_code, "$path");
	$path = Encode::encode($::config_obj->os_code, $path);
	
	if ($path){
		$path = $self->gui_jg_filename_win98($path);
		$path = $self->gui_jg($path);
		$path = $::config_obj->os_path($path);
		
		# Folder entry
		my $uni_path = $::config_obj->uni_path($path);
		$self->{entry_folder}->delete('0','end');
		$self->{entry_folder}->insert(0,$uni_path);
		
		$self->_unified_default;
	}
	
	return $self;
}

sub _unified_default{
	my $self = shift;

	# Unified file entry
	my $unified = $self->{entry_folder}->get;
	$unified = $::config_obj->os_path( $unified );
	if ($unified =~ /\/$/) {
		chop $unified;
	}
	
	my $n = 0;
	while (-e $unified."_uni$n.txt") {
		++$n;
	}
	$unified = $unified."_uni$n.txt";
	
	$unified = $::config_obj->uni_path($unified);
	$self->{entry_unified}->delete('0','end');
	$self->{entry_unified}->insert(0,$unified);
	
	return 1;
}

sub _browse_unified{
	my $self = shift;
	
	my @types = (
		[ "Text files",[qw/.txt/] ],
		[ "All files",'*' ]
	);

	my $path = $self->win_obj->getSaveFile(
		-filetypes  => \@types,
		-title      => $self->gui_jt( kh_msg->get('browse_unified')),
		-initialdir => $::config_obj->uni_path( $::config_obj->cwd ),
	);

	if ($path){
		$self->{entry_unified}->delete('0','end');
		$self->{entry_unified}->insert(0, $::config_obj->uni_path($path) );
	}
}

sub _exec{
	my $self = shift;

	# フォルダのチェック
	my $path = $self->gui_jg_filename_win98( $self->{entry_folder}->get() );
	$path = $self->gui_jg($path);
	$path = $::config_obj->os_path($path);
	unless (-d $path){
		gui_errormsg->open(
			type => 'msg',
			msg  => 'フォルダ指定が不正です',
		);
		return 0;
	}

	# 保存先
	my $save = $self->{entry_unified}->get;
	$save = $::config_obj->os_path($save);

	# 処理の実行
	my @files = ();
	open my $fh, '>:encoding(utf8)', $save or
		gui_errormsg->open(
			type    => 'file',
			thefile => $save,
		);

	my $read_each = sub {
		# ファイル名関係
		my $f = $File::Find::name;
		return if -d $f;
		return unless $f =~ /.+\.txt$|.+\.doc$|.+\.docx$|.+\.rtf$|.+\.odt$/;
		return if $f eq $save;

		my $f_o = substr($f, length($path) + 1, length($f) - length($path));
		$f_o = $::config_obj->uni_path( $f_o );
		$f_o =~ s/\\/\//g;

		print $fh "<$self->{tani}>file:$f_o</$self->{tani}>\n";
		push @files, "file:$f_o";

		# Convert to *.txt
		my $converted = '';
		if ($f =~ /.+\.doc$|.+\.docx$|.+\.rtf$|.+\.odt$/) {
			local ($^W) = 0;
			use File::Temp 'tempfile';
			(undef, $converted) = tempfile(
				OPEN => 0,
				DIR  => $::config_obj->cwd.'/config'
			);
			$converted .= '.txt';
			print "Converted: $converted\n\tFrom: $f_o\n";
			my $c = kh_docx->new($f);
			$c->{converted} = $converted;
			$c->conv;
			unless (-e $converted && -s $converted){
				return 0;
			}
			$f = $converted;
		}

		# 文字コード
		my $icode = $self->{icode};
		if ($icode eq 'jp_auto') {
			$icode = kh_jchar->check_code2($f);
		}
		elsif ($icode eq 'auto'){
			$icode = kh_jchar->check_code_all($f);
		}
		
		# 読み込み
		open (TEMP, "<:encoding($icode)", $f) or
			gui_errormsg->open(
				type    => 'file',
				thefile => $f,
			);
		while ( <TEMP> ){
			if ($self->{if_conv}){
				$_ =~ tr/<>/  /;
			}
			print $fh $_;
		}
		close (TEMP);
		print $fh "\n";
		
		# clean up
		if (-e $converted) {
			unlink $converted;
		}
	};

	use File::Find;
	find(
		{
			preprocess => sub {sort {$a cmp $b} @_},
			wanted     => $read_each
		},
		$path
	);
	close($fh);
	$fh = undef;

	# Create a new project
	unless (-e $save){
		return 0;
	}
	my $new = kh_project->new(
		target  => $save,
		comment => $self->gui_jg( $self->{entry_memo}->get ),
	) or return 0;
	
	kh_projects->read->add_new($new) or return 0;
	
	$new->{target} = $::config_obj->uni_path($save);
	
	$new->open or die;
	
	$::project_obj->morpho_analyzer( $self->{method} );
	$::project_obj->morpho_analyzer_lang( $self->{lang} );
	$::project_obj->read_hinshi_setting;
	
	# ignore file names (don't use them as parts of text data)
	foreach my $i (@files){
		
		# morpho_analyzer
		use Lingua::JA::Regular::Unicode qw(katakana_h2z);
		my $text = $i;
		if (
			   $::config_obj->c_or_j eq 'chasen'
			|| $::config_obj->c_or_j eq 'mecab'
		){
			$text = katakana_h2z($text);
			$text =~ s/ /　/go;
			$text =~ s/\t/　/go;
			$text =~ s/\\/￥/go;
			$text =~ s/'/’/go;
			$text =~ s/"/”/go;
		} else {
			$text = $_;
			$text =~ s/\t/ /go;
			$text =~ s/\\/ /go;
			$text =~ s/。/./go;
		}
		$text = mysql_exec->quote($text);
		mysql_exec->do("
			INSERT INTO dmark (name) VALUES ($text)
		",1);
		mysql_exec->do("
			INSERT INTO dstop (name) VALUES ($text)
		",1);
	}

	$::main_gui->close_all;
	$::main_gui->menu->refresh;
	$::main_gui->inner->refresh;
	return 1
}

sub win_name{
	return 'w_import_folder';
}

1;