package gui_window::sysconfig::win32;
use base qw(gui_window::sysconfig);
use strict;
use Tk;

use gui_jchar;
use Gui_DragDrop;

my $last_stanf_lang;

#------------------#
#   Windowを開く   #
#------------------#

sub __new{
	my $self = shift;
	my $mw   = $::main_gui->mw;
	my $inis = $self->{win_obj};

	# $inis->focus;
	# $inis->grab;
	$inis->title($self->gui_jt( kh_msg->get('win_title') ));

	my $lfra = $inis->LabFrame(
		-label => kh_msg->get('words_ext'),#$self->gui_jchar('[語を抽出する方法]'),
		-labelside => 'acrosstop',
		-borderwidth => 2,
		-foreground => 'blue',
	)->pack(-fill=>'both', -expand => 1, -side => 'left');
	
	#my $fra0 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');
	my $fra0_5 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');
	my $fra0_7 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');

	# ChaSen
	$lfra->Label(
		-text     => kh_msg->get('chasen'),#$self->gui_jchar('茶筌（日本語）'),
	)->pack(-anchor => 'w');

	my $fra1 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');

	$self->{lb1} = $fra1->Label(
		-text => kh_msg->get('p_chasen.exe'),#$self->gui_jchar('chasen.exeのパス：'),
		-font => 'TKFN'
	)->pack(-side => 'left');

	my $entry1 = $fra1->Entry(-font => 'TKFN')->pack(-side => 'right');
	$self->{entry1} = $entry1;

	$entry1->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $entry1,],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['KDE', 'XDND', 'Sun'])
	);

	$self->{btn1} = $fra1->Button(
		-text => kh_msg->gget('browse'),#$self->gui_jchar('参照'),
		-font => 'TKFN',
		-command => sub { $self->browse_chasen(); }
	)->pack(-padx => '2',-side => 'right');

	# MeCab
	my $msg = kh_msg->get('mecab'); #'MeCab（日本語）';

	$lfra->Label(
		-text     => $msg,
	)->pack(-anchor => 'w');

	my $fra2 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');

	$self->{lb2} = $fra2->Label(
		-text => kh_msg->get('p_mecab.exe'),#$self->gui_jchar('mecab.exeのパス：'),
		-font => 'TKFN'
	)->pack(-side => 'left');

	my $entry2 = $fra2->Entry(-font => 'TKFN')->pack(-side => 'right');
	$self->{entry2} = $entry2;

	$entry2->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $entry2,],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['KDE', 'XDND', 'Sun'])
	);

	$self->{btn2} = $fra2->Button(
		-text => kh_msg->gget('browse'),#$self->gui_jchar('参照'),
		-font => 'TKFN',
		-command => sub { $self->browse_mecab(); }
	)->pack(-padx => '2',-side => 'right');
	
	$entry1->insert(0,$self->gui_jchar($::config_obj->chasen_path));
	$entry2->insert(0,$self->gui_jchar($::config_obj->mecab_path));

	my $fra3 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');
	
	$fra3->Label(
		-text => '   ',
		-font => 'TKFN'
	)->pack(-side => 'left');
	
	$self->{check_mecab_unicode} = $::config_obj->mecab_unicode;
	$self->{chkwd_mecab_unicode} = $fra3->Checkbutton(
		-text     => kh_msg->get('mecab_unicode'),
		-variable => \$self->{check_mecab_unicode},
	)->pack(
		-side   => 'left',
	);


	# POS Tagger

	$lfra->Label(
		-text     => kh_msg->get('stanford'),#$self->gui_jchar('Stemming with "Snowball"'),
	)->pack(-anchor => 'w');

	# POS Taggerの*.jarファイル
	my $fra_jar = $lfra->Frame()->pack(-fill=>'x',-expand=>'yes',-pady => 1);

	$self->{label_stan3} = $fra_jar->Label(
		-text => kh_msg->get('p_stanford_jar'),
		-font => 'TKFN'
	)->pack(-side => 'left');

	$self->{entry_stan1} = $fra_jar->Entry(-font => 'TKFN')->pack(-side => 'right');

	$self->{entry_stan1}->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $self->{entry_stan1},],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['KDE', 'XDND', 'Sun'])
	);

	$self->{btn_stan2} = $fra_jar->Button(
		-text => kh_msg->gget('browse'),#$self->gui_jchar('参照'),
		-font => 'TKFN',
		-command => sub { $self->browse_stanford_jar(); }
	)->pack(-padx => '2',-side => 'right');

	$self->{entry_stan1}->insert(
		0, $self->gui_jchar($::config_obj->stanf_jar_path)
	);

	# POS Taggerのその他の設定
	my $fra_stan = $lfra->Frame()->pack(-anchor => 'w',-pady => 1);
	
	$self->{label_stan1} = $fra_stan->Label(
		-text => kh_msg->get('lang'),#'Language:'
	)->pack(-side => 'left',-anchor => 'w');

	$self->{opt_stan} = gui_widget::optmenu->open(
		parent  => $fra_stan,
		pack    => {-anchor=>'w', -side => 'left'},
		options =>
			[
				[ kh_msg->get('l_en') => 'en'],#'English'
				#[ kh_msg->get('l_de') => 'de'],#'German *'
				[ kh_msg->get('l_cn') => 'cn'],#'Chinese'
			],
		variable => \$self->{opt_stan_val},
		command => sub {$self->save_tagger;},
	);
	$self->{opt_stan}->set_value( $::config_obj->stanford_lang );
	$last_stanf_lang = $self->{opt_stan_val};

	$self->{label_stan2} = $fra_stan->Label(
		-text => kh_msg->get('stopwords'),#'  Stop words:'
	)->pack(-side => 'left',-anchor => 'w');

	$self->{btn_stan1} = $fra_stan->Button(
		-text => kh_msg->get('config'),#'config',
		-borderwidth => 1,
		-command => sub {
			my $class = "gui_window::stop_words::stanford_";
			$class   .= "$self->{opt_stan_val}";
			$class->open();
		}
	)->pack(-side => 'left');

	# POS Taggerの*.taggerファイル
	my $fra_tag = $lfra->Frame()->pack(-fill=>'x',-expand=>'yes');

	$self->{label_stan4} = $fra_tag->Label(
		-text => kh_msg->get('p_stanford_tag'),
		-font => 'TKFN'
	)->pack(-side => 'left');

	$self->{entry_stan2} = $fra_tag->Entry(-font => 'TKFN')->pack(-side => 'right');

	$self->{entry_stan2}->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $self->{entry_stan2},],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['KDE', 'XDND', 'Sun'])
	);

	$self->{btn_stan3} = $fra_tag->Button(
		-text => kh_msg->gget('browse'),#$self->gui_jchar('参照'),
		-font => 'TKFN',
		-command => sub { $self->browse_stanford_tag(); }
	)->pack(-padx => '2',-side => 'right');

	my $call = "stanf_tagger_path_".$self->{opt_stan_val};
	$self->{entry_stan2}->insert(
		0, $self->gui_jchar($::config_obj->$call)
	);

	# FreeLing
	$lfra->Label( -text => "FreeLing" )->pack(-anchor => 'w');
	
	my $fra_flp = $lfra->Frame()->pack(-fill=>'x',-expand=>'yes');
	$fra_flp->Label(-text => '    Installation dir: ')->pack(-side => 'left');
	$self->{entry_freeling} = $fra_flp->Entry()->pack(-side => 'right');
	$fra_flp->Button(
		-text => kh_msg->gget('browse'),#$self->gui_jchar('参照'),
		-command => sub { $self->browse_freeling(); }
	)->pack(-padx => '2',-side => 'right');
	$self->{entry_freeling}->insert(
		0, $::config_obj->uni_path($::config_obj->freeling_dir)
	);
	
	my $fra_fls = $lfra->Frame()->pack(-anchor => 'w',-pady => 1);
	
	$fra_fls->Label(
		-text => kh_msg->get('lang'),#'Language:'
	)->pack(-side => 'left',-anchor => 'w');
	$self->{opt_fls} = gui_widget::optmenu->open(
		parent  => $fra_fls,
		pack    => {-anchor=>'w', -side => 'left'},
		options =>
			[
				[ kh_msg->get('l_ca') => 'ca'],
				[ kh_msg->get('l_en') => 'en'],
				[ kh_msg->get('l_fr') => 'fr'],
				[ kh_msg->get('l_de') => 'de'],
				[ kh_msg->get('l_it') => 'it'],
				[ kh_msg->get('l_pt') => 'pt'],
				[ kh_msg->get('l_ru') => 'ru'],
				[ kh_msg->get('l_sl') => 'sl'],
				[ kh_msg->get('l_es') => 'es'],
			],
		variable => \$self->{opt_fls_val},
	);
	$self->{opt_fls}->set_value( $::config_obj->freeling_lang );

	$fra_fls->Label(
		-text => kh_msg->get('stopwords'),#'  Stop words:'
	)->pack(-side => 'left',-anchor => 'w');

	$fra_fls->Button(
		-text => kh_msg->get('config'),#'config',
		-borderwidth => 1,
		-command => sub {
			my $class = "gui_window::stop_words::freeling_";
			$class   .= "$self->{opt_fls_val}";
			$class->open();
		}
	)->pack(-side => 'left');
	
	
	# Stemming
	
	$lfra->Label(
		-text     => kh_msg->get('stemming'),#$self->gui_jchar('Stemming with "Snowball"'),
	)->pack(-anchor => 'w');

	my $fra_stem = $lfra->Frame()->pack(-anchor => 'w');
	
	$self->{label_stem1} = $fra_stem->Label(
		-text => kh_msg->get('lang'),#'Language:'
	)->pack(-side => 'left',-anchor => 'w');

	$self->{opt_stem} = gui_widget::optmenu->open(
		parent  => $fra_stem,
		pack    => {-anchor=>'w', -side => 'left'},
		options =>
			[
				[ kh_msg->get('l_en') => 'en'],#'English'
				[ kh_msg->get('l_nl') => 'nl'],#'Dutch *'
				[ kh_msg->get('l_fr') => 'fr'],#'French *'
				[ kh_msg->get('l_de') => 'de'],#'German *'
				[ kh_msg->get('l_it') => 'it'],#'Italian *'
				[ kh_msg->get('l_pt') => 'pt'],#'Portuguese *'
				[ kh_msg->get('l_es') => 'es'],#'Spanish *'
			],
		variable => \$self->{opt_stem_val},
	);
	$self->{opt_stem}->set_value($::config_obj->stemming_lang);

	$self->{label_stem2} = $fra_stem->Label(
		-text => kh_msg->get('stopwords'),#'  Stop words:'
	)->pack(-side => 'left',-anchor => 'w');

	$self->{btn_stem} = $fra_stem->Button(
		-text => kh_msg->get('config'),#'config',
		-borderwidth => 1,
		-command => sub {
			my $class = "gui_window::stop_words::stemming_";
			$class   .= "$self->{opt_stem_val}";
			$class->open();
		}
	)->pack(-side => 'left');

	$lfra->Separator()->pack( -fill => 'x', -padx => 5, -pady => 7);
	$self->{check_unify_words_sl} = $::config_obj->unify_words_with_same_lemma;
	$self->{chkwd_unify_words_sl} = $lfra->Checkbutton(
		-text     => kh_msg->get('unify_words_sl'),
		-variable => \$self->{check_unify_words_sl},
		-wraplength => "10c",
		-justify  => 'left',
	)->pack(
		-anchor => 'w'
	);

	$self->{mail_obj} = gui_widget::mail_config->open(
		parent => $inis,
		pack   => {
			-fill   => 'both',
			-expand => 0,
			#-side   => 'right',
		},
		command => sub{$self->ok;}
	);

	$inis->Button(
		-text => kh_msg->gget('cancel'),
		-font => 'TKFN',
		-width => 8,
		-command => sub{$self->close;}
	)->pack(-anchor=>'se',-side => 'right',-padx => 2, -pady => 2);

	$inis->Button(
		-text  => kh_msg->gget('ok'),
		-font  => 'TKFN',
		-width => 8,
		-command => sub {$self->ok;}
	)->pack(-anchor => 'se',-side => 'right',  -pady => 2);

	# 文字化け回避用バインド
	$inis->bind('Tk::Entry', '<Key-Delete>', \&gui_jchar::check_key_e_d);
	$entry1->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$entry1]);
	
	
	#$self->gui_switch;

	return $self;
}

#--------------------#
#   ファンクション   #
#--------------------#

sub save_tagger{
	my $self = shift;
	#print "$self->{opt_stan_val}\n";
	#print "$last_stanf_lang\n";
	
	my $path = $self->gui_jg( $self->{entry_stan2}->get );
	if (-e $path) {
		my $call = "stanf_tagger_path_".$last_stanf_lang;
		$::config_obj->$call($path);
	}
	
	unless ($self->{opt_stan_val} eq $last_stanf_lang){
		my $call = "stanf_tagger_path_".$self->{opt_stan_val};
		$self->{entry_stan2}->delete('0','end');
		$self->{entry_stan2}->insert(0,$::config_obj->$call);
	}
	$last_stanf_lang = $self->{opt_stan_val};
}

# OKボタン
sub ok{
	my $self = shift;
	
	my $oldfont = $::config_obj->font_main;
	
	$::config_obj->chasen_path(  $self->gui_jg( $self->entry1->get() ) );
	$::config_obj->mecab_path(   $self->gui_jg( $self->entry2->get() ) );
	$::config_obj->mecab_unicode($self->gui_jg( $self->{check_mecab_unicode}));
	
	$::config_obj->stemming_lang($self->gui_jg( $self->{opt_stem_val}) );
	$::config_obj->stanford_lang($self->gui_jg( $self->{opt_stan_val}) );
	$::config_obj->freeling_lang($self->gui_jg( $self->{opt_fls_val}) );

	$::config_obj->stanf_jar_path(
		$self->gui_jg( $self->{entry_stan1}->get() )
	);

	my $call = "stanf_tagger_path_".$self->{opt_stan_val};
	$::config_obj->$call( $self->gui_jg( $self->{entry_stan2}->get ) );

	$::config_obj->freeling_dir(
		$self->gui_jg( $self->{entry_freeling}->get() )
	);
	
	$::config_obj->use_heap(               $self->{mail_obj}->if_heap );
	$::config_obj->mail_if(                $self->{mail_obj}->if      );
	$::config_obj->mail_smtp(              $self->{mail_obj}->smtp    );
	$::config_obj->mail_from(              $self->{mail_obj}->from    );
	$::config_obj->mail_to(                $self->{mail_obj}->to      );
	$::config_obj->font_main(              $self->{mail_obj}->font    );
	$::config_obj->color_universal_design( $self->{mail_obj}->cud     );
	
	$::config_obj->plot_size_words( $self->{mail_obj}->plot_size1 );
	$::config_obj->plot_size_codes( $self->{mail_obj}->plot_size2 );
	$::config_obj->plot_font_size(  $self->{mail_obj}->plot_font  );

	$::config_obj->unify_words_with_same_lemma( $self->gui_jg( $self->{check_unify_words_sl} ) );

	if ($::config_obj->save){
		$self->close;
	}
	
	$::main_gui->menu->refresh;
	
	unless ($oldfont eq $::config_obj->font_main){
		$::main_gui->close_all;
		$::main_gui->remove_font;
		$::main_gui->make_font;
		$::config_obj->ClearGeometries;
		gui_errormsg->open(
			type => 'msg',
			icon => 'info',
			msg  => kh_msg->get('note_font'),
		);
		
	}

}

# Mecab.exeの参照
sub browse_mecab{
	my $self  = shift;

	my @types =
		(["exe files",           [qw/.exe/]],
		["All files",		'*']
	);
	
	my $path = $self->win_obj->getOpenFile(
		-filetypes  => \@types,
		-title      => $self->gui_jt( kh_msg->get('browse_mecab') ),
		-initialdir => $self->gui_jchar($::config_obj->cwd),
	);
	
	if ($path){
		$path = $self->gui_jg_filename_win98($path);
		$path = $self->gui_jg($path);
		#$path = $::config_obj->os_path($path);
		$self->entry2->delete('0','end');
		$self->entry2->insert(0,$self->gui_jchar($path));
	}
}

# Chasen.exeの参照
sub browse_chasen{
	my $self  = shift;

	my @types =
		(["exe files",           [qw/.exe/]],
		["All files",		'*']
	);
	
	my $path = $self->win_obj->getOpenFile(
		-filetypes  => \@types,
		-title      => $self->gui_jt( kh_msg->get('browse_chasen') ),
		-initialdir => $self->gui_jchar($::config_obj->cwd),
	);
	
	if ($path){
		$path = $self->gui_jg_filename_win98($path);
		$path = $self->gui_jg($path);
		#$path = $::config_obj->os_path($path);
		$self->entry1->delete('0','end');
		$self->entry1->insert(0,$self->gui_jchar($path));
	}
}

#--------------#
#   アクセサ   #
#--------------#

sub entry1{
	my $self = shift; return $self->{entry1};
}
sub entry2{
	my $self = shift; return $self->{entry2};
}
sub btn1{
	my $self = shift; return $self->{btn1};
}
sub btn2{
	my $self = shift; return $self->{btn2};
}
sub chk{
	my $self = shift; return $self->{chk};
}
sub chk2{
	my $self = shift; return $self->{chk2};
}
sub lb1{
	my $self = shift; return $self->{lb1};
}
sub lb2{
	my $self = shift; return $self->{lb2};
}
1;
