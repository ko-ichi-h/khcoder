package plotR::network;

use utf8;

use strict;
use kh_r_plot::network;

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

	# パラメーター設定部分
	if ( $args{n_or_j} eq 'j'){
		$r_command .= "edges <- 0\n";
		$r_command .= "th <- $args{edges_jac}\n";
	}
	elsif ( $args{n_or_j} eq 'n'){
		$r_command .= "edges <- $args{edges_num}\n";
		$r_command .= "th <- -1\n";
	}
	#$r_command .= "cex <- $args{font_size}\n";
	$r_command .= "cex <- 1\n";

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

	$r_command .= "min_sp_tree_only <- $args{min_sp_tree_only}\n";

	$args{use_alpha} = 0 unless ( length($args{use_alpha}) );
	$r_command .= "use_alpha <- $args{use_alpha}\n";

	$args{gray_scale} = 0 unless ( length($args{gray_scale}) );
	$r_command .= "gray_scale <- $args{gray_scale}\n";

	$r_command .= "method_coef <- \"$args{method_coef}\"\n\n";

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
	} else {
		$plots[0] = kh_r_plot::network->new(
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
		) or return 0;

		$plots[1] = kh_r_plot::network->new(
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
		) or return 0;

		$plots[2] = kh_r_plot::network->new(
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
		) or return 0;

		$plots[3] = kh_r_plot::network->new(
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
		) or return 0;

		$plots[4] = kh_r_plot::network->new(
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
		) or return 0;

		$plots[5] = kh_r_plot::network->new(
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
		) or return 0;

		$plots[6] = kh_r_plot::network->new(
			name      => $args{plotwin_name}.'_7',
			command_f =>
				 $r_command
				."\ncom_method <- \"none\"\n"
				.$self->r_plot_cmd_p1
				.$self->r_plot_cmd_p2
				.$self->r_plot_cmd_p3
				.$self->r_plot_cmd_p4,
			command_a =>
				 "com_method <- \"none\"\n"
				.$self->r_plot_cmd_p2
				.$self->r_plot_cmd_p4,
			width     => int( $args{plot_size} * $x_factor ),
			height    => $args{plot_size},
			font_size => $args{font_size},
		) or return 0;
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
				", Min. Coef. ",
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

	kh_r_plot::network->clear_env;
	undef $self;
	undef %args;
	$self->{result_plots} = \@plots;
	$self->{result_info} = $info;
	$self->{result_info_long} = $info_long;
	
	return $self;
}

sub r_plot_cmd_p1{
	return '

# 頻度計算
#if (use_freq_as_size == 1){
	freq <- NULL
	for (i in 1:length( rownames(d) )) {
		freq[i] = sum( d[i,] )
	}
#}

# 類似度計算
if ( (exists("doc_length_mtr")) &! (method_coef == "binary")){
	leng <- as.numeric(doc_length_mtr[,2])
	leng[leng ==0] <- 1
	d <- t(d)
	d <- d / leng
	d <- d * 1000
	d <- t(d)
}
if (method_coef == "euclid"){ # 抽出語ごとに標準化
	d <- t( scale( t(d) ) )
}

library(amap)
d <- Dist(d,method=method_coef)

d <- as.matrix(d)
if ( method_coef == "euclid" ){
	d <- max(d) - d
	d <- d / max(d)
} else {
	d <- 1 - d
}

# 不要なedgeを削除して標準化
if ( exists("com_method") ){
	if (com_method == "twomode_c" || com_method == "twomode_g"){
		d[1:n_words,] <- 0

		std  <- d[(n_words+1):nrow(d),1:n_words]
		chkm <- std
		
		std <- t(std)
		std <- scale(std, center=T, scale=F)
		std <- t(std)

		if ( min(std[!is.na(std)]) < 0.0005 ){
			std <- std + ( 0.0005 - min(std[!is.na(std)]) );
		}
		std <- std / max(std[!is.na(std)])
		
		std[chkm == 0] <- 0
		d[(n_words+1):nrow(d),1:n_words] <- std
	}
}

# グラフ作成 
library(igraph)
new_igraph <- 0
if (as.numeric( substr(sessionInfo()$otherPkgs$igraph$Version, 3,3) ) > 5){
	new_igraph <- 1
}

n <- graph.adjacency(d, mode="lower", weighted=T, diag=F)
n <- set.vertex.attribute(
	n,
	"name",
	(0+new_igraph):(length(d[1,])-1+new_igraph),
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

# edgeを間引いてグラフを再作成 
el2 <- subset(el, el[,3] >= th)
if ( nrow(el2) == 0 ){
	stop(message = "No edges to draw!", call. = F)
}
n2  <- graph.edgelist(
	matrix( as.matrix(el2)[,1:2], ncol=2 ),
	directed	=F
)
n2 <- set.edge.attribute(
	n2,
	"weight",
	(0+new_igraph):(length(get.edgelist(n2)[,1])-1+new_igraph),
	el2[,3]
)

if ( min_sp_tree_only == 1 ){
	n2 <- minimum.spanning.tree(
		n2,
		weights = 1 - get.edge.attribute(n2, "weight"),
		algorithm="prim"
	)
}

# Fix for igraph.Arrows
igraph.Arrows_my0 <- function (x1, y1, x2, y2, code = 2, size = 1, width = 1.2/4/cin, 
    open = TRUE, sh.adj = 0.1, sh.lwd = 1, sh.col = if (is.R()) par("fg") else 1, 
    sh.lty = 1, h.col = sh.col, h.col.bo = sh.col, h.lwd = sh.lwd, 
    h.lty = sh.lty, curved = FALSE) 
{
    cin <- size * par("cin")[2]
    width <- width * (1.2/4/cin)
    uin <- if (is.R()) 
        1/xyinch()
    else par("uin")
    x <- sqrt(seq(0, cin^2, length = floor(35 * cin) + 2))
    delta <- sqrt(h.lwd) * par("cin")[2] * 0.005
    x.arr <- c(-rev(x), -x)
    wx2 <- width * x^2
    y.arr <- c(-rev(wx2 + delta), wx2 + delta)
    deg.arr <- c(atan2(y.arr, x.arr), NA)
    r.arr <- c(sqrt(x.arr^2 + y.arr^2), NA)
    bx1 <- x1
    bx2 <- x2
    by1 <- y1
    by2 <- y2
    lx <- length(x1)
    r.seg <- rep(cin * sh.adj, lx)
    theta1 <- atan2((y1 - y2) * uin[2], (x1 - x2) * uin[1])
    th.seg1 <- theta1 + rep(atan2(0, -cin), lx)
    theta2 <- atan2((y2 - y1) * uin[2], (x2 - x1) * uin[1])
    th.seg2 <- theta2 + rep(atan2(0, -cin), lx)
    x1d <- y1d <- x2d <- y2d <- 0
    if (code %in% c(1, 3)) {
        x2d <- r.seg * cos(th.seg2)/uin[1]
        y2d <- r.seg * sin(th.seg2)/uin[2]
    }
    if (code %in% c(2, 3)) {
        x1d <- r.seg * cos(th.seg1)/uin[1]
        y1d <- r.seg * sin(th.seg1)/uin[2]
    }
    if ( (is.logical(curved) && all(!curved)) || all(!curved) ) { # KH Coder
        segments(x1 + x1d, y1 + y1d, x2 + x2d, y2 + y2d, lwd = sh.lwd, 
            col = sh.col, lty = sh.lty)
    }
    else {
        if (is.numeric(curved)) {
            lambda <- curved
        }
        else {
            lambda <- as.logical(curved) * 0.5
        }
        c.x1 <- x1 + x1d
        c.y1 <- y1 + y1d
        c.x2 <- x2 + x2d
        c.y2 <- y2 + y2d
        midx <- (x1 + x2)/2
        midy <- (y1 + y2)/2
        spx <- midx - lambda * 1/2 * (c.y2 - c.y1)
        spy <- midy + lambda * 1/2 * (c.x2 - c.x1)
        sh.col <- rep(sh.col, length = length(c.x1))
        sh.lty <- rep(sh.lty, length = length(c.x1))
        sh.lwd <- rep(sh.lwd, length = length(c.x1))
        for (i in seq_len(length(c.x1))) {
            spl <- xspline(x = c(c.x1[i], spx[i], c.x2[i]), y = c(c.y1[i], 
                spy[i], c.y2[i]), shape = 1, draw = FALSE)
            lines(spl, lwd = sh.lwd[i], col = sh.col[i], lty = sh.lty[i])
            if (code %in% c(2, 3)) {
                x1[i] <- spl$x[3 * length(spl$x)/4]
                y1[i] <- spl$y[3 * length(spl$y)/4]
            }
            if (code %in% c(1, 3)) {
                x2[i] <- spl$x[length(spl$x)/4]
                y2[i] <- spl$y[length(spl$y)/4]
            }
        }
    }
    if (code %in% c(2, 3)) {
        theta <- atan2((by2 - y1) * uin[2], (bx2 - x1) * uin[1])
        Rep <- rep(length(deg.arr), lx)
        p.x2 <- rep(bx2, Rep)
        p.y2 <- rep(by2, Rep)
        ttheta <- rep(theta, Rep) + rep(deg.arr, lx)
        r.arr <- rep(r.arr, lx)
        if (open) 
            lines((p.x2 + r.arr * cos(ttheta)/uin[1]), (p.y2 + 
                r.arr * sin(ttheta)/uin[2]), lwd = h.lwd, col = h.col.bo, 
                lty = h.lty)
        else polygon(p.x2 + r.arr * cos(ttheta)/uin[1], p.y2 + 
            r.arr * sin(ttheta)/uin[2], col = h.col, lwd = h.lwd, 
            border = h.col.bo, lty = h.lty)
    }
    if (code %in% c(1, 3)) {
        x1 <- bx1
        y1 <- by1
        tmp <- x1
        x1 <- x2
        x2 <- tmp
        tmp <- y1
        y1 <- y2
        y2 <- tmp
        theta <- atan2((y2 - y1) * uin[2], (x2 - x1) * uin[1])
        lx <- length(x1)
        Rep <- rep(length(deg.arr), lx)
        p.x2 <- rep(x2, Rep)
        p.y2 <- rep(y2, Rep)
        ttheta <- rep(theta, Rep) + rep(deg.arr, lx)
        r.arr <- rep(r.arr, lx)
        if (open) 
            lines((p.x2 + r.arr * cos(ttheta)/uin[1]), (p.y2 + 
                r.arr * sin(ttheta)/uin[2]), lwd = h.lwd, col = h.col.bo, 
                lty = h.lty)
        else polygon(p.x2 + r.arr * cos(ttheta)/uin[1], p.y2 + 
            r.arr * sin(ttheta)/uin[2], col = h.col, lwd = h.lwd, 
            border = h.col.bo, lty = h.lty)
    }
}

igraph.Arrows_my1 <- function (x1, y1, x2, y2, code = 2, size = 1, width = 1.2/4/cin, 
    open = TRUE, sh.adj = 0.1, sh.lwd = 1, sh.col = if (is.R()) par("fg") else 1, 
    sh.lty = 1, h.col = sh.col, h.col.bo = sh.col, h.lwd = sh.lwd, 
    h.lty = sh.lty, curved = FALSE) 
{
    cin <- size * par("cin")[2]
    width <- width * (1.2/4/cin)
    uin <- if (is.R()) 
        1/xyinch()
    else par("uin")
    x <- sqrt(seq(0, cin^2, length = floor(35 * cin) + 2))
    delta <- sqrt(h.lwd) * par("cin")[2] * 0.005
    x.arr <- c(-rev(x), -x)
    wx2 <- width * x^2
    y.arr <- c(-rev(wx2 + delta), wx2 + delta)
    deg.arr <- c(atan2(y.arr, x.arr), NA)
    r.arr <- c(sqrt(x.arr^2 + y.arr^2), NA)
    bx1 <- x1
    bx2 <- x2
    by1 <- y1
    by2 <- y2
    lx <- length(x1)
    r.seg <- rep(cin * sh.adj, lx)
    theta1 <- atan2((y1 - y2) * uin[2], (x1 - x2) * uin[1])
    th.seg1 <- theta1 + rep(atan2(0, -cin), lx)
    theta2 <- atan2((y2 - y1) * uin[2], (x2 - x1) * uin[1])
    th.seg2 <- theta2 + rep(atan2(0, -cin), lx)
    x1d <- y1d <- x2d <- y2d <- 0
    if (code %in% c(1, 3)) {
        x2d <- r.seg * cos(th.seg2)/uin[1]
        y2d <- r.seg * sin(th.seg2)/uin[2]
    }
    if (code %in% c(2, 3)) {
        x1d <- r.seg * cos(th.seg1)/uin[1]
        y1d <- r.seg * sin(th.seg1)/uin[2]
    }
    if ( (is.logical(curved) && all(!curved)) || all(!curved) ) { # KH Coder
        segments(x1 + x1d, y1 + y1d, x2 + x2d, y2 + y2d, lwd = sh.lwd, 
            col = sh.col, lty = sh.lty)
        phi <- atan2(y1 - y2, x1 - x2)
        r <- sqrt((x1 - x2)^2 + (y1 - y2)^2)
        lc.x <- x2 + 2/3 * r * cos(phi)
        lc.y <- y2 + 2/3 * r * sin(phi)
    }
    else {
        if (is.numeric(curved)) {
            lambda <- curved
        }
        else {
            lambda <- as.logical(curved) * 0.5
        }
        c.x1 <- x1 + x1d
        c.y1 <- y1 + y1d
        c.x2 <- x2 + x2d
        c.y2 <- y2 + y2d
        midx <- (x1 + x2)/2
        midy <- (y1 + y2)/2
        spx <- midx - lambda * 1/2 * (c.y2 - c.y1)
        spy <- midy + lambda * 1/2 * (c.x2 - c.x1)
        sh.col <- rep(sh.col, length = length(c.x1))
        sh.lty <- rep(sh.lty, length = length(c.x1))
        sh.lwd <- rep(sh.lwd, length = length(c.x1))
        lc.x <- lc.y <- numeric(length(c.x1))
        for (i in seq_len(length(c.x1))) {
            spl <- xspline(x = c(c.x1[i], spx[i], c.x2[i]), y = c(c.y1[i], 
                spy[i], c.y2[i]), shape = 1, draw = FALSE)
            lines(spl, lwd = sh.lwd[i], col = sh.col[i], lty = sh.lty[i])
            if (code %in% c(2, 3)) {
                x1[i] <- spl$x[3 * length(spl$x)/4]
                y1[i] <- spl$y[3 * length(spl$y)/4]
            }
            if (code %in% c(1, 3)) {
                x2[i] <- spl$x[length(spl$x)/4]
                y2[i] <- spl$y[length(spl$y)/4]
            }
            lc.x[i] <- spl$x[2/3 * length(spl$x)]
            lc.y[i] <- spl$y[2/3 * length(spl$y)]
        }
    }
    if (code %in% c(2, 3)) {
        theta <- atan2((by2 - y1) * uin[2], (bx2 - x1) * uin[1])
        Rep <- rep(length(deg.arr), lx)
        p.x2 <- rep(bx2, Rep)
        p.y2 <- rep(by2, Rep)
        ttheta <- rep(theta, Rep) + rep(deg.arr, lx)
        r.arr <- rep(r.arr, lx)
        if (open) 
            lines((p.x2 + r.arr * cos(ttheta)/uin[1]), (p.y2 + 
                r.arr * sin(ttheta)/uin[2]), lwd = h.lwd, col = h.col.bo, 
                lty = h.lty)
        else polygon(p.x2 + r.arr * cos(ttheta)/uin[1], p.y2 + 
            r.arr * sin(ttheta)/uin[2], col = h.col, lwd = h.lwd, 
            border = h.col.bo, lty = h.lty)
    }
    if (code %in% c(1, 3)) {
        x1 <- bx1
        y1 <- by1
        tmp <- x1
        x1 <- x2
        x2 <- tmp
        tmp <- y1
        y1 <- y2
        y2 <- tmp
        theta <- atan2((y2 - y1) * uin[2], (x2 - x1) * uin[1])
        lx <- length(x1)
        Rep <- rep(length(deg.arr), lx)
        p.x2 <- rep(x2, Rep)
        p.y2 <- rep(y2, Rep)
        ttheta <- rep(theta, Rep) + rep(deg.arr, lx)
        r.arr <- rep(r.arr, lx)
        if (open) 
            lines((p.x2 + r.arr * cos(ttheta)/uin[1]), (p.y2 + 
                r.arr * sin(ttheta)/uin[2]), lwd = h.lwd, col = h.col.bo, 
                lty = h.lty)
        else polygon(p.x2 + r.arr * cos(ttheta)/uin[1], p.y2 + 
            r.arr * sin(ttheta)/uin[2], col = h.col, lwd = h.lwd, 
            border = h.col.bo, lty = h.lty)
    }
    list(lab.x = lc.x, lab.y = lc.y)
}

if ( grepl( "mingw32", sessionInfo()$platform ) ) {
	if ( grepl( "0.7.0",   sessionInfo()$otherPkgs$igraph$Version ) ){
		assignInNamespace(
			x="igraph.Arrows",
			value=igraph.Arrows_my0,
			ns=asNamespace("igraph")
		)
	}
	if ( grepl( "0.7.1",   sessionInfo()$otherPkgs$igraph$Version ) ){
		assignInNamespace(
			x="igraph.Arrows",
			value=igraph.Arrows_my1,
			ns=asNamespace("igraph")
		)
	}
}


';
}

sub r_plot_cmd_p2{

return 
'
if (length(get.vertex.attribute(n2,"name")) < 2){
	com_method <- "none"
}

# 中心性
if ( com_method == "cnt-b" || com_method == "cnt-d" || com_method == "cnt-e"){
	ccol <- NULL
	if (com_method == "cnt-b"){                   # 媒介
		ccol <- igraph::betweenness(
			n2,
			v=(0+new_igraph):(length(get.vertex.attribute(n2,"name"))-1+new_igraph),
			directed=F
		)
	}
	if (com_method == "cnt-d"){                   # 次数
		ccol <-  igraph::degree(
			n2,
			v=(0+new_igraph):(length(get.vertex.attribute(n2,"name"))-1+new_igraph)
		)
	}
	if (com_method == "cnt-e"){                   # 固有ベクトル
		try(
			ccol <- igraph::evcent(n2)$vector,
			silent = T
		)
	}
	ccol_raw <- ccol # ggplot2
	
	# 色の設定
	#if ( gray_scale == 1 ) {
	#	ccol <- ccol - min(ccol)
	#	ccol <- 1 - ccol / max(ccol) / 2.5
	#	ccol <- gray(ccol)
	#} else {
	#	ccol <- ccol - min(ccol)
	#	ccol <- ccol * 100 / max(ccol)
	#	ccol <- trunc(ccol + 1)
	#	ccol <- cm.colors(101)[ccol]
	#}

	com_col_v <- "gray40"
	edg_col   <- "gray55"
	edg_lty   <- 1
}

# クリーク検出
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
		com_m$membership <- com_m$membership + new_igraph
	}

	if (com_method == "com-g"){                   # Modularity
		com   <- fastgreedy.community   (n2, merges=TRUE, modularity=TRUE)
		com_m <- community.to.membership(
			n2, com$merges, merge_step(n2,com$merges)
		)
		com_m$membership <- com_m$membership + new_igraph
	}

	if (com_method == "com-r"){                   # Random walks
		com   <-  walktrap.community(
			n2,
			weights=get.edge.attribute(n2, "weight")
		)
		com_m <- NULL

		# コミュニティ数を12以下に
		# →この機能は現在停止中。R（igraph）のバージョンアップ時に復活？
		if (F){
		#if (length( table(com$membership)[table(com$membership) > 1] ) > 12 ){
			best_step <- 0
			for ( i in 1:( trunc( length( com$merges ) / 2 ) - 10 ) ){
				temp_com <- community.to.membership(n2, com$merges, i)
				if (
					   (length(temp_com$csize[temp_com$csize > 1]) == 12)
					&& (i > 12)
				){
					best_step <- i
				}
			}
			if (best_step > 0){
				temp_com <- community.to.membership(n2, com$merges, best_step)
				com_m$membership <- temp_com$membership + new_igraph
				com_m$csize      <- table(temp_com$membership)
			} else {
				com_m$membership <- com$membership
				com_m$csize      <- table(com$membership)
			}
		} else {
			com_m$membership <- com$membership
			com_m$csize      <- table(com$membership)
		}
	}

	com_col <- NULL # vertex frame                # Vertexの色（12色まで）
	ccol    <- NULL # vertex

	library( RColorBrewer )
	colors_for_com <- brewer.pal(12, "Set3")

	col_num <- 1
	for (i in com_m$csize ){
		cu_col <- "white"
		if ( i == 1){
			com_col <- c( com_col, "gray40" )
		} else {
			if (col_num <= 12){
				cu_col  <- colors_for_com[col_num]
				com_col <- c( com_col, "gray40" )
			} else {
				com_col <- c( com_col, "blue" )
			}
			col_num <- col_num + 1
		}
		ccol <- c( ccol, cu_col )
	}
	com_col_v <- com_col[com_m$membership + 1 - new_igraph]
	ccol      <- ccol[com_m$membership + 1 - new_igraph]

	edg_lty <- NULL                               # edgeの色と形状
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
		colnames(d)[ as.numeric( get.vertex.attribute(n2,"name") ) ],
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
		v=(0+new_igraph):(length(get.vertex.attribute(n2,"name"))-1+new_igraph)
	)
	# ggplot2
	ccol_raw <- ccol
	ccol_raw[var_select] <- NA
	ccol_raw <- as.character(ccol_raw)
	ccol_raw[ccol_raw=="5"] <- ">= 5"
	
	#ccol[5 < ccol] <- 5
	#ccol <- ccol + 3
	
	#library( RColorBrewer )
	#ccol <- brewer.pal(8, "Spectral")[ccol]

	#ccol[var_select] <- "#FB8072" # #FB8072 #DEEBF7 #FF9966 #FFDAB9 "#F46D43"

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

# edge.widthを計算
if ( use_weight_as_width == 1 ){
	edg_width <- edg_width <- get.edge.attribute(n2, "weight")
	if ( sd( edg_width ) == 0 ){
		edg_width <- 1
	} else {
		edg_width <- edg_width / sd( edg_width )
		edg_width <- edg_width - mean( edg_width )
		edg_width <- edg_width * 0.6 + 2 # 分散 = 0.5, 平均 = 2
		edg_width <- neg_to_zero(edg_width)
	}
} else {
	edg_width <- 1
}

# Minimum Spanning Tree
if ( min_sp_tree == 1 ){
	# MSTの検出
	mst <- minimum.spanning.tree(
		n2,
		weights = 1 - get.edge.attribute(n2, "weight"),
		algorithm="prim"
	)

	# MSTに合致するedgeを強調
	#if (length(edg_col) == 1){
		edg_col <- rep("gray55", length( get.edge.attribute(n2, "weight") )) 
	#}
	if (length(edg_width) == 1){
	    edg_width <- rep(edg_width, ecount(n2) )
	}

	n2_edges  <- get.edgelist(n2,name=T);
	mst_edges <- get.edgelist(mst,name=T);

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
				edg_col[i]   <- "gray30"                   # edgeの色
				edg_width[i] <- 2                          # 太さ
				if ( length(edg_lty) > 1 ){
					edg_lty[i] <- 1                        # 線種
				}
				break
			}
		}
	}
	edg_mst <- edg_col
}


';

}


sub r_plot_cmd_p3{

return 
'
# 初期配置
lay <- NULL
if ( length(get.vertex.attribute(n2,"name")) >= 3 ){
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
		while ( is.na(check4fr(lay)) == 0 ){
			mv <-  check4fr(lay)
			lay[mv,1] <- lay[mv,1] + 0.001
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
	lay_f <- layout.kamada.kawai(
		n2,
		start   = lay,
		weights = get.edge.attribute(n2, "weight")
	)
} else {
	lay_f <- layout.fruchterman.reingold(
		n2,
		start   = lay,
		niter   = vcount(n2) * 512,
		weights = get.edge.attribute(n2, "weight")
	)
}

lay_f <- scale(lay_f,center=T, scale=F)
for (i in 1:2){
	lay_f[,i] <- lay_f[,i] - min(lay_f[,i]); # 最小を0に
	lay_f[,i] <- lay_f[,i] / max(lay_f[,i]); # 最大を1に
	lay_f[,i] <- ( lay_f[,i] - 0.5 ) * 1.96;
}

# vertex.sizeを計算
if ( use_freq_as_size == 1 ){
	v_size <- freq[ as.numeric( get.vertex.attribute(n2,"name") ) ]
	if (com_method == "twomode_c" || com_method == "twomode_g"){
		v_size <- v_size[var_select==FALSE]
	}
	if ( sd(v_size) == 0 ){
		v_size <- 15
	} else {
		v_size <- v_size / sd(v_size)
		v_size <- v_size - mean(v_size)
		v_size <- v_size * 3 + 12 # 分散 = 3, 平均 = 12
		v_size <- neg_to_zero(v_size)
	}
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
	if ( sd(f_size) == 0 ){
		f_size <- cex
	} else {
		f_size <- f_size / sd(f_size)
		f_size <- f_size - mean(f_size)
		f_size <- f_size * 0.2 + cex
	}

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

# 外部変数・見出しを使う場合の形状やサイズ
v_shape <- "circle"
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
if ( exists("saving_emf") || exists("saving_eps") ){
	use_alpha <- 0 
}

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

edge_label <- NULL
#if (view_coef == 1){
#	edge_label <- substring(
#		round(
#			get.edge.attribute(n2,"weight"),
#			digits=2
#		),
#		2,
#		4
#	)
#}

font_family <- "'.$::config_obj->font_plot_current.'"
if ( exists("PERL_font_family") ){
	font_fam <- PERL_font_family
}

# プロット
#if (smaller_nodes ==1){
#	par(mai=c(0,0,0,0), mar=c(0,0,1,1), omi=c(0,0,0,0), oma =c(0,0,0,0) )
#} else {
#	par(mai=c(0,0,0,0), mar=c(0,0,0,0), omi=c(0,0,0,0), oma =c(0,0,0,0) )
#}
if ( length(get.vertex.attribute(n2,"name")) > 1 ){
	# ネットワークを描画


# edit ------------------------------------------------------------
	if (fix_lab == 1){
		if (exists("if_fixed") == 0){
			plot.new()
			plot.window(xlim=c(-1, 1), ylim=c(-1, 1))
			
			labcd <- NULL
			labcd$x <- lay_f[,1]
			labcd$y <- lay_f[,2]
			word_labs <- colnames(d)[ as.numeric( get.vertex.attribute(n2,"name") ) ]
	
			library(wordcloud)'
			.&r_command_wordlayout
			.'nc <- wordlayout(
				labcd$x,
				labcd$y,
				word_labs,
				cex=cex * 1.28,
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
# edit ------------------------------------------------------------





#-----------------------------------------------------------------------------#
#                       Prepare for Plotting with ggplot2                     #

#-----------------------------------------------#
#  get ready for ggplot2 graph drawing (1): n2  #

n2 <- set.vertex.attribute(
	n2,
	"lab",
	1:length(get.vertex.attribute(n2,"name")),
	colnames(d)[ as.numeric( get.vertex.attribute(n2,"name") ) ]
)

ver_freq <- freq[ as.numeric( get.vertex.attribute(n2,"name") ) ]

if (com_method == "twomode_c" || com_method == "twomode_g"){
	ver_freq[var_select] <- NA
}

if ( is.null(target_ids) == FALSE ){
	ver_freq[target_ids] <- NA
}

if (use_freq_as_size == 0){
	ver_freq[ver_freq > 0] <- 1
}


n2 <- set.vertex.attribute(
	n2,
	"size",
	1:length(get.vertex.attribute(n2,"name")),
	ver_freq
)

# For community detection

if ( exists("com_m") ){
	com_label <- NULL

	for (h in 1:length(com_m$membership)){
		i <- com_m$membership[h]
		if ( com_m$csize[i] > 1 ) {
			if (i < 10){
				com_label <- c(
					com_label,
					paste("0", as.character(i), " ", sep="")
				)
			} else {
				com_label <- c(com_label, as.character(i))
			}
		} else {
			com_label <- c(com_label, NA)
		}
	}

	n2 <- set.vertex.attribute(
		n2,
		"com",
		1:length(get.vertex.attribute(n2,"name")),
		com_label
	)
}

if ( exists("ccol_raw") ){
	n2 <- set.vertex.attribute(
		n2,
		"com",
		1:length(get.vertex.attribute(n2,"name")),
		ccol_raw
	)
	com_label <- ccol_raw
}

if ( com_method == "none" || com_method == "twomode_g"){
	n2 <- set.vertex.attribute(
		n2,
		"com",
		1:length(get.vertex.attribute(n2,"name")),
		rep( "na", length(get.vertex.attribute(n2,"name")) )
	)
	com_label <- NA
}

if ( exists("edg_mst") ){
	n2 <- set.edge.attribute(
		n2,
		"edg_col",
		1:length(get.edge.attribute(n2,"weight")),
		edg_mst
	)
	#print(edg_mst)
}

n2 <- set.vertex.attribute(
	n2,
	"shape",
	1:length(get.vertex.attribute(n2,"name")),
	v_shape
)

edg_lty[edg_lty==1] <- "solid"
edg_lty[edg_lty==3] <- "dotted"

n2 <- set.edge.attribute(
	n2,
	"line",
	1:length(get.edge.attribute(n2,"weight")),
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
	alpha_value = 0.7
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

rownames(lay_f) <- colnames(d)[ as.numeric( get.vertex.attribute(n2,"name") ) ]
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

#-----------------------------------------------------------------------------#
#                           Start Plotting with ggplot2                       #

#---------#
#  Edges  #

if (min_sp_tree == 1){
	edg_col2 <- p$data$edg_col
	edg_col2[edg_col2=="gray30"] <- "MST"
	edg_col2[edg_col2=="gray55"] <- "non-MST"
	edg_col2[edg_col2=="gray70"] <- "non-MST"
	p <- p + geom_edges(
		aes(linetype = as.character(line), alpha=edg_col2),
		#size = 0.8,
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
		#size = 0.8,
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
		size = 0.4,
		color = edge_colour
	)
}

p <- p + scale_linetype_identity()

#---------#
#  Nodes  #

# words

p <- p + geom_nodes(
	aes(
		size = size * 0.333,
		fill = com,
		shape = shape
	),
	alpha = 0.8,
	colour = NA,
	show.legend = F,
	shape = 21
)
p <- p + geom_nodes(
	aes(
		size = size,
		fill = com,
		shape = shape
	),
	colour = gray_color_n,
	alpha = alpha_value,
	shape = 21
)

if ( use_freq_as_size == 1 ){
	p <- p + scale_size_area(
		"Frequency",
		max_size = 30,
		guide = guide_legend(
			title = "Frequency:",
			override.aes = list(colour="black", alpha=1),
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
	( com_method == "com-b" || com_method == "com-g" || com_method == "com-r")
	&& gray_scale == 1
	&& smaller_nodes == 0
){
	theta <- seq(0, 2*pi, length.out=32)
	xo <- 0.8 / 200
	yo <- 0.8 / 200
	for(i in theta) {
		df <- data.frame(
			x = lay_f_df$x + cos(i)*xo,
			y = lay_f_df$y + sin(i)*yo,
			lab = lay_f_df$lab
		)
		p <- p + geom_text( 
			data = df,
			aes(
				x     = x,
				y     = y,
				xend  = x,
				yend  = y,
				label =lab
			),
			colour="white",
			size=4,
			hjust = hjust,
			nudge_x = nudge,
			nudge_y = nudge,
			family=font_fam,
			na.rm = T,
			#alpha = 0.8,
			fontface=face
		)
	}
}

if (
	   (com_method == "twomode_c" || com_method == "twomode_g")
	&& (smaller_nodes == 1)
){
	lay_f_df_bak <- lay_f_df[var_select,]
	lay_f_df$lab[var_select] <- NA
	p <- p + geom_text(
		data = lay_f_df_bak,
		aes(
			x = x,
			y = y,
			xend = x,
			yend = y,
			label = lab
		),
		size=4,
		#hjust = hjust,
		#nudge_x = nudge,
		nudge_y = nudge * 1.65,
		family=font_fam,
		na.rm = T,
		fontface=face
	)
}

p <- p + geom_text(
	data = lay_f_df,
	aes(
		x = x,
		y = y,
		xend = x,
		yend = y,
		label = lab
	),
	size=4,
	hjust = hjust,
	nudge_x = nudge,
	nudge_y = nudge * 1.25,
	family=font_fam,
	na.rm = T,
	fontface=face
)

#---------------#
#  Edge labels  #

if (view_coef == 1){
	p <- p + geom_edgetext(
		aes(label = substring( round(weight, digits = 2), 2, 4) ),
		color = "#000080",
		fill = NA,
		size=3.5,
	)
}

#-------------------#
#  Community color  #

if ( com_method == "com-b" || com_method == "com-g" || com_method == "com-r"){
	if ( gray_scale == 1) {
		p <- p + scale_fill_grey(
			na.value = "white",
			guide = guide_legend(
				title = "Community:",
				override.aes = list(size=5.5, alpha=1, shape=22),
				keyheight = unit(1,"line"),
				ncol=2,
				order = 1
			)
		)
	} else {
		if ( length(com_m$csize[com_m$csize > 1]) <= 12 ){
			p <- p + scale_fill_brewer(
				palette = "Set3",
				na.value = "white",
				guide = guide_legend(
					title = "Community:",
					override.aes = list(size=5.5, alpha=1, shape=22),
					keyheight = unit(1,"line"),
					ncol=2,
					order = 1
				)
			)
		} else {
			p <- p + scale_fill_hue(
				c = 50,
				l = 85,
				na.value = "white",
				guide = guide_legend(
					title = "Community:",
					override.aes = list(size=5.5, alpha=1, shape=22),
					keyheight = unit(1,"line"),
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
	} else {
		#library(RColorBrewer)
		#myPalette <- colorRampPalette(rev(brewer.pal(5, "RdYlBu")))(100) #Spectral
		myPalette <- cm.colors(99)
	}

	p <- p + scale_fill_gradientn(
		colours = myPalette,
		#limits = c( limv * -1, limv ),
		guide = guide_colourbar(
			title = "Centrality:\n",
			title.theme = element_text(
				face="bold",
				size=11,
				lineheight=0.4,
				angle=0
			),
			order = 1,
			#override.aes = list(size=6, shape=22),
			label.hjust = 1,
			#reverse = TRUE,
			#ncol=2,
			#keyheight = unit(1.5,"line")
		)
	)
}

#----------------#
#  2 Mode color  #

if (com_method == "twomode_c"){
	p <- p + scale_fill_manual(
		values = brewer.pal(8, "Spectral")[4:8],
		guide = guide_legend(
			title = "Degree:",
			order = 1,
			override.aes = list(size=6, shape=22),
			label.hjust = 1,
			#reverse = TRUE,
			#ncol=2,
			keyheight = unit(1.2,"line")
		)
	)
}

if ( com_method == "none" || com_method == "twomode_g"){
	p <- p + scale_fill_manual(
		values = c("white"),
		na.value = "white",
		guide = F
	)
}

#---------------------#
#  Final adjustments  #

p <- p + theme_blank()

p <- p + theme(
	legend.title    = element_text(face="bold",  size=11, angle=0),
	legend.text     = element_text(face="plain", size=11, angle=0)
)

p <- p + coord_fixed()

g <- ggplotGrob(p)

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

library(grid)
grid.draw(g)

if (exists("com_m")){
	rm("com_m")
}
if (exists("ccol_raw")){
	rm("ccol_raw")
}
if (exists("edg_mst")){
	rm("edg_mst")
}







}
'
}

sub r_command_wordlayout{
	return '

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
insertSource(filename, package="wordcloud", force=FALSE)

';
}

1;