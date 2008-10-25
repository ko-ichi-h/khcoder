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
		-selectmode       => 'extended',
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

	my $mb = $fhl->Menubutton(
		-text        => $self->gui_jchar('一覧'),
		-tearoff     => 'no',
		-relief      => 'raised',
		-indicator   => 'no',
		-font        => "TKFN",
		#-width       => $self->{width},
		-borderwidth => 1,
	)->pack(-padx => 2, -pady => 2, -anchor => 'c');

	$mb->command(
		-command => sub {$self->v_words_list('xls')},
		-label   => $self->gui_jchar('Excel形式'),
	);

	$mb->command(
		-command => sub {$self->v_words_list('csv')},
		-label   => $self->gui_jchar('CSV形式'),
	);

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
	my $self      = shift;
	my $file_type = shift;
	
	# ラベルの変更内容を保存して、外部変数オブジェクトを再生成
	$self->__save;
	$self->{var_obj} = mysql_outvar::a_var->new( $self->{var_obj}->{name} );

	# 値のリスト
	my $values;
	foreach my $i (@{$self->{var_obj}->print_values}){
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


sub _save{
	my $self = shift;
	$self->__save;
	$self->close;
}

sub __save{
	my $self = shift;

	# 変更されたラベルを保存
	foreach my $i (keys %{$self->{label}}){
		if (
			$self->{label}{$i}
			eq
			Jcode->new( $self->gui_jg($self->{entry}{$i}->get), 'sjis' )->euc
		){
			# print "skip: ", $self->gui_jg($self->{entry}{$i}->get), "\n";
			next;
		}
		$self->{var_obj}->label_save(
			$i,
			Jcode->new( $self->gui_jg($self->{entry}{$i}->get), 'sjis' )->euc,
		);
		$self->{label}{$i} = Jcode->new(
			$self->gui_jg($self->{entry}{$i}->get), 'sjis'
		)->euc;
		# print "saved: ", $self->gui_jg($self->{entry}{$i}->get), "\n";
	}
	return $self;
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
