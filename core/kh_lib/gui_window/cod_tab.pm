package gui_window::cod_tab;
use base qw(gui_window);

use strict;
use gui_widget::optmenu;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $mw->Toplevel;
	#$win->focus;
	$win->title($self->gui_jchar('コーディング・章 節 段落ごとの集計'));
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

#	$f0->Optionmenu(
#		-options => 
#			[
#				[ $self->gui_jchar('度数とパーセント') => 0 ],
#				[ $self->gui_jchar('度数のみ')         => 1 ],
#				[ $self->gui_jchar('パーセントのみ')   => 2 ],
#			],
#		-font => "TKFN",
#		-borderwidth => '1',
#		-width => 4,
#		-variable => \$self->{cell_opt},
#	)->pack(side=>'left');
	
	my $f1 = $lf->Frame->pack(-fill => 'x');
	
	# 単位選択
	my %pack = (
			-pady   => 3,
			-side   => 'left',
	);
	$self->{tani_obj} = gui_widget::tani2->open(
		parent => $f1,
		pack   => \%pack,
	);

	
	$f1->Button(
		-text    => $self->gui_jchar('集計'),
		-font    => "TKFN",
		-width   => 8,
		-command => sub{ $mw->after(10,sub{$self->_calc;});}
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

	$rf->Button(
		-text => $self->gui_jchar('コピー'),
		-font => "TKFN",
		-width => 8,
		-borderwidth => '1',
		-command => sub{ $mw->after(10,sub {gui_hlist->copy($self->list);});} 
	)->pack(-anchor => 'e', -pady => 1, -side => 'right');

	
	return $self;
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
	unless (
		   $self->tani1
		&& $self->tani2
		&& -e $self->cfile
	){
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
		$result = $result->tab(
			$self->tani1,
			$self->tani2,
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
					-text  => $self->gui_jchar($h,'sjis'),
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
					-text  => $self->gui_jchar($h,'sjis'),
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
sub tani1{
	my $self = shift;
	return $self->{tani_obj}->tani1;
}
sub tani2{
	my $self = shift;
	return $self->{tani_obj}->tani2;
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
	return 'w_cod_tab';
}
1;