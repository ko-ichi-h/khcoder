package gui_window::sysconfig::linux;
use base qw(gui_window::sysconfig);
use strict;
use Tk;
use Tk::HList;

use gui_jchar;
use Gui_DragDrop;
#use gui_window::sysconfig::linux::chasen;
#use gui_window::sysconfig::linux::mecab;

my $last_stanf_lang;

#------------------#
#   Windowを開く   #
#------------------#

sub __new{

#------------------#
#   Chasenの設定   #

	my $self = shift;
	my $mw   = $::main_gui->mw;
	my $inis = $self->{win_obj};

	$inis->title( $self->gui_jt( kh_msg->get('win_title') ) );#'KH Coderの設定','euc') );
	
	my $left = $inis->Frame()->pack(-fill=>'both', -expand => 1, -side => 'left');
	
	my $lfra = $left->LabFrame(
		-label => kh_msg->get('words_ext'),#$self->gui_jchar('[語を抽出する方法]'),
		-labelside => 'acrosstop',
		-borderwidth => 2,
		-foreground => 'blue',
	)->pack(-expand=>'yes',-fill=>'x',-anchor=>'nw');
	my $fra0_5 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');
	my $fra0_7 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');

	# ChaSen
	$lfra->Label(
		-text     => kh_msg->get('chasen'),#$self->gui_jchar('茶筌（日本語）'),
	)->pack(-anchor => 'w');

	my $fra1 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');

	$self->{lb1} = $fra1->Label(
		-text => kh_msg->get('p_chasenrc'),#$self->gui_jchar('"chasenrc"のパス：'),
		-font => 'TKFN'
	)->pack(-side => 'left');

	my $entry1 = $fra1->Entry(
		-font => 'TKFN',
		-background => 'white'
	)->pack(-side => 'right');
	$self->{entry1} = $entry1;

	$entry1->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $entry1,],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);

	$self->{btn1} = $fra1->Button(
		-text => kh_msg->gget('browse'),#$self->gui_jchar('参照'),
		-font => 'TKFN',
		-command => sub { $self->gui_get_exe('chasenrc','entry1'); }
	)->pack(-padx => '2',-side => 'right');

	my $fra2 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');

	$self->{lb2} = $fra2->Label(
		-text => kh_msg->get('p_grammer.cha'),#$self->gui_jchar('"grammar.cha"のパス：','euc'),
		-font => 'TKFN'
	)->pack(-side => 'left');

	my $entry2 = $fra2->Entry(
		-font => 'TKFN',
		-background => 'white'
	)->pack(-side => 'right');
	$self->{entry2} = $entry2;

	$entry2->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $entry2,],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);

	$self->{btn2} = $fra2->Button(
		-text => kh_msg->gget('browse'),#$self->gui_jchar('参照'),
		-font => 'TKFN',
		-command => sub { $self->gui_get_exe('grammar.cha','entry2'); }
	)->pack(-padx => '2',-side => 'right');

	# MeCab
	$lfra->Label(
		-text     => kh_msg->get('mecab'),#$self->gui_jchar('MeCabを利用'),
	)->pack(-anchor => 'w');

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

	$self->{entry_stan1} = $fra_jar->Entry(
		-font => 'TKFN',
		-background => 'white',
	)->pack(-side => 'right');

	$self->{entry_stan1}->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $self->{entry_stan1},],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
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

	$self->{entry_stan2} = $fra_tag->Entry(
		-font => 'TKFN',
		-background => 'white',
	)->pack(-side => 'right');

	$self->{entry_stan2}->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $self->{entry_stan2},],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
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
	$self->{entry_freeling} = $fra_flp->Entry(
		-background => 'white'
	)->pack(-side => 'right');
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
				[ kh_msg->get('l_it') => 'it'],
				[ kh_msg->get('l_pt') => 'pt'],
				[ kh_msg->get('l_ru') => 'ru'],
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


	$self->{mail_obj} = gui_widget::mail_config->open(
		parent => $inis,
		pack   => {
			-fill   => 'both',
			-expand => 0,
			#-side   => 'right',
		},
		command => sub{$self->ok;}
	);


#----------------------#
#   外部アプリの設定   #

	my $afra = $inis->LabFrame(
		-label       => kh_msg->get('apps'),#$self->gui_jchar('[外部アプリケーション]'),
		-labelside   => 'acrosstop',
		-borderwidth => 2,
		-foreground  => 'blue',
	)->pack(-expand=>'yes',-fill=>'both');

	#$afra->Label(
	#	-text => $self->gui_jchar('・その他の外部アプリケーション'),
	#	-font => 'TKFN'
	#)->pack(-anchor => 'w');

	# Webブラウザ
	my $appf1 = $afra->Frame()->pack(-expand => 1, -fill => 'x');
	$appf1->Label(
		-text => kh_msg->get('web_browser'),#$self->gui_jchar('Webブラウザ：'),
		-font => 'TKFN'
	)->pack(-side => 'left');
	my $ent_html = $appf1->Entry(
		-font => 'TKFN',
		-background => 'white',
		-width => 26
	)->pack( -side => 'right' );

	# 表計算
	my $appf2 = $afra->Frame()->pack(-expand => 1, -fill => 'x');
	$appf2->Label(
		-text => kh_msg->get('s_sheet'),#$self->gui_jchar('表計算（CSV/Excel）：'),
		-font => 'TKFN'
	)->pack(-side => 'left');
	my $ent_csv = $appf2->Entry(
		-font => 'TKFN',
		-background => 'white',
		-width => 26
	)->pack( -side => 'right' );

	# PDFビューア
	my $appf3 = $afra->Frame()->pack(-expand => 1, -fill => 'x');
	$appf3->Label(
		-text => kh_msg->get('pdf'),#$self->gui_jchar('PDFビューア'),
		-font => 'TKFN'
	)->pack(-side => 'left');
	my $ent_pdf = $appf3->Entry(
		-font => 'TKFN',
		-background => 'white',
		-width => 26
	)->pack( -side => 'right' );

	$afra->Label(
		-text => kh_msg->get('note_s'),#$self->gui_jchar('※ %sはファイル名やURLで置き換えられます'),
		-font => 'TKFN'
	)->pack(-anchor => 'w');



	$inis->Button(
		-text => kh_msg->gget('cancel'),#$self->gui_jchar('キャンセル'),
		-font => 'TKFN',
		-width => 8,
		-command => sub{$self->close;}
	)->pack(-anchor => 'se', -side => 'right',-padx => 2);

	$inis->Button(
		-text => kh_msg->gget('ok'),#'OK',
		-font => 'TKFN',
		-width => 8,
		-command => sub {$self->ok }
	)->pack(-anchor => 'se', -side => 'right');

	$entry1->insert(0,$::config_obj->chasenrc_path);
	$entry2->insert(0,$::config_obj->grammarcha_path);
	$ent_html->insert(0,$::config_obj->app_html);
	$ent_csv->insert(0,$::config_obj->app_csv);
	$ent_pdf->insert(0,$::config_obj->app_pdf);

	$self->{e_html} = $ent_html;
	$self->{e_csv} = $ent_csv;
	$self->{e_pdf} = $ent_pdf;

	return $self;
}

#--------------------#
#   ファンクション   #
#--------------------#

sub unselect{
	my $self = shift;
	$self->hlist->selectionClear();
#	print "fuck\n";
}

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

	$::config_obj->chasenrc_path( $::config_obj->os_path( $self->gui_jg( $self->entry1->get() ) ) );
	$::config_obj->grammarcha_path( $::config_obj->os_path( $self->gui_jg( $self->entry2->get() ) ) );
	$::config_obj->app_html($self->e_html->get());
	$::config_obj->app_pdf($self->e_pdf->get());
	$::config_obj->app_csv($self->e_csv->get());

	$::config_obj->mecab_unicode( $self->gui_jg( $self->{check_mecab_unicode} ) );

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

	$::config_obj->use_heap(  $self->{mail_obj}->if_heap );
	$::config_obj->mail_if(   $self->{mail_obj}->if      );
	$::config_obj->mail_smtp( $self->{mail_obj}->smtp    );
	$::config_obj->mail_from( $self->{mail_obj}->from    );
	$::config_obj->mail_to(   $self->{mail_obj}->to      );
	$::config_obj->font_main( $self->{mail_obj}->font    );

	$::config_obj->plot_size_words( $self->{mail_obj}->plot_size1 );
	$::config_obj->plot_size_codes( $self->{mail_obj}->plot_size2 );
	$::config_obj->plot_font_size(  $self->{mail_obj}->plot_font  );

	if ($::config_obj->save){
		$self->close;
	}

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

# ファイル・オープン・ダイアログ
sub gui_get_exe{
	my $self = shift;
	my $file = shift;
	my $ent  = shift;

	my @types = (
		["All files", '*']
	);

	my $msg = kh_msg->get('browse_');
	$msg =~ s/____/$file/;
	
	my $path = $self->win_obj->getOpenFile(
		-filetypes => \@types,
		-title => $msg,
		-initialdir => $self->gui_jchar($::config_obj->cwd)
	);

	my $entry = $self->{$ent};
	if ($path){
		$path = $self->gui_jg($path);
		$path = $::config_obj->os_path($path);
		$entry->delete('0','end');
		$entry->insert(0,$self->gui_jchar($path) );
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
sub e_html{
	my $self = shift; return $self->{e_html};
}
sub e_csv{
	my $self = shift; return $self->{e_csv};
}
sub e_pdf{
	my $self = shift; return $self->{e_pdf};
}
1;
