package gui_window::outvar_list;
use base qw(gui_window);
use strict;
use Tk;

use mysql_outvar;

# ラベル・エントリーにバインドを設定
# 「閉じる」を「読み込み」に


#---------------------#
#   Window オープン   #
#---------------------#

sub _new{
	my $self = shift;
	
	my $mw = $::main_gui->mw;
	my $wmw= $self->{win_obj};
	$wmw->title($self->gui_jt('外部変数と見出し'));

	my $fra4 = $wmw->Frame();
	my $adj  = $wmw->Adjuster(-widget => $fra4, -side => 'left');
	my $fra5 = $wmw->Frame();

	$fra4->pack(-side => 'left', -fill => 'both', -expand => 1, -padx => 2);
	$adj->pack (-side => 'left', -fill => 'y', -padx => 2, -pady => 2);
	$fra5->pack(-side => 'left', -fill => 'both', -expand => 1, -padx => 2);

	#----------------#
	#   変数リスト   #

	$fra4->Label(
		-text => $self->gui_jchar('■変数リスト'),
	)->pack(-anchor => 'nw');

	my $lis_vr = $fra4->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 1,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => 2,
		-padx             => 2,
		-background       => 'white',
		-selectmode       => 'extended',
		#-selectforeground   => '#800000',
		-selectbackground   => '#AFEEEE', # AFEEEE B0E0E6
		-selectborderwidth  => 0,
		-highlightthickness => 0,
		#-indicator => 0,
		#-command          => sub {$self->_open_var;},
		-browsecmd        => sub {$self->_delayed_open_var;},
		-height           => 10,
	)->pack(-fill =>'both',-expand => 1);

	$lis_vr->header('create',0,-text => $self->gui_jchar('文書単位'));
	$lis_vr->header('create',1,-text => $self->gui_jchar('変数名'));

	my $fra4_bts = $fra4->Frame()->pack(-fill => 'x', -expand => 0);

	#$fra4_bts->Button(
	#	-text => $self->gui_jchar('詳細'),
	#	-font => "TKFN",
#	#	-width => 8,
	#	-command => sub{$self->_open_var;}
	#)->pack(-anchor => 'ne', -side => 'right');

	$fra4_bts->Button(
		-text => $self->gui_jchar('削除'),
		-font => "TKFN",
#		-width => 8,
		-borderwidth => '1',
		-command => sub{$self->_delete;}
	)->pack(-padx => 2, -pady => 2, -anchor => 'nw', -side => 'left');

	$fra4_bts->Button(
		-text => $self->gui_jchar('出力'),
		-font => "TKFN",
#		-width => 8,
		-borderwidth => '1',
		-command => sub{$self->_export;}
	)->pack(-padx => 2, -pady => 2, -anchor => 'nw', -side => 'left');

	$fra4_bts->Button(
		-text => $self->gui_jchar('閉じる'),
		-font => "TKFN",
#		-width => 8,
		-borderwidth => '1',
		-command => sub{$self->close;}
	)->pack(-padx => 2, -pady => 2, -anchor => 'ne', -side => 'right');

	#----------------#
	#   変数の詳細   #

	my $fra5lab = $fra5->Frame()->pack(-anchor => 'w');

	$fra5lab->Label(
		-text => $self->gui_jchar('■選択した変数の値とラベル：'),
	)->pack(-side => 'left');

	$self->{label_name} = $fra5lab->Label(
		-text       => $self->gui_jchar('  '),
		-foreground => 'blue',
	)->pack(-side => 'left');

	my $lis = $fra5->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 1,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => 3,
		-padx             => 2,
		-background       => 'white',
		-selectforeground => 'black',
		-selectbackground => '#F0E68C',
		-selectmode       => 'browse',
		-selectborderwidth=> 0,
		-highlightthickness => 0,
		-height           => 10,
	)->pack(-fill =>'both',-expand => 'yes');

	$lis->header('create',0,-text => $self->gui_jchar('値'));
	$lis->header('create',1,-text => $self->gui_jchar('ラベル'));
	$lis->header('create',2,-text => $self->gui_jchar('度数'));

	$lis->bind("<Shift-Double-1>", sub{$self->v_words;});
	$lis->bind("<Double-1>",       sub{$self->v_docs ;});
	$lis->bind("<Key-Return>",     sub{$self->v_docs ;});

	$self->{list_val} = $lis;

	my $fra5_ets = $fra5->Frame()->pack(-fill => 'x', -expand => 0);
	my $fra5_bts = $fra5->Frame()->pack( -expand => 0, -anchor => 'w');
	$self->{opt_tani_fra} = $fra5_bts;

	#$fra5_ets->Label(
	#	-text => $self->gui_jchar('変数名（単位）：')
	#)->pack(-side => 'left');
	#
	#$self->{entry_name} = $fra5_ets->Entry(
	#	-state => 'disabled',
	#	-disabledbackground => 'gray',
	#	-background => 'gray',
	#	-disabledforeground => 'black',
	#)->pack(-side => 'left', -fill => 'x', -expand => 1);

	$fra5_ets->Button(
		-text        => $self->gui_jchar('ラベルの変更を保存'),
		-font        => "TKFN",
		-borderwidth => '1',
		-command     => sub {$self->_save;}
	)->pack(-padx => 2, -pady => 2, -fill => 'x');

	#$self->{label_num} = $fra5_ets->Label(
	#	-text => $self->gui_jchar('値の種類： 000')
	#)->pack(-padx => 2, -pady => 2, -side => 'left');

	my $btn_doc = $fra5_bts->Button(
		-text        => $self->gui_jchar('文書検索'),
		-font        => "TKFN",
		-borderwidth => '1',
		-command     => sub {$self->v_docs;}
	)->pack(-padx => 2, -pady => 2, -side => 'left');

	$wmw->Balloon()->attach(
		$btn_doc,
		-balloonmsg => $self->gui_jchar("特定の値を持つ文書を検索します\n[値をダブルクリック]"),
		-font       => "TKFN"
	);

	#my $btn_aso = $fra5_bts->Button(
	#	-text        => $self->gui_jchar('特徴語'),
	#	-font        => "TKFN",
	#	-borderwidth => '1',
	#	-command     => sub {$self->v_words;}
	#)->pack(-padx => 2, -pady => 2, -side => 'left');
	#
	#$wmw->Balloon()->attach(
	#	$btn_aso,
	#	-balloonmsg => $self->gui_jchar('特定の値を持つ文書を検索し、それらの文書に特徴的な語を探索します'),
	#	-font       => "TKFN"
	#);

	$fra5_bts->Label(
		-text => $self->gui_jchar('集計単位：')
	)->pack(-side => 'left');

	# ダミーを作っておく...
	$self->{opt_tani} = gui_widget::optmenu->open(
		parent  => $self->{opt_tani_fra},
		pack    => {-side => 'left', -padx => 2, -pady => 2},
		options => [
			[$self->gui_jchar('段落'), 'dan'],
			[$self->gui_jchar('文'  ), 'bun']
		],
		variable => \$self->{calc_tani},
	);

	my $mb = $fra5_bts->Menubutton(
		-text        => $self->gui_jchar('特徴語'),
		-tearoff     => 'no',
		-relief      => 'raised',
		-indicator   => 'no',
		-font        => "TKFN",
		#-width       => $self->{width},
		-borderwidth => 1,
	)->pack(-padx => 2, -pady => 2, -side => 'right');

	$mb->command(
		-command => sub {$self->v_words;},
		-label   => $self->gui_jchar('選択した値の特徴'),
	);

	$mb->command(
		-command => sub {$self->v_words_list('xls')},
		-label   => $self->gui_jchar('一覧： Excel'),
	);

	$mb->command(
		-command => sub {$self->v_words_list('csv')},
		-label   => $self->gui_jchar('一覧： CSV'),
	);

	$wmw->Balloon()->attach(
		$mb,
		-balloonmsg => $self->gui_jchar("特定の値を持つ文書に特徴的な語を探索します\n[Shift + 値をダブルクリック]"),
		-font       => "TKFN"
	);

	#$fra4_bts->Button(
	#	-text => $self->gui_jchar('閉じる'),
	#	-font => "TKFN",
	#	-width => 8,
	#	-command => sub{$self->close;}
	#)->pack(-side => 'right',-padx => 2);

	#MainLoop;
	
	$self->{list}    = $lis_vr;
	#$self->{win_obj} = $wmw;
	$self->_fill;
	return $self;
}

#----------------------------#
#   値関系のファンクション   #
#----------------------------#

sub _save{
	my $self = shift;

	return 0 unless $self->{selected_var_obj};

	# 変更されたラベルを保存
	foreach my $i (keys %{$self->{label}}){
		if (
			$self->{label}{$i}
			eq
			Jcode->new( $self->gui_jg($self->{entry}{$i}->get), 'sjis' )->euc
		){
			#print "skip: ", $self->gui_jg($self->{entry}{$i}->get), "\n";
			next;
		}
		$self->{selected_var_obj}->label_save(
			$i,
			Jcode->new( $self->gui_jg($self->{entry}{$i}->get), 'sjis' )->euc,
		);
		$self->{label}{$i} = Jcode->new(
			$self->gui_jg($self->{entry}{$i}->get), 'sjis'
		)->euc;
		#print "saved: ", $self->gui_jg($self->{entry}{$i}->get), "\n";
	}
	return $self;
}


sub v_docs{
	my $self = shift;
	
	unless ($self->{selected_var_obj}){
		$self->_error_no_var;
		return 0;
	}
	
	# クエリー作成
	my @selected = $self->{list_val}->infoSelection;
	unless(@selected){
		$self->{list_val}->selectionSet(0);
		@selected = $self->{list_val}->infoSelection;
	}
	my $query = $self->gui_jg( $self->{list_val}->itemCget($selected[0], 0, -text) );
	$query = Jcode->new($query, 'sjis')->euc;
	$query = '<>'.$self->{selected_var_obj}->{name}.'-->'.$query;
	$query = $self->gui_jchar($query,'euc');
	
	# リモートウィンドウの操作
	my $win;
	if ($::main_gui->if_opened('w_doc_search')){
		$win = $::main_gui->get('w_doc_search');
	} else {
		$win = gui_window::doc_search->open;
	}
	
	$win->{tani_obj}->{raw_opt} = $self->gui_jg( $self->{calc_tani} );
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
	
	unless ($self->{selected_var_obj}){
		$self->_error_no_var;
		return 0;
	}
	
	# クエリー作成
	my @selected = $self->{list_val}->infoSelection;
	unless(@selected){
		$self->{list_val}->selectionSet(0);
		@selected = $self->{list_val}->infoSelection;
	}
	my $query = $self->gui_jg(
		$self->{list_val}->itemCget($selected[0], 0, -text)
	);
	$query = Jcode->new($query, 'sjis')->euc;
	$query = '<>'.$self->{selected_var_obj}->{name}.'-->'.$query;
	$query = $self->gui_jchar($query,'euc');
	
	# リモートウィンドウの操作
	my $win;
	if ($::main_gui->if_opened('w_doc_ass')){
		$win = $::main_gui->get('w_doc_ass');
	} else {
		$win = gui_window::word_ass->open;
	}
	
	$win->{tani_obj}->{raw_opt} = $self->gui_jg( $self->{calc_tani} );
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
	my $self      = shift;
	my $file_type = shift;
	
	unless ($self->{selected_var_obj}){
		$self->_error_no_var;
		return 0;
	}
	
	# ラベルの変更内容を保存して、外部変数オブジェクトを再生成
	$self->_save;
	$self->{selected_var_obj} = mysql_outvar::a_var->new(
		$self->{selected_var_obj}->{name}
	);

	# 値のリスト
	my $values;
	foreach my $i (@{$self->{selected_var_obj}->print_values}){
		if ( $i eq '.' || $i =~ /missing/i || $i eq '欠損値' ){
			next;
		}
		push @{$values}, $i;
	}

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
		my $query = '<>'.$self->{selected_var_obj}->{name}.'-->'.$i;
		$query = $self->gui_jchar($query,'euc');
		
		# リモートウィンドウの操作
		$win->{tani_obj}->{raw_opt} = $self->gui_jg( $self->{calc_tani} );
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
				$d->{$i}[$n][0] = 
					Jcode->new(
						$self->gui_jg(
								$win->{rlist}->itemCget($n, 1, -text)
						),
						'sjis'
					)->euc
				;
			}
			if ( $win->{rlist}->itemExists($n, 5) ){
				$d->{$i}[$n][1] = 
					Jcode->new(
						$self->gui_jg(
							$win->{rlist}->itemCget($n, 5, -text)
						),
						'sjis'
					)->euc
				;
			}
			++$n;
			last if $n >= 10;
		}
	}
	
	$file_type = '_write_'.$file_type;
	$self->$file_type($values,$d);
}

sub _write_csv{
	my $self   = shift;
	my $values = shift;
	my $d      = shift;

	# 出力用の整理
	my $b_row_max = @{$values};
	$b_row_max /= 4;
	$b_row_max = int($b_row_max) + 1 if $b_row_max > int($b_row_max);
	
	my $t = '';
	for (my $b_row = 0; $b_row < $b_row_max; ++$b_row){
		my @c = ($b_row * 4, $b_row * 4 + 1, $b_row * 4 + 2, $b_row * 4 + 3);
		foreach my $i (@c){                                 # ヘッダ
			$t .= kh_csv->value_conv($values->[$i]).",,";
		}
		chop $t;
		$t .= "\n";
		for (my $n = 0; $n <= 10; ++$n){                    # 中身
			foreach my $i (@c){
				$t .= kh_csv->value_conv($d->{$values->[$i]}[$n][0]).",";
				$t .= "$d->{$values->[$i]}[$n][1],";
			}
			chop $t;
			$t .= "\n";
		}
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

sub _write_xls{
	my $self   = shift;
	my $values = shift;
	my $d      = shift;

	use Spreadsheet::WriteExcel;
	use Unicode::String qw(utf8 utf16);

	my $f    = $::project_obj->file_TempExcel;
	my $workbook  = Spreadsheet::WriteExcel->new($f);
	my $worksheet = $workbook->add_worksheet(
		utf8( Jcode->new('シート1')->utf8 )->utf16,
		1
	);

	my $font = '';
	if ($] > 5.008){
		$font = $self->gui_jchar('ＭＳ Ｐゴシック', 'euc');
	} else {
		$font = 'MS PGothic';
	}
	$workbook->{_formats}->[15]->set_properties(
		font       => $font,
		size       => 9,
		valign     => 'vcenter',
		align      => 'center',
	);
	my $format_n = $workbook->add_format(         # 数値
		num_format => '.000',
		size       => 9,
		font       => $font,
		align      => 'right',
	);
	my $format_nl = $workbook->add_format(        # 数値・下に罫線
		num_format => '.000',
		size       => 9,
		font       => $font,
		align      => 'right',
		bottom     => 1,
	);
	my $format_c = $workbook->add_format(         # 文字列
		font       => $font,
		size       => 9,
		align      => 'left',
		num_format => '@'
	);
	my $format_cl = $workbook->add_format(        # 文字列・下に罫線
		font       => $font,
		size       => 9,
		align      => 'left',
		bottom     => 1,
		num_format => '@'
	);
	my $format_l = $workbook->add_format(         # 上に罫線
		font       => $font,
		size       => 9,
		top        => 1,
		align      => 'center',
	);

	my $big_row = 0;
	my $col     = 0;
	my $n       = 0;
	foreach my $i (@{$values}){
		my $row = $big_row * 11 + 1;
		
		# ヘッダ
		my $format_m = $workbook->add_format(
			font          => $font,
			size          => 9,
			bottom        => 1,
			top           => 1,
			#align         => 'center',
			center_across => 1,
			num_format    => '@'
		);
		$worksheet->write_unicode(
			$row,
			$col,
			utf8( Jcode->new($i,'euc')->utf8 )->utf16,
			$format_m
		);
		$worksheet->write_blank(
			$row,
			$col + 1,
			$format_m
		);
		
		if ($col - 1 > 0){
			$worksheet->set_column($col - 1,$col - 1, 1);
			$worksheet->write_blank($row, $col - 1, $format_l);
		}
		
		++$row;
		
		# データ
		my $row_cu = 0;
		foreach my $h (@{$d->{$i}}){
			if ($row_cu == 9 && $n + 5 > @{$values}){       # 下に罫線あり
				$worksheet->write_unicode(
					$row,
					$col,
					utf8( Jcode->new($h->[0],'euc')->utf8 )->utf16,
					$format_cl
				);
				$worksheet->write_number(
					$row,
					$col + 1,
					$h->[1],
					$format_nl
				);
			} else {                                        # 罫線無し
				$worksheet->write_unicode(
					$row,
					$col,
					utf8( Jcode->new($h->[0],'euc')->utf8 )->utf16,
					$format_c
				);
				$worksheet->write_number(
					$row,
					$col + 1,
					$h->[1],
					$format_n
				);
			}
			++$row;
			++$row_cu;
		}
		
		# 下線(1)
		if ( $col - 1 > 0 && $n + 5 > @{$values} ){
			$worksheet->write_blank(
				$row - 1,
				$col - 1,
				$format_cl
			);
		}
		
		# 位置調整
		$col += 3;
		if ($col > 10){
			$col = 0;
			++$big_row;
		}
		++$n;
	}

	# 下線(2)
	if ($col > 0 && $col - 1 < 9 && $big_row > 0){
		$col -= 1;
		while ($col <= 10){
			$worksheet->write_blank(
				$big_row * 11 + 11,
				$col,
				$format_cl
			);
			++$col;
		}
	}


	$workbook->close;
	gui_OtherWin->open($f);
}

sub _error_no_var{
	my $self = shift;

	$self->win_obj->messageBox(
		-message => $self->gui_jchar('変数または見出しを選択してください。'),
		-icon    => 'info',
		-type    => 'Ok',
		-title   => 'KH Coder'
	);

}

#----------------------------#
#   変数系のファンクション   #
#----------------------------#

sub _fill{
	my $self = shift;
	
	my $h = mysql_outvar->get_list;
	
	$self->{list}->delete('all');
	my $n = 0;
	foreach my $i (@{$h}){
		if ($i->[0] eq 'dan'){$i->[0] = '段落';}
		if ($i->[0] eq 'bun'){$i->[0] = '文';}
		$self->{list}->add($n,-at => "$n");
		$self->{list}->itemCreate($n,0,-text => $self->gui_jchar($i->[0]),);
		$self->{list}->itemCreate($n,1,-text => $self->gui_jchar($i->[1]),);
		++$n;
		# my $chk = Jcode->new($i->[1])->icode;
		# print "$chk, $i->[1]\n";
	}
	$self->{var_list} = $h;
	gui_hlist->update4scroll($self->{list});
	return $self;
}

sub _delete{
	my $self = shift;
	my %args = @_;
	
	# 選択確認
	my @selection = $self->{list}->info('selection');
	unless (@selection){
		gui_errormsg->open(
			type => 'msg',
			msg  => '削除する変数を選択してください。',
		);
		return 0;
	}
	
	# 本当に削除するのか確認
	unless ( $args{no_conf} ){
		my $confirm = $self->{win_obj}->messageBox(
			-title   => 'KH Coder',
			-type    => 'OKCancel',
			#-default => 'OK',
			-icon    => 'question',
			-message => $self->gui_jchar('選択されている変数を削除しますか？'),
		);
		unless ($confirm =~ /^OK$/i){
			return 0;
		}
	}
	
	# 既に詳細Windowが開いている場合はいったん閉じる
	$::main_gui->get('w_outvar_detail')->close
		if $::main_gui->if_opened('w_outvar_detail');
	
	# 削除実行
	foreach my $i (@selection){
		mysql_outvar->delete(
			tani => $self->{var_list}[$i][0],
			name => $self->{var_list}[$i][1],
		);
	}
	$self->_fill;
	$self->_clear_values;
}

sub _export{
	my $self = shift;
	
	# 選択確認
	my @selection = $self->{list}->info('selection');
	unless (@selection){
		gui_errormsg->open(
			type => 'msg',
			msg  => '出力する変数を選択してください。',
		);
		return 0;
	}
	my @vars = (); my $last = '';
	foreach my $i (@selection){
		push @vars, $self->{var_list}[$i][1];
		
		$last = $self->{var_list}[$i][0] unless length($last);
		
		unless ($last eq $self->{var_list}[$i][0]){
			gui_errormsg->open(
				type => 'msg',
				msg  => '集計単位の異なる変数群を一度に保存することはできません。',
			);
			return 0;
		}
	}

	# 保存先ファイル名
	my @types = (
		['CSV Files',[qw/.csv/] ],
		["All files",'*']
	);
	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.csv',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt('「文書ｘ抽出語」表：名前を付けて保存'),
		-initialdir       => $self->gui_jchar($::config_obj->cwd)
	);
	unless ($path){
		return 0;
	}
	$path = gui_window->gui_jg_filename_win98($path);
	$path = gui_window->gui_jg($path);
	$path = $::config_obj->os_path($path);

	mysql_outvar->save(
		path => $path,
		vars => \@vars,
	);

	return 1;
}

# あまり速いペースでgui_widget::optmenuのdestroyを行うとエラーになる？ので、
# 少し待ってみて、選択が変わっていなかった場合のみ実行する（x 3）

sub _delayed_open_var{
	my $self = shift;

	#$self->{list}->anchorClear;

	my @selection = $self->{list}->info('selection');
	my $current = $self->{var_list}[$selection[0]][1];
	my $cn = @selection;

	$self->win_obj->after(80,sub{ $self->_chk1_open_var($current, $cn) });
}

sub _chk1_open_var{
	my $self   = shift;
	my $chk    = shift;
	my $chk_n  = shift;

	my @selection = $self->{list}->info('selection');
	my $current = $self->{var_list}[$selection[0]][1];
	my $cn = @selection;

	#print Jcode->new("1: $chk, $chk_n, $current, $cn\n")->sjis ;
	
	if ($chk eq $current && $chk_n == $cn){
		$self->win_obj->after(120,sub{ $self->_chk2_open_var($current, $cn) });
	}
}

sub _chk2_open_var{
	my $self   = shift;
	my $chk    = shift;
	my $chk_n  = shift;

	my @selection = $self->{list}->info('selection');
	my $current = $self->{var_list}[$selection[0]][1];
	my $cn = @selection;

	#print Jcode->new("2: $chk, $chk_n, $current, $cn\n")->sjis ;

	if ($chk eq $current && $chk_n == $cn){
		$self->win_obj->after(50,sub{ $self->_chk3_open_var($current, $cn) });
	}
}

sub _chk3_open_var{
	my $self   = shift;
	my $chk    = shift;
	my $chk_n  = shift;

	my @selection = $self->{list}->info('selection');
	my $current = $self->{var_list}[$selection[0]][1];
	my $cn = @selection;

	#print Jcode->new("2: $chk, $chk_n, $current, $cn\n")->sjis ;

	if ($chk eq $current && $chk_n == $cn){
		$self->_open_var;
	}
}

sub _open_var{
	my $self = shift;
	
	my @selection = $self->{list}->info('selection');
	unless (@selection){
		return 0;
	}
	return 1 if
		   $self->{selected_var_obj}->{name}
		eq $self->{var_list}[$selection[0]][1];

	#print "go!\n";

	# 変数名の表示
	$self->{label_name}->configure(
		-text => $self->gui_jchar(
			$self->{var_list}[$selection[0]][1]
		)
	);

	# 値とラベルの表示
	$self->{label} = undef;
	$self->{list_val}->delete('all');
	$self->{selected_var_obj} = mysql_outvar::a_var->new($self->{var_list}[$selection[0]][1]);
	my $v = $self->{selected_var_obj}->detail_tab;
	my $n = 0;
	my $right = $self->{list_val}->ItemStyle('text',
		-anchor           => 'e',
		-background       => 'white',
		-selectbackground => 'white',
		-activebackground => 'white',
	);
	my $left = $self->{list_val}->ItemStyle('text',
		-anchor           => 'w',
		-background       => 'white',
		-selectbackground => 'white',
		-activebackground => 'white',
	);
	foreach my $i (@{$v}){
		$self->{list_val}->add($n,-at => "$n");
		$self->{list_val}->itemCreate(
			$n,
			0,
			-text  => $self->gui_jchar($i->[0]),
			-style => $left
		);
		$self->{list_val}->itemCreate(
			$n,
			2,
			-text  => $self->gui_jchar($i->[2]),
			-style => $right
		);
		
		my $c = $self->{list_val}->Entry(
			-font  => "TKFN",
			-width => 15
		);
		$self->{list_val}->itemCreate(
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
	gui_hlist->update4scroll($self->{list_val});

	#$self->{label_num}->configure(
	#	-text => $self->gui_jchar("値の種類： $n")
	#);

	# 集計単位
	my @tanis   = ();
	if ($self->{opt_tani}){
		$self->{opt_tani}->destroy;
		$self->{opt_tani} = undef;
	}

	my %tani_name = (
		"bun" => "文",
		"dan" => "段落",
		"h5"  => "H5",
		"h4"  => "H4",
		"h3"  => "H3",
		"h2"  => "H2",
		"h1"  => "H1",
	);

	@tanis = ();
	my $flag_t = 0;
	foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
		$flag_t = 1 if ($self->{selected_var_obj}->tani eq $i);
		if (
			   $flag_t
			&& mysql_exec->select(
				   "select status from status where name = \'$i\'",1
			   )->hundle->fetch->[0]
		){
			push @tanis, [$self->gui_jchar($tani_name{$i}),$i];
		}
	}

	if (@tanis){
		$self->{opt_tani} = gui_widget::optmenu->open(
			parent  => $self->{opt_tani_fra},
			pack    => {-side => 'left', -padx => 2},
			options => \@tanis,
			variable => \$self->{calc_tani},
		);
	}

	#gui_window::outvar_detail->open(
	#	tani => $self->{var_list}[$selection[0]][0],
	#	name => $self->{var_list}[$selection[0]][1],
	#);
}

sub _clear_values{
	my $self = shift;
	
	$self->{selected_var_obj} = undef;
	$self->{label} = undef;
	
	$self->{label_name}->configure(
		-text => '  '
	);
	
	#$self->{label_num}->configure(
	#	-text => $self->gui_jchar('値の種類： 000')
	#);
	
	$self->{list_val}->delete('all');
	
	$self->{opt_tani}->destroy;
	$self->{opt_tani} = undef;
	
	return 1;
}

#--------------#
#   アクセサ   #
#--------------#


sub win_name{
	return 'w_outvar_list';
}


1;
