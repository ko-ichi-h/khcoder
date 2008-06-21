package gui_window::morpho_check;
use base qw(gui_window);
use strict;
use Tk;
use Jcode;
use mysql_morpho_check;
use gui_window::morpho_detail;

#----------------#
#   Window描画   #

sub _new{
	my $self = shift;
	
	my $mw = $::main_gui->mw;
	my $wmw= $self->{win_obj};
	$wmw->title($self->gui_jt('語の抽出結果'));

	my $fra4 = $wmw->LabFrame(
		-label => 'Search Entry',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill=>'x');

	$fra4->Label(
		-text => $self->gui_jchar('・語の抽出（形態素解析）結果を確認したいフレーズ / 文を入力して下さい'),
		-font => "TKFN",
	)->pack(-anchor => 'w');

	# エントリと検索ボタンのフレーム
	my $fra4e = $fra4->Frame()->pack(-expand => 'y', -fill => 'x');
	my $e1 = $fra4e->Entry(
		-font => "TKFN",
		-background => 'white'
	)->pack(-expand => 'y', -fill => 'x', -side => 'left');
	$wmw->bind('Tk::Entry', '<Key-Delete>', \&gui_jchar::check_key_e_d);
	$e1->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$e1]);
	$e1->bind("<Key-Return>",sub{$self->search;});

	my $sbutton = $fra4e->Button(
		-text => $self->gui_jchar('検索'),
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->search;});} 
	)->pack(-side => 'right', -padx => '2');

	# 結果表示部分
	my $fra5 = $wmw->LabFrame(
		-label => 'Result',
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
		-command          => sub {$mw->after(10, sub{$self->detail;});},
		-height           => 20,
		-width            => 20,
	)->pack(-fill =>'both',-expand => 'yes');

	$lis->header('create',0,-text => 'ID');
	$lis->header('create',1,-text => $self->gui_jchar('文（分割済み）'));

	$fra5->Button(
		-text => $self->gui_jchar('コピー'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $mw->after(10,sub {gui_hlist->copy($self->list);});} 
	)->pack(-side => 'right');

	$self->{conc_button} = $fra5->Button(
		-text => $self->gui_jchar('詳細表示'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $mw->after(10,sub {$self->detail;});} 
	)->pack(-side => 'left');
	
	$self->{label} = $fra5->Label(
		-text => '    Ready.'
	)->pack(-side => 'left');
	$e1->focus;
	
	$self->{list_f} = $hlist_fra;
	$self->{list}  = $lis;
	$self->{entry}   = $e1;
	return $self;
}

#----------#
#   検索   #

sub search{
	my $self = shift;
	my $query = Jcode->new( $self->gui_jg($self->entry->get),'sjis')->euc;
	unless ($query){
		return;
	}
	$self->label->configure(-foreground => 'red', -text => 'Searching...');
	$self->win_obj->update;
	
	my $result = mysql_morpho_check->search(
		query   => $query,
	);
	
	$self->list->delete('all');
	my $row = 0;
	foreach my $i (@{$result}){
		$self->list->add($row,-at => "$row");
		$self->list->itemCreate($row,0,-text  => "$i->[1]");
		$self->list->itemCreate(
			$row,
			1,
			-text  => $self->gui_jchar("$i->[0]"),
		);
		++$row;
	}
	$self->label->configure(-foreground => 'black', -text => "    Ready.");
	$self->list->yview(0);
	$self->{result} = $result;
}

#--------------#
#   詳細表示   #

sub detail{
	my $self = shift;
	my @selected = $self->list->infoSelection;
	unless(@selected){
		return;
	}
	my $selected = $selected[0];
	$selected = $self->list->itemCget($selected, 0, -text);
	my $view_win = gui_window::morpho_detail->open;
	$view_win->view(
		query  => $selected,
		parent => $self
	);
}

sub next{
	my $self = shift;
	my @selected = $self->list->infoSelection;
	unless (@selected){
		return -1;
	}
	my $selected = $selected[0] + 1;
	my $max = @{$self->result} - 1;
	if ($selected > $max){
		$selected = $max;
	}
	my $num = $self->list->itemCget($selected, 0, -text);
	
	$self->list->selectionClear;
	$self->list->selectionSet($selected);
	$self->list->yview($selected);
	my $n = @{$self->result};
	if ($n - $selected > 7){
		$self->list->yview(scroll => -5, 'units');
	}
	
	return $num;
}
sub prev{
	my $self = shift;
	my @selected = $self->list->infoSelection;
	unless (@selected){
		return -1;
	}
	my $selected = $selected[0] - 1;
	if ($selected < 0){
		$selected = 0;
	}
	my $num = $self->list->itemCget($selected, 0, -text);

	$self->list->selectionClear;
	$self->list->selectionSet($selected);
	$self->list->yview($selected);
	my $n = @{$self->result};
	if ($n - $selected > 7){
		$self->list->yview(scroll => -5, 'units');
	}
	
	return $num;
}
sub if_next{
	my $self = shift;
	my @selected = $self->list->infoSelection;
	unless (@selected){
		return;
	}
	my $selected = $selected[0];
	my $max = @{$self->result} - 1;
	if ($selected < $max){
		return 1;
	} else {
		return 0;
	}
}
sub if_prev{
	my $self = shift;
	my @selected = $self->list->infoSelection;
	unless (@selected){
		return 0;
	}
	my $selected = $selected[0];
	if ($selected > 0){
		return 1;
	} else {
		return 0;
	}
}
sub end{
	my $check = 0;
	if ($::main_gui){
		$check = $::main_gui->if_opened('w_morpho_detail');
	}
	if ( $check ){
		$::main_gui->get('w_morpho_detail')->close;
	}
}



sub win_name{return 'w_morpho_check';}
sub list{
	my $self = shift;
	return $self->{list};
}
sub entry{
	my $self = shift;
	return $self->{entry};
}
sub label{
	my $self = shift;
	return $self->{label};
}
sub result{
	my $self = shift;
	return $self->{result};
}
1;
