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

	my $mw = $self->{win_obj};
	$mw->title($self->gui_jt( kh_msg->get('win_title') ) );
	#$self->{win_obj} = $mw;
	my $lfra = $mw->LabFrame(-label => 'Entry',-labelside => 'acrosstop',
		-borderwidth => 2,)
		->pack(-expand=>'yes',-fill=>'both');
	my $fra1 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');
	my $fra3 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');
	my $fra4 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes',-pady => 2);
	my $fra2 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');

	$fra1->Label(
		-text => kh_msg->get('target_file'),#$self->gui_jchar('分析対象ファイル：'),
		-font => "TKFN"
	)->pack(-side => 'left');

	my $e1 = $fra1->Entry(
		-font => "TKFN",
		-background => 'white'
	)->pack(-side => 'right');

	$self->{icode_label} = $fra3->Label(
		-text => kh_msg->get('target_char_code'),#$self->gui_jchar('分析対象ファイルの文字コード：'),
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{icode_menu} = gui_widget::optmenu->open(
		parent  => $fra3,
		pack    => { -side => 'right', -padx => 2},
		options =>
			[
				[kh_msg->get('auto_detect')  => 0], #$self->gui_jchar('自動判別')
				[$self->gui_jchar('EUC') => 'euc'],
				[$self->gui_jchar('JIS') => 'jis'],
				[$self->gui_jchar('Shift-JIS') => 'sjis']
			],
		variable => \$self->{icode},
	);

	$self->{column_label} = $fra4->Label(
		-text => kh_msg->get('target_column'),
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{column_menu} = gui_widget::optmenu->open(
		parent  => $fra4,
		pack    => { -side => 'right', -padx => 2},
		options =>
			[
				['N/A'  => 0],
			],
		variable => \$self->{column},
	);
	$self->{column_frame} = $fra4;

	$self->{column_label}->configure( -state => 'disabled' );
	$self->{column_menu}->configure( -state => 'disabled' );


	$fra1->Button(
		-text => kh_msg->gget('browse'),#$self->gui_jchar('参照'),
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{$self->_sansyo;}
	)->pack(-side => 'right',-padx => 2);

	$fra2->Label(
		-text => kh_msg->get('memo'),#$self->gui_jchar('説明（メモ）：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	my $e2 = $fra2->Entry(
		-font => "TKFN",
		-background => 'white'
	)->pack(-side => 'right',-pady => 2);

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
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $e1,],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);
	#$mw->bind('Tk::Entry', '<Key-Delete>', \&gui_jchar::check_key_e_d);
	$e2->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$e2]);
	$e2->bind("<Key-Return>",sub{$self->_make_new;});
	$e2->bind("<KP_Enter>",sub{$self->_make_new;});
	
	$self->{e1}  = $e1;
	$self->{e2}  = $e2;

	#MainLoop;
	return $self;
}

#--------------------#
#   ファンクション   #

sub _make_new{
	my $self = shift;

	my $t = $::config_obj->os_path(
		$self->gui_jg(
			$self->e1->get
		)
	);

	# Excel / CSV (1)
	my $file_vars;
	if ($t =~ /(.+)\.(xls|xlsx|csv)$/i){
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
		);

		$t = $file_text;
	}

	my $new = kh_project->new(
		target  => $t,
		comment => $self->gui_jg($self->e2->get),
		icode   => $self->gui_jg($self->{icode}),
	) or return 0;
	kh_projects->read->add_new($new) or return 0;
	$self->close;

	$new->open or die;
	$::main_gui->close_all;
	$::main_gui->menu->refresh;
	$::main_gui->inner->refresh;
	
	# Excel / CSV (2)
	if (-e $file_vars){
		# read variables
		mysql_outvar::read::tab->new(
			file        => $file_vars,
			tani        => 'h5',
			skip_checks => 1,
		)->read;

		# ignoring the separator string
		mysql_exec->do("
			INSERT INTO dmark (name) VALUES ('---cell---')
		",1);
		mysql_exec->do("
			INSERT INTO dstop (name) VALUES ('---cell---')
		",1);
		
		# some configurations
		$new->last_tani('h5');
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
		$path = $::config_obj->os_path($path);
		$self->e1->delete('0','end');
		$self->e1->insert(0,$self->gui_jchar($path));
		
		# Excel / CSV
		if ($path =~ /\.(xls|xlsx|csv)$/i){
			# column selection interface
			use kh_spreadsheet;
			my $columns = kh_spreadsheet->new($path)->columns;
			
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
				pack     => { -side => 'right', -padx => 2},
				options  => \@options,
				variable => \$self->{column},
			);
			
			# character code selection
			if ($path =~ /\.(xls|xlsx)$/i){
				$self->{icode_label}->configure( -state => 'disable' );
				$self->{icode_menu} ->configure( -state => 'disable' );
			} else {
				$self->{icode_label}->configure( -state => 'normal' );
				$self->{icode_menu} ->configure( -state => 'normal' );
			}
		}
		# TXT / HTML
		else {
			# column selection interface
			$self->{column_label}->configure( -state => 'disable' );
			$self->{column_menu}->{win_obj}->destroy;
			$self->{column_menu} = undef;
			$self->{column_menu} = gui_widget::optmenu->open(
				parent  => $self->{column_frame},
				pack    => { -side => 'right', -padx => 2},
				options =>
					[
						['N/A'  => 0],
					],
				variable => \$self->{column},
			);
			$self->{column_menu}->configure( -state => 'disable' );
			
			# character code selection
			$self->{icode_label}->configure( -state => 'normal' );
			$self->{icode_menu} ->configure( -state => 'normal' );
		}
	}
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
