package gui_window::doc_cls;
use base qw(gui_window);

use strict;
use Tk;

use gui_window::doc_cls::clara;
use gui_window::doc_cls::ward;
use gui_window::doc_cls::complete;
use gui_window::doc_cls::average;

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
		verb   => kh_msg->get('verb'), # 使用
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
		-text => kh_msg->get('gui_widget::r_cls->method'), # 方法：
		-font => "TKFN",
	)->pack(-side => 'left');

	my $widget_method = gui_widget::optmenu->open(
		parent  => $f4,
		pack    => {-side => 'left'},
		options =>
			[
				[kh_msg->get('gui_widget::r_cls->ward'),     'ward'    ],
				[kh_msg->get('gui_widget::r_cls->average'),  'average' ],
				[kh_msg->get('gui_widget::r_cls->complete'), 'complete'],
				[kh_msg->get('gui_widget::r_cls->clara'),    'clara'   ],
			],
		variable => \$self->{method_method},
		command => sub {$self->config_dist;},
	);
	$widget_method->set_value('ward');

	$f4->Label(
		-text => kh_msg->get('gui_widget::r_cls->dist'), # 距離：
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{widget_dist} = gui_widget::optmenu->open(
		parent  => $f4,
		pack    => {-side => 'left'},
		options =>
			[
				['Jaccard', 'binary'],
				['Euclid',  'euclid'],
				['Cosine',  'pearson'],
			],
		variable => \$self->{method_dist},
		command => sub {$self->config_opts;},
	);
	$self->{widget_dist}->set_value('binary');



	# 標準化とTF-IDF
	my $f6 = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);

	$f6->Label(
		-text => kh_msg->get('gui_widget::r_cls->stand'), # 標準化：
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{widget_stand} = gui_widget::optmenu->open(
		parent  => $f6,
		pack    => {-side => 'left'},
		options =>
			[
				[kh_msg->get('gui_widget::r_cls->none'),     'none'     ],
				[kh_msg->get('gui_widget::r_cls->by_words'), 'by_words' ],
				[kh_msg->get('gui_widget::r_cls->by_docs'),  'by_docs'  ],
			],
		variable => \$self->{method_stand},
		command => sub {$self->config_tfidf;},
	);
	$self->{widget_stand}->set_value('none');

	$f6->Label(
		-text => kh_msg->get('gui_widget::r_cls->tfidf'), # 頻度：
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{widget_tfidf} = gui_widget::optmenu->open(
		parent  => $f6,
		pack    => {-side => 'left'},
		options =>
			[
				['TF',     'tf'     ],
				['TF-IDF', 'tf-idf' ],
			],
		variable => \$self->{method_tfidf},
	);
	$self->{widget_tfidf}->set_value('tf-idf');
	$self->config_opts();




	my $f5 = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);

	$f5->Label(
		-text => kh_msg->get('gui_widget::r_cls->n_cls'), #   クラスター数：
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_cluster_number} = $f5->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_cluster_number}->insert(0,'10');
	$self->{entry_cluster_number}->bind("<Key-Return>",sub{$self->calc;});
	$self->{entry_cluster_number}->bind("<KP_Enter>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_cluster_number});

	$win->Button(
		-text => kh_msg->gget('cancel'), # キャンセル
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->withd;}
	)->pack(-side => 'right',-padx => 2, -pady => 2, -anchor => 'se');

	$win->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->calc;}
	)->pack(-side => 'right', -pady => 2, -anchor => 'se');

	return $self;
}

sub config_tfidf{
	my $self = shift;
	if ($self->{method_stand} eq 'by_words'){
		$self->{widget_tfidf}->configure(-state => 'disabled');
	} else {
		$self->{widget_tfidf}->configure(-state => 'normal');
	}
}

sub config_opts{
	my $self = shift;
	if ($self->{method_dist} eq 'binary'){
		$self->{widget_tfidf}->configure(-state => 'disabled');
		$self->{widget_stand}->configure(-state => 'disabled');
	} else {
		$self->{widget_tfidf}->configure(-state => 'normal');
		$self->{widget_stand}->configure(-state => 'normal');
	}
}

sub config_dist{
	my $self = shift;
	if ( $self->{method_method} eq 'clara' ){
		$self->{widget_dist}->configure(-state => 'disable');
		$self->{widget_tfidf}->configure(-state => 'normal');
		$self->{widget_stand}->configure(-state => 'normal');
	} else {
		$self->{widget_dist}->configure(-state => 'normal');
		$self->config_opts();
	}
}

#--------------#
#   チェック   #

sub check{
	my $self = shift;
	
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('gui_widget::words->no_pos_selected'), # 品詞が1つも選択されていません。
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

sub start_raise{
	my $self = shift;
	$self->{words_obj}->settings_load;
}

sub start{
	my $self = shift;

	# Windowを閉じる際のバインド
	$self->win_obj->bind(
		'<Control-Key-q>',
		sub{ $self->withd; }
	);
	$self->win_obj->bind(
		'<Key-Escape>',
		sub{ $self->withd; }
	);
	$self->win_obj->protocol('WM_DELETE_WINDOW', sub{ $self->withd; });
}

#----------#
#   実行   #

sub calc{
	my $self = shift;

	# 入力のチェック
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('gui_widget::words->no_pos_selected'),# '品詞が1つも選択されていません。',
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
			msg  => kh_msg->get('select_3words'), # 少なくとも3つ以上の抽出語を選択して下さい。
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

	my $wait_window = gui_wait->start;

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

	$file_csv = gui_window->gui_jchar($file_csv);
	$file_csv =~ s/\\/\\\\/g;

	my $r_command = "d <- read.csv(\"$file_csv\")\n";
	$r_command .= &r_command_fix_d;

	$r_command .= "\n# END: DATA\n";

	$::config_obj->R->send("print( sessionInfo()[2]\$platform )");
	if ( $::config_obj->R->read =~ /32\-bit/ ){
		$::config_obj->R->send("memory.limit(size=2047)");
		print "Sent to R: memory.limit(size=2047)\n";
	}

	my $cluster = &calc_exec(
		base_win       => $self,
		cluster_number => $self->gui_jg( $self->{entry_cluster_number}->get ),
		r_command      => $r_command,
		method_dist    => $self->gui_jg( $self->{method_dist} ),
		method_method  => $self->gui_jg( $self->{method_method} ),
		method_tfidf   => $self->gui_jg( $self->{method_tfidf} ),
		method_stand   => $self->gui_jg( $self->{method_stand} ),
		tani           => $self->tani,
	);
	
	$wait_window->end(no_dialog => 1);
	$self->withd;

	$cluster->open_result_win;

	return 1;
}

sub open_result_win{
	my $self = shift;
	gui_window::doc_cls_res->open(
		command_f   => $self->{r_command},
		tani        => $self->{tani},
		plots       => $self->{plots},
		merge_files => $self->{merges},
	);
	$self = undef;
	return 1;
}

sub calc_exec{
	my $self = {@_};
	bless $self, "gui_window::doc_cls::".$self->{method_method};
	return $self->_calc_exec;
}



sub _calc_exec{
	my $self = shift;
	
	my $r_command = $self->{r_command};
	my $cluster_number = $self->{cluster_number};

	# クラスター分析の結果を納めるファイル名
	my $file = $::project_obj->file_datadir.'_doc_cls_ward';
	my $file_org = $file;
	my $icode;
	if ($::config_obj->os eq 'win32'){
		$file = Jcode->new($file,'sjis')->euc;
		$file =~ s/\\/\\\\/g;
	} else {
		# たぶん変換は不要
		#$icode = Jcode::getcode($file);
		#$file = Jcode->new($file, $icode)->euc unless $icode eq 'euc';
		#$file =~ s/\\/\\\\/g;
		#$file = Jcode->new($file,'euc')->$icode unless $icode eq 'ascii';
	}

	# 各種準備（Rコマンド）
	$r_command .= "n_org <- nrow(d)\n";                     # 分析対象語を含ま
	$r_command .= "row.names(d) <- 1:nrow(d)\n";            # ない文書を除外
	$r_command .= "d_labels <- d_labels[rowSums(d) > 0]\n";
	$r_command .= "d <- d[rowSums(d) > 0, ]\n";
	$r_command .= "n_cls <- $cluster_number\n";
	
	if ( $self->{method_tfidf} eq 'tf-idf' ){
		$r_command .= &r_command_tfidf;
	}
	
	unless ( $self->{method_dist} eq 'binary' ){
		if ($self->{method_stand} eq 'by_words'){
			$r_command .= "d <- scale(d)\n";
		}
		elsif ($self->{method_stand} eq 'by_docs'){
			$r_command .= "d <- t( scale( t(d) ) )\n";
		}
	}

	$r_command .= "d_names <- row.names(d)\n";
	
	# 併合水準のプロット（Rコマンド）
	my $r_command_height = &r_command_height;
	
	# クラスター化（Rコマンド）
	my $r_command_ward;
	
	$r_command_ward .= "method_dist <- \"$self->{method_dist}\"\n";
	$r_command_ward .= "method_clst <- \"$self->{method_method}\"\n";
	
	$r_command_ward .= '
library(amap)
dj <- Dist(d,method=method_dist)

if (
	   ( as.numeric( R.Version()$major ) >= 3 )
	&& ( as.numeric( R.Version()$minor ) >= 1.0)
){                                                      # >= R 3.1.0
	if (method_clst == "ward"){
		method_clst  <-  "ward.D2"
	}
	dcls <- hclust(dj,method=method_clst)
} else {                                                # <= R 3.0
	if (method_clst == "ward"){
		dj <- dj^2
		dcls <- hclust(dj,method=method_clst)
		dcls$height <- sqrt( dcls$height )
	} else {
		dcls <- hclust(dj,method=method_clst)
	}
}
';


	$r_command_ward .= "q <- cutree(dcls,k=$cluster_number)\n";
	
	$r_command_ward .= "ord <- order( unique( q[order.dendrogram( as.dendrogram(dcls) )] ) )\n";
	$r_command_ward .= "q   <- ord[q]\n";
	
	$r_command_ward .= "q <- cbind(q)\n";
	$r_command_ward .= "row.names(q) <- row.names(d)\n";
	
	$r_command_ward .= "q <- check_cutree(q, n_org)\n";
	$r_command_ward .= "r <- NULL\n";
	$r_command_ward .= "r <- cbind(r, q)\n";

	# 併合過程を保存するファイル
	my ($merges, $merges_org);
	$merges_org->{_cluster_tmp} = $::project_obj->file_TempCSV();

	$merges->{_cluster_tmp} = gui_window->gui_jchar(
		$merges_org->{_cluster_tmp}
	);

	# kh_r_plotモジュールには基本的にEUCのRコマンドを渡すが、
	# ここではUTF8フラグ付きを渡している
	#print
	#	"is_utf8? ", 
	#	utf8::is_utf8($r_command),
	#	", ",
	#	utf8::is_utf8($r_command_ward),
	#	", ",
	#	utf8::is_utf8($r_command_height),
	#	"\n"
	#;

	kh_r_plot->clear_env;
	my $plots;
	
	# 併合過程のファイル3種類
	$plots->{_cluster_tmp}{last} = kh_r_plot->new(
		name      => 'doc_cls_height_ward_last',
		command_f =>  $r_command
		             .$r_command_ward
		             ."pp_type <- \"last\"\n"
		             .$r_command_height
		             .&r_command_mout($merges->{_cluster_tmp}),
		width     => $::config_obj->plot_size_words,
		height    => $::config_obj->plot_size_codes,
	) or return 0;

	$plots->{_cluster_tmp}{first} = kh_r_plot->new(
		name      => 'doc_cls_height_ward_first',
		command_f =>  $r_command
		             .$r_command_ward
		             ."pp_type <- \"first\"\n"
		             .$r_command_height,
		command_a =>  "pp_type <- \"first\"\n"
		             .$r_command_height,
		width     => $::config_obj->plot_size_words,
		height    => $::config_obj->plot_size_codes,
	) or return 0;

	$plots->{_cluster_tmp}{all} = kh_r_plot->new(
		name      => 'doc_cls_height_ward_all',
		command_f =>  $r_command
		             .$r_command_ward
		             ."pp_type <- \"all\"\n"
		             .$r_command_height,
		command_a =>  "pp_type <- \"all\"\n"
		             .$r_command_height,
		width     => $::config_obj->plot_size_words,
		height    => $::config_obj->plot_size_codes,
	) or return 0;

	# デンドログラム
	
	$::config_obj->R->send("
		print( paste( \"khc\",nrow(d),\"khc\", sep=\"\" ) )
	");
	my $ndocs = $::config_obj->R->read;
	if ($ndocs =~ /"khc([0-9]+)khc"/){
		$ndocs = $1;
	} else {
		warn "Could not get number of documents...\n";
		return 0;
	}
	
	my $size = int( ($ndocs * ( (20 + 5) * 1) + 45) * 1 );
	$size = int( $size * ( $::config_obj->plot_size_codes / 480 ) );
	if ($size < $::config_obj->plot_size_codes){
		$size = $::config_obj->plot_size_codes;
	}
	elsif ($size < $::config_obj->plot_size_words){
		$size = $::config_obj->plot_size_words;
	}

	if ($ndocs <= 500){
		$plots->{_dendro} = kh_r_plot->new(
			name      => 'doc_cls_dendro',
			command_f =>  $r_command
			             .$r_command_ward
			             .&r_command_dendro1(1),
			command_a =>  &r_command_dendro1(1),
			width     => $size,
			height    => $::config_obj->plot_size_codes,
		) or return 0;
		$plots->{_dendro}->rotate_cls;
	}

	# クラスター番号の書き出し（Rコマンド）
	#my $r_command_fin = &r_command_fix_r;
	my $r_command_fin;
	$r_command_fin .= "colnames(r) <- c(\"_cluster_tmp\")\n";
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
			msg    => kh_msg->get('fail')."\n\n".$r # 計算に失敗しました
		);
		return 0;
	}
	kh_r_plot->clear_env;

	if ($::main_gui->if_opened('w_doc_cls_res')){
		$::main_gui->get('w_doc_cls_res')->close;
	}

	# Rの計算結果を外部変数として読み込む
	foreach my $i (@{mysql_outvar->get_list}){
		if ($i->[1] eq "_cluster_tmp"){
			mysql_outvar->delete(name => $i->[1]);
		}
	}

	mysql_outvar::read::tab->new(
		file     => $file_org,
		tani     => $self->{tani},
		#var_type => 'INT',
	)->read;

	#gui_window::doc_cls_res->open(
	#	command_f   => $r_command.$r_command_ward,
	#	tani        => $self->{tani},
	#	plots       => $plots,
	#	merge_files => $merges_org,
	#);

	$self->{r_command} = $r_command.$r_command_ward;
	$self->{plots} = $plots;
	$self->{merges} = $merges_org;
	
	return $self;
}

#--------------#
#   アクセサ   #


sub label{
	return kh_msg->get('win_title'), # 文書のクラスター分析：オプション
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
	my $t = '

# Preparing the plot
pp_focus  <- 50     # plot first & last 50 stages
pp_kizami <-  5     # indicator of N of clusters

# Calcurate coeff.
mergep <- dcls$merge
if ( length(d_names) < n_org ){
	merge_tmp <- NULL
	for (i in 1:nrow(dcls$merge)){
		if (dcls$merge[i,1] < 0){
			c1 <- as.numeric( d_names[dcls$merge[i,1] * -1] ) * -1
		} else {
			c1 <- dcls$merge[i,1]
		}
		if (dcls$merge[i,2] < 0){
			c2 <- as.numeric( d_names[dcls$merge[i,2] * -1] ) * -1
		} else {
			c2 <- dcls$merge[i,2]
		}
		merge_tmp <- rbind( merge_tmp, c(c1, c2) )
	}
	mergep <- merge_tmp
}
det <- mergep
det <- cbind(1:nrow(det), nrow(det):1, det, dcls$height)
colnames(det) <- c("u_n", "cls_n", "u1", "u2", "height")

# all, first, last
if (pp_type == "last"){
	n_start <- nrow(det) - pp_focus + 1
	if (n_start < 1){ n_start <- 1 }
	det <- det[nrow(det):n_start,]
	
	str_xlab <- paste(" ('
	.kh_msg->get('gui_window::word_cls->last1') # 最後の
	.'",pp_focus,"'
	.kh_msg->get('gui_window::word_cls->last2') # 回
	.') ",sep="")
} else if (pp_type == "first") {
	if ( pp_focus > nrow(det) ){
		pp_focus <- nrow(det)
	}
	det <- det[pp_focus:1,]
	
	str_xlab <- paste(" ('
	.kh_msg->get('gui_window::word_cls->first1') # 最初の
	.'",pp_focus,"'
	.kh_msg->get('gui_window::word_cls->first2') # 回
	.') ",sep="")
} else if (pp_type == "all") {
	det <- det[nrow(det):1,]
	pp_kizami <- nrow(det) / 8
	pp_kizami <- pp_kizami - ( pp_kizami %% 5 ) + 5
	
	str_xlab <- ""
}

# Indication of "N of clusters"
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

# Plot
par(mai=c(0,0,0,0), mar=c(4,4,1,1), omi=c(0,0,0,0), oma =c(0,0,0,0) )
plot(
	det[,"u_n"],
	det[,"height"],
	type = "b",
	pch  = p_type,
	xlab = paste("'
	.kh_msg->get('gui_window::word_cls->agglomer') # クラスター併合の段階
	.'",str_xlab,sep = ""),
	ylab = "'
	.kh_msg->get('gui_window::word_cls->hight') # 併合水準（非類似度）
	.'"
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
	legend = c("'
	.kh_msg->get('gui_window::word_cls->note1') # ※プロット内の数値ラベルは\n　併合後のクラスター総数
	.'"),
	#pch = c(16),
	cex = .8,
	box.lty = 0
)

';
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

d_labels <- as.character( d$name )
if ( is.null(d$name) ){
	d_labels <- as.character(1:nrow(d))
}

doc_length_mtr <- d[,(n_cut-1):n_cut]

n_cut <- n_cut * -1
d <- d[,-1:n_cut]

#for (i in 1:nrow(d)){
#	len <- as.numeric(doc_length_mtr[i,2])
#	if (len > 0){
#		d[i,] <- d[i,] / len * 1000
#	}
#}

leng <- as.numeric(doc_length_mtr[,2])
leng[leng ==0] <- 1
d <- d / leng
d <- d * 1000

check_cutree <- function(r, n_org) {
	if ( nrow(r) < n_org ){
		r_temp <- NULL
		fixed  <- 0
		for ( i in 1:nrow(r) ){
			if (
				   ( i         != as.numeric( row.names(r)[i] ) )
				&& ( i + fixed != as.numeric( row.names(r)[i] ) )
			){
				gap <- as.numeric( row.names(r)[i] ) - i - fixed
				print(paste("gap", gap, "fixed", fixed))
				for (h in 1:gap){
					r_temp <- rbind(r_temp, c("."))
					fixed <- fixed + 1
				}
			}
			#print (paste(i,row.names(r)[i]))
			r_temp <- rbind(r_temp, r[i,])
		}
		
		if ( nrow(r_temp) < n_org ){
			for (i in 1:(n_org - nrow(r_temp))){
				r_temp <- rbind(r_temp, c("."))
			}
		}
		print(paste( "n_org", n_org, "nrow", nrow(r_temp) ))
		r <- r_temp
	}
	return(r)
}

END_OF_the_R_COMMAND
return $t;
}

sub r_command_mout{
	my $file = shift;
	if ($::config_obj->os eq 'win32'){
		#$file = Jcode->new($file,'sjis')->euc;
		$file =~ s/\\/\\\\/g;
	}
	
	my $t = '';
	$t .= 'mout <- cbind(1:nrow(mergep), mergep, dcls$height)'."\n";
	$t .= "write.table(mout, file=\"$file\", col.names=FALSE, row.names=FALSE, sep=\",\")\n"
}

sub r_command_fix_r{
	my $t = << 'END_OF_the_R_COMMAND';

if ( nrow(d) < n_org ){
	r_temp <- NULL
	fixed  <- 0
	for ( i in 1:nrow(r) ){
		if (
			   ( i         != as.numeric( row.names(r)[i] ) )
			&& ( i + fixed != as.numeric( row.names(r)[i] ) )
		){
			gap <- as.numeric( row.names(r)[i] ) - i - fixed
			#print(paste("gap", gap, "fixed", fixed))
			for (h in 1:gap){
				r_temp <- rbind(r_temp, c(".",".","."))
				fixed <- fixed + 1
			}
		}
		#print (paste(i,row.names(r)[i]))
		r_temp <- rbind(r_temp, r[i,])
	}
	r <- r_temp
}

END_OF_the_R_COMMAND
return $t;
}

sub r_command_cosine{
	my $t = << 'END_OF_the_R_COMMAND';

my.cosine <- function(x)
{
	x <- as.matrix(x)
	x <- t(x)
	ss <- 1/sqrt(colSums(x^2))
	col.similarity <- t(x) %*% x*outer(ss, ss)
	colnames(col.similarity) <- rownames(col.similarity) <- colnames(x)
	return(as.dist(1 - col.similarity))
}
dj <- my.cosine(d)
gc()

END_OF_the_R_COMMAND
return $t;
}


sub r_command_tfidf{
	my $t = << 'END_OF_the_R_COMMAND';

# binary termfrequency
lw_bintf <- function(m) {
    return( (m>0)*1 )
}

# inverse document frequency
# from Dumais (1992), Nakov (2001) uses log not log2
gw_idf <- function(m) {
    df = rowSums(lw_bintf(m), na.rm=TRUE)
    return ( ( log2(ncol(m)/df) + 1 ) )
}

d <- t(d)
d <- d[rowSums(d) > 0, ]
d <- d * gw_idf(d)
d <- t(d)

END_OF_the_R_COMMAND
return $t;
}

sub r_command_dendro1{
	my $font_size = shift;

	my $t = "# start dendro\n";

	$t .= "font_size <- $font_size\n";

	$t .= '

par(
			mai=c(0,0,0,0),
			mar=c(1,2,1,0),
			omi=c(0,0,0,0),
			oma=c(0,0,0,0) 
		)

dcls$labels <- d_labels
plot(dcls,ann=0,cex=font_size, hang=-1)

rect.hclust(dcls, k=n_cls, border="#FF8B00FF")

';
return $t;
}

sub r_command_dendro2{
	my $font_size = shift;

	my $t = "# start dendro\n";

	$t .= "font_size <- $font_size\n";

	$t .= '

freq <- as.vector( doc_length_mtr$length_w )

library(grid)
library(ggplot2)
library(ggdendro)

ddata <- dendro_data(as.dendrogram(dcls), type="rectangle")

p <- NULL
p <- ggplot()

# クラスターごとのカラー設定

if (n_cls > 1){
	memb <- cutree(dcls,k=n_cls)
	# 全体の色設定
	p <- p + scale_colour_hue(l=40, c=100)
	# 切り離し線(1)
	cutpoint <- mean(
		c(
			rev(dcls$height)[n_cls-1],
			rev(dcls$height)[n_cls]
		)
	)
	# 色の順番を決定
	n <- length( unique(memb[dcls$order]) )
	new_col <- NULL
	for (i in 1:ceiling(n / 2) ){
		new_col <- c(new_col, i)
		if (i + ceiling(n / 2) <= n){
			new_col <- c(new_col, i + ceiling(n / 2))
		}
	}
	# クラスター番号→色名の変換用ベクトル作成（col_vec）
	col_tab <- cbind(
		unique(memb[dcls$order]),
		new_col
	)
	colnames(col_tab) <- c("org","new")
	col_vec <- NULL
	for (i in col_tab[order(col_tab[,1]),2]){
		c <- as.character(i)
		while (nchar(c) < 3){
			c <- paste("0",c,sep="")
		}
		col_vec <- c(col_vec, c)
	}
	# 線の色分け
	seg_bl <- NULL
	seg_cl <- NULL
	colnames(ddata$segment) <- c(
		"x0",
		"y0",
		"x1",
		"y1"
	)
	colnames(ddata$labels) <- c(
		"x",
		"y",
		"text"
	)
	for ( i in 1:nrow( ddata$segment ) ) {
		if (
			   ddata$segment$y0[i] > cutpoint
			|| ddata$segment$y1[i] > cutpoint
			|| (
				   ddata$segment$y0[i] >= cutpoint
				&& ddata$segment$y1[i] >= cutpoint
			   )
		) {
			seg_bl <- c(
				seg_bl,
				ddata$segment$x0[i],
				ddata$segment$y0[i],
				ddata$segment$x1[i],
				ddata$segment$y1[i]
			)
		} else {
			seg_cl <- c(
				seg_cl,
				ddata$segment$x0[i],
				ddata$segment$y0[i],
				ddata$segment$x1[i],
				ddata$segment$y1[i],
				#col_vec[
					memb[dcls$order][
						floor(
							mean(
								ddata$segment$x0[i],
								ddata$segment$x1[i]) 
							)
					]
				#]
			)
		}
	}
	seg_bl = matrix(seg_bl, byrow=T, ncol=4 )
	seg_cl = matrix(seg_cl, byrow=T, ncol=5 )
	
	if (is.null(seg_bl) == F){
		colnames(seg_bl) <- c("x0", "y0", "x1", "y1")
		seg_bl <- as.data.frame(seg_bl)
		# 切り離し線(2)
		if ( max(seg_bl$y1) > cutpoint ){
			p <- p + geom_hline(
				yintercept = cutpoint,
				colour="black",
				linetype=5,
				size=0.5
			)
		}
	}
	colnames(seg_cl) <- c("x0", "y0", "x1", "y1", "c")
	seg_cl <- as.data.frame(seg_cl)
	seg_cl$c <- col_vec[seg_cl$c]

	p <- p + geom_text(
		data=data.frame(                    # ラベル
			x=label(ddata)$x,
			y=label(ddata)$y,
			text=d_labels[ as.numeric( as.vector( ddata$labels$text ) ) ],
			cols= col_vec[ memb[ as.numeric( as.vector( ddata$labels$text ) ) ] ]
		),
		aes_string(
			x="x",
			y="y",
			label="text",
			colour="cols"
		),
		hjust=1,
		angle =0,
		size = 5 * 0.85 * font_size
	)

	p <- p + geom_segment(
		data=seg_cl,
		aes_string(x="x0", y="y0", xend="x1", yend="y1", colour="c"),
		size=0.5
	)
} else {
	memb <- rep( c("a"), length(d_labels) )
	p <- p + scale_colour_manual(values=c("black"))
	seg_bl <- ddata$segment
	col_vec <- c("001")
	p <- p + geom_text(
		data=data.frame(                    # ラベル
			x=label(ddata)$x,
			y=label(ddata)$y,
			text=d_labels[ as.numeric( as.vector( ddata$labels$text ) ) ],
			cols= col_vec[ memb[ as.numeric( as.vector( ddata$labels$text ) ) ] ]
		),
		aes_string(
			x="x",
			y="y",
			label="text",
			colour="cols"
		),
		hjust=1,
		angle =0,
		size = 5 * 0.85 * font_size
	)
}

if (is.null(seg_bl) == F){
	p <- p + geom_segment(
		data=seg_bl,
		aes_string(x="x0", y="y0", xend="x1", yend="y1"),
		color="gray50",
		linetype=1,
	)
}

p <- p + geom_text(
	data=data.frame(                    # ラベル変換
		x=label(ddata)$x,
		y=label(ddata)$y,
		text=d_labels[ as.numeric( as.vector( ddata$labels$text ) ) ],
		cols= col_vec[ memb[ as.numeric( as.vector( ddata$labels$text ) ) ] ]
	),
	aes_string(
		x="x",
		y="y",
		label="text",
		colour="cols"
	),
	hjust=1,
	angle =0,
	size = 5 * 0.85 * font_size
)

p <- p + coord_flip()
p <- p + scale_x_reverse( expand = c(0.01,0.01) )
p <- p + scale_y_continuous(expand = c(0.25,0))

p <- p + theme(
	axis.title.y = element_blank(),
	axis.title.x = element_blank(),
	axis.ticks   = element_line(colour="gray60"),
	axis.text.y  = element_text(size=12,colour="gray40"),
	axis.text.x  = element_text(size=12,colour="gray40"),
	legend.position="none"
)

if (n_cls <= 1){
	p <- p + theme(
		axis.text.y  = element_blank(),
		axis.text.x  = element_text(size=12,colour="black"),
		axis.ticks = element_line(colour="black"),
		#panel.grid.major = element_blank(),
		#panel.grid.minor = element_blank(),
		#panel.background = element_blank(),
		axis.line = element_line(colour = "black")
	)
}

show_bar <- 1

if (show_bar == 1){
	p <- p + theme(
		axis.ticks  = element_blank(),
		axis.text.y = element_blank()
	)
	p <- p + theme(
		plot.margin = unit(c(0,0,0,0), "lines")
	)


	#freq <- NULL
	#for (i in 1:nrow(d)) {
	#	freq[i] = sum( d[i,] )
	#}

	bard <- data.frame(
		nm <- d_labels[ as.numeric( as.vector( ddata$labels$text ) ) ],
		ht <- freq[ as.numeric( as.vector( ddata$labels$text ) ) ],
		cl <- col_vec[ memb[ as.numeric( as.vector( ddata$labels$text ) ) ] ],
		od <- nrow(d):1
	)

	if (n_cls <= 1){
		bard$cl <- "001"
	}

	p2 <- NULL
	p2 <- ggplot()
	p2 <- p2 + geom_bar(
		stat="identity",
		position = "identity",
		width=0.75,
		data=bard,
		aes(
			x=reorder(od,od),
			y=ht,
			fill=cl
		)
	)
	p2 <- p2 + coord_flip()
	p2 <- p2 + scale_y_reverse( expand = c(0,0))
	p2 <- p2 + scale_x_discrete( expand = c(0.005,0.005) )
	p2 <- p2 + theme(
		axis.title.y     = element_blank(),
		axis.title.x     = element_blank(),
		axis.ticks       = element_blank(),
		axis.text.y      = element_blank(),
		axis.text.x      = element_text(size=12,colour="white"),
		legend.position  = "none",
		panel.background = element_rect(fill="white", colour="white"),
		panel.grid.major = element_blank(),
		panel.grid.minor = element_blank()
	)

	margin <- 0.002 * nrow(d) + 0.00001 * nrow(d)^2 - 0.12
	p2 <- p2 + theme(
		plot.margin = unit(c(margin,-0.75,margin,0), "lines")
	)

	grid.newpage()
	pushViewport(viewport(layout=grid.layout(1,2, width=c(1,5)) ) )
	print(p,  vp= viewport(layout.pos.row=1, layout.pos.col=2) )
	print(p2, vp= viewport(layout.pos.row=1, layout.pos.col=1) )
} else {
	print(p)
}

if ( is.na(dev.list()["pdf"]) && is.na(dev.list()["postscript"]) ){
	if ( grepl("darwin", R.version$platform) ){
		quartzFonts(HiraKaku=quartzFont(rep("Hiragino Kaku Gothic Pro W6",4)))
		grid.gedit("GRID.text", grep=TRUE, global=TRUE, gp=gpar(fontfamily="HiraKaku"))
	} else {
		grid.gedit("GRID.text", grep=TRUE, global=TRUE, gp=gpar(fontfamily="'.$::config_obj->font_plot.'", fontface="bold"))
	}
}

detach("package:ggdendro", unload=T)

';
return $t;
}



1;