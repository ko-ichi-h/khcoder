package gui_window::doc_view;
use base qw(gui_window);
use strict;
use gui_jchar;
use Tk;
use Tk::ROTextANSIColor;
use mysql_getdoc;

sub _new{
	my $self = shift;
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
	)->pack(-fill => 'both', -expand => 'yes');

	$srtxt->bind("<Key>",[\&gui_jchar::check_key,Ev('K'),\$srtxt]);
	$srtxt->bind("<Button-1>",[\&gui_jchar::check_mouse,\$srtxt]);

	my $bframe = $bunhyojiwin->Frame(-borderwidth => 2) ->pack(
		-fill => 'x',-expand => 'no');

	$msg = '直前の文書'; Jcode::convert(\$msg,'sjis','euc');
	my $pre_btn = $bframe->Button(
		-text => $msg,
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub { $::mw->after
			(10,
				sub {
					
				}
			);
		}
	)->pack(-side => 'left',-pady => '0');

	$msg = '直後の文書'; Jcode::convert(\$msg,'sjis','euc');
	my $nxt_btn = $bframe->Button(
		-text => $msg,
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub { $::mw->after
			(10,
				sub {
					
				}
			);
		}
	)->pack(-side => 'left',-pady => '0');

	$msg = '　'; Jcode::convert(\$msg,'sjis','euc');
	$bframe->Label(-text => "$msg",
		-font => "TKFN")
		->pack(-anchor=>'w',-side => 'left');

	$msg = '前の検索結果'; Jcode::convert(\$msg,'sjis','euc');
	my $prev_result_btn = $bframe->Button(
		-text => $msg,
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub { $::mw->after
			(10,
				sub {
					
				}
			);
		}
	)->pack(-side => 'left',-pady => '0');

	$msg = '次の検索結果'; Jcode::convert(\$msg,'sjis','euc');
	my $next_result_btn = $bframe->Button(
		-text => $msg,
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub { $::mw->after
			(10,
				sub {
					
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
		-command => sub{ $::mw->after
			(10,
				sub {
					$self->close;
				}
			);
		}
	)->pack(-side => 'right',-pady => '0');
	
	$self->{text}    = $srtxt;
	$self->{win_obj} = $bunhyojiwin;
	return $self;
}

sub view{
	my $self = shift;
	my %args = @_;
	
	my $doc = mysql_getdoc->get(
		hyosobun_id => $args{hyosobun_id},
		w_search      => $args{kyotyo},
		tani        => $args{tani},
	);
	
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
}



sub win_name{ return 'w_doc_view'; }
sub text{ my $self = shift; return $self->{text}; }

1;
