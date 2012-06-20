package gui_window::doc_cls::clara;
use base qw(gui_window::doc_cls);

sub calc_exec{
	my $self = shift;
	my %args = @_;

	my $r_command = $args{r_command};
	my $cluster_number = $args{cluster_number};

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

	$r_command .= "n_org <- nrow(d)\n";                     # 分析対象語を含ま
	$r_command .= "row.names(d) <- 1:nrow(d)\n";            # ない文書を除外
	$r_command .= "d <- subset(d, rowSums(d) > 0)\n";
	
	$r_command .= &gui_window::doc_cls::r_command_tfidf;

	# 文書ごとに標準化
		# euclid係数を使う主旨からすると、標準化は不要とも考えられるが、
		# 標準化を行わないと連鎖の程度が激しくなり、クラスター分析として
		# の用をなさなくなる場合がまま見られる。
	$r_command .= "d <- t( scale( t(d) ) )\n";

	$r_command .= "d_names <- row.names(d)\n";
	
	# クラスター化（Rコマンド）
	my $r_command_ward;
	$r_command_ward .= "library(cluster)\n";
	$r_command_ward .=
		"q <- clara(
			d,
			$cluster_number,
			samples=100,
			sampsize= min(nrow(d), 100 + 20 * $cluster_number),
			medoids.x=FALSE,
			rngR=TRUE
		)\$clustering\n"
	;

	$r_command_ward .= "q <- check_cutree(q, n_org)\n";
	$r_command_ward .= "r <- NULL\n";
	$r_command_ward .= "r <- cbind(r, q)\n";

	# kh_r_plotモジュールには基本的にEUCのRコマンドを渡すが、
	# ここではUTF8フラグ付きを渡している
	#print
	#	"is_utf8? ", 
	#	utf8::is_utf8($r_command),
	#	utf8::is_utf8($r_command_ward),
	#	utf8::is_utf8($r_command_height),
	#	"\n"
	#;

	kh_r_plot->clear_env;

	# クラスター番号の書き出し（Rコマンド）
	#my $r_command_fin = &r_command_fix_r;
	my $r_command_fin;
	$r_command_fin .= "colnames(r) <- c(\"_cluster_tmp\")\n";
	$r_command_fin .= "write.table(r, file=\"$file\", row.names=F, append=F, sep=\"\\t\", quote=F)\n";
	$r_command_fin .= "print(\"ok\")\n";

	$r_command_fin = Jcode->new($r_command_fin,'euc')->sjis
		if $::config_obj->os eq 'win32';

	$::config_obj->R->send(
		 $r_command
		.$r_command_ward
		.$r_command_fin
	);
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
		tani     => $args{tani},
		#var_type => 'INT',
	)->read;

	gui_window::doc_cls_res->open(
		command_f   => $r_command.$r_command_ward,
		tani        => $args{tani},
		plots       => $plots,
		merge_files => '',
	);

	$self->close;
	return 1;
}

1;