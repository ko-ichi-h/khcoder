package gui_window::project_new;
use base qw(gui_window);
use strict;
use Tk;

use gui_jchar;

#----------------------------#
#   新規プロジェクトWindow   #
#----------------------------#

sub _new{
	my $self = shift;

	# Minimize Console
	if (defined($PerlApp::VERSION) && substr($PerlApp::VERSION,0,1) >= 7 ){
		require Win32::API;
		my $FindWindow = new Win32::API('user32', 'FindWindow', 'PP', 'N');
		my $ShowWindow = new Win32::API('user32', 'ShowWindow', 'NN', 'N');
		my $hw = $FindWindow->Call( 0, 'Console of KH Coder' );
		$ShowWindow->Call( $hw, 7 );
	}

	my $mw = $self->{win_obj};
	$mw->title($self->gui_jt( kh_msg->get('win_title') ) );
	my $lfra = $mw->LabFrame(-label => 'Entry',-labelside => 'acrosstop',
		-borderwidth => 2,)
		->pack(-expand=>'yes',-fill=>'both');

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

	# Excel or CSV
	$self->{column_label} = $lfra->Label(
		-text => kh_msg->get('target_column'),
		-font => "TKFN"
	)->grid(-row => 1, -column => 0, -sticky => 'w', -pady=>2);
	
	my $fra4 = $lfra->Frame()->grid(-row => 1, -column => 1, -sticky => 'ew',-pady=>2);

	$self->{column_menu} = gui_widget::optmenu->open(
		parent  => $fra4,
		pack    => { -side => 'right', -padx => 2, -fill => 'x', -expand => 1},
		options =>
			[
				['N/A'  => 0],
			],
		variable => \$self->{column},
	);
	$self->{column_frame} = $fra4;

	$self->{column_label}->configure( -state => 'disabled' );
	$self->{column_menu}->configure( -state => 'disabled' );

	# language
	$lfra->Label(
		-text => kh_msg->get('lang', 'gui_window::stop_words'), # 言語
		-font => "TKFN"
	)->grid(-row => 2, -column => 0, -sticky => 'w', -pady=>2);
	
	my $fra3 = $lfra->Frame()->grid(-row => 2, -column => 1, -sticky => 'ew',-pady=>2);
	$self->{fra3} = $fra3;

	$self->{lang_menu} = gui_widget::optmenu->open(
		parent  => $fra3,
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
	$lfra->Label(
		-text => kh_msg->get('memo'),#$self->gui_jchar('説明（メモ）：'),
		-font => "TKFN"
	)->grid(-row => 3, -column => 0, -sticky => 'w', -pady=>2);;

	my $e2 = $lfra->Entry(
		-font => "TKFN",
		-background => 'white'
	)->grid(-row => 3, -column => 1, -sticky => 'ew',-pady=>2, -padx=>2);

	$mw->Button(
		-text => kh_msg->gget('cancel'),#$self->gui_jchar('キャンセル'),
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->close;}
	)->pack(-side => 'right',-padx => 2);

	$self->{ok_btn} = $mw->Button(
		-text => kh_msg->gget('ok'),
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->_make_new;}
	)->pack(-side => 'right');

	# ENTRYのバインド
	$e1->DropSite(
		-dropcommand => 
			[
				sub {
					&Gui_DragDrop::get_filename_droped;
					my $path = $self->gui_jg( $self->{e1}->get );
					$path = $::config_obj->os_path($path);
					$self->check_path($path);
				},
				$e1,
			],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);
	#$mw->bind('Tk::Entry', '<Key-Delete>', \&gui_jchar::check_key_e_d);
	#$e2->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$e2]);
	$e2->bind("<Key-Return>",sub{$self->_make_new;});
	$e2->bind("<KP_Enter>",sub{$self->_make_new;});
	
	$self->{e1}  = $e1;
	$self->{e2}  = $e2;

	#MainLoop;
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
		parent  => $self->{fra3}, #$fra3,
		width   => 19,
		pack    => { -side => 'right', -padx => 2},
		options => \@options,
		variable => \$self->{method},
		command => sub {}
	);

	return $self;
}

#--------------------#
#   ファンクション   #

sub _make_new{
	my $self = shift;
	my $from_table = 0;

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
		$from_table = 1;
		
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
			lang     => $self->{lang},
			#icode    => $self->{icode},
		);

		$t = $file_text;
	}

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

	# Excel / CSV (2)
	if ( $from_table ){
		# read variables
		mysql_outvar::read::tab->new(
			file        => $file_vars,
			tani        => 'h5',
			skip_checks => 1,
		)->read if -e $file_vars;

		# ignoring the separator string
		mysql_exec->do("
			INSERT INTO dmark (name) VALUES ('---cell---')
		",1);
		mysql_exec->do("
			INSERT INTO dstop (name) VALUES ('---cell---')
		",1);
		
		# some configurations
		$::project_obj->last_tani('h5');
		$::project_obj->status_from_table(1);
	} else {
		$::project_obj->status_from_table(0);
	}
	
	return 1;
}

sub _sansyo{
	my $self = shift;

	my @types = (
		[ "data files",[qw/.txt .xls .xlsx .csv .htm .html/] ],
		["All files",'*']
	);

	#print $::config_obj->cwd, "\n";
	my $path = $self->win_obj->getOpenFile(
		-filetypes  => \@types,
		-title      => $self->gui_jt( kh_msg->get('browse_target')),#'分析対象ファイルを選択してください'
		-initialdir => $self->gui_jchar($::config_obj->cwd),
	);

	if ($path){
		$path = $self->gui_jg_filename_win98($path);
		$path = $self->gui_jg($path);
		$self->e1->delete('0','end');
		$self->e1->insert(0,$self->gui_jchar($path));
		
		$path = $::config_obj->os_path($path);
		$self->check_path($path);
		
	}
}

sub check_path{
	my $self = shift;
	my $path = shift;
	
	# Excel / CSV
	if ($path =~ /\.(xls|xlsx|csv)$/i){
		$self->_columns($path);
	}
	# TXT / HTML
	else {
		# column selection interface
		$self->{column_label}->configure( -state => 'disable' );
		$self->{column_menu}->{win_obj}->destroy;
		$self->{column_menu} = undef;
		$self->{column_menu} = gui_widget::optmenu->open(
			parent  => $self->{column_frame},
			pack    => { -side => 'right', -padx => 2, -fill=>'x', -expand=>1},
			options =>
				[
					['N/A'  => 0],
				],
			variable => \$self->{column},
		);
		$self->{column_menu}->configure( -state => 'disable' );
		
	}
	
	return 1;
}

sub _columns{
	my $self = shift;
	my $path = shift;
	
	# column selection interface
	use kh_spreadsheet;
	my $columns = kh_spreadsheet->new($path)->columns();
	
	$self->{column_label}->configure( -state => 'normal' );
	$self->{column_menu}->{win_obj}->destroy;
	$self->{column_menu} = undef;
	
	my @options;
	my $n = 0;
	foreach my $i (@{$columns}){
		my $label = $i;
		if ( length($label) > 40 ){
			$label =
				substr($label, 0, 31)
				.'...'
				.substr($label, length($label)-6, 6)
			;
		}
		push @options, [$label, $n];
		++$n;
	}
	$self->{column_menu} = gui_widget::optmenu->open(
		parent   => $self->{column_frame},
		pack     => { -side => 'right', -padx => 2, -fill => 'x', -expand => 1},
		options  => \@options,
		variable => \$self->{column},
	);
	
	return $self;
}


#--------------#
#   アクセサ   #

sub e1{
	my $self = shift;
	return $self->{e1};
}
sub e2{
	my $self = shift;
	return $self->{e2};
}

sub win_name{
	return 'w_new_pro';
}


1;
