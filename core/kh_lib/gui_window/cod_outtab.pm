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
	my $win = $mw->Toplevel;
	$win->focus;
	$win->title(Jcode->new('コーディング・外部変数とのクロス集計')->sjis);
	$self->{win_obj} = $win;
	
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
		-text => Jcode->new('　　セル内容：')->sjis,
		-font => "TKFN",
	)->pack(side => 'left');
	
	gui_widget::optmenu->open(
		parent  => $f0,
		pack    => {-side => 'left'},
		options =>
			[
				[Jcode->new('度数とパーセント')->sjis , 0],
				[Jcode->new('度数のみ')->sjis         , 1],
				[Jcode->new('パーセントのみ')->sjis   , 2],
			],
		variable => \$self->{cell_opt},
	);
	
	my $f1 = $lf->Frame->pack(-fill => 'x', -pady => 3);
	
	# 単位選択
	$f1->Label(
		-text => Jcode->new('コーディング単位：')->sjis,
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
		-text => Jcode->new(' 　クロスする変数：')->sjis,
		-font => "TKFN"
	)->pack(-side => 'left');
	
	$self->{opt_frame} = $f1;
	
	$f1->Button(
		-text    => Jcode->new('集計')->sjis,
		-font    => "TKFN",
		-width   => 8,
		-command => sub{ $mw->after(10,sub{$self->_calc;});}
	)->pack( -anchor => 'e', side => 'right');
	
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
		text       => 'Ready.',
		font       => "TKFN",
		foreground => 'blue'
	)->pack(side => 'left');

	$rf->Button(
		-text => Jcode->new('コピー')->sjis,
		-font => "TKFN",
		-width => 8,
		-borderwidth => '1',
		-command => sub{ $mw->after(10,sub {gui_hlist->copy($self->list);});} 
	)->pack(-anchor => 'e', -pady => 1, -side => 'right');

	$self->fill;
	return $self;
}

#----------------------------------#
#   利用できる変数のリストを表示   #
#----------------------------------#

sub fill{
	my $self = shift;
	unless ($self->{tani_obj}){return 0;}
	
	if ($self->{opt_body}){
		$self->{opt_body}->destroy;
	}
	
	# 利用できる変数があるかどうかチェック
	my $h = mysql_outvar->get_list;
	my @options;
	foreach my $i (@{$h}){
		if ($i->[0] eq $self->tani){
			push @options, [Jcode->new($i->[1])->sjis, $i->[2]];
		}
	}
	
	if (@options){
		$self->{opt_body} = gui_widget::optmenu->open(
			parent  => $self->{opt_frame},
			pack    => {-side => 'left', -padx => 2},
			options => \@options,
			variable => \$self->{var_id},
		);
	} else {
		$self->{opt_body} = gui_widget::optmenu->open(
			parent  => $self->{opt_frame},
			pack    => {-side => 'left', -padx => 2},
			options => 
				[
					[Jcode->new('利用不可')->sjis, -1],
				],
			variable => \$self->{var_id},
		);
		$self->{opt_body}->configure(-state => 'disable');
	}
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
	unless ( $self->tani && -e $self->cfile && $self->{var_id} > -1){
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
			$self->{var_id},
			$self->{cell_opt}
		)
	){
		$self->rtn;
		return 0;
	}
	
	# 結果の書き出し
	
	my $cols = @{$result->[0]};
	$self->list->destroy;
	$self->{list} = $self->{list_flame}->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 0,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => $cols,
		-padx             => 2,
		-background       => 'white',
		-selectforeground => 'black',
		-selectmode       => 'extended',
		-height           => 10,
	)->pack(-fill =>'both',-expand => 'yes');
	
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
	
	my $row = 0;
	foreach my $i (@{$result}){
		$self->list->add($row,-at => "$row");
		my $col = 0;
		foreach my $h (@{$i}){
			if ($row == 0){
				$self->list->itemCreate(
					$row,
					$col,
					-text  => $h,
					-style => $center_style
				);
			}
			elsif ($col && $row){
				$self->list->itemCreate(
					$row,
					$col,
					-text  => $h,
					-style => $right_style
				);
			} else {
				$self->list->itemCreate(
					$row,
					$col,
					-text  => $h,
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