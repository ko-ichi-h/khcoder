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

#------------------#
#   Windowを開く   #
#------------------#

sub _new{
	my $self = shift;
	my $class = 'gui_window::doc_view::'.$::config_obj->os;
	bless $self, $class;

	my $mw = $::main_gui->mw;
	my $bunhyojiwin = $::main_gui->mw->Toplevel;
	$bunhyojiwin->focus;
	my $msg = '文書表示'; Jcode::convert(\$msg,'sjis','euc');
	$bunhyojiwin->title("$msg");

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

	$msg = '直前の文書'; Jcode::convert(\$msg,'sjis','euc');
	$self->{pre_btn} = $bframe->Button(
		-text => $msg,
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

	$msg = '直後の文書'; Jcode::convert(\$msg,'sjis','euc');
	$self->{nxt_btn} = $bframe->Button(
		-text => $msg,
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

	$msg = '　'; Jcode::convert(\$msg,'sjis','euc');
	$bframe->Label(-text => "$msg",
		-font => "TKFN")
		->pack(-anchor=>'w',-side => 'left');

	$msg = '前の検索結果'; Jcode::convert(\$msg,'sjis','euc');
	$self->{pre_result_btn} = $bframe->Button(
		-text => $msg,
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub { $mw->after
			(10,
				sub {
					my ($hyosobun_id,$doc_id,$foot) = $self->{parent}->prev;
					if ( ! defined($doc_id) && $hyosobun_id <= 0){
						return;
					}
					$self->{foot} = $foot;
					$self->{doc} = mysql_getdoc->get(
						hyosobun_id => $hyosobun_id,
						doc_id      => $doc_id,
						w_search    => $self->{w_search},
						tani        => $self->{tani},
					);
					$self->{doc_id} = $self->{doc}->{doc_id};
					$self->_view_doc($self->{doc});
				}
			);
		}
	)->pack(-side => 'left',-pady => '0');

	$msg = '次の検索結果'; Jcode::convert(\$msg,'sjis','euc');
	$self->{nxt_result_btn} = $bframe->Button(
		-text => $msg,
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub { $mw->after
			(10,
				sub {
					my ($hyosobun_id,$doc_id,$foot) = $self->{parent}->next;
					if ( ! defined($doc_id) && $hyosobun_id <= 0){
						return;
					}
					$self->{foot} = $foot;
					$self->{doc} = mysql_getdoc->get(
						hyosobun_id => $hyosobun_id,
						doc_id      => $doc_id,
						w_search    => $self->{w_search},
						tani        => $self->{tani},
					);
					$self->{doc_id} = $self->{doc}->{doc_id};
					$self->_view_doc($self->{doc});
				}
			);
		}
	)->pack(-side => 'left',-pady => '0');

	$msg = '　'; Jcode::convert(\$msg,'sjis','euc');
	$bframe->Label(-text => "$msg",
		-font => "TKFN")
		->pack(-anchor=>'w',-side => 'left');


	$msg = '閉じる'; Jcode::convert(\$msg,'sjis','euc');
	$bframe->Button(
		-text => $msg,
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
		tani        => $args{tani},
	);
	$self->{doc}    = $doc;
	$self->{doc_id} = $doc->{doc_id};
	
	$self->_view_doc($doc);
}

sub check_codes{
	
}

sub near{
	my $self = shift;
	my $id = shift;
	my $doc = mysql_getdoc->get(
		doc_id   => $id,
		w_search => $self->{w_search},
		tani     => $self->{tani},
	);
	$self->{doc}    = $doc;
	$self->{doc_id} = $doc->{doc_id};
	$self->_view_doc($doc);

}

sub _view_doc{
	my $self = shift;
	my $doc = shift;
	my %color;                                    # 色情報準備
	foreach my $i ('info', 'search','html'){
		my $name = "color_DocView_".$i;
		$color{$i} = Term::ANSIColor::color($::config_obj->$name);
	}
	my $black = Term::ANSIColor::color('clear');
	
	$self->text->delete('0.0','end');             # 見出し書き出し
	$self->text->insert('end',"$color{info}".$doc->header."$black");
	
	my $t;                                        # 本文書き出し
	foreach my $i (@{$doc->body}){
		if ($color{$i->[1]}){
			$t .= "$color{$i->[1]}"."$i->[0]"."$black";
		} else {
			$t .= "$i->[0]";
		}
	}
	$self->text->insert('end',$t);
	
	$self->text->insert('end',"\n\n"."$color{info}"."$self->{foot}");
	
	$self->wrap;
	$self->update_buttons;
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


sub win_name{ return 'w_doc_view'; }
sub text{ my $self = shift; return $self->{text}; }

1;
