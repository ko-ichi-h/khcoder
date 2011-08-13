package gui_window::outvar_list::midashi;
use base qw(gui_window::outvar_list);
use strict;

sub v_words_list{
	my $self      = shift;
	my $file_type = shift;
	
	unless ($self->{selected_var_obj}){
		$self->_error_no_var;
		return 0;
	}
	
	# ラベルの変更内容を保存して、外部変数オブジェクトを再生成
	#$self->_save;
	#$self->{selected_var_obj} = mysql_outvar::a_var->new(
	#	$self->{selected_var_obj}->{name}
	#);

	# 値のリスト
	my $values = mysql_getheader->get_selected(             # 値リストと頻度
		tani => $self->{selected_var_obj}{tani}
	);
	my %freq = ();
	my @values_org = ();
	foreach my $i (@{$values}){
		push @values_org, $i unless $freq{$i};
		++$freq{$i};
	}
	$values = \@values_org;

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

	# ここは今後要検討？
	my $hoge;
	$hoge->{name} = $self->{var_list}[$selection[0]][1];
	$hoge->{tani} = $self->{var_list}[$selection[0]][0];
	$self->{selected_var_obj} = $hoge;

	# 値とラベルの表示
	$self->{label} = undef;
	$self->{list_val}->delete('all');

	my $values = mysql_getheader->get_selected(             # 値リストと頻度
		tani => $self->{var_list}[$selection[0]][0]
	);
	my %freq = ();
	my @values_org = ();
	foreach my $i (@{$values}){
		push @values_org, $i unless $freq{$i};
		++$freq{$i};
	}

	#print "ok 1\n";
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
	my $gray = $self->{list_val}->ItemStyle('text',
		-anchor           => 'c',
		-foreground       => '#696969',
		-background       => 'white',
		-selectbackground => 'white',
		-activebackground => 'white',
	);
	foreach my $i (@values_org){
		$self->{list_val}->add($n,-at => "$n");
		#print "ok 1.5 $i\n";
		$self->{list_val}->itemCreate(
			$n,
			0,
			-text  => $self->gui_jchar($i),
			-style => $left
		);
		#print "ok 2\n";
		$self->{list_val}->itemCreate(
			$n,
			2,
			-text  => $freq{$i},
			-style => $right
		);
		#print "ok 3\n";

		#print "ok 4\n";
		$self->{list_val}->itemCreate(
			$n,1,
			-text  => 'n/a',
			-style => $gray,
		);
		#$c->insert(0,$self->gui_jchar($i->[1]));
		#$c->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$c]);
		#$c->bind(
		#	"<Key-Return>",
		#	sub{
		#		$self->{btn_save}->focus;
		#		#$self->{btn_save}->invoke;
		#	}
		#);
		
		#$self->{entry}{$i->[0]} = $c;
		#$self->{label}{$i->[0]} = $i->[1];
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
		$flag_t = 1 if ($self->{selected_var_obj}->{tani} eq $i);
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

	$self->{btn_save}->configure(-state => 'disabled');

	#gui_window::outvar_detail->open(
	#	tani => $self->{var_list}[$selection[0]][0],
	#	name => $self->{var_list}[$selection[0]][1],
	#);
}




1;