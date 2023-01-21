package plotR::network;

use strict;
#use utf8;

use kh_r_plot::network;

my $debug = 0;

sub new{
	my $class = shift;
	my %args = @_;
	@_ = ();

	#print "$class\n";

	my $self = \%args;
	bless $self, $class;

	kh_r_plot::network->clear_env;

	my $r_command = $args{r_command};
	$args{r_command} = '';
	#print '$r_command is_utf8 (2): ', utf8::is_utf8($r_command), "\n";

	# パラメーター設定部分
	if ( $args{n_or_j} eq 'j'){
		$r_command .= "edges <- 0\n";
		$r_command .= "th <- $args{edges_jac}\n";
	}
	elsif ( $args{n_or_j} eq 'n'){
		$r_command .= "edges <- $args{edges_num}\n";
		$r_command .= "th <- -1\n";
	}
	$r_command .= "font_size <- $args{font_size}\n";
	$r_command .= "line_width <- $args{line_width}\n";
	$r_command .= "line_width_n <- $args{line_width_n}\n";

	$r_command .= "margin_top <- $args{margin_top}\n";
	$r_command .= "margin_bottom <- $args{margin_bottom}\n";
	$r_command .= "margin_left <- $args{margin_left}\n";
	$r_command .= "margin_right <- $args{margin_right}\n";

	unless ( $args{view_coef} ){
		$args{view_coef} = 0;
	}
	$r_command .= "view_coef <- $args{view_coef}\n";
	
	unless ( $args{fix_lab} ){
		$args{fix_lab} = 0;
	}
	$r_command .= "fix_lab <- $args{fix_lab}\n";

	unless ( $args{use_freq_as_size} ){
		$args{use_freq_as_size} = 0;
	}
	$r_command .= "use_freq_as_size <- $args{use_freq_as_size}\n";

	unless ( $args{bubble_size} ){
		$args{bubble_size} = 100;
	}
	$r_command .= "bubble_size <- $args{bubble_size}\n";

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

	$r_command .= "min_sp_tree_only <- $args{min_sp_tree_only}\n";

	$args{cor_var} = 0 unless length($args{cor_var} );
	$r_command .= "cor_var <- $args{cor_var}\n";

	$args{cor_var_darker} = 0 unless length($args{cor_var_darker} );
	$r_command .= "cor_var_darker <- $args{cor_var_darker}\n";

	$args{cor_var_min} = -1 unless length($args{cor_var_min} );
	$r_command .= "cor_var_min <- $args{cor_var_min}\n";
	$args{cor_var_max} = 1 unless length($args{cor_var_max} );
	$r_command .= "cor_var_max <- $args{cor_var_max}\n";

	$args{use_alpha} = 0 unless ( length($args{use_alpha}) );
	$r_command .= "use_alpha <- $args{use_alpha}\n";

	$args{gray_scale} = 0 unless ( length($args{gray_scale}) );
	$r_command .= "gray_scale <- $args{gray_scale}\n";

	$r_command .= "method_coef <- \"$args{method_coef}\"\n\n";

	$args{standardize_coef} = 1 unless ( length($args{standardize_coef}) );
	$r_command .= "standardize_coef <- $args{standardize_coef}\n";

	if (length($args{breaks})) {
		$r_command .= "breaks <- c($args{breaks})\n";
	} else {
		$r_command .= "breaks <- NULL\n";
	}

	$args{additional_plots} = 0 unless length( $args{additional_plots} );
	$r_command .= "# additional_plots: $args{additional_plots}\n";

	# プロット作成
	
	#use Benchmark;
	#my $t0 = new Benchmark;
	
	my @plots = ();
	my $x_factor = 4/3;
	
	if ($self->{edge_type} eq 'twomode'){
		$plots[0] = kh_r_plot::network->new(
			name      => $args{plotwin_name}.'_1',
			command_f =>
				 $r_command
				."com_method <- \"twomode_c\"\n"
				.$self->r_plot_cmd_p1
				.$self->r_plot_cmd_p2
				.$self->r_plot_cmd_p3
				.$self->r_plot_cmd_p4,
			width     => int( $args{plot_size} * $x_factor ),
			height    => $args{plot_size},
			font_size => $args{font_size},
		) or return 0;

		$plots[1] = kh_r_plot::network->new(
			name      => $args{plotwin_name}.'_2',
			command_f =>
				 $r_command
				."com_method <- \"twomode_g\"\n"
				.$self->r_plot_cmd_p1
				.$self->r_plot_cmd_p2
				.$self->r_plot_cmd_p3
				.$self->r_plot_cmd_p4,
			command_a =>
				 "com_method <- \"twomode_g\"\n"
				.$self->r_plot_cmd_p2
				.$self->r_plot_cmd_p4,
			width     => int( $args{plot_size} * $x_factor ),
			height    => $args{plot_size},
			font_size => $args{font_size},
		) or return 0;
	}
	elsif ($::config_obj->web_if == 0) {
		
		print "netwrok: cnt-b\n" if $debug;
		push (
			@plots,
			kh_r_plot::network->new(
				name      => $args{plotwin_name}.'_1',
				command_f =>
					 $r_command
					.$self->r_plot_cmd_p1
					."\ncom_method <- \"cnt-b\"\n"
					.$self->r_plot_cmd_p2
					.$self->r_plot_cmd_p3
					.$self->r_plot_cmd_p4,
				width     => int( $args{plot_size} * $x_factor ),
				height    => $args{plot_size},
				font_size => $args{font_size},
			)
		) or return 0;

		if ( $args{additional_plots} ) {
			print "netwrok: cnt-d\n" if $debug;
			push (
				@plots,
				kh_r_plot::network->new(
					name      => $args{plotwin_name}.'_2',
					command_f =>
						 $r_command
						."\ncom_method <- \"cnt-d\"\n"
						.$self->r_plot_cmd_p1
						.$self->r_plot_cmd_p2
						.$self->r_plot_cmd_p3
						.$self->r_plot_cmd_p4,
					command_a =>
						 "com_method <- \"cnt-d\"\n"
						.$self->r_plot_cmd_p2
						.$self->r_plot_cmd_p4,
					width     => int( $args{plot_size} * $x_factor ),
					height    => $args{plot_size},
					font_size => $args{font_size},
				)
			) or return 0;

			print "netwrok: cnt-e\n" if $debug;
			push (
				@plots,
				kh_r_plot::network->new(
					name      => $args{plotwin_name}.'_3',
					command_f =>
						 $r_command
						."\ncom_method <- \"cnt-e\"\n"
						.$self->r_plot_cmd_p1
						.$self->r_plot_cmd_p2
						.$self->r_plot_cmd_p3
						.$self->r_plot_cmd_p4,
					command_a =>
						 "com_method <- \"cnt-e\"\n"
						.$self->r_plot_cmd_p2
						.$self->r_plot_cmd_p4,
					width     => int( $args{plot_size} * $x_factor ),
					height    => $args{plot_size},
					font_size => $args{font_size},
				)
			) or return 0;

			print "netwrok: com-b\n" if $debug;
			push (
				@plots,
				kh_r_plot::network->new(
					name      => $args{plotwin_name}.'_4',
					command_f =>
						 $r_command
						."\ncom_method <- \"com-b\"\n"
						.$self->r_plot_cmd_p1
						.$self->r_plot_cmd_p2
						.$self->r_plot_cmd_p3
						.$self->r_plot_cmd_p4,
					command_a =>
						 "com_method <- \"com-b\"\n"
						.$self->r_plot_cmd_p2
						.$self->r_plot_cmd_p4,
					width     => int( $args{plot_size} * $x_factor ),
					height    => $args{plot_size},
					font_size => $args{font_size},
				)
			) or return 0;
		}

		print "netwrok: com-r\n" if $debug;
		push (
			@plots,
			kh_r_plot::network->new(
				name      => $args{plotwin_name}.'_5',
				command_f =>
					 $r_command
					."\ncom_method <- \"com-r\"\n"
					.$self->r_plot_cmd_p1
					.$self->r_plot_cmd_p2
					.$self->r_plot_cmd_p3
					.$self->r_plot_cmd_p4,
				command_a =>
					"com_method <- \"com-r\"\n"
					.$self->r_plot_cmd_p2
					.$self->r_plot_cmd_p4,
				width     => int( $args{plot_size} * $x_factor ),
				height    => $args{plot_size},
				font_size => $args{font_size},
			)
		) or return 0;

		print "netwrok: com-g\n" if $debug;
		push (
			@plots,
			kh_r_plot::network->new(
				name      => $args{plotwin_name}.'_6',
				command_f =>
					 $r_command
					."\ncom_method <- \"com-g\"\n"
					.$self->r_plot_cmd_p1
					.$self->r_plot_cmd_p2
					.$self->r_plot_cmd_p3
					.$self->r_plot_cmd_p4,
				command_a =>
					 "com_method <- \"com-g\"\n"
					.$self->r_plot_cmd_p2
					.$self->r_plot_cmd_p4,
				width     => int( $args{plot_size} * $x_factor ),
				height    => $args{plot_size},
				font_size => $args{font_size},
			)
		) or return 0;

		if (
			(
				   $args{plotwin_name} eq 'word_netgraph'
				|| $args{plotwin_name} eq 'cod_netg'
			)
			&& $args{cor_var} == 1
		) {
			print "netwrok: cor\n" if $debug;
			push (
				@plots,
				kh_r_plot::network->new(
					name      => $args{plotwin_name}.'_7',
					command_f =>
						 $r_command
						."\ncom_method <- \"cor\"\n"
						.$self->r_plot_cmd_p1
						.$self->r_plot_cmd_p2
						.$self->r_plot_cmd_p3
						.$self->r_plot_cmd_p4,
					command_a =>
						 "com_method <- \"cor\"\n"
						.$self->r_plot_cmd_p2
						.$self->r_plot_cmd_p4,
					width     => int( $args{plot_size} * $x_factor ),
					height    => $args{plot_size},
					font_size => $args{font_size},
				)
			);
			return 0 unless $plots[$#plots];
		}

		if ( $args{additional_plots} ) {
			print "netwrok: none\n" if $debug;
			push (
				@plots,
				kh_r_plot::network->new(
					name      => $args{plotwin_name}.'_8',
					command_f =>
						 $r_command
						."\ncom_method <- \"none\"\n"
						.$self->r_plot_cmd_p1
						.$self->r_plot_cmd_p2
						.$self->r_plot_cmd_p3
						.$self->r_plot_cmd_p4,
					command_a =>
						 "com_method <- \"none\"\n"
						#.$self->r_plot_cmd_p2
						.$self->r_plot_cmd_p4,
					width     => int( $args{plot_size} * $x_factor ),
					height    => $args{plot_size},
					font_size => $args{font_size},
				)
			);
			return 0 unless $plots[$#plots];
		}
	} else { # For web if
		$plots[5] = kh_r_plot::network->new(
			name      => $args{plotwin_name}.'_6',
			command_f =>
				 $r_command
				."\ncom_method <- \"com-r\"\n"
				.$self->r_plot_cmd_p1
				.$self->r_plot_cmd_p2
				.$self->r_plot_cmd_p3
				.$self->r_plot_cmd_p4,
			width     => int( $args{plot_size} * $x_factor ),
			height    => $args{plot_size},
			font_size => $args{font_size},
		) or return 0;
	}
	
	#my $t1 = new Benchmark;
	#print timestr(timediff($t1,$t0)),"\n" if $bench;

	# 座標の取得
	my $csv = $::project_obj->file_TempCSV;
	$::config_obj->R->send("
		if (com_method == 'twomode_c' || com_method == 'twomode_g') {
			coord <- lay_f[var_select==F,]
		} else {
			coord <- lay_f
		}
		
		add <- -1 * xlimv[1]
		div <- add + xlimv[2]
		coord[,1] <- ( coord[,1] + add ) / div
		
		add <- -1 *  ylimv[1]
		div <- add + ylimv[2]
		coord[,2] <- ( coord[,2] + add ) / div
		
		write.table(coord, file=\"".$::config_obj->uni_path($csv)."\", fileEncoding=\"UTF-8\", sep=\"\\t\", quote=F, col.names=F)\n
	");

	# 情報の取得（短いバージョン）
	my $info;
	$::config_obj->R->send('
		print(
			paste(
				"khcoderN ",
				length(igraph::get.vertex.attribute(n2,"name")),
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
		thrnd <- NULL
		if ( round( th, 3 ) == 0 ){
			thrnd <- "0"
		} else {
			thrnd <- substr( paste( round( th, 3 ) ), 2, 5)
		}
		print(
			paste(
				"khcoderNodes ",
				length(igraph::get.vertex.attribute(n2,"name")),
				" (",
				length(igraph::get.vertex.attribute(n,"name")),
				"), Edges ",
				length(get.edgelist(n2,name=T)[,1]),
				" (",
				length(get.edgelist(n,name=T)[,1]),
				"), Density ",
				substr(paste( round( graph.density(n2), 3 ) ), 2, 5 ),
				", Min. Coef. ",
				thrnd,
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

	# get XY ratio
	$::config_obj->R->send("
		ratio <- ( xlimv[2] - xlimv[1] ) / ( ylimv[2] - ylimv[1] )
		print( paste0('<ratio>', ratio ,'</ratio>') )
	");
	my $ratio = $::config_obj->R->read;
	if ( $ratio =~ /<ratio>(.+)<\/ratio>/) {
		$ratio = $1;
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

	# get breaks of bubble plot legend
	if ($args{use_freq_as_size}){
		$::config_obj->R->send('
			legend_breaks_n <- ""
			for ( i in 1:length(breaks_a) ){
				legend_breaks_n <- paste(legend_breaks_n, breaks_a[i], sep = ", ")
			}
			print(paste0("<breaks>", legend_breaks_n, "</breaks>"))
		');
		my $breaks = $::config_obj->R->read;
		if ( $breaks =~ /<breaks>(.+)<\/breaks>/) {
			$breaks = $1;
			substr($breaks, 0, 2) = '';
		}
		foreach my $i (@plots){
			$i->{command_f} .= "\n# breaks: $breaks\n";
		}
		print "breaks: $breaks\n";
	}

	kh_r_plot::network->clear_env;
	undef $self;
	undef %args;
	$self->{result_plots} = \@plots;
	$self->{result_info} = $info;
	$self->{result_info_long} = $info_long;
	$self->{coord} = $csv;
	$self->{ratio} = $ratio;
	
	my $n = @plots;
	print "plots: $n\n";
	
	return $self;
}

sub r_plot_cmd_p1{
	my $t = '

# Count frequency of each word
freq <- NULL
for (i in 1:length( rownames(d) )) {
	freq[i] = sum( d[i,] )
}

# Compute co-occurrence coefficient
if (
	(exists("doc_length_mtr"))
	&! (
		(method_coef == "binary")
		|| (method_coef == "Dice")
		|| (method_coef == "Simpson")
	)
){
	leng <- as.numeric(doc_length_mtr[,2])
	leng[leng ==0] <- 1
	d <- t(d)
	d <- d / leng
	d <- d * 1000
	d <- t(d)
}
if (method_coef == "euclid"){ # standardize for each word
	d <- t( scale( t(d) ) )
}

dr <- d
if (
	   ( method_coef == "Dice" )
	|| ( method_coef == "Simpson" )
){
	library(proxy)
	d <- proxy::dist(d,method=method_coef)
	detach("package:proxy")
} else {
	library(amap)
	d <- Dist(d,method=method_coef)
}

d <- as.matrix(d)
if ( method_coef == "euclid" ){
	d <- max(d) - d
	d <- d / max(d)
} else {
	d <- 1 - d
}

# For twomode
if ( exists("com_method") ){
	if ( com_method == "twomode_c" || com_method == "twomode_g" ){
		# delete unnecessary edges
		d[1:n_words,] <- 0

		# standardize coef.
		if ( standardize_coef == 1 ) {
			std  <- d[(n_words+1):nrow(d),1:n_words]
			chkm <- std
			
			std <- t(std)
			std <- scale(std, center=T, scale=F)
			std <- t(std)
	
			chkm_temp <- chkm[!is.na(chkm)]
			std_range <- max(chkm_temp) - min(chkm_temp[chkm_temp!=0])
			std <- std - min(std[!is.na(std)])        # min = 0
			std <- std / max(std[!is.na(std)])        # max = 1
			std <- std * std_range                    # set range
			std <- std + min(chkm_temp[chkm_temp!=0]) # set min
			chkm_temp <- NULL
			
			std[chkm == 0] <- 0
			d[(n_words+1):nrow(d),1:n_words] <- std
		}
	}
}

# Make a graph
# For igraph > 1.0.0
library(igraph)
new_igraph <- 0
igraph_ver <- (
	  as.numeric( substr(sessionInfo()$otherPkgs$igraph$Version, 1,1) ) * 10
	+ as.numeric( substr(sessionInfo()$otherPkgs$igraph$Version, 3,3) )
)
if ( igraph_ver > 5){
	new_igraph <- 1
}

n <- graph.adjacency(d, mode="lower", weighted=T, diag=F)
n <- igraph::set.vertex.attribute(
	n,
	"name",
	(0+new_igraph):(length(d[1,])-1+new_igraph),
	as.character( 1:length(d[1,]) )
)

# Prepare for deleting weak edges
el <- data.frame(
	edge1            = get.edgelist(n,name=T)[,1],
	edge2            = get.edgelist(n,name=T)[,2],
	weight           = igraph::get.edge.attribute(n, "weight"),
	stringsAsFactors = FALSE
)

# making backup of coef.
if ( exists("com_method") ){
	if (
		( com_method == "twomode_c" || com_method == "twomode_g" )
		&& ( standardize_coef == 1 )
	){
		dbb <- d
		dbb[(n_words+1):nrow(dbb),1:n_words] <- chkm
		
		nbb <- graph.adjacency(dbb, mode="lower", weighted=T, diag=F)
		nbb <- igraph::set.vertex.attribute(
			nbb,
			"name",
			(0+new_igraph):(length(dbb[1,])-1+new_igraph),
			as.character( 1:length(dbb[1,]) )
		)
		
		elbb <- data.frame(
			edge1            = get.edgelist(nbb,name=T)[,1],
			edge2            = get.edgelist(nbb,name=T)[,2],
			weight_b           = igraph::get.edge.attribute(nbb, "weight"),
			stringsAsFactors = FALSE
		)
		
		if ( identical(el[,1:2], elbb[,1:2]) == F ){
			print("Error: could not make coef. backup!")
		}
		
		el <- data.frame(el, elbb$weight_b)
	}
}

# Find a threshold value
if (th < 0){
	if(edges > length(el[,1])){
		edges <- length(el[,1])
	}
	th = quantile(
		el$weight,
		names = F,
		probs = 1 - edges / length(el[,1])
	)
}

# Delete weak edges and make a graph again
el2 <- subset(el, el[,3] >= th)
if ( nrow(el2) == 0 ){
	stop(message = "No edges to draw!", call. = F)
}
n2  <- graph.edgelist(
	matrix( as.matrix(el2)[,1:2], ncol=2 ),
	directed	=F
)
n2 <- igraph::set.edge.attribute(
	n2,
	"weight",
	(0+new_igraph):(length(get.edgelist(n2)[,1])-1+new_igraph),
	el2[,3]
)

# use the backup of coef.
if ( exists("com_method") ){
	if (
		( com_method == "twomode_c" || com_method == "twomode_g" )
		&& ( standardize_coef == 1 )
	){
		n2 <- igraph::set.edge.attribute(
			n2,
			"weight",
			(0+new_igraph):(length(get.edgelist(n2)[,1])-1+new_igraph),
			el2[,4]
		)
	}
}

if ( min_sp_tree_only == 1 ){
	n2 <- minimum.spanning.tree(
		n2,
		weights = 1 - igraph::get.edge.attribute(n2, "weight"),
		algorithm="prim"
	)
}

';
	# こんなことをせずに「use utf8;」と書きたいが、そうするとなぜかMac版のPerlAppで作ったバイナリで文字化け
	$t = Encode::decode('UTF-8', $t);
	return $t;
}

sub r_plot_cmd_p2{

	my $t = 
'
if (length(igraph::get.vertex.attribute(n2,"name")) < 2){
	com_method <- "none"
}

# Centrality
if ( com_method == "cnt-b" || com_method == "cnt-d" || com_method == "cnt-e"){
	ccol <- NULL
	if (com_method == "cnt-b"){                   # betweenness
		ccol <- igraph::betweenness(
			n2,
			v=(0+new_igraph):(length(igraph::get.vertex.attribute(n2,"name"))-1+new_igraph),
			directed=F
		)
	}
	if (com_method == "cnt-d"){                   # degree
		ccol <-  igraph::degree(
			n2,
			v=(0+new_igraph):(length(igraph::get.vertex.attribute(n2,"name"))-1+new_igraph)
		)
	}
	if (com_method == "cnt-e"){                   # evcent
		try(
			ccol <- igraph::evcent(n2)$vector,
			silent = T
		)
	}
	ccol_raw <- ccol

	edg_col   <- "gray55"
	edg_lty   <- 1
}

# Community detection
if (com_method == "com-b" || com_method == "com-g" || com_method == "com-r"){
	merge_step <- function(n2, m){                # 共通利用の関数
		for ( i in 1:( trunc( length( m ) / 2 ) ) ){
			temp_csize <- community.to.membership(n2, m,i)$csize
			num_max   <- max( temp_csize )
			num_alone <- sum( temp_csize[ temp_csize == 1 ] )
			num_cls   <- length( temp_csize[temp_csize > 1] )
			#print( paste(i, "a", num_alone, "max", num_max, "cls", num_cls) )
			if (
				# 最大コミュニティサイズが全ノード数の22.5%以上
				   num_max / length(igraph::get.vertex.attribute(n2,"name")) >= 0.225
				# かつ、最大コミュニティサイズが単独ノード数よりも大きい
				&& num_max > num_alone
				# かつ、サイズが2以上のコミュニティ数が12未満
				&& num_cls < 12
			){
				return(i)
			}
			# 最大コミュニティサイズがノード数の40%を越える直前で打ち切り
			if (num_max / length(igraph::get.vertex.attribute(n2,"name")) >= 0.4 ){
				return(i-1)
			}
		}
		return( trunc(length( m ) / 2) )
	}
	# For igraph > 1.0.0
	if (com_method == "com-b"){                   # Betweenness
		com   <- edge.betweenness.community(n2, directed=F)    
		if (igraph_ver < 10){
			com_m <- community.to.membership(
				n2, com$merges, merge_step(n2,com$merges)
			)
			com_m$membership <- com_m$membership + new_igraph
		}
	}
	if (com_method == "com-g"){                   # Modularity
		com   <- fastgreedy.community   (n2, merges=TRUE, modularity=TRUE)
		if (igraph_ver < 10){
			com_m <- community.to.membership(
				n2, com$merges, merge_step(n2,com$merges)
			)
			com_m$membership <- com_m$membership + new_igraph
		}
	}
	if (com_method == "com-r"){                   # Random walks
		com   <-  walktrap.community(
			n2,
			weights=igraph::get.edge.attribute(n2, "weight")
		)
		if (igraph_ver < 10){
			com_m <- NULL
			com_m$membership <- com$membership
			com_m$csize      <- table(com$membership)
		}
	}
	if (igraph_ver >= 10){
		com_m <- NULL
		com_m$membership <- as.vector( membership(com) )
		com_m$csize      <- table(com_m$membership)
	}

	# Configure Edges
	edg_lty <- NULL
	edg_col <- NULL
	for (i in 1:nrow(get.edgelist(n2,name=F))){
		if (
			   com_m$membership[ get.edgelist(n2,name=F)[i,1] + 1 - new_igraph]
			== com_m$membership[ get.edgelist(n2,name=F)[i,2] + 1 - new_igraph]
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
	if ( exists("var_select") ){
		var_select_bak <- var_select
	}
	
	var_select <- substring(
		colnames(d)[ as.numeric( igraph::get.vertex.attribute(n2,"name") ) ],
		1,
		2
	) == "<>"

	if (length(var_select[var_select==TRUE]) == 0 && exists("var_select_bak")){
		var_select <- var_select_bak;
	}
}

if (com_method == "twomode_c"){
	ccol <-  igraph::degree(
		n2,
		v=(0+new_igraph):(length(igraph::get.vertex.attribute(n2,"name"))-1+new_igraph)
	)
	# ggplot2
	ccol_raw <- ccol
	ccol_raw[var_select] <- NA
	ccol_raw[ccol_raw >= 5] <- 5
	ccol_raw <- as.character(ccol_raw)
	ccol_raw[ccol_raw=="5"] <- "5+"

	edg_col   <- "gray70"
	edg_lty   <- 1

}

# カラーリング「なし」の場合の線の色（2010 12/4）
if (com_method == "none" || com_method == "twomode_g"){
	edg_lty <- 1
	edg_col   <- "gray40"
}

if (com_method == "twomode_g"){
	edg_lty <- 3
}

# Minimum Spanning Tree
if ( min_sp_tree == 1 ){
	# MSTの検出
	mst <- minimum.spanning.tree(
		n2,
		weights = 1 - igraph::get.edge.attribute(n2, "weight"),
		algorithm="prim"
	)

	# MSTに合致するedgeを強調
	#if (length(edg_col) == 1){
		edg_col <- rep("gray55", length( igraph::get.edge.attribute(n2, "weight") )) 
	#}

	n2_edges  <- get.edgelist(n2,name=T);
	mst_edges <- get.edgelist(mst,name=T);

	if (exists("edg_lty") == F){
		edg_lty <- 1
	}
	for ( i in 1:ecount(n2) ){
		name_n2 <- paste(
			n2_edges[i,1],
			n2_edges[i,2]
		)
		for ( j in 1:ecount(mst) ){
			name_mst <- paste(
				mst_edges[j,1],
				mst_edges[j,2]
			)
			if ( name_n2 == name_mst ){
				edg_col[i]   <- "gray30"                   # edge color
				if ( length(edg_lty) > 1 ){
					edg_lty[i] <- 1                        # edge linetype
				}
				break
			}
		}
	}
	edg_mst <- edg_col
}
';
	$t = Encode::decode('UTF-8', $t);
	return $t;
}


sub r_plot_cmd_p3{

	my $t =
'
# 初期配置
lay <- NULL
if ( length(igraph::get.vertex.attribute(n2,"name")) >= 3 ){
	d4l <- as.dist( shortest.paths(n2) )
	if ( min(d4l) < 1 ){
		d4l <- as.dist( shortest.paths(n2, weights=NA ) )
	}
	if ( max(d4l) == Inf){
		d4l[d4l == Inf] <- vcount(n2)
	}
	try( lay <- cmdscale( d4l, k=2 ), silent=TRUE )
	if ( is.null(lay) == F ){
		lay <- round(lay, digits=5)
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
		salt <- 1
		while ( is.na(check4fr(lay)) == 0 ){
			mv <-  check4fr(lay)
			lay[mv,1] <- lay[mv,1] + 0.001 * salt
			# Much faster if you add salt. But layout will be changed.
			#salt <- salt + 0.2
			#print( paste( "Moved:", mv ) )
		}
	}
}

# 配置
set.seed(100)
if (
	   (com_method == "twomode_c" || com_method == "twomode_g")
	&& ( igraph::is.connected(n2) )
){
	# For igraph > 1.0.0
	if (igraph_ver >= 10){
		lay_f <- layout.kamada.kawai(
			n2,
			#coords   = lay,
			weights = igraph::get.edge.attribute(n2, "weight")
		)
	} else {
		lay_f <- layout.kamada.kawai(
			n2,
			start   = lay,
			weights = igraph::get.edge.attribute(n2, "weight")
		)
	}
} else {
	# For igraph > 1.0.0
	if (igraph_ver >= 10){
		lay_f <- layout.fruchterman.reingold(
			n2,
			#coords   = lay,
			niter   = vcount(n2) * 512,
			weights = igraph::get.edge.attribute(n2, "weight")
		)
	} else {
		lay_f <- layout.fruchterman.reingold(
			n2,
			start   = lay,
			niter   = vcount(n2) * 512,
			weights = igraph::get.edge.attribute(n2, "weight")
		)
	}
}

lay_f <- scale(lay_f,center=T, scale=F)
for (i in 1:2){
	lay_f[,i] <- lay_f[,i] - min(lay_f[,i]); # 最小を0に
	lay_f[,i] <- lay_f[,i] / max(lay_f[,i]); # 最大を1に
	lay_f[,i] <- ( lay_f[,i] - 0.5 ) * 1.96;
}


# 外部変数・見出しを使う場合の形状やサイズ
if (com_method == "twomode_c" || com_method == "twomode_g"){
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

';
	$t = Encode::decode('UTF-8', $t);
	return $t;
}

sub r_plot_cmd_p4{

	my $t = 
'
if ( exists("saving_emf") || exists("saving_eps") ){
	use_alpha <- 0           # need something before \n (gui_widget::r_net)
	use_weight_as_width <- 0 # need something before \n (gui_widget::r_net)
}

target_ids <-  NULL
if ( exists("target_words") ){
	# get word IDs
	for (i in 1:length( igraph::get.vertex.attribute(n2,"name") ) ){
		for (w in target_words){
			if (
				colnames(d)[ as.numeric(igraph::get.vertex.attribute(n2,"name")[i]) ]
				== w
			){
				target_ids <- c(target_ids, i)
			}
		}
	}
}

edge_label <- NULL

font_fam <- "'.Encode::encode('UTF-8',$::config_obj->font_plot_current).'"
if ( exists("PERL_font_family") ){
	font_fam <- PERL_font_family
}

if ( length(igraph::get.vertex.attribute(n2,"name")) > 1 ){
	if (fix_lab == 1){
		if (exists("if_fixed") == 0){
			plot.new()
			plot.window(xlim=c(-1, 1), ylim=c(-1, 1))
			
			labcd <- NULL
			labcd$x <- lay_f[,1]
			labcd$y <- lay_f[,2]
			word_labs <- colnames(d)[ as.numeric( igraph::get.vertex.attribute(n2,"name") ) ]
	
			library(wordcloud)'
			.&r_command_wordlayout
			.'nc <- wordlayout(
				labcd$x,
				labcd$y,
				word_labs,
				cex=1.28,
				xlim=c( -1, 1 ),
				ylim=c( -1, 1 )
			)
	
			xorg <- labcd$x
			yorg <- labcd$y
			labcd$x <- nc[,1] + .5 * nc[,3]
			labcd$y <- nc[,2] + .5 * nc[,4]
			lay_f <- cbind(labcd$x, labcd$y)
	
			if_fixed <- 1
		}
	}

#-----------------------------------------------------------------------------#
#                       Prepare for Plotting with ggplot2                     #

#------------------------------------------------#
#  get ready for ggplot2 graph drawing (0): cor  #

if ( com_method == "cor" ){  # cor
	dr <- as.data.frame( t(dr) )
	dv <- data.frame(
	  khvar_ = as.numeric(v0)
	)
	dr <- cbind(dr,dv)

	edge_pos <- NULL
	edges <- get.edgelist(n2, names=TRUE)
	for (i in 1:nrow(edges)){
		i1 <- as.numeric( edges[i,1] )
		i2 <- as.numeric( edges[i,2] )
		
		edge_pos <- c(
			edge_pos,
			cor(
				as.numeric( dr[,i1] > 0 & dr[,i2] >0 ),
				dr$khvar_,
				method="pearson"
			)
			#mean( dr[dr[,i1] > 0 & dr[,i2] >0,]$khvar_ )
		)
	}

	if ( length( edge_pos[is.na(edge_pos) == F] ) == 0 ){
		edge_pos <- 0
	}

	#n2 <- igraph::set.edge.attribute(
	#	n2,
	#	"edge_pos_o",
	#	1:length(igraph::get.edge.attribute(n2,"weight")),
	#	edge_pos
	#)

	#edge_pos <- edge_pos - mean(edge_pos)
	#edge_pos <- edge_pos / sd(edge_pos)
	##edge_pos <- edge_pos * 10 + 50

	#limv <- 0.15
	#maxv <- max( abs( edge_pos ) )
	
	#if ( limv < maxv ){
	#	edge_pos[edge_pos > limv]  <- limv
	#	edge_pos[edge_pos < -limv] <- -limv
	#}

	edge_pos[edge_pos > cor_var_max] <- cor_var_max
	edge_pos[edge_pos < cor_var_min] <- cor_var_min
	
	n2 <- igraph::set.edge.attribute(
		n2,
		"edge_pos",
		1:length(igraph::get.edge.attribute(n2,"weight")),
		edge_pos
	)

	ver_pos <- NULL
	vertices <- as.numeric( igraph::get.vertex.attribute(n2,"name") )
	for (i in 1:length(vertices) ){
		ver_pos <- c(
			ver_pos,
			cor(
				as.numeric( dr[,vertices[i]] > 0 ),
				dr$khvar_,
				method="pearson"
			)
		)
	}

	if ( length( ver_pos[is.na(ver_pos) == F] ) == 0 ){
	  ver_pos <- 0
	}

	ver_pos[ver_pos > max(edge_pos)] <- max(edge_pos)
	ver_pos[ver_pos < min(edge_pos)] <- min(edge_pos)

	#n2 <- igraph::set.vertex.attribute(
	#	n2,
	#	"ver_pos",
	#	1:length(igraph::get.vertex.attribute(n2,"name")),
	#	ver_pos
	#)
	ccol_raw <- ver_pos
	if ( is.null( igraph::get.vertex.attribute(n2,"com") ) == FALSE ){
		n2 <- remove.vertex.attribute(n2, "com")
		edg_lty <- 1
	}
}

#-----------------------------------------------#
#  get ready for ggplot2 graph drawing (1): n2  #

n2 <- igraph::set.vertex.attribute(
	n2,
	"lab",
	1:length(igraph::get.vertex.attribute(n2,"name")),
	colnames(d)[ as.numeric( igraph::get.vertex.attribute(n2,"name") ) ]
)

ver_freq <- freq[ as.numeric( igraph::get.vertex.attribute(n2,"name") ) ]

if (com_method == "twomode_c" || com_method == "twomode_g"){
	ver_freq[var_select] <- NA
}

if ( is.null(target_ids) == FALSE ){
	ver_freq[target_ids] <- NA
}

if (use_freq_as_size == 0){
	ver_freq[ver_freq > 0] <- 1
}

n2 <- igraph::set.vertex.attribute(
	n2,
	"size",
	1:length(igraph::get.vertex.attribute(n2,"name")),
	ver_freq
)

# For community detection

if ( exists("ccol") ){ # clean up previous data
	try( n2 <- remove.vertex.attribute(n2, "com"), silent=T )
}

if ( exists("com_m") ){
	com_label <- NULL

	for (h in 1:length(com_m$membership)){
		i <- com_m$membership[h]
		if ( com_m$csize[i] > 1 ) {
			if (i < 10){
				com_label <- c(
					com_label,
					paste("0", as.character(i), "   ", sep="")
				)
			} else {
				com_label <- c(com_label, as.character(i))
			}
		} else {
			com_label <- c(com_label, NA)
		}
	}

	n2 <- igraph::set.vertex.attribute(
		n2,
		"com",
		1:length(igraph::get.vertex.attribute(n2,"name")),
		com_label
	)
}

if ( exists("ccol_raw") ){
	n2 <- igraph::set.vertex.attribute(
		n2,
		"com",
		1:length(igraph::get.vertex.attribute(n2,"name")),
		ccol_raw
	)
	com_label <- ccol_raw
}

if ( com_method == "none" || com_method == "twomode_g"){
	n2 <- igraph::set.vertex.attribute(
		n2,
		"com",
		1:length(igraph::get.vertex.attribute(n2,"name")),
		rep( "na", length(igraph::get.vertex.attribute(n2,"name")) )
	)
	com_label <- NA
}

if ( exists("edg_mst") ){
	n2 <- igraph::set.edge.attribute(
		n2,
		"edg_col",
		1:length(igraph::get.edge.attribute(n2,"weight")),
		edg_mst
	)
	#print(edg_mst)
}

if ( exists("edg_lty") == F ){
	edg_lty <- 1
}
edg_lty[edg_lty==1] <- "solid"
edg_lty[edg_lty==3] <- "dotted"

n2 <- igraph::set.edge.attribute(
	n2,
	"line",
	1:length(igraph::get.edge.attribute(n2,"weight")),
	edg_lty
)

#-------------------------------------------------------#
#  get ready for ggplot2 graph drawing (2): parameters  #

library(ggplot2)
library(ggnetwork)

p <- ggplot(
	ggnetwork(n2, layout=lay_f),
	aes(x = x, y = y, xend = xend, yend = yend),
)

if (use_alpha == 1){
	alpha_value = 0.62
	gray_color_n <- "gray20"
} else {
	alpha_value = 1
	gray_color_n <- "gray40"

}

if (text_font == 2){
	face <- "bold"
} else {
	face <- "plain"
}
if (smaller_nodes == 1 ){
	edge_colour <- "gray68"
	nudge <- 0.015
	hjust <- "left"
} else {
	edge_colour <- "gray55"
	nudge <- 0
	hjust <- "center"
}

if (com_method == "twomode_c"){
	edge_colour <- "gray70"
}

if (com_method == "none" || com_method == "twomode_g"){
	edge_colour <- "gray40"
	gray_color_n <- "black"
}

rownames(lay_f) <- colnames(d)[ as.numeric( igraph::get.vertex.attribute(n2,"name") ) ]
lay_f[,1] <- lay_f[,1] - min(lay_f[,1])
lay_f[,1] <- lay_f[,1] / max(lay_f[,1])
lay_f[,2] <- lay_f[,2] - min(lay_f[,2])
lay_f[,2] <- lay_f[,2] / max(lay_f[,2])
lay_f_df <- data.frame(
	x = lay_f[,1],
	y = lay_f[,2],
	lab = rownames(lay_f)
)

if ( smaller_nodes == 1 ){
	vv <- 6.2
} else {
	vv <- 20
}

sans <- "sans"
if ( exists("saving_eps") ){
	sans <- NULL
}

#-----------------------------------------------------------------------------#
#                           Start Plotting with ggplot2                       #

#---------#
#  Edges  #

line_width_act <- line_width / 100

if (com_method == "cor"){ # cor

	if ( gray_scale == 1) {
		myPalette <- gray( seq(1, 0, length.out=100) )
		gray_color_n <- "black"
		if (alpha_value < 0.8) {
			alpha_value <- 0.8
		}
		p <- p + geom_edges(
			color = "black",
			size = 1.5 * line_width_act
		)
		p <- p + geom_edges(
			aes(
				color = edge_pos
			),
			size = 1 * line_width_act,
		)
		ticks_color = "white"
	} else {
		myPalette <- colorRampPalette(
			rev( brewer.pal(9, "RdYlBu") )
		)(100) #Spectral
		p <- p + geom_edges(
			aes(
				color = edge_pos
			),
			size = 0.6 * line_width_act,
		)
		ticks_color = "gray40"
	}

	p <- p + scale_color_gradientn(
		colours = myPalette,
		#limits = c( min(edge_pos), limv ),
		#limits = c( 0 - limv, 0 + limv ),
		guide = guide_colourbar(
			title = "Correlation:\n",
			title.theme = element_text(
				family=sans,
				face="bold",
				size=11,
				lineheight=0.4,
				angle=0
			),
			order = 1,
			#override.aes = list(size=6, shape=22),
			label.hjust = 1,
			ticks.colour = ticks_color,
			ticks.linewidth = 1.25/.pt,
			#reverse = TRUE,
			#ncol=2,
			#keyheight = unit(1.5,"line")
		)
	)
	p <- p + scale_fill_gradientn(
		colours = myPalette,
		guide = FALSE
	)
} else if (min_sp_tree == 1){
	edg_col2 <- p$data$edg_col
	edg_col2[edg_col2=="gray30"] <- "MST"
	edg_col2[edg_col2=="gray55"] <- "non-MST"
	edg_col2[edg_col2=="gray70"] <- "non-MST"
	p <- p + geom_edges(
		aes(linetype = as.character(line), alpha=edg_col2),
		size = 0.4 * line_width_act,
		color = "grey10"
	)
	p <- p + scale_alpha_discrete(
		range = c(1, 0.3),
		guide = guide_legend(
			title = "Edge:",
			keyheight = unit(1.2,"line"),
			order = 2
		)
	)
} else if ( use_weight_as_width == 1 ){
	p <- p + geom_edges(
		aes(linetype = as.character(line), alpha=weight),
		size = 0.4 * line_width_act,
		color = "grey10"
	)
	p <- p + scale_alpha(
		range = c(0.2, 1),
		guide = guide_legend(
			title = "Coefficient:",
			label.hjust = 1,
			keyheight = unit(1.2,"line"),
			order = 2
		)
	)
} else {
	p <- p + geom_edges(
		aes(linetype = as.character(line)),
		size = 0.4 * line_width_act,
		color = edge_colour
	)
}

p <- p + scale_linetype_identity()

#---------#
#  Nodes  #

# words

line_width_n_act <- line_width_n / 100

p <- p + geom_nodes(                # fill the entire shape
	aes(
		size = size * 0.41,
		color = com
	),
	alpha = 0.85,
	show.legend = F,
	shape = 16
)
p <- p + geom_nodes(                # fill the core
	aes(
		size = size,
		color = com,
		shape = shape
	),
	alpha = alpha_value,
	shape = 16
)
p <- p + geom_nodes(                # frame border
	aes(
		size = size,
		shape = shape
	),
	colour = gray_color_n,
	show.legend = F,
	alpha = alpha_value,
	stroke = 0.5 * line_width_n_act,
	shape = 1
)
p <- p + geom_nodes(                # dummy for the legend
	aes( fill = com ),
	size=0,
	colour = gray_color_n,
	alpha = 0,
	shape = 21
)

if ( use_freq_as_size == 1 ){
	# bubble plot legend configuration
	limits_a <- c(NA, NA);
	if (is.null(breaks)){
		breaks <- labeling::extended(
			min(ver_freq, na.rm=T),
			max(ver_freq, na.rm=T),
			5
		)
		breaks_a <- NULL
		for ( i in 1:length(breaks) ){
			if (
				   min(ver_freq, na.rm=T) <= breaks[i]
				&& max(ver_freq, na.rm=T) >= breaks[i]
			){
				breaks_a <- c(breaks_a, breaks[i])
			}
		}
		breaks <- breaks_a
	} else {
		breaks_a <- breaks
		if (  min(breaks) < min(ver_freq, na.rm=T) ){
			limits_a[1] <- min(breaks)
		}
		if (  max(breaks) > max(ver_freq, na.rm=T) ){
			limits_a[2] <- max(breaks)
		}
	}

	p <- p + scale_size_area(
		"Frequency",
		max_size = 30 * bubble_size / 100,
		breaks = breaks_a,
		limits = limits_a,
		guide = guide_legend(
			title = "Frequency:",
			override.aes = list(colour="black", alpha=1, shape=1),
			label.hjust = 1,
			order = 3
		)
	)
} else {
	p <- p + scale_size_area(
		max_size = vv,
		guide = F
	)
}

# variables

if ( (com_method == "twomode_c" || com_method == "twomode_g") ) {
	# (is.null(target_ids) == FALSE)

	if ( com_method == "twomode_c" ){
		var_outline_c <- "gray50"
		var_fill_c <- "#FB8072"
	}
	if ( com_method == "twomode_g" ){
		var_outline_c <- "black"
		var_fill_c <- "white"
	}
	
	p <- p + geom_point(
		data = data.frame(
			x = lay_f[var_select,1],
			y = lay_f[var_select,2]
		),
		aes(
			x = x,
			y = y,
			xend = x,
			yend = y
		),
		fill = var_fill_c,
		show.legend = F,
		colour = NA,
		alpha = 0.8,
		size = vv * 2 / 3,
		shape = 22
	)
	
	p <- p + geom_point(
		data = data.frame(
			x = lay_f[var_select,1],
			y = lay_f[var_select,2]
		),
		aes(
			x = x,
			y = y,
			xend = x,
			yend = y
		),
		fill = var_fill_c,
		show.legend = F,
		colour = var_outline_c,
		stroke = 0.5 * line_width_n_act,
		alpha = alpha_value,
		size = vv,
		shape = 22
	)
}

# selected words

if ( (is.null(target_ids) == FALSE) ) {
	var_select <- target_ids

	p <- p + geom_point(
		data = data.frame(
			x = lay_f[var_select,1],
			y = lay_f[var_select,2]
		),
		aes(
			x = x,
			y = y,
			xend = x,
			yend = y,
			fill = com_label[var_select]
		),
		show.legend = F,
		colour = NA,
		alpha = 0.8,
		size = vv * 2 / 3,
		shape = 22
	)
	
	p <- p + geom_point(
		data = data.frame(
			x = lay_f[var_select,1],
			y = lay_f[var_select,2]
		),
		aes(
			x = x,
			y = y,
			xend = x,
			yend = y,
			fill = com_label[var_select]
		),
		show.legend = F,
		colour = gray_color_n,
		stroke = 0.5 * line_width_n_act,
		alpha = alpha_value,
		size = vv,
		shape = 22
	)
	
	p <- p + geom_point(
		data = data.frame(
			x = lay_f[var_select,1],
			y = lay_f[var_select,2]
		),
		aes(
			x = x,
			y = y,
			xend = x,
			yend = y
		),
		fill = NA,
		show.legend = F,
		colour = gray_color_n,
		stroke = 0.5 * line_width_n_act,
		alpha = alpha_value,
		size = vv * 1.4,
		shape = 22
	)
}

#---------------#
#  Node labels  #

#if ( (use_freq_as_fontsize == 1) && (use_freq_as_size == 1) ) {
#	p <- p + geom_nodetext(
#		aes(label = lab, size=size * 0.1),
#		show.legend = F,
#		family="Meiryo UI",
#		fontface=face
#	)
#}

if (
	( com_method == "com-b" || com_method == "com-g" || com_method == "com-r" || com_method == "cor")
	&& gray_scale == 1
	&& smaller_nodes == 0
){
	p <- p + geom_label(
		data = lay_f_df,
		aes(
			x = x,
			y = y,
			xend = x,
			yend = y,
			label = lab
		),
		size=4 * font_size,
		hjust = hjust,
		nudge_x = nudge,
		nudge_y = nudge * 1.25,
		family=font_fam,
		na.rm = T,
		label.size = NA,
		label.padding = unit(0.2 * font_size, "lines"),
		label.r = unit(0.1, "lines"),
		fontface=face
	)
} else {
	p <- p + geom_text(
		data = lay_f_df,
		aes(
			x = x,
			y = y,
			xend = x,
			yend = y,
			label = lab
		),
		size=4 * font_size,
		hjust = hjust,
		nudge_x = nudge,
		nudge_y = nudge * 1.25,
		family=font_fam,
		na.rm = T,
		fontface=face
	)
}

#---------------#
#  Edge labels  #

if (view_coef == 1){
	my_n_form <- function(d){
		len = length(d)
		for (i in 1:len){
			s <- d[i]
			if ( is.na(s) || is.nan(s) || is.null(s) ){
				s <- NA
			} else {
				s <- as.numeric(s)
				if (s < 1){
					s <- sprintf("%.2f",s)
					s <- substring(s, 2, 4)
				} else {
					s <- sprintf("%.1f",s)
				}
			}
			d[i] <- s
		}
		return(d)
	}
	
	p <- p + geom_edgetext(
		aes(label = my_n_form(weight)),
		color = "#000080",
		fill = NA,
		size=3.5,
	)
}

#-------------------#
#  Community color  #

if ( com_method == "com-b" || com_method == "com-g" || com_method == "com-r"){
	if ( gray_scale == 1) {
		p <- p + scale_color_grey(
			na.value = "white",
			guide = FALSE
		)
		p <- p + scale_fill_grey(
			na.value = "white",
			guide = guide_legend(
				title = "Subgraph:",
				override.aes = list(size=5.5, alpha=1, shape=22),
				keyheight = unit(1,"line"),
				ncol=2,
				order = 1
			)
		)
	} else {
		if ( length(com_m$csize[com_m$csize > 1]) <= 12 ){
			p <- p + scale_color_brewer(
				palette = "Set3",
				na.value = "white",
				guide = FALSE
			)
			p <- p + scale_fill_brewer(
				palette = "Set3",
				na.value = "white",
				guide = guide_legend(
					title = "Subgraph:",
					override.aes = list(size=5.5, alpha=1, shape=22),
					keyheight = unit(1.25,"line"),
					ncol=2,
					order = 1
				)
			)
		} else if (length(com_m$csize[com_m$csize > 1]) <= 20)  {
			library(ggsci)
			c20org <- col2rgb( pal_d3("category20")(20) )

			p <- p + scale_color_manual(
				values = rgb( t( ( 255 - ( 255 - c20org ) * 0.5 ) / 255  ) ),
				na.value = "white",
				guide = FALSE
			)
			p <- p + scale_fill_manual(
				values = rgb( t( ( 255 - ( 255 - c20org ) * 0.5 ) / 255  ) ),
				na.value = "white",
				guide = guide_legend(
					title = "Subgraph:",
					override.aes = list(size=5.5, alpha=1, shape=22),
					keyheight = unit(1.25,"line"),
					ncol=2,
					order = 1
				)
			)
		} else {
			p <- p + scale_color_hue(
				c = 50,
				l = 85,
				na.value = "white",
				guide = FALSE
			)
			p <- p + scale_fill_hue(
				c = 50,
				l = 85,
				na.value = "white",
				guide = guide_legend(
					title = "Subgraph:",
					override.aes = list(size=5.5, alpha=1, shape=22, colour="gray45"),
					keyheight = unit(1.25,"line"),
					ncol=2,
					order = 1
				)
			)
		}
	}
}

#--------------------#
#  Centrality color  #

if ( com_method == "cnt-b" || com_method == "cnt-d" || com_method == "cnt-e"){
	
	if (gray_scale == 1){
		myPalette <- gray( seq(1, 0.4, length.out=100) )
		ticks_color = "gray30"
	} else {
		if (color_universal_design == 0){
			myPalette <- cm.colors(99)
		} else {
			library(RColorBrewer)
			col_seed <- '.$::config_obj->color_palette.'

			myPalette <- colorRampPalette( col_seed )
			myPalette <- myPalette(99)
		}
		ticks_color = "gray45"
	}

	p <- p + scale_color_gradientn(
		colours = myPalette,
		guide = FALSE
	)
	p <- p + scale_fill_gradientn(
		colours = myPalette,
		guide = guide_colourbar(
			title = "Centrality:\n",
			title.theme = element_text(
				family=sans,
				face="bold",
				size=11,
				lineheight=0.4,
				angle=0
			),
			order = 1,
			#override.aes = list(size=6, shape=22),
			label.hjust = 1,
			ticks.colour = ticks_color,
			ticks.linewidth = 1.25/.pt,
			#reverse = TRUE,
			#ncol=2,
			#keyheight = unit(1.5,"line")
		)
	)
}

#----------------#
#  2 Mode color  #

if (com_method == "twomode_c"){
	p <- p + scale_color_manual(
		values = brewer.pal(8, "Spectral")[4:8],
		guide = FALSE
	)
	p <- p + scale_fill_manual(
		values = brewer.pal(8, "Spectral")[4:8],
		guide = guide_legend(
			title = "Degree:",
			order = 1,
			override.aes = list(size=5.5, shape=22, alpha=1),
			#label.hjust = "left",
			#reverse = TRUE,
			#ncol=2,
			keyheight = unit(1.2,"line")
		)
	)
}

if ( com_method == "none" || com_method == "twomode_g"){
	p <- p + scale_color_manual(
		values = c("white"),
		na.value = "white",
		guide = F
	)
	p <- p + scale_fill_manual(
		values = c("white"),
		na.value = "white",
		guide = F
	)
}

#---------------------#
#  Final adjustments  #

p <- p + theme_blank(
	base_family  = font_fam
)

if (com_method == "cor" && gray_scale == 0){ # cor
	if ( cor_var_darker == 1 ){
		col_backg <- "gray50"
	} else {
		col_backg <- "gray60"
	}
	p <- p + theme(
		panel.background = element_rect(fill = col_backg, colour = NA)
	)
}

p <- p + theme(
	legend.title    = element_text(family=sans, face="bold",  size=11, angle=0),
	legend.text     = element_text(face="plain", size=11, angle=0)
)


# make a small space between the graph and the legend
margin <- 0.04
extra  <- 0.025

m_t <- margin_top    / 100
m_b <- margin_bottom / 100
m_l <- margin_left   / 100
m_r <- margin_right  / 100

xlimv <- c(0-margin-extra-m_l, 1+margin+extra+m_r)
ylimv <- c(0-margin-m_b, 1+margin+m_t)

p <- p + coord_fixed(
	ratio = 1,
	expand = F,
	xlim = xlimv,
	ylim = ylimv
)

g <- ggplotGrob(p)

# color and width of ticks; continuous color scale legends; for ggplot2 v2.x.x
if ( length( g$grobs[[8]][[1]][[1]] ) > 1){
	if ( 
		(com_method == "cnt-b" || com_method == "cnt-d" || com_method == "cnt-e")
		&& ( gray_scale == 0 )
	){
		g$grobs[[8]][[1]][[1]]$grobs[[5]]$gp$col <- "gray45"
		g$grobs[[8]][[1]][[1]]$grobs[[5]]$gp$lwd <- 1.25
	}
	if ( 
		(com_method == "cnt-b" || com_method == "cnt-d" || com_method == "cnt-e")
		&& ( gray_scale == 1 )
	){
		g$grobs[[8]][[1]][[1]]$grobs[[5]]$gp$col <- "gray30"
		g$grobs[[8]][[1]][[1]]$grobs[[5]]$gp$lwd <- 1.25
	}
	if ( com_method == "cor" && gray_scale == 0){
		g$grobs[[8]][[1]][[1]]$grobs[[5]]$gp$col <- "gray40"
		g$grobs[[8]][[1]][[1]]$grobs[[5]]$gp$lwd <- 1.1
	}
}

library(grid)
library(gtable)

# fixing width of legends to 22%
if ( exists("saving_file") ){
	if ( saving_file == 0){
		if ( as.numeric( substr( packageVersion("ggplot2"), 1, 1) ) <= 2 ){   # ggplot2 v2.x.x
			target_legend_width <- convertX(
				unit( image_width * 0.22, "in" ),
				"mm"
			)
			diff_mm <- diff( c(
				convertX( g$widths[5], "mm" ),
				target_legend_width
			))
			if ( diff_mm > 0 ){
				print(diff_mm)
				g <- gtable_add_cols(g, unit(diff_mm, "mm"))
			}
			grid.draw(g)
		} else {                                                              # ggplot2 v3.x.x
			library(cowplot)
			grid <- plot_grid(
				p + theme(legend.position = "none"), # plot without legends
				get_legend(p),                       # legends only
				rel_widths = c(78, 22),
				#labels = c("A", "B"),
				nrow = 1
			)
			print(grid)
		}
	}
} else {
	grid.draw(g)
}

if (exists("com_m")){
	rm("com_m")
}
if (exists("ccol_raw")){
	rm("ccol_raw")
}
if (exists("edg_mst")){
	rm("edg_mst")
}
if (exists("edg_lty")){
  rm("edg_lty")
}
ccol <- igraph::get.vertex.attribute(n2,"com")
}
';
	$t = Encode::decode('UTF-8', $t);
	return $t;
}

sub r_command_wordlayout{
	my $t = '

# fix for "wordlayout" function
filename <- tempfile()
writeLines("wordlayout <- function (x, y, words, cex = 1, rotate90 = FALSE, xlim = c(-Inf, 
	Inf), ylim = c(-Inf, Inf), tstep = 0.1, rstep = 0.1, ...) 
{
	tails <- \"g|j|p|q|y\"
	n <- length(words)
	sdx <- sd(x, na.rm = TRUE)
	sdy <- sd(y, na.rm = TRUE)
	iterations <- 0
	if (sdx == 0) 
		sdx <- 1
	if (sdy == 0) 
		sdy <- 1
	if (length(cex) == 1) 
		cex <- rep(cex, n)
	if (length(rotate90) == 1) 
		rotate90 <- rep(rotate90, n)
	boxes <- list()
	for (i in 1:length(words)) {
		rotWord <- rotate90[i]
		r <- 0
		theta <- runif(1, 0, 2 * pi)
		x1 <- xo <- x[i]
		y1 <- yo <- y[i]
		wid <- strwidth(words[i], cex = cex[i], ...)
		ht <- strheight(words[i], cex = cex[i], ...)
		if (grepl(tails, words[i])) 
			ht <- ht + ht * 0.2
		if (rotWord) {
			tmp <- ht
			ht <- wid
			wid <- tmp
		}
		isOverlaped <- TRUE
		while (isOverlaped) {
			if (!.overlap(x1 - 0.5 * wid, y1 - 0.5 * ht, wid, 
				ht, boxes) && x1 - 0.5 * wid > xlim[1] && y1 - 
				0.5 * ht > ylim[1] && x1 + 0.5 * wid < xlim[2] && 
				y1 + 0.5 * ht < ylim[2]) {
				boxes[[length(boxes) + 1]] <- c(x1 - 0.5 * wid, 
				  y1 - 0.5 * ht, wid, ht)
				isOverlaped <- FALSE
			}
			else {
				theta <- theta + tstep
				r <- r + rstep * tstep/(2 * pi)
				x1 <- xo + sdx * r * cos(theta)
				y1 <- yo + sdy * r * sin(theta)
				iterations <- iterations + 1
				if (iterations > 500000){
					boxes[[length(boxes) + 1]] <- c(x1 - 0.5 * wid, 
				  y1 - 0.5 * ht, wid, ht)
					isOverlaped = FALSE
				}
			}
		}
	}
	print( paste(\"iterations: \", iterations) )
	result <- do.call(rbind, boxes)
	colnames(result) <- c(\"x\", \"y\", \"width\", \"ht\")
	rownames(result) <- words
	result
}
", filename)
if ( packageVersion("wordcloud") == 2.4){
	insertSource(filename, package="wordcloud", force=FALSE)
}
';
	$t = Encode::decode('UTF-8', $t);
	return $t;
}

1;