package jssdb_search;

sub plugin_config{
	return {
		name     => '検索 & ネットワーク作成',
		menu_grp => 'JSSDB',
	};
}

use strict;

sub exec{
	
	my $query = '家族 高齢';
	
	use Benchmark;
	my $t0 = new Benchmark;
	
	# 文書検索
	mysql_exec->drop_table("tmp_dan_id");
	mysql_exec->do("
		create temporary table tmp_dan_id (
			dan_id int primary key not null
		) TYPE=HEAP
	",1);
	mysql_exec->do("
		INSERT INTO tmp_dan_id (dan_id)
		SELECT dan_r.id
		FROM dan_r
		WHERE
			txt like '%情報%'
	",1);
	
	my $n_hits = mysql_exec->select("select count(*) from tmp_dan_id",1)
		->hundle->fetch->[0];
	unless ( $n_hits ){
		return 0;
	}
	my $n_all = mysql_exec->select("select count(*) from dan")
		->hundle->fetch->[0];
	
	# 語の出現数集計
	mysql_exec->drop_table("tmp_pdf1");
	mysql_exec->do("
		create temporary table tmp_pdf1 (
			genkei_id int primary key not null,
			pdf       int not null
		) TYPE=HEAP
	",1);
	
	mysql_exec->do("
		INSERT INTO tmp_pdf1 (genkei_id, pdf)
		SELECT genkei_id, count(*)
		FROM   genkei_dan, tmp_dan_id
		WHERE  genkei_dan.dan_id = tmp_dan_id.dan_id
		GROUP  BY genkei_id
	",1);
	
	# Jaccard係数集計
	mysql_exec->drop_table("tmp_pdf2");
	mysql_exec->do("
		create temporary table tmp_pdf2 (
			genkei_id int primary key not null,
			jac       double(16,15) not null
		)
	",1);
	
	mysql_exec->do("
		INSERT INTO tmp_pdf2 (genkei_id, jac)
		SELECT tmp_pdf1.genkei_id, ROUND( tmp_pdf1.pdf / (tmp_pdf1.pdf  + genkei_jss.df - tmp_pdf1.pdf + $n_hits - tmp_pdf1.pdf ), 15 ) as jaccard
		FROM tmp_pdf1, genkei_jss
		WHERE
			tmp_pdf1.genkei_id = genkei_jss.genkei_id
			AND tmp_pdf1.pdf / $n_hits - genkei_jss.df / $n_all > 0
		ORDER BY jaccard DESC
		LIMIT 75
	",1);
	
	# データの取り出し1: 語のリスト
	my @word_ids = ();
	my @word_nms = ();
	my $h = mysql_exec->select("
		SELECT genkei_jss.genkei_id, genkei_jss.name
		FROM   genkei_jss, tmp_pdf2, genkei
		WHERE
			genkei_jss.genkei_id = tmp_pdf2.genkei_id
			AND genkei_jss.genkei_id = genkei.id
		ORDER BY genkei.khhinshi_id, genkei.num DESC, genkei.name
	",1)->hundle;
	
	while (my $i = $h->fetch){
		push @word_ids, $i->[0];
		push @word_nms, $i->[1];
	}
	
	# データの取り出し1: 段落-語
	my $d;
	$h = mysql_exec->select("
		SELECT genkei_dan.dan_id, genkei_dan.genkei_id
		FROM genkei_dan, tmp_dan_id, genkei_jss, tmp_pdf2
		WHERE
			genkei_dan.dan_id = tmp_dan_id.dan_id
			AND genkei_dan.genkei_id = genkei_jss.genkei_id
			AND tmp_pdf2.genkei_id = genkei_jss.genkei_id
	",1)->hundle;
	while (my $i = $h->fetch){
		$d->{$i->[0]}{$i->[1]} = 1;
	}
	
	# R用のデータ作成
	my $nrow = 0;
	my $ncol = @word_ids;
	my $r_cmd = "d <- matrix( c(";
	foreach my $i ( sort { $a <=> $b } keys %{$d} ){
		foreach my $h (@word_ids){
			if ($d->{$i}{$h}){
				$r_cmd .= "1,";
			} else {
				$r_cmd .= "0,";
			}
		}
		$r_cmd .= "\n";
		++$nrow;
	}
	chop $r_cmd;
	chop $r_cmd;
	$r_cmd .= "), ncol=$nrow, nrow=$ncol)\n";
	
	$r_cmd .= "rownames(d) = c(";
	foreach my $i (@word_nms){
		$r_cmd .= "\"$i\",";
	}
	chop $r_cmd;
	$r_cmd .= ")\n\n";
	$r_cmd .= "# END: DATA\n\n";
	
	# デフォルト設定でネットワークを描画
	use plotR::network;
	my $plotR = plotR::network::jssdb->new(
		font_size           => $::config_obj->r_default_font_size / 100,
		plot_size           => 640,
		n_or_j              => "n",
		edges_num           => 80,
		edges_jac           => 0,
		use_freq_as_size    => 0,
		use_freq_as_fsize   => 0,
		smaller_nodes       => 0,
		use_weight_as_width => 0,
		min_sp_tree         => 0,
		r_command           => $r_cmd,
		plotwin_name        => 'selected_netgraph',
	);
	
	#$wait_window->end(no_dialog => 1);

	

	my $t1 = new Benchmark;
	print timestr( timediff($t1, $t0) ), "\n";
	
	print $plotR->{result_plots}[0]->path, "\n";
	system('start '.$plotR->{result_plots}[0]->path );
	
	$plotR = undef;

}

package plotR::network::jssdb;
use base qw(plotR::network);

use strict;

use kh_r_plot;

sub new{
	my $class = shift;
	my %args = @_;

	#print "$class\n";

	my $self = \%args;
	bless $self, $class;

	kh_r_plot->clear_env;

	my $r_command = $args{r_command};

	# パラメーター設定部分
	if ( $args{n_or_j} eq 'j'){
		$r_command .= "edges <- 0\n";
		$r_command .= "th <- $args{edges_jac}\n";
	}
	elsif ( $args{n_or_j} eq 'n'){
		$r_command .= "edges <- $args{edges_num}\n";
		$r_command .= "th <- 0\n";
	}
	$r_command .= "cex <- $args{font_size}\n";

	unless ( $args{use_freq_as_size} ){
		$args{use_freq_as_size} = 0;
	}
	$r_command .= "use_freq_as_size <- $args{use_freq_as_size}\n";

	unless ( $args{use_freq_as_fsize} && $args{use_freq_as_size}){
		$args{use_freq_as_fsize} = 0;
	}
	$r_command .= "use_freq_as_fontsize <- $args{use_freq_as_fsize}\n";

	unless ( $args{use_weight_as_width} ){
		$args{use_weight_as_width} = 0;
	}
	$r_command .= "use_weight_as_width <- $args{use_weight_as_width}\n";

	unless ( $args{smaller_nodes} ){
		$args{smaller_nodes} = 0;
	}
	$r_command .= "smaller_nodes <- $args{smaller_nodes}\n";

	if ($args{font_bold} == 1){
		$args{font_bold} = 2;
	} else {
		$args{font_bold} = 1;
	}
	$r_command .= "text_font <- $args{font_bold}\n";

	$r_command .= "min_sp_tree <- $args{min_sp_tree}\n";


	# プロット作成
	
	#use Benchmark;
	#my $t0 = new Benchmark;
	
	my @plots = ();
	my $flg_error = 0;
	
	$plots[0] = kh_r_plot->new(
		name      => $args{plotwin_name}.'_1',
		command_f =>
			 $r_command
			.$self->r_plot_cmd_p1
			."\ncom_method <- \"com-g\"\n"
			.$self->r_plot_cmd_p2
			.$self->r_plot_cmd_p3
			.$self->r_plot_cmd_p4,
		width     => $args{plot_size},
		height    => $args{plot_size},
	) or $flg_error = 1;

	kh_r_plot->clear_env;
	$self = undef;
	%args = undef;
	$self->{result_plots} = \@plots;

	return 0 if $flg_error;
	return $self;
}


1;


__END__
