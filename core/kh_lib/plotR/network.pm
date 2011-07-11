package plotR::network;

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

	#$r_command .= &r_plot_cmd_p1;

	# プロット作成
	
	#use Benchmark;
	#my $t0 = new Benchmark;
	
	my @plots = ();
	my $flg_error = 0;
	
	if ($self->{edge_type} eq 'twomode'){
		$plots[0] = kh_r_plot->new(
			name      => $args{plotwin_name}.'_1',
			command_f =>
				 $r_command
				."com_method <- \"twomode_c\"\n"
				.&r_plot_cmd_p1
				.&r_plot_cmd_p2
				.&r_plot_cmd_p3
				.&r_plot_cmd_p4,
			width     => $args{plot_size},
			height    => $args{plot_size},
		) or $flg_error = 1;

		$plots[1] = kh_r_plot->new(
			name      => $args{plotwin_name}.'_2',
			command_f =>
				 $r_command
				."com_method <- \"twomode_g\"\n"
				.&r_plot_cmd_p1
				.&r_plot_cmd_p2
				.&r_plot_cmd_p3
				.&r_plot_cmd_p4,
			command_a =>
				 "com_method <- \"twomode_g\"\n"
				.&r_plot_cmd_p2
				.&r_plot_cmd_p4,
			width     => $args{plot_size},
			height    => $args{plot_size},
		) or $flg_error = 1;
	} else {
		$plots[0] = kh_r_plot->new(
			name      => $args{plotwin_name}.'_1',
			command_f =>
				 $r_command
				.&r_plot_cmd_p1
				."\ncom_method <- \"cnt-b\"\n"
				.&r_plot_cmd_p2
				.&r_plot_cmd_p3
				.&r_plot_cmd_p4,
			width     => $args{plot_size},
			height    => $args{plot_size},
		) or $flg_error = 1;

		$plots[1] = kh_r_plot->new(
			name      => $args{plotwin_name}.'_2',
			command_f =>
				 $r_command
				."\ncom_method <- \"cnt-d\"\n"
				.&r_plot_cmd_p1
				.&r_plot_cmd_p2
				.&r_plot_cmd_p3
				.&r_plot_cmd_p4,
			command_a =>
				 "com_method <- \"cnt-d\"\n"
				.&r_plot_cmd_p2
				.&r_plot_cmd_p4,
			width     => $args{plot_size},
			height    => $args{plot_size},
		) or $flg_error = 1;

		$plots[2] = kh_r_plot->new(
			name      => $args{plotwin_name}.'_3',
			command_f =>
				 $r_command
				."\ncom_method <- \"com-b\"\n"
				.&r_plot_cmd_p1
				.&r_plot_cmd_p2
				.&r_plot_cmd_p3
				.&r_plot_cmd_p4,
			command_a =>
				 "com_method <- \"com-b\"\n"
				.&r_plot_cmd_p2
				.&r_plot_cmd_p4,
			width     => $args{plot_size},
			height    => $args{plot_size},
		) or $flg_error = 1;

		$plots[3] = kh_r_plot->new(
			name      => $args{plotwin_name}.'_4',
			command_f =>
				 $r_command
				."\ncom_method <- \"com-g\"\n"
				.&r_plot_cmd_p1
				.&r_plot_cmd_p2
				.&r_plot_cmd_p3
				.&r_plot_cmd_p4,
			command_a =>
				 "com_method <- \"com-g\"\n"
				.&r_plot_cmd_p2
				.&r_plot_cmd_p4,
			width     => $args{plot_size},
			height    => $args{plot_size},
		) or $flg_error = 1;

		$plots[4] = kh_r_plot->new(
			name      => $args{plotwin_name}.'_5',
			command_f =>
				 $r_command
				."\ncom_method <- \"none\"\n"
				.&r_plot_cmd_p1
				.&r_plot_cmd_p2
				.&r_plot_cmd_p3
				.&r_plot_cmd_p4,
			command_a =>
				 "com_method <- \"none\"\n"
				.&r_plot_cmd_p2
				.&r_plot_cmd_p4,
			width     => $args{plot_size},
			height    => $args{plot_size},
		) or $flg_error = 1;
	}
	
	#my $t1 = new Benchmark;
	#print timestr(timediff($t1,$t0)),"\n" if $bench;

	# 情報の取得（短いバージョン）
	my $info;
	$::config_obj->R->send('
		print(
			paste(
				"khcoderN ",
				length(get.vertex.attribute(n2,"name")),
				", E ",
				length(get.edgelist(n2,name=T)[,1]),
				", D ",
				substr(paste( round( graph.density(n2), 3 ) ), 2, 5 ),
				sep=""
			)
		)
	');
	$info = $::config_obj->R->read;
	if ($info =~ /"khcoder(.+)"/){
		$info = $1;
	} else {
		$info = undef;
	}

	# 情報の取得（長いバージョン）
	my $info_long;
	$::config_obj->R->send('
		print(
			paste(
				"khcoderNodes ",
				length(get.vertex.attribute(n2,"name")),
				" (",
				length(get.vertex.attribute(n,"name")),
				"), Edges ",
				length(get.edgelist(n2,name=T)[,1]),
				" (",
				length(get.edgelist(n,name=T)[,1]),
				"), Density ",
				substr(paste( round( graph.density(n2), 3 ) ), 2, 5 ),
				", Min. Jaccard ",
				substr( paste( round( th, 3 ) ), 2, 5),
				sep=""
			)
		)
	');
	$info_long = $::config_obj->R->read;
	if ($info_long =~ /"khcoder(.+)"/){
		$info_long = $1;
	} else {
		$info_long = undef;
	}

	# edgeの数・最小のjaccard係数などの情報をcommand_fに付加
	my ($info_edges, $info_jac);
	if ($info =~ /E ([0-9]+), D/){
		$info_edges = $1;
	}
	$::config_obj->R->send('print( paste( "khcoderJac", th, "ok", sep="" ) )');
	$info_jac = $::config_obj->R->read;
	if ($info_jac =~ /"khcoderJac(.+)ok"/){
		$info_jac = $1;
	}
	foreach my $i (@plots){
		$i->{command_f} .= "\n# edges: $info_edges\n";
		$i->{command_f} .= "\n# min. jaccard: $info_jac\n";
	}

	kh_r_plot->clear_env;
	$self = undef;
	%args = undef;
	$self->{result_plots} = \@plots;
	$self->{result_info} = $info;
	$self->{result_info_long} = $info_long;
	
	return 0 if $flg_error;
	return $self;
}

sub r_plot_cmd_p1{
	return '

# 頻度計算
freq <- NULL
for (i in 1:length( rownames(d) )) {
	freq[i] = sum( d[i,] )
}

# 類似度計算 
d <- dist(d,method="binary")
d <- as.matrix(d)
d <- 1 - d;

# 不要なedgeを削除して標準化
if ( exists("com_method") ){
	if (com_method == "twomode_c" || com_method == "twomode_g"){
		d[1:n_words,] <- 0

		std <- d[(n_words+1):nrow(d),1:n_words]
		std <- t(std)
		std <- scale(std, center=T, scale=F)
		std <- t(std)

		if ( min(std) < 0 ){
			std <- std - min(std);
		}
		std <- std / max(std)
		
		d[(n_words+1):nrow(d),1:n_words] <- std
	}
}

# グラフ作成 
library(igraph)
n <- graph.adjacency(d, mode="lower", weighted=T, diag=F)
n <- set.vertex.attribute(
	n,
	"name",
	0:(length(d[1,])-1),
	as.character( 1:length(d[1,]) )
)

# edgeを間引く準備 
el <- data.frame(
	edge1            = get.edgelist(n,name=T)[,1],
	edge2            = get.edgelist(n,name=T)[,2],
	weight           = get.edge.attribute(n, "weight"),
	stringsAsFactors = FALSE
)

# 閾値を計算 
if (th == 0){
	if(edges > length(el[,1])){
		edges <- length(el[,1])
	}
	th = quantile(
		el$weight,
		names = F,
		probs = 1 - edges / length(el[,1])
	)
}

# edgeを間引いてグラフを再作成 
el2 <- subset(el, el[,3] >= th)
n2  <- graph.edgelist(
	matrix( as.matrix(el2)[,1:2], ncol=2 ),
	directed	=F
)
n2 <- set.edge.attribute(
	n2, "weight", 0:(length(get.edgelist(n2)[,1])-1), el2[,3]
)
	';
}

sub r_plot_cmd_p2{

return 
'
if (length(get.vertex.attribute(n2,"name")) < 2){
	com_method <- "none"
}

# 中心性
if ( com_method == "cnt-b" || com_method == "cnt-d"){
	if (com_method == "cnt-b"){                   # 媒介
		ccol <- betweenness(
			n2, v=0:(length(get.vertex.attribute(n2,"name"))-1), directed=F
		)
	}
	if (com_method == "cnt-d"){                   # 次数
		ccol <-  degree(n2, v=0:(length(get.vertex.attribute(n2,"name"))-1) )
	}
	ccol <- ccol - min(ccol)                      # 色の設定
	ccol <- ccol * 100 / max(ccol)
	ccol <- trunc(ccol + 1)
	ccol <- cm.colors(101)[ccol]

	com_col_v <- "gray40"
	edg_col   <- "gray65"
	edg_lty   <- 1
}

# クリーク検出
if ( com_method == "com-b" || com_method == "com-g"){
	merge_step <- function(n2, m){                # 共通利用の関数
		for ( i in 1:( trunc( length( m ) / 2 ) ) ){
			temp_csize <- community.to.membership(n2, m,i)$csize
			num_max   <- max( temp_csize )
			num_alone <- sum( temp_csize[ temp_csize == 1 ] )
			num_cls   <- length( temp_csize[temp_csize > 1] )
			#print( paste(i, "a", num_alone, "max", num_max, "cls", num_cls) )
			if (
				# 最大コミュニティサイズが全ノード数の22.5%以上
				   num_max / length(get.vertex.attribute(n2,"name")) >= 0.225
				# かつ、最大コミュニティサイズが単独ノード数よりも大きい
				&& num_max > num_alone
				# かつ、サイズが2以上のコミュニティ数が12未満
				&& num_cls < 12
			){
				return(i)
			}
			# 最大コミュニティサイズがノード数の40%を越える直前で打ち切り
			if (num_max / length(get.vertex.attribute(n2,"name")) >= 0.4 ){
				return(i-1)
			}
		}
		return( trunc(length( m ) / 2) )
	}

	if (com_method == "com-b"){                   # 媒介性（betweenness）
		com   <- edge.betweenness.community(n2, directed=F)    
		com_m <- community.to.membership(
			n2, com$merges, merge_step(n2,com$merges)
		)
	}

	if (com_method == "com-g"){                   # Modularity
		com   <- fastgreedy.community   (n2, merges=TRUE, modularity=TRUE)
		com_m <- community.to.membership(
			n2, com$merges, merge_step(n2,com$merges)
		)
	}

	com_col <- NULL # vertex frame                # Vertexの色（12色まで）
	ccol    <- NULL # vertex
	col_num <- 1
	library( RColorBrewer )
	for (i in com_m$csize ){
		if ( i == 1){
			ccol    <- c( ccol, "white" )
			com_col <- c( com_col, "gray40" )
		} else {
			if (col_num <= 12){
				ccol    <- c( ccol, brewer.pal(12, "Set3")[col_num] )
				com_col <- c( com_col, "gray40" )
			} else {
				ccol    <- c( ccol, "white" )
				com_col <- c( com_col, "blue" )
			}
			col_num <- col_num + 1
		}
	}
	com_col_v <- com_col[com_m$membership + 1]
	ccol      <- ccol[com_m$membership + 1]

	edg_lty <- NULL                               # edgeの色と形状
	edg_col <- NULL
	for (i in 1:length(el2$edge1)){
		if (
			   com_m$membership[ get.edgelist(n2,name=F)[i,1] + 1 ]
			== com_m$membership[ get.edgelist(n2,name=F)[i,2] + 1 ]
		){
			edg_col <- c( edg_col, "gray55" )
			edg_lty <- c( edg_lty, 1 )
		} else {
			edg_col <- c( edg_col, "gray" )
			edg_lty <- c( edg_lty, 3 )
		}
	}
}

# 変数・見出しを利用する場合のカラー
if (com_method == "twomode_c" || com_method == "twomode_g"){
	var_select <- substring(
		colnames(d)[ as.numeric( get.vertex.attribute(n2,"name") ) ],
		1,
		2
	) == "<>"
}

if (com_method == "twomode_c"){
	ccol <-  degree(n2, v=0:(length(get.vertex.attribute(n2,"name"))-1) )
	ccol[5 < ccol] <- 5
	ccol <- ccol + 3
	
	library( RColorBrewer )
	ccol <- brewer.pal(8, "Spectral")[ccol]

	ccol[var_select] <- "#FB8072" # #FB8072 #DEEBF7 #FF9966 #FFDAB9 "#F46D43"

	com_col_v <- "gray65"
	edg_col   <- "gray70"
	edg_lty   <- 1

}

# カラーリング「なし」の場合の線の色（2010 12/4）
if (com_method == "none" || com_method == "twomode_g"){
	ccol <- "white"
	com_col_v <- "black"
	edg_lty <- 1
	edg_col   <- "gray40"
}

if (com_method == "twomode_g"){
	edg_lty <- 3
}

';

}


sub r_plot_cmd_p3{

return 
'
# 初期配置
if ( length(get.vertex.attribute(n2,"name")) >= 3 ){
	d4l <- as.dist( shortest.paths(n2) )
	if ( min(d4l) < 1 ){
		d4l <- as.dist( shortest.paths(n2, weights=NA ) )
	}
	if ( max(d4l) == Inf){
		d4l[d4l == Inf] <- vcount(n2)
	}
	lay <-  cmdscale( d4l, k=2 )
	check4fr <- function(d){
		chk <- 0
		for (i in combn( length(d[,1]), 2, simplify=F ) ){
			if (
				   d[i[1],1] == d[i[2],1]
				&& d[i[1],2] == d[i[2],2]
			){
				return( i[1] )
			}
		}
		return( NA )
	}
	while ( is.na(check4fr(lay)) == 0 ){
		mv <-  check4fr(lay)
		lay[mv,1] <- lay[mv,1] + 0.001
		#print( paste( "Moved:", mv ) )
	}
} else {
	lay <- NULL
}

# 配置
if (
	   (com_method == "twomode_c" || com_method == "twomode_g")
	&& ( is.connected(n2) )
){
	lay_f <- layout.kamada.kawai(
		n2,
		start   = lay,
		weights = get.edge.attribute(n2, "weight")
	)
} else {
	lay_f <- layout.fruchterman.reingold(
		n2,
		start   = lay,
		weights = get.edge.attribute(n2, "weight")
	)
}

lay_f <- scale(lay_f,center=T, scale=F)
for (i in 1:2){
	lay_f[,i] <- lay_f[,i] - min(lay_f[,i]); # 最小を0に
	lay_f[,i] <- lay_f[,i] / max(lay_f[,i]); # 最大を1に
	lay_f[,i] <- ( lay_f[,i] - 0.5 ) * 1.96;
}

# 負の値を0に変換する関数
neg_to_zero <- function(nums){
  temp <- NULL
  for (i in 1:length(nums) ){
    if (nums[i] < 0){
      temp[i] <- 0
    } else {
      temp[i] <-  nums[i]
    }
  }
  return(temp)
}

# vertex.sizeを計算
if ( use_freq_as_size == 1 ){
	v_size <- freq[ as.numeric( get.vertex.attribute(n2,"name") ) ]
	if (com_method == "twomode_c" || com_method == "twomode_g"){
		v_size <- v_size[var_select==FALSE]
	}
	v_size <- v_size / sd(v_size)
	v_size <- v_size - mean(v_size)
	v_size <- v_size * 3 + 12 # 分散 = 3, 平均 = 12
	v_size <- neg_to_zero(v_size)
	if (com_method == "twomode_c" || com_method == "twomode_g"){
		v_size[var_select==FALSE] <- v_size
		v_size[var_select] <- 15
	}
} else {
	v_size <- 15
}

# vertex.label.cexを計算
if ( use_freq_as_fontsize ==1 ){
	f_size <- freq[ as.numeric( get.vertex.attribute(n2,"name") ) ]
	if (com_method == "twomode_c" || com_method == "twomode_g"){
		f_size <- f_size[var_select==FALSE]
	}
	f_size <- f_size / sd(f_size)
	f_size <- f_size - mean(f_size)
	f_size <- f_size * 0.2 + cex

	for (i in 1:length(f_size) ){
	  if (f_size[i] < 0.6 ){
	    f_size[i] <- 0.6
	  }
	}
	if (com_method == "twomode_c" || com_method == "twomode_g"){
		f_size[var_select==FALSE] <- f_size
		f_size[var_select] <- cex
	}
} else {
	f_size <- cex
}

# 小さめの円で描画
if (smaller_nodes ==1){
	f_size <- cex
	v_size <- 5
	vertex_label_dist <- 0.75
} else {
	vertex_label_dist <- 0
}

# edge.widthを計算
if ( use_weight_as_width == 1 ){
	edg_width <- el2[,3]
	edg_width <- edg_width / sd( edg_width )
	edg_width <- edg_width - mean( edg_width )
	edg_width <- edg_width * 0.6 + 2 # 分散 = 0.5, 平均 = 2
	edg_width <- neg_to_zero(edg_width)
} else {
	edg_width <- 1
}

# 外部変数・見出しを使う場合の形状やサイズ
if (com_method == "twomode_c" || com_method == "twomode_g"){
	# ノードの形
	v_shape <- rep("circle", length( get.vertex.attribute(n2,"name") ) )
	v_shape[var_select] <- "square"

	# 小さな円で描画している場合のノードサイズ
	if (smaller_nodes == 1){
		# ラベルの距離
		if (length( vertex_label_dist ) == 1){
			vertex_label_dist <- rep(
				vertex_label_dist,
				length( get.vertex.attribute(n2,"name") )
			)
		}
		vertex_label_dist[var_select] <- 0
		# サイズ
		if (length( v_size ) == 1){
			v_size <- rep(v_size, length( get.vertex.attribute(n2,"name") ) )
		}
		v_size[var_select] <- 10
	}

	# 識別用の「<>」を外す
	colnames(d)[
		substring(colnames(d), 1, 2) == "<>"
	] <- substring(
		colnames(d)[
			substring(colnames(d), 1, 2) == "<>"
		],
		3,
		nchar(colnames(d)[
			substring(colnames(d), 1, 2) == "<>"
		],type="c")
	)
}

'
}

sub r_plot_cmd_p4{

return 
'
# 語の強調
if ( exists("v_shape") == FALSE ){
	v_shape    <- "circle"
}
target_ids <-  NULL
if ( exists("target_words") ){
	# IDの取得
	for (i in 1:length( get.vertex.attribute(n2,"name") ) ){
		for (w in target_words){
			if (
				colnames(d)[ as.numeric(get.vertex.attribute(n2,"name")[i]) ]
				== w
			){
				target_ids <- c(target_ids, i)
			}
		}
	}
	# 形状
	if (length(v_shape) == 1){
		v_shape <- rep(v_shape, length( get.vertex.attribute(n2,"name") ) )
	}
	v_shape[target_ids] <- "square"
	# 枠線の色
	if (length(com_col_v) == 1){
		com_col_v <- rep(com_col_v, length( get.vertex.attribute(n2,"name") ) )
	}
	com_col_v[target_ids] <- "black"
	# サイズ
	if (length( v_size ) == 1){
		v_size <- rep(v_size, length( get.vertex.attribute(n2,"name") ) )
	}
	v_size[target_ids] <- 15
	# 小さな円で描画している場合
	rect_size <- 0.095
	if (smaller_nodes == 1){
		# ラベルの距離
		if (length( vertex_label_dist ) == 1){
			vertex_label_dist <- rep(
				vertex_label_dist,
				length( get.vertex.attribute(n2,"name") )
			)
		}
		vertex_label_dist[target_ids] <- 0
		# サイズ
		if (length( v_size ) == 1){
			v_size <- rep(v_size, length( get.vertex.attribute(n2,"name") ) )
		}
		v_size[target_ids] <- 10
		rect_size <- 0.07
	}
}

# プロット
if (smaller_nodes ==1){
	par(mai=c(0,0,0,0), mar=c(0,0,1,1), omi=c(0,0,0,0), oma =c(0,0,0,0) )
} else {
	par(mai=c(0,0,0,0), mar=c(0,0,0,0), omi=c(0,0,0,0), oma =c(0,0,0,0) )
}
if ( length(get.vertex.attribute(n2,"name")) > 1 ){
	plot.igraph(
		n2,
		vertex.label       =colnames(d)
		                    [ as.numeric( get.vertex.attribute(n2,"name") ) ],
		vertex.label.cex   =f_size,
		vertex.label.color ="black",
		vertex.label.family= "", # Linux・Mac環境では必須
		vertex.label.dist  =vertex_label_dist,
		vertex.color       =ccol,
		vertex.frame.color =com_col_v,
		vertex.size        =v_size,
		vertex.shape       =v_shape,
		edge.color         =edg_col,
		edge.lty           =edg_lty,
		edge.width         =edg_width,
		layout             =lay_f,
		rescale            =F
	)

if ( exists("target_words") ){
	if ( is.null(target_ids) == FALSE){
		rect(
			lay_f[target_ids,1] - rect_size, lay_f[target_ids,2] - rect_size,
			lay_f[target_ids,1] + rect_size, lay_f[target_ids,2] + rect_size,
		)
	}
}


if(0){
if (com_method == "twomode_g"){
# 枠付きプロット関数の設定
s.label_my <- function (dfxy, xax = 1, yax = 2, label = row.names(dfxy),
    clabel = 1, 
    pch = 20, cpoint = if (clabel == 0) 1 else 0, boxes = TRUE, 
    neig = NULL, cneig = 2, xlim = NULL, ylim = NULL, grid = TRUE, 
    addaxes = TRUE, cgrid = 1, include.origin = TRUE, origin = c(0, 
        0), sub = "", csub = 1.25, possub = "bottomleft", pixmap = NULL, 
    contour = NULL, area = NULL, add.plot = FALSE) 
{
    dfxy <- data.frame(dfxy)
    opar <- par(mar = par("mar"))
    on.exit(par(opar))
    par(mar = c(0.1, 0.1, 0.1, 0.1))
    coo <- scatterutil.base(dfxy = dfxy, xax = xax, yax = yax, 
        xlim = xlim, ylim = ylim, grid = grid, addaxes = addaxes, 
        cgrid = cgrid, include.origin = include.origin, origin = origin, 
        sub = sub, csub = csub, possub = possub, pixmap = pixmap, 
        contour = contour, area = area, add.plot = add.plot)
    if (!is.null(neig)) {
        if (is.null(class(neig))) 
            neig <- NULL
        if (class(neig) != "neig") 
            neig <- NULL
        deg <- attr(neig, "degrees")
        if ((length(deg)) != (length(coo$x))) 
            neig <- NULL
    }
    if (!is.null(neig)) {
        fun <- function(x, coo) {
            segments(coo$x[x[1]], coo$y[x[1]], coo$x[x[2]], coo$y[x[2]], 
                lwd = par("lwd") * cneig)
        }
        apply(unclass(neig), 1, fun, coo = coo)
    }
    if (clabel > 0) 
        scatterutil.eti(coo$x, coo$y, label, clabel, boxes)
    if (cpoint > 0 & clabel < 1e-06) 
        points(coo$x, coo$y, pch = pch, cex = par("cex") * cpoint)
    #box()
    invisible(match.call())
}
library(ade4)

s.label_my(
	lay_f[var_select,],
	xax=1,
	yax=2,
	label=colnames(d)[ as.numeric( get.vertex.attribute(n2,"name") ) ][var_select],
	boxes=T,
	clabel=0.8,
	addaxes=F,
	include.origin=F,
	grid=F,
	cpoint=0,
	cneig=0,
	cgrid=0,
	add.plot=T,
)
}
}



}
'
}


1;