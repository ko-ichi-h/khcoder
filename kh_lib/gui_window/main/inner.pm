package gui_window::main::inner;
use strict;

#----------------------#
#   Windowの中身作成   #
#----------------------#

sub make{
	my $class = shift;
	my $gui   = shift;
	my $self;
	my $mw = ${$gui}->mw;

	# プロジェクト情報
	my $fra1 = $mw->LabFrame(
		-label       => 'Project',
		-labelside   => 'acrosstop',
		-borderwidth => 2,
	)->pack(
		-fill   => 'x',
		-expand => '0',
		-anchor => 'n',
		-side   => 'top'
	);

	my $fra1a = $fra1->Frame(-borderwidth => 2) ->pack(-fill => 'x');
	my $fra1b = $fra1->Frame(-borderwidth => 2) ->pack(-fill => 'x');
	
	my $msg = Jcode->new('現在のプロジェクト：','euc')->sjis;
	$fra1a->Label(
		-text => "$msg",
		-font => "TKFN"
	)->pack(-anchor=>'w',-side=>'left');
	
	my $cupro = $fra1a->Entry(
		-width      => $::config_obj->mw_entry_length,
		-background => 'gray',
		-font       => 'TKFN',
		-state      => 'disable',
	)->pack(-anchor=>'e',-side=>'right');
	
	$msg = Jcode->new('説明（メモ）：','euc')->sjis;
	$fra1b->Label(
		-text => "$msg",
		-font => "TKFN"
	)->pack(-anchor=>'w',-side=>'left');

	my $cuprom = $fra1b->Entry(
		-width      => $::config_obj->mw_entry_length,
		-background => 'gray',
		-font       => 'TKFN',
		-state      => 'disable',
	)->pack(-anchor=>'e',-side=>'right');

	# データベース情報
	my $fra2 = $mw->LabFrame(
		-label       => 'Database Stats',
		-labelside   => 'acrosstop',
		-borderwidth => '2'
	)->pack(
		-fill   => 'both',
		-expand => 'yes',
		-anchor => 'n'
	);

	my $hlist = $fra2->Scrolled(
		'HList',
		-scrollbars         => 'osoe',
		-font               => 'TKFN',
		-selectmode         => 'none',
		-indicator          => 0,
		-command            => sub{$mw->after(10,sub{$self->unselect;});},
		-highlightthickness => 0,
		-columns            => 2,
		-borderwidth        => 0,
		-height             => 3,
	)->pack(-expand => '1', -fill => 'both');

	sub unselect{
		my $self = shift;
		$self->hlist->selectionClear();
		print "fuck\n";
	}

	$self->{e_curent_project} = $cupro;
	$self->{e_project_memo}   = $cuprom;
	$self->{hlist}            = $hlist;
	bless $self, $class;
	
#	$self->refresh;
	
	return $self;
}

#--------------------#
#   中身の書き換え   #
#--------------------#
sub refresh{
	my $self = shift;
	my $mw = $::main_gui->mw;

	$self->hlist->delete('all');
	my @list = (
		[Jcode->new('単語（種類）数：')->sjis,'n/a'],
		[Jcode->new('総単語数：')->sjis,'n/a'],
		[Jcode->new('使用単語（種類）数：　 ')->sjis,'n/a']
	);

	if ($::project_obj){
		my $title;
		if ( length($::project_obj->comment) ){
			$title = $::project_obj->comment;
		} else {
			$title = $::project_obj->file_short_name;
		}
		$title .= ' - KHC';
		$mw->title($title);
		$self->entry('e_curent_project', $::project_obj->file_short_name);
		$self->entry('e_project_memo', $::project_obj->comment);
		
		if ($::project_obj->status_morpho){
			@list = (
				[
					Jcode->new('単語（種類）数：')->sjis,
					num_format(mysql_words->num_kinds_all)
				],
				[
					Jcode->new('総単語数：')->sjis,
					num_format(mysql_words->num_all)
				],
				[
					Jcode->new('使用単語（種類）数：　 ')->sjis,
					num_format(mysql_words->num_kinds)
				]
			);
		}
	} else {
		$mw->title('KHC');
		$self->entry('e_curent_project', '');
		$self->entry('e_project_memo', '');
	}

	my $right = $self->hlist->ItemStyle('text',-anchor => 'e',-font => "TKFN");
	my $row = 0;
	foreach my $i (@list){
		$self->hlist->add($row,-at => $row);
		$self->hlist->itemCreate(
			$row,0,
			-itemtype  => 'text',
			-text      => $i->[0]
		);
		$self->hlist->itemCreate(
			$row,1,
			-itemtype  => 'text',
			-style     => $right,
			-text      => $i->[1]
		);
		++$row;
	}



}

#--------------#
#   アクセサ   #
#--------------#

# エントリー関係
# $obj->entry('entry_name','content');
# entry names: e_curent_project, e_project_memo, e_words_num

sub entry{
	my $self = shift;
	my $entry_name = shift;
	my $entry_cont = shift;
#	$entry_cont = Jcode->new(\$entry_cont,'euc')->sjis;
	
	my $ent = $self->{$entry_name};
	$ent->configure(-state,'normal');
	$ent->delete(0, 'end');
	$ent->insert('0',"$entry_cont");
	$ent->configure(-state,'disable');
}

sub hlist{
	my $self = shift;
	return $self->{hlist};
}

# 数字の3桁ごとにコンマを・・・
sub num_format{
	$_ = shift;
	1 while s/(.*\d)(\d\d\d)/$1,$2/;
	return $_;
}

1;
