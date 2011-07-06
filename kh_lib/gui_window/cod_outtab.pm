package gui_window::cod_outtab;
use base qw(gui_window);
use strict;
use gui_widget::optmenu;
use mysql_outvar;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	#$win->focus;
	$win->title($self->gui_jt('コーディング・外部変数とのクロス集計'));
	
	#------------------------#
	#   オプション入力部分   #
	
	my $lf = $win->LabFrame(
		-label => 'Entry',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x');
	
	my $f0 = $lf->Frame->pack(-fill => 'x');
	# ルール・ファイル
	my %pack0 = (-side => 'left');
	$self->{codf_obj} = gui_widget::codf->open(
		parent => $f0,
		pack   => \%pack0
	);
	# セル内容選択
	$f0->Label(
		-text => $self->gui_jchar('　　セル内容：'),
		-font => "TKFN",
	)->pack(-side => 'left');
	
	gui_widget::optmenu->open(
		parent  => $f0,
		pack    => {-side => 'left'},
		options =>
			[
				[$self->gui_jchar('度数とパーセント') , 0],
				[$self->gui_jchar('度数のみ')         , 1],
				[$self->gui_jchar('パーセントのみ')   , 2],
			],
		variable => \$self->{cell_opt},
	);
	
	my $f1 = $lf->Frame->pack(-fill => 'x', -pady => 3);
	
	# 単位選択
	$f1->Label(
		-text => $self->gui_jchar('コーディング単位：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	my %pack = (
		-pady   => 3,
		-side   => 'left',
	);
	$self->{tani_obj} = gui_widget::tani->open(
		parent  => $f1,
		pack    => \%pack,
		command => sub{$self->fill;}
	);

	# 変数選択
	$f1->Label(
		-text => $self->gui_jchar(' 　クロスする変数：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	
	$self->{opt_frame} = $f1;
	
	$f1->Button(
		-text    => $self->gui_jchar('集計'),
		-font    => "TKFN",
		-width   => 8,
		-command => sub{$self->_calc;}
	)->pack( -anchor => 'e', -side => 'right');
	
	#------------------#
	#   結果表示部分   #

	my $rf = $win->LabFrame(
		-label => 'Result',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both',-expand => 'yes',-anchor => 'n');

	$self->{list_flame} = $rf->Frame()->pack(-fill => 'both',-expand => 1);
	
	$self->{list} = $self->{list_flame}->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 0,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => 3,
		-padx             => 2,
		-background       => 'white',
		-selectforeground => 'black',
		-selectbackground => 'cyan',
		-selectmode       => 'extended',
		-height           => 10,
	)->pack(-fill =>'both',-expand => 'yes');

	$self->{label} = $rf->Label(
		-text       => 'Ready.',
		-font       => "TKFN",
		-foreground => 'blue'
	)->pack(-side => 'left');

	$self->{copy_btn} = $rf->Button(
		-text => $self->gui_jchar('コピー（表全体）'),
		-font => "TKFN",
		#-width => 8,
		-borderwidth => '1',
		-command => sub { $self->copy; }
	)->pack(-anchor => 'e', -pady => 1, -side => 'right');

	$self->win_obj->bind(
		'<Control-Key-c>',
		sub{ $self->{copy_btn}->invoke; }
	);
	$self->win_obj->Balloon()->attach(
		$self->{copy_btn},
		-balloonmsg => 'Ctrl + C',
		-font => "TKFN"
	);

	$self->fill;
	return $self;
}

#----------------------------------#
#   利用できる変数のリストを表示   #
#----------------------------------#

sub fill{
	my $self = shift;
	unless ($self->{tani_obj}){return 0;}
	
	if ( ! $self->{var_obj} ){
		$self->{var_obj} =  gui_widget::select_a_var->open(
			parent        => $self->{opt_frame},
			tani          => $self->tani,
		);
	} else {
		$self->{var_obj}->new_tani( $self->tani );
	}
}

sub var_id{
	my $self = shift;
	return $self->{var_obj}->var_id;
}

#------------------#
#   集計ルーチン   #

sub _calc{
	my $self = shift;
	$self->label->configure(
		-text => 'Counting...',
		-foreground => 'red'
	);
	$self->win_obj->update;
	
	# 入力内容チェック
	unless ( $self->tani && -e $self->cfile && $self->var_id > -1){
		my $win = $self->win_obj;
		gui_errormsg->open(
			msg => "指定された条件での集計は行えません。",
			window => \$win,
			type => 'msg',
		);
		$self->rtn;
		return 0;
	}
	
	# 集計の実行

	my $result;
	unless ($result = kh_cod::func->read_file($self->cfile)){
		$self->rtn;
		return 0;
	}
	unless (
		$result = $result->outtab(
			$self->tani,
			$self->var_id,
			$self->{cell_opt}
		)
	){
		$self->rtn;
		return 0;
	}

	# 結果表示用のHList作成
	my $cols = @{$result->[0]};
	my $width = 0;
	foreach my $i (@{$result}){
		if ( length($i->[0]) > $width ){
			$width = length($i->[0]);
		}
	}
	
	$self->{list}->destroy if $self->{list};                # 古いものを廃棄
	$self->{list2}->destroy if $self->{list2};
	$self->{sb1}->destroy if $self->{sb1};
	$self->{sb2}->destroy if $self->{sb2};
	$self->{list_flame_inner}->destroy if $self->{list_flame_inner};

	$self->{list_flame_inner} = $self->{list_flame}->Frame( # 新たなリスト作成
		-relief      => 'sunken',
		-borderwidth => 2
	);
	$self->{list2} = $self->{list_flame_inner}->HList(
		-header             => 1,
		-itemtype           => 'text',
		-font               => 'TKFN',
		-columns            => 1,
		-padx               => 2,
		-background         => 'white',
		-selectbackground   => 'white',
		-selectforeground   => 'black',
		-selectmode         => 'extended',
		-height             => 10,
		-width              => $width,
		-borderwidth        => 0,
		-highlightthickness => 0,
	);
	$self->{list2}->header('create',0,-text => ' ');
	$self->{list} = $self->{list_flame_inner}->HList(
		-header             => 1,
		-itemtype           => 'text',
		-font               => 'TKFN',
		-columns            => $cols - 1,
		-padx               => 2,
		-background         => 'white',
		-selectforeground   => 'black',
		-selectmode         => 'extended',
		-height             => 10,
		-borderwidth        => 0,
		-highlightthickness => 0,
	);

	my $sb1 = $self->{list_flame}->Scrollbar(               # スクロール設定
		-orient  => 'v',
		-command => [ \&multiscrolly, $self->{sb1}, [$self->{list}, $self->{list2}]]
	);
	my $sb2 = $self->{list_flame}->Scrollbar(
		-orient => 'h',
		-command => ['xview' => $self->{list}]
	);
	$self->{list}->configure( -yscrollcommand => ['set', $sb1] );
	$self->{list}->configure( -xscrollcommand => ['set', $sb2] );
	$self->{list2}->configure( -yscrollcommand => ['set', $sb1] );
	$self->{sb1} = $sb1;
	$self->{sb2} = $sb2;

	$sb1->pack(-side => 'right', -fill => 'y');             # Pack
	$self->{list_flame_inner}->pack(-fill =>'both',-expand => 'yes');
	$self->{list2}->pack(-side => 'left', -fill =>'y', -pady => 0);
	$self->{list}->pack(-fill =>'both',-expand => 'yes', -pady => 0);
	$sb2->pack(-fill => 'x');

	# 結果の書き出し
	my $right_style = $self->list->ItemStyle(
		'text',
		-font => "TKFN",
		-anchor => 'e',
	);
	my $center_style = $self->list->ItemStyle(
		'text',
		-font => "TKFN",
		-anchor => 'c',
		-background => 'white',
	);
	
	# 一行目（Header）
	my $col = 0;
	foreach my $i (@{$result->[0]}){
		if ($col){
			my $w = $self->{list}->Label(
				-text               => $self->gui_jchar($i),
				-font               => "TKFN",
				-foreground         => 'black',
				#-background         => 'white',
				-padx               => 0,
				-pady               => 0,
				-borderwidth        => 0,
				-highlightthickness => 0,
			);
			$self->list->header(
				'create',
				$col - 1,
				-itemtype  => 'window',
				-widget    => $w,
			);
		}
		++$col;
	}
	$self->{result} = $result;
	my @result_inside = @{$result};
	shift @result_inside;
	
	my $row = 0;
	foreach my $i (@result_inside){
		$self->list->add($row,-at => "$row");
		$self->{list2}->add($row,-at => "$row");
		my $col = 0;
		foreach my $h (@{$i}){
			if ($col){
				$self->list->itemCreate(
					$row,
					$col -1,
					-text  => $self->gui_jchar($h,'sjis'),
					-style => $right_style
				);
			} else {
				$self->{list2}->itemCreate(
					$row,
					0,
					-text  => $self->gui_jchar($h,'sjis')
				);
			}
			++$col;
		}
		++$row
		;
	}
	
	
	$self->rtn;
}

sub rtn{
	my $self = shift;
	$self->label->configure(
		-text => 'Ready.',
		-foreground => 'blue'
	);
}

sub copy{
	my $self = shift;
	my $t = '';
	
	foreach my $i (@{$self->{result}}){
		my $n = 0;
		foreach my $h (@{$i}){
			$t .= "\t" if $n;
			$t .= $h;
			++$n;
		}
		$t .= "\n";
	}
	require Win32::Clipboard;
	my $CLIP = Win32::Clipboard();
	$CLIP->Set("$t");
}

sub multiscrolly{
	my ($sb,$wigs,@args) = @_;
	my $w;
	foreach $w (@$wigs){
		$w->yview(@args);
	}
}

#--------------#
#   アクセサ   #

sub cfile{
	my $self = shift;
	return $self->{codf_obj}->cfile;
}
sub tani{
	my $self = shift;
	return $self->{tani_obj}->tani;
}
sub label{
	my $self = shift;
	return $self->{label};
}
sub list{
	my $self = shift;
	return $self->{list};
}
sub list_frame{
	my $self = shift;
	return $self->{listframe};
}
sub win_name{
	return 'w_cod_outtab';
}
1;