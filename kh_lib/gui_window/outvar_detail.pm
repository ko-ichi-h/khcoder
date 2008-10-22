package gui_window::outvar_detail;
use base qw(gui_window);
use strict;
use Tk;

use mysql_outvar;

#---------------------#
#   Window オープン   #
#---------------------#

sub _new{
	my $self = shift;
	my %args = @_;
	
	my $mw = $::main_gui->mw;
	my $wmw= $self->{win_obj};

	$wmw->title($self->gui_jt("変数詳細： "."$args{name}"));

	my $fra4 = $wmw->LabFrame(
		-label => 'Values',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill=>'both', -expand => 'yes');

	my $fh = $fra4->Frame()->pack(-fill =>'both',-expand => 'yes');

	my $lis = $fh->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 1,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => 3,
		-padx             => 2,
		-background       => 'white',
		-selectforeground => 'black',
		-selectbackground => 'white',
		-selectmode       => 'single',
		-selectborderwidth=> 0,
		-height           => 10,
	)->pack(-fill =>'both',-expand => 'yes', -side => 'left');

	$lis->header('create',0,-text => $self->gui_jchar('値'));
	$lis->header('create',1,-text => $self->gui_jchar('ラベル'));
	$lis->header('create',2,-text => $self->gui_jchar('度数'));

	$lis->bind("<Shift-Double-1>", sub{$self->v_words;});
	$lis->bind("<Double-1>",       sub{$self->v_docs ;});
	$lis->bind("<Key-Return>",     sub{$self->v_docs ;});

	my $fhl = $fh->Frame->pack(-fill => 'x', -side => 'left');

	$fhl->Button(
		-text        => $self->gui_jchar('文書'),
		-font        => "TKFN",
		-borderwidth => '1',
		-width       => 4,
		-command     => sub{ $mw->after(10,sub {$self->v_docs;}); }
	)->pack(-padx => 2, -pady => 2, -anchor => 'c');

	$fhl->Button(
		-text        => $self->gui_jchar('特徴'),
		-font        => "TKFN",
		-borderwidth => '1',
		-width       => 4,
		-command     => sub{ $mw->after(10,sub {$self->v_words;}); }
	)->pack(-padx => 2, -pady => 2, -anchor => 'c');

	$wmw->Button(
		-text => $self->gui_jchar('キャンセル'),
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2);

	$wmw->Button(
		-text => $self->gui_jchar('OK'),
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->_save;});}
	)->pack(-side => 'right');

	# 情報の取得と表示
	$self->{var_obj} = mysql_outvar::a_var->new($args{name});
	my $v = $self->{var_obj}->detail_tab;
	my $n = 0;
	my $right = $lis->ItemStyle('text',
		-anchor           => 'e',
		-background       => 'white',
		-selectbackground => 'white',
		-activebackground => 'white',
	);
	my $left = $lis->ItemStyle('text',
		-anchor           => 'w',
		-background       => 'white',
		-selectbackground => 'white',
		-activebackground => 'white',
	);
	foreach my $i (@{$v}){
		$lis->add($n,-at => "$n");
		$lis->itemCreate(
			$n,
			0,
			-text  => $self->gui_jchar($i->[0]),
			-style => $left
		);
		$lis->itemCreate(
			$n,
			2,
			-text  => $self->gui_jchar($i->[2]),
			-style => $right
		);
		
		my $c = $lis->Entry(
			-font  => "TKFN",
			-width => 15
		);
		$lis->itemCreate(
			$n,1,
			-itemtype  => 'window',
			-widget    => $c,
		);
		$c->insert(0,$self->gui_jchar($i->[1]));
		$c->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$c]);
		
		$self->{entry}{$i->[0]} = $c;
		$self->{label}{$i->[0]} = $i->[1];
		++$n;
	}
	$wmw->bind('Tk::Entry', '<Key-Delete>', \&gui_jchar::check_key_e_d);

	# マニュアルに記載のない機能
	$self->win_obj->bind(
		'<Control-Key-h>',
		sub { $self->v_words_list; }
	);

	$self->{list} = $lis;
	return $self;
}

#--------------------#
#   ファンクション   #
#--------------------#

sub v_docs{
	my $self = shift;
	
	# クエリー作成
	my @selected = $self->list->infoSelection;
	unless(@selected){
		return 0;
	}
	my $query = $self->gui_jg( $self->list->itemCget($selected[0], 0, -text) );
	$query = Jcode->new($query, 'sjis')->euc;
	$query = '<>'.$self->{var_obj}->{name}.'-->'.$query;
	$query = $self->gui_jchar($query,'euc');
	
	# リモートウィンドウの操作
	my $win;
	if ($::main_gui->if_opened('w_doc_search')){
		$win = $::main_gui->get('w_doc_search');
	} else {
		$win = gui_window::doc_search->open;
	}
	
	$win->{tani_obj}->{raw_opt} = $self->{var_obj}->{tani};
	$win->{tani_obj}->mb_refresh;
	
	$win->{clist}->selectionClear;
	$win->{clist}->selectionSet(0);
	$win->clist_check;
	
	$win->{direct_w_e}->delete(0,'end');
	$win->{direct_w_e}->insert('end',$query);
	$win->win_obj->focus;
	$win->search;
}

sub v_words{
	my $self = shift;
	
	# クエリー作成
	my @selected = $self->list->infoSelection;
	unless(@selected){
		return 0;
	}
	my $query = $self->gui_jg( $self->list->itemCget($selected[0], 0, -text) );
	$query = Jcode->new($query, 'sjis')->euc;
	$query = '<>'.$self->{var_obj}->{name}.'-->'.$query;
	$query = $self->gui_jchar($query,'euc');
	
	# リモートウィンドウの操作
	my $win;
	if ($::main_gui->if_opened('w_doc_ass')){
		$win = $::main_gui->get('w_doc_ass');
	} else {
		$win = gui_window::word_ass->open;
	}
	
	$win->{tani_obj}->{raw_opt} = $self->{var_obj}->{tani};
	$win->{tani_obj}->mb_refresh;
	
	$win->{clist}->selectionClear;
	$win->{clist}->selectionSet(0);
	$win->clist_check;
	
	$win->{direct_w_e}->delete(0,'end');
	$win->{direct_w_e}->insert('end',$query);
	$win->win_obj->focus;
	$win->search;
}

sub v_words_list{
	my $self = shift;
	
	# 値のリスト
	my $values = $self->{var_obj}->print_values;
	
	# リモートウィンドウの準備
	my $win;
	if ($::main_gui->if_opened('w_doc_ass')){
		$win = $::main_gui->get('w_doc_ass');
	} else {
		$win = gui_window::word_ass->open;
	}
	
	my $d;
	# 値ごとに特徴的な語を取得
	foreach my $i (@{$values}){
		# クエリー作成
		my $query = '<>'.$self->{var_obj}->{name}.'-->'.$i;
		$query = $self->gui_jchar($query,'euc');
		
		# リモートウィンドウの操作
		$win->{tani_obj}->{raw_opt} = $self->{var_obj}->{tani};
		$win->{tani_obj}->mb_refresh;
		
		$win->{clist}->selectionClear;
		$win->{clist}->selectionSet(0);
		$win->clist_check;
		
		$win->{direct_w_e}->delete(0,'end');
		$win->{direct_w_e}->insert('end',$query);
		$win->win_obj->focus;
		$win->search;
		
		# 値の取得
		my $n = 0;
		while ($win->{rlist}->info('exists', $n)){
			if ( $win->{rlist}->itemExists($n, 1) ){
				$d->{$i}[$n][0] = kh_csv->value_conv(
					Jcode->new(
						$self->gui_jg(
								$win->{rlist}->itemCget($n, 1, -text)
						),
						'sjis'
					)->euc
				);
			}
			if ( $win->{rlist}->itemExists($n, 5) ){
				$d->{$i}[$n][1] = kh_csv->value_conv(
					Jcode->new(
						$self->gui_jg(
							$win->{rlist}->itemCget($n, 5, -text)
						),
						'sjis'
					)->euc
				);
			}
			++$n;
			last if $n > 10;
		}
	}
	
	# 出力用の整理
	my $t = '';
	foreach my $i (@{$values}){                             # ヘッダ
		$t .= kh_csv->value_conv($i).",,";
	}
	chop $t;
	$t .= "\n";
	print "head: $t\n\n";
	for (my $n = 0; $n <= 10; ++$n){                        # 中身
		foreach my $i (@{$values}){
			$t .= "$d->{$i}[$n][0],";
			$t .= "$d->{$i}[$n][1],";
		}
		chop $t;
		$t .= "\n";
	}
	$t = Jcode->new($t,'euc')->sjis if $::config_obj->os eq 'win32';
	
	# ファイルへ出力
	my $f = $::project_obj->file_TempCSV;
	open (TEMPCSV,">$f") or
		gui_errormsg->open(
			type => 'file',
			file => $f
		)
	;
	print TEMPCSV $t;
	close(TEMPCSV);
	
	gui_OtherWin->open($f);
}

sub _save{
	my $self = shift;
	
	# 変更されたラベルを保存
	foreach my $i (keys %{$self->{label}}){
		if (
			$self->{label}{$i}
			eq
			Jcode->new( $self->gui_jg($self->{entry}{$i}->get), 'sjis' )->euc
		){
			next;
		}
		$self->{var_obj}->label_save(
			Jcode->new($i)->euc,
			Jcode->new( $self->gui_jg($self->{entry}{$i}->get), 'sjis' )->euc,
		);
	}
	$self->close;
}

#--------------#
#   アクセサ   #
#--------------#

sub list{
	my $self = shift;
	return $self->{list};
}

sub win_name{
	return 'w_outvar_detail';
}


1;
