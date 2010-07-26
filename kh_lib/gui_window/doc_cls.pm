package gui_window::doc_cls;
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

	my $lf_w = $win->LabFrame(
		-label => 'Words',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 1);

	$self->{words_obj} = gui_widget::words->open(
		parent => $lf_w,
		verb   => '使用',
	);

	my $lf = $win->LabFrame(
		-label => 'Options',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x', -expand => 0);

	# クラスター数
	my $f4 = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);

	$f4->Label(
		-text => $self->gui_jchar('・距離：'),
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


	$f4->Label(
		-text => $self->gui_jchar('  クラスター数：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_cluster_number} = $f4->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_cluster_number}->insert(0,'10');
	$self->{entry_cluster_number}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_cluster_number});

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

	if ($check_num < 3){
		gui_errormsg->open(
			type => 'msg',
			msg  => '少なくとも3つ以上の抽出語を選択して下さい。',
		);
		return 0;
	}

	#if ($check_num > 500){
	#	my $ans = $self->win_obj->messageBox(
	#		-message => $self->gui_jchar
	#			(
	#				 '現在の設定では'.$check_num.'語が使用されます。'
	#				."\n"
	#				.'使用する語の数は200〜300程度におさえることを推奨します。'
	#				."\n"
	#				.'続行してよろしいですか？'
	#			),
	#		-icon    => 'question',
	#		-type    => 'OKCancel',
	#		-title   => 'KH Coder'
	#	);
	#	unless ($ans =~ /ok/i){ return 0; }
	#}

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

	# データの取り出し
	my $file_csv = $::project_obj->file_TempCSV;
	mysql_crossout::csv->new(
		file   => $file_csv,
		tani   => $self->tani,
		tani2  => $self->tani,
		hinshi => $self->hinshi,
		max    => $self->max,
		min    => $self->min,
		max_df => $self->max_df,
		min_df => $self->min_df,
	)->run;

	my $icode = Jcode->new($file_csv)->icode;
	$file_csv = Jcode->new($file_csv)->euc
		unless $icode eq 'euc' or $icode eq 'ascii';
	$file_csv =~ s/\\/\\\\/g;
	$file_csv = Jcode->new($file_csv)->$icode
		unless $icode eq 'euc' or $icode eq 'ascii';
	print "$file_csv\n";

	my $r_command = "d <- read.csv(\"$file_csv\")\n";
	$r_command .= &r_command_fix_d;



	$r_command .= "\n# END: DATA\n";

	&calc_exec(
		base_win       => $self,
		cluster_number => $self->gui_jg( $self->{entry_cluster_number}->get ),
		r_command      => $r_command,
		method_dist    => $self->gui_jg( $self->{method_dist} ),
		tani           => $self->tani,
	);
}

sub calc_exec{
	my %args = @_;

	my $r_command = $args{r_command};
	my $cluster_number = $args{cluster_number};

	# クラスター分析の結果を納めるファイル名
	my $file = $::project_obj->file_datadir.'_doc_cls_ward';
	my $icode;
	if ($::config_obj->os eq 'win32'){
		$file = Jcode->new($file,'sjis')->euc;
		$file =~ s/\\/\\\\/g;
	} else {
		$icode = Jcode::getcode($file);
		$file = Jcode->new($file, $icode)->euc unless $icode eq 'euc';
		$file =~ s/\\/\\\\/g;
		#$file = Jcode->new($file,'euc')->$icode unless $icode eq 'ascii';
	}

	# 類似度行列の作成（Rコマンド）
	$r_command .= "library(amap)\n";
	if ($args{method_dist} eq 'euclid'){
		# 文書ごとに標準化（文書のサイズ差による分類にならないように…）
		$r_command .= "d <- t( scale( t(d) ) )\n";
		$r_command .= "dj <- Dist(d,method=\"euclid\")^2\n";
	} else {
		$r_command .= "dj <- Dist(d,method=\"$args{method_dist}\")\n";
	}
	
	# 併合水準のプロット（Rコマンド）
	my $r_command_height = &r_command_height;
	
	# クラスター化（Rコマンド）
	my $r_command_ward;
	$r_command_ward .= "dcls <- hclust(dj, method=\"ward\")\n";
	$r_command_ward .= "r    <- cutree(dcls,k=$cluster_number)\n";

	my $r_command_ave;
	$r_command_ave .= "dcls <- hclust(dj, method=\"average\")\n";
	$r_command_ave .= "r    <- cbind(r, cutree(dcls,k=$cluster_number))\n";

	my $r_command_cmp;
	$r_command_cmp .= "dcls <- hclust(dj, method=\"complete\")\n";
	$r_command_cmp .= "r    <- cbind(r, cutree(dcls,k=$cluster_number))\n";

	# kh_r_plotモジュールにはEUCのRコマンドを渡す
	kh_r_plot->clear_env;
	my $plots;
	
	$plots->{_cluster_tmp_w} = kh_r_plot->new(
		name      => 'doc_cls_height_ward',
		command_f =>  $r_command
		             .$r_command_ward
		             .$r_command_height,
		width     => 640,
		height    => 480,
	);


	$plots->{_cluster_tmp_a} = kh_r_plot->new(
		name      => 'doc_cls_height_ave',
		command_f =>  $r_command
		             .$r_command_ave
		             .$r_command_height,
		command_a =>  $r_command_ave
		             .$r_command_height,
		width     => 640,
		height    => 480,
	);

	$plots->{_cluster_tmp_c} = kh_r_plot->new(
		name      => 'doc_cls_height_cmp',
		command_f =>  $r_command
		             .$r_command_cmp
		             .$r_command_height,
		command_a =>  $r_command_cmp
		             .$r_command_height,
		width     => 640,
		height    => 480,
	);
	
	# クラスター番号の書き出し（Rコマンド）
	my $r_command_fin = '';
	$r_command_fin .= "colnames(r) <- 
		c(\"_cluster_tmp_w\",\"_cluster_tmp_a\",\"_cluster_tmp_c\")\n";
	$r_command_fin .= "write.table(r, file=\"$file\", row.names=F, append=F, sep=\"\\t\", quote=F)\n";
	$r_command_fin .= "print(\"ok\")\n";

	$r_command_fin = Jcode->new($r_command_fin,'euc')->sjis
		if $::config_obj->os eq 'win32';

	$::config_obj->R->send($r_command_fin);
	my $r = $::config_obj->R->read;

	if (
		   ( $r =~ /error/i )
		or ( index($r, 'エラー') > -1 )
		or ( index($r, Jcode->new('エラー','euc')->sjis) > -1 )
	) {
		gui_errormsg->open(
			type   => 'msg',
			window  => \$::main_gui->mw,
			msg    => "計算に失敗しました\n\n".$r
		);
		return 0;
	}
	kh_r_plot->clear_env;

	$args{base_win}->close;
	if ($::main_gui->if_opened('w_doc_cls_res')){
		$::main_gui->get('w_doc_cls_res')->close;
	}

	# Rの計算結果を外部変数として読み込む
	foreach my $i (@{mysql_outvar->get_list}){
		if ($i->[1] =~ /^_cluster_tmp_[wac]$/){
			mysql_outvar->delete(name => $i->[1]);
		}
	}

	$file =~ s/\\\\/\\/g;
	if ($::config_obj->os eq 'win32'){
		$file = Jcode->new($file,'euc')->sjis;
	} else {
		$file = Jcode->new($file,'euc')->$icode unless $icode eq 'ascii';
	}

	mysql_outvar::read::tab->new(
		file     => $file,
		tani     => $args{tani},
		var_type => 'INT',
	)->read;

	gui_window::doc_cls_res->open(
		command_f => $r_command,
		tani      => $args{tani},
		plots     => $plots,
	);

	return 1;
}

#--------------#
#   アクセサ   #


sub label{
	return '文書・クラスター分析：オプション';
}

sub win_name{
	return 'w_doc_cls';
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

sub r_command_height{
	my $t = << 'END_OF_the_R_COMMAND';

pp_type <- "last" # first, last, all

# プロットの準備開始
pp_focus  <- 50     # 最初・最後の50回の併合をプロット
pp_kizami <-  5     # クラスター数を5個おきに表示するか

# 併合水準を取得
det <- dcls$merge
det <- cbind(1:nrow(det), nrow(det):1, det, dcls$height)
colnames(det) <- c("u_n", "cls_n", "u1", "u2", "height")

# 必要な部分の併合を取得
if (pp_type == "last"){
	n_start <- nrow(det) - pp_focus + 1
	if (n_start < 1){ n_start <- 1 }
	det <- det[nrow(det):n_start,]
} else if (pp_type == "first") {
	det <- det[pp_focus:1,]
}

# クラスター数のマーカーを入れる準備
p_type <- NULL
p_nums <- NULL
for (i in 1:nrow(det)){
	if ( (det[i,"cls_n"] %%  pp_kizami == 0) | (det[i,"cls_n"] == 1)){
		p_type <- c(p_type, 16)
		p_nums <- c(p_nums, det[i,"cls_n"])
	} else {
		p_type <- c(p_type, 1)
		p_nums <- c(p_nums, "")
	}
}

# プロット
par(mai=c(0,0,0,0), mar=c(4,4,1,1), omi=c(0,0,0,0), oma =c(0,0,0,0) )
plot(
	det[,"u_n"],
	det[,"height"],
	type = "b",
	pch  = p_type,
	xlab = paste("クラスター併合の段階（最後の",pp_focus,"回）",sep = ""),
	ylab = "併合水準（非類似度）"
)

text(
	x      = det[,"u_n"],
	y      = det[,"height"]
	         - ( max(det[,"height"]) - min(det[,"height"]) ) / 40,
	labels = p_nums,
	pos    = 4,
	offset = .2,
	cex    = .8
)

legend(
	min(det[,"u_n"]),
	max(det[,"height"]),
	legend = c("※プロット内の数値ラベルは\n　併合後のクラスター総数"),
	#pch = c(16),
	cex = .8,
	box.lty = 0
)

END_OF_the_R_COMMAND
return $t;
}

sub r_command_fix_d{
	my $t = << 'END_OF_the_R_COMMAND';

n_cut <- NULL
for (i in 1:12){
	if ( colnames(d)[i] == "length_w" ){
		n_cut <- i
		break
	}
}
n_cut <- n_cut * -1
d <- d[,-1:n_cut]

END_OF_the_R_COMMAND
return $t;
}

1;