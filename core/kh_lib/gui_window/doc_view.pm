package gui_window::doc_view;
use base qw(gui_window);
use strict;
use Tk;
use Tk::Balloon;
use Tk::ROTextANSIColor;
use gui_jchar;
use mysql_getdoc;
use gui_window::word_conc;
use gui_window::doc_view::win32;
use gui_window::doc_view::linux;

my $ascii = '[\x00-\x7F]';
my $twoBytes = '[\x8E\xA1-\xFE][\xA1-\xFE]';
my $threeBytes = '\x8F[\xA1-\xFE][\xA1-\xFE]';

#------------------#
#   Windowを開く   #
#------------------#

sub _new{
	my $self = shift;
	my $class = 'gui_window::doc_view::'.$::config_obj->os;
	bless $self, $class;
	$self->_init;
	
	my $mw = $::main_gui->mw;
	my $bunhyojiwin = $::main_gui->mw->Toplevel;
	$bunhyojiwin->title($self->gui_jchar('文書表示'));

	my $srtxt = $bunhyojiwin->Scrolled(
		"ROTextANSIColor",
		spacing1 => 3,
		spacing2 => 2,
		spacing3 => 3,
		-scrollbars=> 'osoe',
		-height => 20,
		-width => 64,
		-wrap => 'word',
		-font => "TKFN",
		-background => 'white',
		-foreground => 'black'
	)->pack(-fill => 'both', -expand => 'yes');

	$srtxt->bind("<Key>",[\&gui_jchar::check_key,Ev('K'),\$srtxt]);
	$srtxt->bind("<Button-1>",[\&gui_jchar::check_mouse,\$srtxt]);

	my $bframe = $bunhyojiwin->Frame(-borderwidth => 2) ->pack(
		-fill => 'x',-expand => 'no');

	$self->{pre_btn} = $bframe->Button(
		-text => $self->gui_jchar('直前の文書'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub { $mw->after
			(10,
				sub {
					my $id = $self->{doc_id};
					--$id;
					$self->near($id);
				}
			);
		}
	)->pack(-side => 'left',-pady => '0');

	$self->{nxt_btn} = $bframe->Button(
		-text => $self->gui_jchar('直後の文書'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub { $mw->after
			(10,
				sub {
					my $id = $self->{doc_id};
					++$id;
					$self->near($id);
				}
			);
		}
	)->pack(-side => 'left',-pady => '0');

	$bframe->Label(
		-text => $self->gui_jchar('　'),
		-font => "TKFN"
	)->pack(-anchor=>'w',-side => 'left');

	$self->{pre_result_btn} = $bframe->Button(
		-text => $self->gui_jchar('前の検索結果'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub { $mw->after
			(10,
				sub {
					my ($hyosobun_id,$doc_id,$foot,$w) = $self->{parent}->prev;
					if ( ! defined($doc_id) && $hyosobun_id <= 0){
						return;
					}
					$self->{foot} = $foot;
					$self->{doc} = mysql_getdoc->get(
						hyosobun_id => $hyosobun_id,
						doc_id      => $doc_id,
						w_search    => $self->{w_search},
						w_force     => $self->{w_force},
						w_other     => $w,
						tani        => $self->{tani},
					);
					$self->{doc_id} = $self->{doc}->{doc_id};
					$self->_view_doc($self->{doc});
				}
			);
		}
	)->pack(-side => 'left',-pady => '0');

	$self->{nxt_result_btn} = $bframe->Button(
		-text => $self->gui_jchar('次の検索結果'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub { $mw->after
			(10,
				sub {
					my ($hyosobun_id,$doc_id,$foot,$w) = $self->{parent}->next;
					if ( ! defined($doc_id) && $hyosobun_id <= 0){
						return;
					}
					$self->{foot} = $foot;
					$self->{doc} = mysql_getdoc->get(
						hyosobun_id => $hyosobun_id,
						doc_id      => $doc_id,
						w_search    => $self->{w_search},
						w_force     => $self->{w_force},
						w_other     => $w,
						tani        => $self->{tani},
					);
					$self->{doc_id} = $self->{doc}->{doc_id};
					$self->_view_doc($self->{doc});
				}
			);
		}
	)->pack(-side => 'left',-pady => '0');

	$bframe->Label(
		-text => $self->gui_jchar('　'),
		-font => "TKFN"
	)->pack(-anchor=>'w',-side => 'left');

	$bframe->Button(
		-text => $self->gui_jchar('閉じる'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $mw->after
			(10,
				sub {
					$self->close;
				}
			);
		}
	)->pack(-side => 'right',-pady => '0');

	$bframe->Label(
		-text => ' ',
		-font => "TKFN"
	)->pack(-side => 'right');

	$bframe->Button(
		-text => $self->gui_jchar('強調'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $mw->after
			(10,
				sub {
					gui_window::force_color->open(
						parent => $self
					);
				}
			);
		}
	)->pack(-side => 'right',-pady => '0', -padx => 2);

	# バインド関係
	$bunhyojiwin->bind(
		"<Shift-Key-Prior>",
		sub { $self->{pre_btn}->invoke; }
	);
	$bunhyojiwin->bind(
		"<Shift-Key-Next>",
		sub { $self->{nxt_btn}->invoke; }
	);
	$bunhyojiwin->bind(
		"<Control-Key-Prior>",
		sub { $self->{pre_result_btn}->invoke; }
	);
	$bunhyojiwin->bind(
		"<Control-Key-Next>",
		sub { $self->{nxt_result_btn}->invoke; }
	);
	$bunhyojiwin->Balloon()->attach(
		$self->{pre_btn},
		-balloonmsg => '"Shift + PageUp"',
		-font => "TKFN"
	);
	$bunhyojiwin->Balloon()->attach(
		$self->{nxt_btn},
		-balloonmsg => '"Shift + PageDown"',
		-font => "TKFN"
	);
	$bunhyojiwin->Balloon()->attach(
		$self->{pre_result_btn},
		-balloonmsg => '"Ctrl + PageUp"',
		-font => "TKFN"
	);
	$bunhyojiwin->Balloon()->attach(
		$self->{nxt_result_btn},
		-balloonmsg => '"Ctrl + PageDown"',
		-font => "TKFN"
	);



	$self->{text}    = $srtxt;
	$self->{win_obj} = $bunhyojiwin;
	return $self;
}

#--------------------------#
#   文書の読み込み＆表示   #
#--------------------------#

# 通常の文書読み込み
sub view{
	my $self = shift;
	my %args = @_;
	$self->{w_search} = $args{kyotyo};
	$self->{tani}     = $args{tani};
	$self->{parent}   = $args{parent};
	$self->{foot}     = $args{foot};

	my $doc = mysql_getdoc->get(
		hyosobun_id => $args{hyosobun_id},
		doc_id      => $args{doc_id},
		w_search    => $args{kyotyo},
		w_other     => $args{kyotyo2},
		w_force     => $self->{w_force},
		tani        => $args{tani},
	);
	$self->{doc}    = $doc;
	$self->{doc_id} = $doc->{doc_id};
	
	$self->_view_doc($doc);
}

# 直前・直後の文書を読み込み
sub near{
	my $self = shift;
	my $id = shift;
	
	my ($t,$w);
	if ($self->{parent}{code_obj}){
		($t,$w) = $self->{parent}{code_obj}->check_a_doc($id);
	}
	$self->{foot} = $t;
	
	my $doc = mysql_getdoc->get(
		doc_id   => $id,
		w_search => $self->{w_search},
		w_force  => $self->{w_force},
		w_other  => $w,
		tani     => $self->{tani},
	);
	$self->{doc}    = $doc;
	$self->{doc_id} = $doc->{doc_id};
	$self->_view_doc($doc);

}

# 実際の表示用ルーチン
sub _view_doc{
	my $self = shift;
	my $doc = shift;
	my %color;                                    # 色情報準備
	foreach my $i ('info', 'search','html','CodeW','force'){
		my $name = "color_DocView_".$i;
		$color{$i} = Term::ANSIColor::color($::config_obj->$name);
	}
	my $black = Term::ANSIColor::color('clear');
	
	$self->text->delete('0.0','end');             # 見出し書き出し
	$self->text->insert('end',"$color{info}".$self->gui_jchar($doc->header,'sjis')."$black");
	
	my $t;                                        # 本文書き出し
	my $buffer;
	foreach my $i (@{$doc->body}){
		if ($color{$i->[1]}){
			if (length($buffer)){
				$t .= $self->_str_color($buffer);
				$buffer = '';
			}
			
			$t .= "$color{$i->[1]}".$self->gui_jchar("$i->[0]",'sjis')."$black";
		} else {
			$buffer .= $self->gui_jchar("$i->[0]",'sjis');
		}
	}
	$t .= $self->_str_color($buffer);

	$self->text->insert('end',$t);
	$self->text->insert('end',"\n\n"."$color{info}".$self->gui_jchar("$self->{foot}",'euc'));
	
	$self->wrap;
	$self->update_buttons;
}

# 文字列強調ルーチン
sub _str_color{
	my $self = shift;
	my $str  = shift;
	
	my $black = Term::ANSIColor::color('clear');
	my $color = Term::ANSIColor::color($::config_obj->color_DocView_force);
	
	$str = Jcode->new($str)->euc;
	foreach my $i (@{$self->{str_force}}){
		my $pat = $i;
		my $rep = $color.$i.$black;
		$str =~ s/\G((?:$ascii|$twoBytes|$threeBytes)*?)(?:$pat)/$1$rep/g;
	}
	$str = Jcode->new($str)->sjis;
	return $str;
}

# 再描画ルーチン
sub refresh{
	my $self = shift;
	
	# 設定の読み込み
	$self->_init;
	
	# 文書再取得
	my ($t,$w);
	if ($self->{parent}{code_obj}){
		($t,$w) = $self->{parent}{code_obj}->check_a_doc($self->{doc_id});
	}
	$self->{foot} = $t;
	my $doc = mysql_getdoc->get(
		doc_id   => $self->{doc_id},
		w_search => $self->{w_search},
		w_force  => $self->{w_force},
		w_other  => $w,
		tani     => $self->{tani},
	);
	$self->{doc}    = $doc;
	
	# 表示
	$self->_view_doc($doc);
}

#------------#
#   その他   #
#------------#

sub _init{
	my $self = shift;
	my @l;
	
	# 強調語の取得
	my $h = mysql_exec->select(
		"SELECT name FROM d_force WHERE type=1",
		1
	)->hundle;
	while (my $i = $h->fetch){
		my $list = mysql_a_word->new(
			genkei => $i->[0]
		)->hyoso_id_s;
		if ($list){
			@l = (@l,@{$list});
		}
	}
	$self->{w_force} = \@l;
	
	# 強調文字列の取得
	$self->{str_force} = undef;
	my $h = mysql_exec->select(
		"SELECT name FROM d_force WHERE type=0 ORDER BY id",
		1
	)->hundle;
	while (my $i = $h->fetch){
		push @{$self->{str_force}}, $i->[0]
	}

	return $self;
}

sub wrap{
	return 1;
}

sub update_buttons{
	my $self = shift;
	
	# 直後ボタン
	if ($self->{doc}->if_next){
		$self->{nxt_btn}->configure(-state, 'normal');
	} else {
		$self->{nxt_btn}->configure(-state, 'disable');
	}
	# 直前ボタン
	if ($self->{doc_id} > 1){
		$self->{pre_btn}->configure(-state, 'normal');
	} else {
		$self->{pre_btn}->configure(-state, 'disable');
	}
	
	# 次の結果
	if ($self->{parent}->if_next){
		$self->{nxt_result_btn}->configure(-state, 'normal');
	} else {
		$self->{nxt_result_btn}->configure(-state, 'disable');
	}
	# 前の結果
	if ($self->{parent}->if_prev){
		$self->{pre_result_btn}->configure(-state, 'normal');
	} else {
		$self->{pre_result_btn}->configure(-state, 'disable');
	}
}


sub win_name{
	return 'w_doc_view'; 
}
sub text{
	my $self = shift; return $self->{text};
}

1;
