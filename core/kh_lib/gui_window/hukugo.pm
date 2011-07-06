package gui_window::hukugo;
use base qw(gui_window);
use mysql_hukugo;
use strict;
use Tk;

#------------------#
#   Windowを開く   #

sub _new{
	my $self = shift;
	$self->{win_obj}->title(
		$self->gui_jt('複合語の検出（茶筌）','euc')
	);

	# エントリと検索ボタンのフレーム
	my $fra4 = $self->{win_obj}->LabFrame(
		-label => 'Search Entry',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill=>'x');
	my $fra4e = $fra4->Frame()->pack(-expand => 'y', -fill => 'x');

	my $e1 = $fra4e->Entry(
		-font => "TKFN",
		-background => 'white'
	)->pack(-expand => 'y', -fill => 'x', -side => 'left');
	$self->{win_obj}->bind('Tk::Entry', '<Key-Delete>', \&gui_jchar::check_key_e_d);
	$e1->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$e1]);
	$e1->bind("<Key-Return>",sub{$self->search;});

	my $sbutton = $fra4e->Button(
		-text => $self->gui_jchar('検索','euc'),
		-font => "TKFN",
		-command => sub{$self->search;}
	)->pack(-side => 'right', -padx => '2');

	my $blhelp = $self->{win_obj}->Balloon();
	$blhelp->attach(
		$sbutton,
		-balloonmsg => '"ENTER" key',
		-font => "TKFN"
	);

	# オプション・フレーム
	my $fra4i = $fra4->Frame->pack(-expand => 'y', -fill => 'x');

	$self->{optmenu_andor} = gui_widget::optmenu->open(
		parent  => $fra4i,
		pack    => {-anchor=>'e', -side => 'left', -padx => 2},
		options =>
			[
				[$self->gui_jchar('OR検索','euc') , 'OR'],
				[$self->gui_jchar('AND検索','euc'), 'AND'],
			],
		variable => \$self->{and_or},
	);

	$self->{optmenu_bk} = gui_widget::optmenu->open(
		parent  => $fra4i,
		pack    => {-anchor=>'e', -side => 'left', -padx => 12},
		options =>
			[
				[$self->gui_jchar('部分一致','euc')  => 'p'],
				[$self->gui_jchar('完全一致','euc') => 'c'],
				[$self->gui_jchar('前方一致','euc') => 'z'],
				[$self->gui_jchar('後方一致','euc') => 'k']
			],
		variable => \$self->{s_mode},
	);

	# 結果表示部分
	my $fra5 = $self->{win_obj}->LabFrame(
		-label => 'Result (Top 500)',
		-labelside => 'acrosstop',
		-borderwidth => 2
	)->pack(-expand=>'yes',-fill=>'both');
	
	my $hlist_fra = $fra5->Frame()->pack(-expand => 'y', -fill => 'both');

	my $lis = $hlist_fra->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 1,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => 2,
		-padx             => 2,
		-background       => 'white',
		-selectforeground => 'brown',
		-selectbackground => 'cyan',
		-selectmode       => 'extended',
		-height           => 20,
	)->pack(-fill =>'both',-expand => 'yes');

	$lis->header('create',0,-text => $self->gui_jchar('複合語','euc'));
	$lis->header('create',1,-text => $self->gui_jchar('出現数','euc'));

	$fra5->Button(
		-text => $self->gui_jchar('コピー','euc'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {gui_hlist->copy($self->{list});}
	)->pack(-side => 'right');

	$self->{conc_button} = $fra5->Button(
		-text => $self->gui_jchar('全複合語のリスト','euc'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {$self->open_full_list;}
	)->pack(-side => 'left');
	
	$self->{list}  = $lis;
	$self->{entry}   = $e1;

	return $self;
}

#----------#
#   実行   #

sub search{
	my $self = shift;

	# 検索実行
	my $result = mysql_hukugo->search(
		query  => $self->gui_jg( $self->{entry}->get ),
		method => $self->gui_jg( $self->{and_or} ),
		mode   => $self->gui_jg( $self->{s_mode} ),
	);

	# 結果表示
	my $numb_style = $self->{list}->ItemStyle(
		'text',
		-anchor => 'e',
		-background => 'white',
		-font => "TKFN"
	);
	my $row = 0;
	$self->{list}->delete('all');

	foreach my $i (@{$result}){
		my $cu = $self->{list}->add($row,-at => "$row");
		$self->{list}->itemCreate(
			$cu,
			0,
			-text  => $self->gui_jchar($i->[0],,'euc'),
		);
		$self->{list}->itemCreate(
			$cu,
			1,
			-text  => $i->[1],
			-style => $numb_style
		);
		++$row;
	}

}

sub open_full_list{
	my $self = shift;
	my $debug = 1;

	my $target_csv = $::project_obj->file_HukugoList;
	gui_OtherWin->open($target_csv);
}

sub start{
	my $self = shift;
	$self->search;
	$self->{entry}->focus;
}

#--------------#
#   アクセサ   #

sub win_name{
	return 'w_hukugo';
}
1;