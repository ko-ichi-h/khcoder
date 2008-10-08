package gui_window::word_mds;
use base qw(gui_window);

use strict;

use Tk;

use gui_widget::tani;
use gui_widget::hinshi;
use mysql_crossout;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt($self->label));

	my $lf = $win->LabFrame(
		-label => 'Options',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 1);

	my $left = $lf->Frame()->pack(-fill => 'both', -expand => 1);

	# 集計単位の選択
	my $l1 = $left->Frame()->pack(-fill => 'x', -pady => 2);
	$l1->Label(
		-text => $self->gui_jchar('・集計単位：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	my %pack = (
			-anchor => 'e',
			-pady   => 0,
			-side   => 'left'
	);
	$self->{tani_obj} = gui_widget::tani->open(
		parent => $l1,
		pack   => \%pack,
		#dont_remember => 1,
	);

	# 最小・最大出現数
	$left->Label(
		-text => $self->gui_jchar('・最小/最大 出現数による語の取捨選択'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 2);
	my $l2 = $left->Frame()->pack(-fill => 'x', -pady => 2);
	$l2->Label(
		-text => $self->gui_jchar('　 　最小出現数：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_min} = $l2->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_min}->insert(0,'1');
	$self->{ent_min}->bind("<Key-Return>",sub{$self->check;});
	$self->config_entry_focusin($self->{ent_min});
	
	$l2->Label(
		-text => $self->gui_jchar('　 最大出現数：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_max} = $l2->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_max}->bind("<Key-Return>",sub{$self->check;});
	$self->config_entry_focusin($self->{ent_max});

	# 最小・最大文書数
	$left->Label(
		-text => $self->gui_jchar('・最小/最大 文書数による語の取捨選択'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 2);

	my $l3 = $left->Frame()->pack(-fill => 'x', -pady => 2);
	$l3->Label(
		-text => $self->gui_jchar('　 　最小文書数：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_min_df} = $l3->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_min_df}->insert(0,'1');
	$self->{ent_min_df}->bind("<Key-Return>",sub{$self->check;});
	$self->config_entry_focusin($self->{ent_min_df});

	$l3->Label(
		-text => $self->gui_jchar('　 最大文書数：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_max_df} = $l3->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_max_df}->bind("<Key-Return>",sub{$self->check;});
	$self->config_entry_focusin($self->{ent_max_df});

	# 品詞による単語の取捨選択
	$left->Label(
		-text => $self->gui_jchar('・品詞による語の取捨選択'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 2);
	my $l5 = $left->Frame()->pack(-fill => 'both',-expand => 1, -pady => 2);
	$l5->Label(
		-text => $self->gui_jchar('　　'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left',-fill => 'y',-expand => 1);
	%pack = (
			-anchor => 'w',
			-side   => 'left',
			-pady   => 1,
			-fill   => 'y',
			-expand => 1
	);
	$self->{hinshi_obj} = gui_widget::hinshi->open(
		parent => $l5,
		pack   => \%pack
	);
	my $l4 = $l5->Frame()->pack(-fill => 'x', -expand => 'y',-side => 'left');
	$l4->Button(
		-text => $self->gui_jchar('全て選択'),
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $mw->after(10,sub{$self->{hinshi_obj}->select_all;});}
	)->pack(-pady => 3);
	$l4->Button(
		-text => $self->gui_jchar('クリア'),
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $mw->after(10,sub{$self->{hinshi_obj}->select_none;});}
	)->pack();

	# チェック部分
	$lf->Label(
		-text => $self->gui_jchar('・現在の設定で布置される語の数：'),
		-font => "TKFN"
	)->pack(-anchor => 'w');

	my $cf = $lf->Frame()->pack(-fill => 'x', -pady => 2);

	$cf->Label(
		-text => $self->gui_jchar('　 　'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');

	$cf->Button(
		-text => $self->gui_jchar('チェック'),
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $mw->after(10,sub{$self->check;});}
	)->pack(-side => 'left', -padx => 2);

	$self->{ent_check} = $cf->Entry(
		-font        => "TKFN",
		-background  => 'gray',
		-foreground  => 'black',
		-state       => 'disable',
	)->pack(-side => 'left', -fill => 'x', -expand => 1);
	$self->disabled_entry_configure($self->{ent_check});

	# アルゴリズム選択
	my $f4 = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);
	$f4->Label(
		-text => $self->gui_jchar('・方法：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	my $widget = gui_widget::optmenu->open(
		parent  => $f4,
		pack    => {-side => 'left'},
		options =>
			[
				['Classical', 'C'],
				['Kruskal',   'K'],
				['Sammon',    'S'],
			],
		variable => \$self->{method_opt},
	);
	$widget->set_value('K');

	$f4->Label(
		-text => $self->gui_jchar('  距離：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	my $widget_dist = gui_widget::optmenu->open(
		parent  => $f4,
		pack    => {-side => 'left'},
		options =>
			[
				['Jaccard', 'binary'],
				['Euclid',  'euclid'],
			],
		variable => \$self->{method_dist},
	);
	$widget_dist->set_value('binary');


	# 次元の数
	my $fnd = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 4,
	);

	$fnd->Label(
		-text => $self->gui_jchar('・次元：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_dim_number} = $fnd->Entry(
		-font       => "TKFN",
		-width      => 2,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_dim_number}->insert(0,'2');
	$self->{entry_dim_number}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_dim_number});

	$fnd->Label(
		-text => $self->gui_jchar('（1から3までの範囲で指定）'),
		-font => "TKFN",
	)->pack(-side => 'left');


	# フォントサイズ
	my $ff = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2,
	);

	$ff->Label(
		-text => $self->gui_jchar('・フォントサイズ：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_font_size} = $ff->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_font_size}->insert(0,'80');
	$self->{entry_font_size}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_font_size});

	$ff->Label(
		-text => $self->gui_jchar('%'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$ff->Label(
		-text => $self->gui_jchar('  プロットサイズ：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_plot_size} = $ff->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_plot_size}->insert(0,'640');
	$self->{entry_plot_size}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_plot_size});

	$win->Button(
		-text => $self->gui_jchar('キャンセル'),
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2, -pady => 2, -anchor => 'se');

	$win->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->calc;});}
	)->pack(-side => 'right', -pady => 2, -anchor => 'se');


	return $self;
}

#--------------#
#   チェック   #
sub check{
	my $self = shift;
	
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => '品詞が1つも選択されていません。',
		);
		return 0;
	}
	
	my $tani2 = '';
	if ($self->{radio} == 0){
		$tani2 = $self->gui_jg($self->{high});
	}
	elsif ($self->{radio} == 1){
		if ( length($self->{var_id}) ){
			$tani2 = mysql_outvar::a_var->new(undef,$self->{var_id})->{tani};
		}
	}
	
	my $check = mysql_crossout::r_com->new(
		tani   => $self->tani,
		tani2  => $tani2,
		hinshi => $self->hinshi,
		max    => $self->max,
		min    => $self->min,
		max_df => $self->max_df,
		min_df => $self->min_df,
	)->wnum;
	
	$self->{ent_check}->configure(-state => 'normal');
	$self->{ent_check}->delete(0,'end');
	$self->{ent_check}->insert(0,$check);
	$self->{ent_check}->configure(-state => 'disable');
}

#----------#
#   実行   #

sub calc{
	my $self = shift;
	
	# 入力のチェック
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => '品詞が1つも選択されていません。',
		);
		return 0;
	}

	my $check_num = mysql_crossout::r_com->new(
		tani     => $self->tani,
		tani2    => $self->tani,
		hinshi   => $self->hinshi,
		max      => $self->max,
		min      => $self->min,
		max_df   => $self->max_df,
		min_df   => $self->min_df,
	)->wnum;
	
	$check_num =~ s/,//g;
	#print "$check_num\n";

	if ($check_num < 5){
		gui_errormsg->open(
			type => 'msg',
			msg  => '少なくとも5つ以上の抽出語を選択して下さい。',
		);
		return 0;
	}

	if ($check_num > 200){
		my $ans = $self->win_obj->messageBox(
			-message => $self->gui_jchar
				(
					 '現在の設定では'.$check_num.'語が布置されます。'
					."\n"
					.'布置する語の数は100〜150程度におさえることを推奨します。'
					."\n"
					.'続行してよろしいですか？'
				),
			-icon    => 'question',
			-type    => 'OKCancel',
			-title   => 'KH Coder'
		);
		unless ($ans =~ /ok/i){ return 0; }
	}

	my $ans = $self->win_obj->messageBox(
		-message => $self->gui_jchar
			(
			   "この処理には時間がかかることがあります。\n".
			   "続行してよろしいですか？"
			),
		-icon    => 'question',
		-type    => 'OKCancel',
		-title   => 'KH Coder'
	);
	unless ($ans =~ /ok/i){ return 0; }

	#my $w = gui_wait->start;

	# データの取り出し
	my $r_command = mysql_crossout::r_com->new(
		tani   => $self->tani,
		tani2  => $self->tani,
		hinshi => $self->hinshi,
		max    => $self->max,
		min    => $self->min,
		max_df => $self->max_df,
		min_df => $self->min_df,
		rownames => 0,
	)->run;

	# データ整理
	$r_command .= "d <- t(d)\n";
	$r_command .= "# END: DATA\n";

	my $fontsize = $self->gui_jg( $self->{entry_font_size}->get );
	$fontsize /= 100;

	&make_plot(
		base_win       => $self,
		font_size      => $fontsize,
		plot_size      => $self->gui_jg( $self->{entry_plot_size}->get ),
		method         => $self->gui_jg( $self->{method_opt}  ),
		method_dist    => $self->gui_jg( $self->{method_dist} ),
		dim_number     => $self->gui_jg( $self->{entry_dim_number}->get ),
		r_command      => $r_command,
		plotwin_name   => 'word_mds',
	);
}

sub make_plot{
	my %args = @_;
	
	my $fontsize = $args{font_size};
	my $r_command = $args{r_command};

	unless ($args{dim_number} <= 3 && $args{dim_number} >= 1 ){
		gui_errormsg->open(
			type => 'msg',
			msg  => "次元の指定が不正です。1から3までの数値を指定して下さい。",
		);
		return 0;
	}

	$args{method_dist} = 'binary' unless $args{method_dist} eq 'euclid';

	$r_command .= "
check4mds <- function(d){
	jm <- as.matrix(dist(d, method=\"$args{method_dist}\"))
	jm[upper.tri(jm,diag=TRUE)] <- NA
	return( which(jm==0, arr.ind=TRUE)[,1][1] )
}

while ( is.na(check4mds(d)) == 0 ){
	n <-  check4mds(d)
	print( paste( \"Dropped object:\", row.names(d)[n]) )
	d <- d[-n,]
}
";

	if ($args{method_dist} eq 'euclid'){
		$r_command .= "d <- t( scale( t(d) ) )\n";
	}
	$r_command .= "dj <- dist(d,method=\"$args{method_dist}\")\n";

	# アルゴリズム別のコマンド
	my $r_command_d = '';
	my $r_command_a = '';
	if ($args{method} eq 'K'){
		$r_command .= "library(MASS)\n";
		$r_command .= "c <- isoMDS(dj, k=$args{dim_number})\n";
		$r_command .= "cl <- c\$points\n";
	}
	elsif ($args{method} eq 'S'){
		$r_command .= "library(MASS)\n";
		$r_command .= "c <- sammon(dj, k=$args{dim_number})\n";
		$r_command .= "cl <- c\$points\n";
	}
	elsif ($args{method} eq 'C'){
		$r_command .= "c <- cmdscale(dj, k=$args{dim_number})\n";
		$r_command .= "cl <- c\n";
	}

	# プロット用のコマンド（次元別）
	$r_command_d = $r_command;
	if ($args{dim_number} == 1){
		$r_command_d .=
			 "cl <- cbind(cl,0)\n"
			.'plot(cl, pch=20, col="mediumaquamarine",'
				.'xlab="次元1",ylab="")'."\n"
			."library(maptools)\n"
			.'pointLabel('
				.'x=cl[,1], y=cl[,2], labels=rownames(cl),'
				."cex=$fontsize, offset=0)\n";
		;
		$r_command_a .=
			 'plot(cl,'
				.'xlab="次元1",ylab="")'."\n"
		;
	}
	elsif ($args{dim_number} == 2){
		$r_command_d .=
			 'plot(cl,pch=20,col="mediumaquamarine",'
				.'xlab="次元1",ylab="次元2")'."\n"
			."library(maptools)\n"
			.'pointLabel('
				.'x=cl[,1], y=cl[,2], labels=rownames(cl),'
				."cex=$fontsize, offset=0)\n";
		;
		$r_command_a .=
			 'plot(cl,'
				.'xlab="次元1",ylab="次元2")'."\n"
		;
	}
	elsif ($args{dim_number} == 3){
		$r_command_d .=
			"library(scatterplot3d)\n"
			."s3d <- scatterplot3d(cl, type=\"h\", box=TRUE, pch=16,"
				."highlight.3d=FALSE, color=\"#FFA200FF\", "
				."col.grid=\"gray\", col.lab=\"black\", xlab=\"次元1\","
				."ylab=\"次元2\", zlab=\"次元3\", col.axis=\"#000099\","
				."mar=c(3,3,0,2), lty.hide=\"dashed\" )\n"
			."cl2 <- s3d\$xyz.convert(cl)\n"
			."library(maptools)\n"
			."pointLabel(x=cl2\$x, y=cl2\$y, labels=rownames(cl),"
				."cex=$fontsize, offset=0, col=\"black\")\n"
		;
		$r_command_a .=
			 "library(scatterplot3d)\n"
			."s3d <- scatterplot3d(cl, type=\"h\", box=TRUE, pch=16,"
				."highlight.3d=TRUE, mar=c(3,3,0,2), "
				."col.grid=\"gray\", col.lab=\"black\", xlab=\"次元1\","
				."ylab=\"次元2\", zlab=\"次元3\", col.axis=\"#000099\","
				."lty.hide=\"dashed\" )\n"
		;
	}

	$r_command .= $r_command_a;

	# プロット作成
	use kh_r_plot;
	my $plot1 = kh_r_plot->new(
		name      => $args{plotwin_name}.'_1',
		command_f => $r_command_d,
		width     => $args{plot_size},
		height    => $args{plot_size},
	) or return 0;
	my $plot2 = kh_r_plot->new(
		name      => $args{plotwin_name}.'_2',
		command_a => $r_command_a,
		command_f => $r_command,
		width     => $args{plot_size},
		height    => $args{plot_size},
	) or return 0;

	# 分析から省かれた語／コードをチェック
	my $dropped = '';
	foreach my $i (split /\n/, $plot1->r_msg){
		if ($i =~ /"Dropped object: (.+)"/){
			$dropped .= "$1, ";
		}
	}
	if ( length($dropped) ){
		chop $dropped;
		chop $dropped;
		$dropped = Jcode->new($dropped,'sjis')->euc
			if $::config_obj->os eq 'win32';
		gui_errormsg->open(
			type => 'msg',
			msg  => "以下の抽出語／コードは分析から省かれました：\n$dropped",
		);
	}

	# ストレス値の取得
	my $stress;
	if ($args{method} eq 'K' or $args{method} eq 'S'){
		$::config_obj->R->send(
			 'str <- paste("khcoder",c$stress, sep = "")'."\n"
			.'print(str)'
		);
		$stress = $::config_obj->R->read;

		if ($stress =~ /"khcoder(.+)"/){
			$stress = $1;
			$stress /= 100 if $args{method} eq 'K';
			$stress = sprintf("%.3f",$stress);
			$stress = "  stress = $stress";
		} else {
			$stress = undef;
		}
	}

	# プロットWindowを開く
	my $plotwin_id = 'w_'.$args{plotwin_name}.'_plot';
	if ($::main_gui->if_opened($plotwin_id)){
		$::main_gui->get($plotwin_id)->close;
	}
	$args{base_win}->close;
	my $plotwin = 'gui_window::r_plot::'.$args{plotwin_name};
	$plotwin->open(
		plots       => [$plot1, $plot2],
		msg         => $stress,
		no_geometry => 1,
	);
	
	return 1;
}

#--------------#
#   アクセサ   #


sub label{
	return '抽出語・多次元尺度法：オプション';
}

sub win_name{
	return 'w_word_mds';
}

sub min{
	my $self = shift;
	return $self->gui_jg( $self->{ent_min}->get );
}
sub max{
	my $self = shift;
	return $self->gui_jg( $self->{ent_max}->get );
}
sub min_df{
	my $self = shift;
	return $self->gui_jg( $self->{ent_min_df}->get );
}
sub max_df{
	my $self = shift;
	return $self->gui_jg( $self->{ent_max_df}->get );
}
sub tani{
	my $self = shift;
	return $self->{tani_obj}->tani;
}
sub hinshi{
	my $self = shift;
	return $self->{hinshi_obj}->selected;
}



1;