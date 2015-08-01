package gui_window::project_edit;
use base qw(gui_window);
use strict;
use Tk;

sub _new{
	my $self = shift;
	$self->{projects} = $_[0];
	$self->{num}      = $_[1];
	$self->{mother}   = $_[2];

	$self->{project}  = $self->projects->a_project($self->num);
	my $lm = $self->{project}->lang_method;

	# 開く
	my $mw = $::main_gui->mw;
	my $npro = $self->{win_obj};
	$npro->focus();

	$npro->title( $self->gui_jt( kh_msg->get('win_title') ) );

	# $self->{win_obj} = $npro;

	my $lfra = $npro->LabFrame(
		-label => 'Entry',
		-labelside => 'acrosstop',
		-borderwidth => 2
	)->pack(-expand=>'yes',-fill=>'both');

	# target file
	$lfra->Label(
		-text => kh_msg->get('target_file'),#$self->gui_jchar('分析対象ファイル：'),
		-font => "TKFN"
	)->grid(-row => 0, -column => 0, -sticky => 'w', -pady=>2);
	
	my $fra1 = $lfra->Frame()->grid(-row => 0, -column => 1, -sticky => 'ew',-pady=>2);

	my $e1 = $fra1->Entry(
		-font => "TKFN",
		-background => 'white'
	)->pack(-side => 'right', -fill => 'x', -expand => 1);

	$fra1->Button(
		-text => kh_msg->gget('browse'),#$self->gui_jchar('参照'),
		-font => "TKFN",
		#-borderwidth => 1,
		-command => sub{$self->_sansyo;}
	)->pack(-side => 'right',-padx => 2);

	# language
	$lfra->Label(
		-text => kh_msg->get('lang', 'gui_window::stop_words'), # 言語
		-font => "TKFN"
	)->grid(-row => 1, -column => 0, -sticky => 'w', -pady=>2);
	
	my $fra3 = $lfra->Frame()->grid(-row => 1, -column => 1, -sticky => 'ew',-pady=>2);
	$self->{fra3} = $fra3;

	$self->{lang_menu} = gui_widget::optmenu->open(
		parent  => $fra3,
		pack    => { -side => 'left', -padx => 2},
		options =>
			[
				[ kh_msg->get('l_jp', 'gui_window::sysconfig') => 'jp'],# Japanese
				[ kh_msg->get('l_en', 'gui_window::sysconfig') => 'en'],# English
				[ kh_msg->get('l_cn', 'gui_window::sysconfig') => 'cn'],# Chinese
				[ kh_msg->get('l_nl', 'gui_window::sysconfig') => 'nl'],# Dutch
				[ kh_msg->get('l_fr', 'gui_window::sysconfig') => 'fr'],# French
				[ kh_msg->get('l_de', 'gui_window::sysconfig') => 'de'],# German
				[ kh_msg->get('l_it', 'gui_window::sysconfig') => 'it'],# Italian
				[ kh_msg->get('l_pt', 'gui_window::sysconfig') => 'pt'],# Portuguese
				[ kh_msg->get('l_es', 'gui_window::sysconfig') => 'es'],# Spanish
			],
		variable => \$self->{lang},
		command => sub {$self->refresh_method;},
	);
	$self->{lang_menu}->set_value( $lm->[0] );

	# method
	$self->refresh_method;
	$self->{method_menu}->set_value( $lm->[1] );

	# Memo
	$lfra->Label(
		-text => kh_msg->get('memo'),#$self->gui_jchar('説明（メモ）：'),
		-font => "TKFN"
	)->grid(-row => 3, -column => 0, -sticky => 'w', -pady=>2);;

	my $e2 = $lfra->Entry(
		-font => "TKFN",
		-background => 'white'
	)->grid(-row => 3, -column => 1, -sticky => 'ew',-pady=>2, -padx=>2);

	$npro->Button(
		-text => kh_msg->gget('cancel'),
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->close();}
	)->pack(-side => 'right',-padx => 2);

	$self->{ok_btn} = $npro->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->_edit;},
	)->pack(-side => 'right');

	# ENTRYのバインド
	$npro->bind('Tk::Entry', '<Key-Delete>', \&gui_jchar::check_key_e_d);
	$e2->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$e2]);
	$e2->bind("<Key-Return>",sub{$self->_edit;});
	$e2->bind("<KP_Enter>",sub{$self->_edit;});
	
	# ENTRYへの挿入
	$e1->insert(0,$self->gui_jchar($self->project->file_target));
	$e2->insert(0,$self->gui_jchar($self->project->comment));
	$e1->configure(-state => 'disable');
	$self->{e2}  = $e2;

	
	#MainLoop;
	return $self;
}

sub _edit{
	my $self = shift;
	
	my $t = $self->gui_jg($self->e2->get);
	
	$self->projects->edit(
		$self->num,
		$t,
		$self->{lang},
		$self->{method},
	);
	
	$self->close();
	$self->mother->refresh;
	
	# 現在開いているプロジェクトを編集した場合
	my $current_file;
	eval{ $current_file = $::project_obj->file_target; };
	if (
		   $self->{projects}->a_project($self->{num})->file_target
		eq $current_file
	){
		# コメントの編集をメインのWindowに反映させる
		$::project_obj->comment( $t );
		$::main_gui->inner->refresh;
	}
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
	# Chinese
	elsif ($self->{lang} eq 'cn') {
		push @options, ['Stanford POS Tagger', 'stanford'];
		$possbile{stanford} = 1;
	}
	# English
	elsif ($self->{lang} eq 'en') {
		push @options, ['Stanford POS Tagger', 'stanford'];
		push @options, ['Snowball stemmer',    'stemming'];
		$possbile{stanford} = 1;
		$possbile{stemming} = 1;
	}
	# Other
	else {
		push @options, ['Snowball stemmer',    'stemming'];
		$possbile{stemming} = 1;
	}

	my $last = $::config_obj->last_method;
	if ($possbile{$last}) {
		$self->{method} = $last;
	} else {
		$self->{method} = $options[0]->[1];
	}
	
	$self->{method_menu} = gui_widget::optmenu->open(
		parent  => $self->{fra3}, #$fra3,
		width   => 19,
		pack    => { -side => 'right', -padx => 2},
		options => \@options,
		variable => \$self->{method},
		command => sub {}
	);

	return $self;
}

#--------------#
#   アクセサ   #
#--------------#

sub e2{
	my $self = shift;
	return $self->{e2};
}
sub num{
	my $self = shift;
	return $self->{num};
}
sub project{
	my $self = shift;
	return $self->{project};
}
sub projects{
	my $self = shift;
	return $self->{projects};
}
sub mother{
	my $self = shift;
	return $self->{mother};
}
sub win_name{
	return 'w_edit_pro';
}
1;
