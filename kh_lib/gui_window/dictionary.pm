package gui_window::dictionary;
use base qw(gui_window);
use Tk;
use Tk::Checkbutton;
use Tk::HList;
use Tk::ItemStyle;
use strict;

use kh_dictio;

#----------------#
#   Window表示   #
#----------------#

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	
	my $wmw= $self->{win_obj};
	#$wmw->focus;
	$wmw->title($self->gui_jt( kh_msg->get('win_title') )); # '分析に使用する語の取捨選択'
	
	my $base = $wmw->Frame()->pack(-expand => '1', -fill => 'both');

	my $f_hinshi = $base->LabFrame(
		-label =>'parts of speech',
		-labelside => 'acrosstop'
	)->pack(-side => 'left', -expand => '1', -fill => 'both');

	my $f_mark = $base->LabFrame(
		-label =>'force pick up',
		-labelside => 'acrosstop'
	)->pack(-side => 'left', -expand => '1', -fill => 'both', -padx => 3);

	my $f_stop = $base->LabFrame(
		-label =>'force ignore',
		-labelside => 'acrosstop'
	)->pack(-side => 'right', -expand => '1', -fill => 'both');


	$f_hinshi->Label(
		-text => kh_msg->get('pos'),#$self->gui_jchar('・品詞による語の選択'),
		-font => "TKFN"
	)->pack(-anchor=>'w');
	my $hlist = $f_hinshi->Scrolled(
		'HList',
		-scrollbars         => 'osoe',
#		-relief             => 'sunken',
		-font               => 'TKFN',
		-selectmode         => 'none',
		-indicator => 0,
		-command            => sub{$self->unselect;},
		-highlightthickness => 0,
		-columns            => 1,
		-borderwidth        => 0,
	)->pack(-expand => '1', -fill => 'both');

	$f_mark->Label(
		-text => kh_msg->get('force_pick'),#$self->gui_jchar('・強制抽出する語の指定'),
		-font => "TKFN"
	)->pack(-anchor=>'w');
	$f_mark->Label(
		-text => kh_msg->get('one_line1'),#$self->gui_jchar('　（複数の場合は改行で区切る）'),
		-font => "TKFN"
	)->pack(-anchor=>'w');
	
	$self->{ff_mark_check_v} = 0;
	$f_mark->Radiobutton(
		-text             => kh_msg->get('input_directly'), # 直接入力
		-font             => "TKFN",
		-variable         => \$self->{ff_mark_check_v},
		-value            => 0,
		-command          => sub{ $self->ff_mark_refresh; },
	)->pack(-anchor => 'w');
	
	my $f_mark_input = $f_mark->Frame()->pack(-expand => 1, -fill => 'both');
	
	$f_mark_input->Label(
		-text => '  ',
	)->pack(
		-side => 'left',
	);
	
	my $t1 = $f_mark_input->Scrolled(
		'Text',
		-scrollbars => 'se',
		-background => 'white',
		-height     => 16,
		-width      => 14,
		-wrap       => 'none',
		-font       => "TKFN",
	)->pack(-side => 'left', -expand => 1, -fill => 'both');

	# ファイルからの読み込み
	$f_mark->Radiobutton(
		-text             => kh_msg->get('use_file'), # ファイルから読み込み
		-font             => "TKFN",
		-variable         => \$self->{ff_mark_check_v},
		-value            => 1,
		-command          => sub{ $self->ff_mark_refresh; },
	)->pack(-anchor => 'w');

	my $ff_mark = $f_mark->Frame()->pack(-fill => 'x');

	$ff_mark->Label(
		-text => '  ',
	)->pack(
		-side => 'left',
	);

	$self->{ff_mark_button} = $ff_mark->Button(
		-text    => kh_msg->gget('browse'),
		-command => sub{$self->ff_mark_browse;},
	)->pack(
		-side => 'left',
		-padx => 1,
	);

	$self->{ff_mark_entry} = $ff_mark->Entry(
		-font => "TKFN",
		-background => 'white',
	)->pack(
		-expand => 1,
		-fill   => 'x',
		-padx   => 1,
	);
	gui_window->disabled_entry_configure($self->{ff_mark_entry});

	$f_stop->Label(
		-text => kh_msg->get('force_ignore'),#$self->gui_jchar('・使用しない語の指定'),
		-font => "TKFN"
	)->pack(-anchor=>'w');
	$f_stop->Label(
		-text => kh_msg->get('one_line2'),#$self->gui_jchar('　（複数の場合は改行で区切る）'),
		-font => "TKFN"
	)->pack(-anchor=>'w');

	$self->{ff_stop_check_v} = 0;
	$f_stop->Radiobutton(
		-text             => kh_msg->get('input_directly'), # 直接入力
		-font             => "TKFN",
		-variable         => \$self->{ff_stop_check_v},
		-value            => 0,
		-command          => sub{ $self->ff_stop_refresh; },
	)->pack(-anchor => 'w');
	
	my $f_stop_input = $f_stop->Frame()->pack(-expand => 1, -fill => 'both');
	
	$f_stop_input->Label(
		-text => '  ',
	)->pack(
		-side => 'left',
	);
	
	my $t2 = $f_stop_input->Scrolled(
		'Text',
		-scrollbars => 'se',
		-height     => 16,
		-width      => 14,
		-wrap       => 'none',
		-font       => "TKFN",
		-background => 'white'
	)->pack(-expand => 1, -fill => 'both');

	# ファイルからの読み込み
	$f_stop->Radiobutton(
		-text             => kh_msg->get('use_file'), # ファイルから読み込み
		-font             => "TKFN",
		-variable         => \$self->{ff_stop_check_v},
		-value            => 1,
		-command          => sub{ $self->ff_stop_refresh; },
	)->pack(-anchor => 'w');

	my $ff_stop = $f_stop->Frame()->pack(-fill => 'x');

	$ff_stop->Label(
		-text => '  ',
	)->pack(
		-side => 'left',
	);

	$self->{ff_stop_button} = $ff_stop->Button(
		-text    => kh_msg->gget('browse'),
		-command => sub{$self->ff_stop_browse;},
	)->pack(
		-side => 'left',
		-padx => 1,
	);

	$self->{ff_stop_entry} = $ff_stop->Entry(
		-font => "TKFN",
		-background => 'white',
	)->pack(
		-expand => 1,
		-fill   => 'x',
		-padx   => 1,
	);
	gui_window->disabled_entry_configure($self->{ff_stop_entry});


	# 文字化け回避バインド
	#$t1->bind("<Key>",[\&gui_jchar::check_key,Ev('K'),\$t1]);
	#$t1->bind("<Button-1>",[\&gui_jchar::check_mouse,\$t1]);
	#$t2->bind("<Key>",[\&gui_jchar::check_key,Ev('K'),\$t2]);
	#$t2->bind("<Button-1>",[\&gui_jchar::check_mouse,\$t2]);

	# ドラッグ＆ドロップ
	$t1->DropSite(
		-dropcommand => [\&Gui_DragDrop::read_TextFile_droped,$t1],
		-droptypes => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);
	$t2->DropSite(
		-dropcommand => [\&Gui_DragDrop::read_TextFile_droped,$t2],
		-droptypes => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);

	#SCREEN Plugin
	use screen_code::negationchecker;
	&screen_code::negationchecker::add_label($self,$wmw);
	#SCREEN Plugin
	
	$wmw->Label(
		-text => kh_msg->get('note1'),#$self->gui_jchar("(*) 「強制抽出する語」の指定は、再度\n　　前処理を行うまで反映されません。"),
		-font => 'TKFN',
		-justify => 'left',
	)->pack(-anchor => 'w', -side => 'left');

	$wmw->Button(
		-text => kh_msg->gget('cancel'),#$self->gui_jchar('キャンセル'),
		-font => 'TKFN',
		-width => 8,
		-command => sub{$self->close;}
	)->pack(-anchor=>'e',-side => 'right',-padx => 2);

	$self->{ok_btn} = $wmw->Button(
		-text => kh_msg->gget('ok'),#'OK',
		-font => 'TKFN',
		-width => 8,
		-command => sub{$self->save;}
	)->pack(-anchor=>'e',-side => 'right');

	$self->{t1} = $t1;
	$self->{t2} = $t2;
	$self->{hlist} = $hlist;
	
	$self->_fill_in;


	$self->ff_mark_refresh;
	$self->ff_stop_refresh;

	return $self;
}

sub ff_mark_refresh{
	my $self = shift;
	
	return 0 unless $self->{ff_mark_button};
	
	if ( $self->{ff_mark_check_v} ){
		$self->{ff_mark_button}->configure(-state => "normal");
		$self->{ff_mark_entry} ->configure(-state => "normal");
		$self->{t1}            ->configure(
			-state      => "disable",
			-background => $self->{ff_mark_entry}->cget(-disabledbackground),
		);
	} else {
		$self->{ff_mark_button}->configure(-state => "disable");
		$self->{ff_mark_entry} ->configure(-state => "disable");
		$self->{t1}            ->configure(
			-state      => "normal",
			-background => "white",
		);
	}
	return $self;
}

sub ff_mark_browse{
	my $self = shift;

	my @types = (
		["Text Files", '.txt' ],
		["All Files" , '*'    ]
	);
	
	my $path = $self->win_obj->getOpenFile(
		-filetypes  => \@types,
		-title      => kh_msg->gget('select_a_file'),
		-initialdir => $self->gui_jchar($::config_obj->cwd),
	);

	if ($path){
		$path = $self->gui_jg_filename_win98($path);
		$path = $self->gui_jg($path);
		$path = $::config_obj->os_path($path);
		$self->{ff_mark_entry}->delete('0','end');
		$self->{ff_mark_entry}->insert(0,$self->gui_jchar($path));
	}

}

sub ff_stop_refresh{
	my $self = shift;
	
	return 0 unless $self->{ff_stop_button};
	
	if ( $self->{ff_stop_check_v} ){
		$self->{ff_stop_button}->configure(-state => "normal");
		$self->{ff_stop_entry} ->configure(-state => "normal");
		$self->{t2}            ->configure(
			-state      => "disable",
			-background => $self->{ff_stop_entry}->cget(-disabledbackground),
		);
	} else {
		$self->{ff_stop_button}->configure(-state => "disable");
		$self->{ff_stop_entry} ->configure(-state => "disable");
		$self->{t2}            ->configure(
			-state      => "normal",
			-background => "white",
		);
	}
	return $self;
}

sub ff_stop_browse{
	my $self = shift;

	my @types = (
		["Text Files", '.txt' ],
		["All Files" , '*'    ]
	);
	
	my $path = $self->win_obj->getOpenFile(
		-filetypes  => \@types,
		-title      => kh_msg->gget('select_a_file'),
		-initialdir => $self->gui_jchar($::config_obj->cwd),
	);

	if ($path){
		$path = $self->gui_jg_filename_win98($path);
		$path = $self->gui_jg($path);
		$path = $::config_obj->os_path($path);
		$self->{ff_stop_entry}->delete('0','end');
		$self->{ff_stop_entry}->insert(0,$self->gui_jchar($path));
	}

}



#---------------------------------------#
#   現在の設定内容をWindownに書き込み   #
#---------------------------------------#

sub _fill_in{
	my $self = shift;
	$self->{config} = kh_dictio->readin;

	# 品詞リスト
	my $row = 0;
	my @selection;
	my $right = $self->hlist->ItemStyle('window',-anchor => 'w');
	if ($self->config->hinshi_list){
		foreach my $i (@{$self->config->hinshi_list}){
			#print Jcode->new("$i\n",'euc')->sjis;
			$selection[$row] = $self->config->ifuse_this($i);
			my $c = $self->hlist->Checkbutton(
				-text     => $self->gui_jchar($i),
				-variable => \$selection[$row],
				-anchor   => 'w',
			);
			$self->hlist->add($row,-at => $row,);
			$self->hlist->itemCreate(
				$row,0,
				-itemtype => 'window',
				-style    => $right,
				-widget   => $c,
			);
			#$self->hlist->itemCreate(
			#	$row,1,
			#	-itemtype => 'text',
			#	-text     => $self->gui_jchar($i,'euc')
			#);
			++$row;
		}
		$self->{checks} = \@selection;
		my @org = @selection;
		$self->{org_checks} = \@org;
	}


	# 強制抽出
	if ($self->config->words_mk){
		foreach my $i (@{$self->config->words_mk}){
#			print "$i\n";
			next unless length($i);
			my $t = $self->gui_jchar($i);
			$self->t1->insert('end',"$t\n");
		}
	}
	# 使用しない語
	if ($self->config->words_st){
		foreach my $i (@{$self->config->words_st}){
			next unless length($i);
			my $t = $self->gui_jchar($i);
			$self->t2->insert('end',"$t\n");
		}
	}

	# 強制抽出・ファイル
	if ($self->config->words_mk_file_chk){
		$self->{ff_mark_check_v} = 1;
		$self->{ff_mark_entry}->insert(
			0, $self->gui_jchar( $self->config->words_mk_file )
		);
	}

	# 使用しない語・ファイル
	if ($self->config->words_st_file_chk){
		$self->{ff_stop_check_v} = 1;
		$self->{ff_stop_entry}->insert(
			0, $self->gui_jchar( $self->config->words_st_file )
		);
	}

}

sub unselect{
	my $self = shift;
	$self->hlist->selectionClear();
	#print "fuck\n";
}

#----------------------#
#   設定を保存・適用   #
#----------------------#
sub save{
	my $self = shift;

	# fool proof
	if ($self->config->hinshi_list){
		my $count_pos = 0;
		foreach my $i ( @{$self->{checks}} ){
			++$count_pos if $i;
		}
		unless ($count_pos){
			gui_errormsg->open(
				msg    => kh_msg->get('no_pos_selected'),
				type   => 'msg',
				window => \$self->{win_obj},
			);
			return 0;
		}
	}

	# 強制抽出
	my @mark; my %check;
	my $t = $self->t1->get("1.0","end");
	$t =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
	#print Jcode->new("$t\n")->sjis;

	foreach my $i (split /\n/, $t){
		$i =~ s/\x0D|\x0A//g;
		if (length($i) and not $check{$i}) {
			push @mark, $i;
			$check{$i} = 1;
		}
	}

	if ( $self->{ff_mark_check_v} == 0 ){
		$self->config->words_mk_file_chk(0);
	} else {
		my $file = $::config_obj->os_path(
			$self->gui_jg(
				$self->{ff_mark_entry}->get
			)
		);
		
		unless (-e $file){
			gui_errormsg->open(
				msg    => kh_msg->get('file_error')."\n$file",
				type   => 'msg',
				#window => $self->win_obj,
			);
			return 0;
		}
		
		$self->config->words_mk_file_chk(1);
		$self->config->words_mk_file($file);
	}

	$self->config->words_mk(\@mark); # ファイル利用のあとから設定

	# 使用しない語
	my @stop; %check = ();
	$t = $self->t2->get("1.0","end");
	$t =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
	#print Jcode->new("$t\n")->sjis;

	foreach my $i (split /\n/, $t){
		$i =~ s/\x0D|\x0A//g;
		if (length($i) and not $check{$i}) {
			push @stop, $i;
			$check{$i} = 1;
		}
	}
	
	if ( $self->{ff_stop_check_v} == 0 ){
		$self->config->words_st_file_chk(0);
	} else {
		my $file = $::config_obj->os_path(
			$self->gui_jg(
				$self->{ff_stop_entry}->get
			)
		);

		unless (-e $file){
			gui_errormsg->open(
				msg    => kh_msg->get('file_error')."\n$file",
				type   => 'msg',
				#window => $self->win_obj,
			);
			return 0;
		}
		
		$self->config->words_st_file_chk(1);
		$self->config->words_st_file($file);
	}

	$self->config->words_st(\@stop); # ファイル利用のあとから設定

	# 品詞選択
	if ($self->config->hinshi_list){
		my $changed = 0;
		my $row = 0;
		foreach my $i (@{$self->config->hinshi_list}){
			#print Jcode->new("$i, ".$self->checks->[$row]."\n",'euc')->sjis;
			$self->config->ifuse_this($i,$self->gui_jg($self->checks->[$row]));
			if ($self->{checks}[$row] != $self->{org_checks}[$row]) {
				$changed = 1;
			}
			
			++$row;
		}
		if ( $changed ){
			my $settings = $::project_obj->load_dmp(
				name => 'widget_words',
			);
			if ($settings) {
				$settings->{hinshi} = undef;
				$::project_obj->save_dmp(
					name => 'widget_words',
					var  => $settings,
				);
			}
		}
	}

	$self->config->save;
	$::main_gui->close_all;
	
	# Main Windowの表示を更新
	$::main_gui->inner->refresh;
	
}

#--------------#
#   アクセサ   #
#--------------#
sub config{
	my $self = shift;
	return  $self->{config};
}

sub win_name{
	return 'w_dictionary';
}
sub t1{
	my $self = shift;
	return $self->{t1};
}
sub t2{
	my $self = shift;
	return $self->{t2};
}
sub hlist{
	my $self = shift;
	return $self->{hlist};
}
sub checks{
	my $self = shift;
	return $self->{checks};
}

1;
