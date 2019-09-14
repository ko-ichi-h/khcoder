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

	my $fra_lab = $mw->LabFrame(
		-label       => 'Options',
		-labelside   => 'acrosstop',
		-borderwidth => 2
	)->pack(
		-expand => 'yes',
		-fill   => 'both'
	);

	# フォルダ用フレーム
	my $fra1 = $fra_lab->Frame()->pack(
		-anchor => 'c',
		-fill   => 'x',
		-expand => 'x',
	);

	$fra1->Label(
		-text => kh_msg->get('folder'),
	)->pack(
		-side => 'left',
	);

	$self->{btn1} = $fra1->Button(
		-text => kh_msg->gget('browse'),
		-font => 'TKFN',
		-borderwidth => 1,
		-command => sub{ $mw->after
			(10,
				sub { $self->_get_folder; }
			);
		}
	)->pack(-padx => '2',-side => 'left');

	$self->{entry_folder} = $fra1->Entry()->pack(
		-side   => 'left',
		-fill   => 'x',
		-expand => 'x',
	);

	$self->{entry_folder}->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $self->{entry_folder},],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);

	# 見出しレベル選択用フレーム
	my $fra2 = $fra_lab->Frame()->pack(
		-anchor => 'c',
		-fill   => 'x',
		-expand => 'x',
	);

	$fra2->Label(
		-text => kh_msg->get('level'),#'ファイル名の見出しレベル：',
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
		-text => kh_msg->get('char_code'),
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
	$self->{if_conv} = 1;
	$self->{check2} = $fra_lab->Checkbutton(
		-variable => \$self->{if_conv},
		-text     => kh_msg->get('conv'),#'データ内の半角山カッコ「<>」をスペースに変換する',
		-font     => "TKFN",
	)->pack(-anchor => 'w');
	
	# Memo
	my $fra4 = $fra_lab->Frame()->pack(
		-anchor => 'c',
		-fill   => 'x',
		-expand => 'x',
	);
	$fra4->Label(
		-text => kh_msg->get('memo'),
	)->pack(
		-side => 'left',
	);
	

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
		$self->{entry_folder}->delete('0','end');
		$self->{entry_folder}->insert(0,$self->gui_jchar($path));
	}
	
	return $self;
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

	# 保存先の参照
	my @types = (
		[ "text file",[qw/.txt/] ],
		["All files",'*']
	);
	my $save = $self->win_obj->getSaveFile(
		-defaultextension => '.txt',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt('名前を付けて結合ファイルを保存')
	);
	unless ($save){
		return 0;
	}
	$save = gui_window->gui_jg_filename_win98($save);
	$save = gui_window->gui_jg($save);
	$save = $::config_obj->os_path($save);
	#print "file save: $save\n";

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
	#if ($::config_obj->os eq 'win32'){
	#	kh_jchar->to_sjis($save);
	#}

	# ファイル名の格納
	my $names = substr( $save,0, rindex($save,'.txt') );
	$names .= '_names.txt';
	open my $fhn, '>:encoding(utf8)', $names or
		gui_errormsg->open(
			type    => 'file',
			thefile => $names,
		);
	foreach my $i (@files){
		print $fhn "$i\n";
	}
	close ($fhn);

	$self->close;
}

sub win_name{
	return 'w_import_folder';
}

1;