package gui_window::word_mds;
use base qw(gui_window);

use strict;
use Tk;

use gui_widget::tani;
use gui_widget::hinshi;
use mysql_crossout;
use kh_r_plot;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt($self->label));


	my $lf_w = $win->LabFrame(
		-label => 'Words',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 1, -side => 'left');

	$lf_w->Label(
		-text => gui_window->gui_jchar('■集計単位と語の選択'),
		-font => "TKFN",
		-foreground => 'blue'
	)->pack(-anchor => 'w', -pady => 2);

	$self->{words_obj} = gui_widget::words->open(
		parent => $lf_w,
		verb   => '布置',
	);

	my $lf = $win->LabFrame(
		-label => 'Options',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x', -expand => 0);

	$lf->Label(
		-text => $self->gui_jchar('■多次元尺度構成法の設定'),
		-font => "TKFN",
		-foreground => 'blue'
	)->pack(-anchor => 'w', -pady => 2);


	# アルゴリズム選択
	my $f4 = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);
	$f4->Label(
		-text => $self->gui_jchar('方法：'),
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
				['Cosine',  'pearson'],
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
		-text => $self->gui_jchar('次元：'),
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


	# バブルプロット
	$self->{bubble_obj} = gui_widget::bubble->open(
		parent       => $lf,
		type         => 'mds',
		command      => sub{ $self->calc; },
		pack    => {
			-anchor   => 'w',
		},
	);

	# クラスター化
	$self->{cls_obj} = gui_widget::cls4mds->open(
		parent       => $lf,
		command      => sub{ $self->calc; },
		pack    => {
			-anchor   => 'w',
		},
	);

	# フォントサイズ
	my $ff = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2,
	);

	$ff->Label(
		-text => $self->gui_jchar('フォントサイズ：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_font_size} = $ff->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_font_size}->insert(0,$::config_obj->r_default_font_size);
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

	$win->Checkbutton(
			-text     => $self->gui_jchar('実行時にこの画面を閉じない','euc'),
			-variable => \$self->{check_rm_open},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	$win->Button(
		-text => $self->gui_jchar('キャンセル'),
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->close;}
	)->pack(-side => 'right',-padx => 2, -pady => 2, -anchor => 'se');

	$win->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->calc;}
	)->pack(-side => 'right', -pady => 2, -anchor => 'se');


	return $self;
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

	if ($check_num < 5){
		gui_errormsg->open(
			type => 'msg',
			msg  => '少なくとも5つ以上の抽出語を選択して下さい。',
		);
		return 0;
	}

	if ($check_num > 150){
		my $ans = $self->win_obj->messageBox(
			-message => $self->gui_jchar
				(
					 '現在の設定では'.$check_num.'語が布置されます。'
					."\n"
					.'布置する語の数は100程度以下におさえることを推奨します。'
					."\n"
					.'続行してよろしいですか？'
				),
			-icon    => 'question',
			-type    => 'OKCancel',
			-title   => 'KH Coder'
		);
		unless ($ans =~ /ok/i){ return 0; }
	}

	$self->{words_obj}->settings_save;

	my $w = gui_wait->start;

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
		#base_win       => $self,
		font_size      => $fontsize,
		plot_size      => $self->gui_jg( $self->{entry_plot_size}->get ),
		method         => $self->gui_jg( $self->{method_opt}  ),
		method_dist    => $self->gui_jg( $self->{method_dist} ),
		dim_number     => $self->gui_jg( $self->{entry_dim_number}->get ),
		r_command      => $r_command,
		plotwin_name   => 'word_mds',
		bubble       => $self->{bubble_obj}->check_bubble,
		std_radius   => $self->{bubble_obj}->chk_std_radius,
		bubble_size  => $self->{bubble_obj}->size,
		bubble_var   => $self->{bubble_obj}->var,
		n_cls        => $self->{cls_obj}->n,
		cls_raw      => $self->{cls_obj}->raw,
	);
	
	$w->end(no_dialog => 1);
	
	unless ( $self->{check_rm_open} ){
		$self->close;
	}
}

sub make_plot{
	my %args = @_;
	
	my $fontsize = $args{font_size};
	my $r_command = $args{r_command};

	kh_r_plot->clear_env;

	unless ($args{dim_number} <= 3 && $args{dim_number} >= 1 ){
		gui_errormsg->open(
			type => 'msg',
			msg  => "次元の指定が不正です。1から3までの数値を指定して下さい。",
		);
		return 0;
	}

	#$args{method_dist} = 'binary' unless $args{method_dist} eq 'euclid';

	$r_command .= "
library(amap)
check4mds <- function(d){
	jm <- as.matrix(Dist(d, method=\"$args{method_dist}\"))
	jm[upper.tri(jm,diag=TRUE)] <- NA
	if ( length( which(jm==0, arr.ind=TRUE) ) ){
		return( which(jm==0, arr.ind=TRUE)[,1][1] )
	} else {
		return( NA )
	}
}

while ( is.na(check4mds(d)) == 0 ){
	n <-  check4mds(d)
	print( paste( \"Dropped object:\", row.names(d)[n]) )
	d <- d[-n,]
}
";

	if ($args{method_dist} eq 'euclid'){
		$r_command .= "dj <- Dist(t( scale( t(d) ) ),method=\"$args{method_dist}\")\n";
	} else {
		$r_command .= "dj <- Dist(d,method=\"$args{method_dist}\")\n";
	}

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
	$args{n_cls} = 0 unless ( length($args{n_cls}) );
	$args{cls_raw} = 0 unless ( length($args{cls_raw}) );
	
	$r_command_d = $r_command;

	$r_command_d .= "plot_mode <- \"color\"\n";
	$r_command_d .= "font_size <- $fontsize\n";
	$r_command_d .= "n_cls <- $args{n_cls}\n";
	$r_command_d .= "cls_raw <- $args{cls_raw}\n";
	$r_command_d .= "dim_n <- $args{dim_number}\n";
	
	$r_command_a .= "plot_mode <- \"dots\"\n";
	$r_command_a .= "font_size <- $fontsize\n";
	$r_command_a .= "n_cls <- $args{n_cls}\n";
	$r_command_a .= "cls_raw <- $args{cls_raw}\n";
	$r_command_a .= "dim_n <- $args{dim_number}\n";


	if ( $args{dim_number} <= 2){
		if ( $args{bubble} == 0 ){
			$r_command_d .= &r_command_plot;
			$r_command_a .= &r_command_plot;
		
			#$r_command_d .=
			#	 'plot(cl,pch=20,col="mediumaquamarine",'
			#		.'xlab="次元1",ylab="次元2")'."\n"
			#	."library(maptools)\n"
			#	.'pointLabel('
			#		.'x=cl[,1], y=cl[,2], labels=rownames(cl),'
			#		."cex=$fontsize, offset=0)\n";
			#;
			#$r_command_a .=
			#	 'plot(cl,'
			#		.'xlab="次元1",ylab="次元2")'."\n"
			#;
		} else {
			# バブル表現を行う場合
			$r_command_d .= "std_radius <- $args{std_radius}\n";
			$r_command_d .= "bubble_size <- $args{bubble_size}\n";
			$r_command_d .= "bubble_var <- $args{bubble_var}\n";
			$r_command_d .= &r_command_bubble;

			$r_command_a .= "std_radius <- $args{std_radius}\n";
			$r_command_a .= "bubble_size <- $args{bubble_size}\n";
			$r_command_a .= "bubble_var <- $args{bubble_var}\n";
			$r_command_a .= &r_command_bubble;
		}
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
	my $flg_error = 0;
	my $plot1 = kh_r_plot->new(
		name      => $args{plotwin_name}.'_1',
		command_f => $r_command_d,
		width     => $args{plot_size},
		height    => $args{plot_size},
	) or $flg_error = 1;
	my $plot2 = kh_r_plot->new(
		name      => $args{plotwin_name}.'_2',
		command_a => $r_command_a,
		command_f => $r_command,
		width     => $args{plot_size},
		height    => $args{plot_size},
	) or $flg_error = 1;

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

	my $txt = $plot1->r_msg;
	if ( length($txt) ){
		$txt = Jcode->new($txt)->sjis if $::config_obj->os eq 'win32';
		print "-------------------------[Begin]-------------------------[R]\n";
		print "$txt\n";
		print "---------------------------------------------------------[R]\n";
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
	kh_r_plot->clear_env;
	my $plotwin_id = 'w_'.$args{plotwin_name}.'_plot';
	if ($::main_gui->if_opened($plotwin_id)){
		$::main_gui->get($plotwin_id)->close;
	}
	
	return 0 if $flg_error;
	
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
	return $self->{words_obj}->min;
}
sub max{
	my $self = shift;
	return $self->{words_obj}->max;
}
sub min_df{
	my $self = shift;
	return $self->{words_obj}->min_df;
}
sub max_df{
	my $self = shift;
	return $self->{words_obj}->max_df;
}
sub tani{
	my $self = shift;
	return $self->{words_obj}->tani;
}
sub hinshi{
	my $self = shift;
	return $self->{words_obj}->hinshi;
}

sub r_command_plot{
	return '

ylab_text <- ""
if ( dim_n == 2 ){
	ylab_text <- "次元2"
}
if ( dim_n == 1 ){
	cl <- cbind(cl[,1],cl[,1])
}

col_base <- "mediumaquamarine"

# クラスター分析
if (n_cls > 0){
	library( RColorBrewer )
	if (cls_raw == 1){
		hcl <- hclust( dj, method="ward" )
	} else {
		hcl <- hclust( dist(cl,method="euclid")^2, method="ward" )
	}
	col_bg_words <- brewer.pal(12, "Set3")[cutree(hcl, k=n_cls)]
	col_base <- NA
}

plot(
	cl,
	pch=20,
	col=col_base,
	xlab="次元1",
	ylab=ylab_text,
	#bty="l",
)

if (n_cls > 0){
	symbols(
		cl[,1],
		cl[,2],
		circles=rep(1,length(cl[,1])),
		inches=0.1,
		fg="gray40",
		bg=col_bg_words,
		add=T,
	)
}

if ( plot_mode == "color" ){
	library(maptools)
	pointLabel(
		x=cl[,1],
		y=cl[,2],
		labels=rownames(cl),
		cex=font_size,
		offset=0
	)
}

';
}

sub r_command_bubble{
	return '

ylab_text <- ""
if ( dim_n == 2 ){
	ylab_text <- "次元2"
}
if ( dim_n == 1 ){
	cl <- cbind(cl[,1],cl[,1])
}


if (plot_mode == "color"){
	col_txt_words <- "black"
	col_dot_words <- "#00CED1"
	col_dot_vars  <- "#FF6347"
	col_bg_words  <- "white"
}

if (plot_mode == "dots"){
	col_txt_words <- NA
	col_dot_words <- "black"
	col_dot_vars  <- "black"
	col_bg_words  <- "white"
}

# バブルのサイズを決定
neg_to_zero <- function(nums){
  temp <- NULL
  for (i in 1:length(nums) ){
    if ( is.na( nums[i] ) ){
      temp[i] <- 1
    } else {
	    if (nums[i] < 1){
	      temp[i] <- 1
	    } else {
	      temp[i] <-  nums[i]
	    }
	}
  }
  return(temp)
}

b_size <- NULL
for (i in rownames(cl)){
	if ( is.na(i) || is.null(i) || is.nan(i) ){
		b_size <- c( b_size, 1 )
	} else {
		b_size <- c( b_size, sum( d[i,] ) )
	}
}

b_size <- sqrt( b_size / pi ) # 出現数比＝面積比になるように半径を調整

if (std_radius){ # 円の大小をデフォルメ
	b_size <- b_size / sd(b_size)
	b_size <- b_size - mean(b_size)
	b_size <- b_size * 5 * bubble_var / 100 + 10
	b_size <- neg_to_zero(b_size)
}

# クラスター分析
if (n_cls > 0){
	library( RColorBrewer )
	if (cls_raw == 1){
		hcl <- hclust( dj, method="ward" )
	} else {
		hcl <- hclust( dist(cl,method="euclid")^2, method="ward" )
	}
	col_bg_words <- brewer.pal(12, "Set3")[cutree(hcl, k=n_cls)]
	col_dot_words <- "gray40"
}

# バブル描画
plot(
	cl,
	pch=NA,
	col="black",
	xlab="次元1",
	ylab=ylab_text,
	#bty="l"
)

symbols(
	cl[,1],
	cl[,2],
	circles=b_size,
	inches=0.5 * bubble_size / 100,
	fg=col_dot_words,
	bg=col_bg_words,
	add=T,
)

# ラベル位置を決定
library(maptools)
labcd <- pointLabel(
	x=cl[,1],
	y=cl[,2],
	labels=rownames(cl),
	cex=font_size,
	offset=0,
	doPlot=F
)

# ラベル描画
if (plot_mode == "color") {
	text(
		labcd$x,
		labcd$y,
		rownames(cl),
		cex=font_size,
		offset=0,
		col=col_txt_words,
	)
}


';
}


1;