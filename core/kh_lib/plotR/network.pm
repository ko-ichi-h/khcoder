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


	# プロット作成
	
	#use Benchmark;
	#my $t0 = new Benchmark;
	
	my @plots = ();
	my $flg_error = 0;
	
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
			width     => $args{plot_size},
			height    => $args{plot_size},
			font_size => $args{font_size},
		) or $flg_error = 1;

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
			width     => $args{plot_size},
			height    => $args{plot_size},
			font_size => $args{font_size},
		) or $flg_error = 1;
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
			width     => $args{plot_size},
			height    => $args{plot_size},
			font_size => $args{font_size},
		) or $flg_error = 1;

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
			width     => $args{plot_size},
			height    => $args{plot_size},
			font_size => $args{font_size},
		) or $flg_error = 1;

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
			width     => $args{plot_size},
			height    => $args{plot_size},
			font_size => $args{font_size},
		) or $flg_error = 1;

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
			width     => $args{plot_size},
			height    => $args{plot_size},
			font_size => $args{font_size},
		) or $flg_error = 1;

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
			width     => $args{plot_size},
			height    => $args{plot_size},
			font_size => $args{font_size},
		) or $flg_error = 1;

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
			width     => $args{plot_size},
			height    => $args{plot_size},
			font_size => $args{font_size},
		) or $flg_error = 1;

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
			width     => $args{plot_size},
			height    => $args{plot_size},
			font_size => $args{font_size},
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

	kh_r_plot::network->clear_env;
	undef $self;
	undef %args;
	$self->{result_plots} = \@plots;
	$self->{result_info} = $info;
	$self->{result_info_long} = $info_long;
	
	return 0 if $flg_error;
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
d <- dist(d,method="binary")
d <- as.matrix(d)
d <- 1 - d;

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
		ccol <- betweenness(
			n2,
			v=(0+new_igraph):(length(get.vertex.attribute(n2,"name"))-1+new_igraph),
			directed=F
		)
	}
	if (com_method == "cnt-d"){                   # 次数
		ccol <-  degree(
			n2,
			v=(0+new_igraph):(length(get.vertex.attribute(n2,"name"))-1+new_igraph)
		)
	}
	if (com_method == "cnt-e"){                   # 固有ベクトル
		try(
			ccol <- evcent(n2)$vector,
			silent = T
		)
	}
	
	# 色の設定
	if ( gray_scale == 1 ) {
		ccol <- ccol - min(ccol)
		ccol <- 1 - ccol / max(ccol) / 2.5
		ccol <- gray(ccol)
	} else {
		ccol <- ccol - min(ccol)
		ccol <- ccol * 100 / max(ccol)
		ccol <- trunc(ccol + 1)
		ccol <- cm.colors(101)[ccol]
	}

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
	ccol <-  degree(
		n2,
		v=(0+new_igraph):(length(get.vertex.attribute(n2,"name"))-1+new_igraph)
	)
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
	if (length(edg_col) == 1){
		edg_col <- rep(edg_col, length( get.edge.attribute(n2, "weight") ))
	}
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
# レイアウトを考慮したグレーの配色
if (
	( gray_scale == 1 ) && (
		   com_method == "com-b"
		|| com_method == "com-g"
		|| com_method == "com-r"
	)
){
	com_col_v <- "gray40"
	
	# グレーを準備
	grays <- NULL
	n_coms <- length(com_m$csize[com_m$csize > 1]);
	for (i in 1:n_coms){
		#print(0.8 / (n_coms-1) * (i - 1) + 0.15)
		grays <- c( grays, 0.8 / (n_coms-1) * (i - 1) + 0.15 )
	}
	grays <- gray(grays)

	# グループのリスト（1はじまり）
	groups <- NULL
	groups <- as.matrix( table(com_m$membership + 1 - new_igraph) )
	groups <- data.frame(
		name = rownames(groups),
		freq = groups[,1]
	)
	# groups$freq[groups$name==3]

	# メンバーのリスト（1はじまり）
	group_members <- data.frame(
		vid = 1:length(com_m$membership),
		gp  = com_m$membership + 1 - new_igraph,
		x   = lay_f[,1],
		y   = lay_f[,2]
	)
	
	dist_single <- function(d, g1, g2){
		sub <- subset(d,gp==g1|gp==g2)
		sub <- sub[order(sub$gp),]
		
		if (g1 > g2){
			tmp1 <- g1
			tmp2 <- g2
			g1 <- tmp2
			g2 <- tmp1
		}
		
		#print("-----------------------")
		#print(g1)
		#print(g2)
		
		dd <- sub[,3:4];
		rownames(dd) <- paste(sub$gp, sub$vid, sep="-")
		
		#print(dd)
		
		dis <- as.matrix( dist(dd,method = "euclidean") )
		
		n_g1 <- length( sub$vid[sub$gp==g1] )
		n_g2 <- length( sub$vid[sub$gp==g2] )
		
		#print(dis)
		
		dis <- dis[(n_g1+1):length(rownames(dis)), 1:n_g1]
		
		#print(dis)
		#print(min(dis))
		
		return (mean(dis))
	}
	
	group_dist <- matrix(rep(NA, n_coms^2), ncol=n_coms, nrow=n_coms  )
	for (i in groups$name[groups$freq>1]){
		for (h in groups$name[groups$freq>1]){
			i <- as.numeric(i)
			h <- as.numeric(h)
			if (i == h){
				group_dist[i,h] <- 0
			} else {
				group_dist[i,h] <- dist_single(group_members, i, h)
			}
		}
	}
	group_dist <- as.dist(group_dist)
	
	#library(MASS)
	#order <- isoMDS(group_dist, k=1)$points
	
	#order <- cmdscale(group_dist, k=1)
	#order <- order(order[,1])
	
	h <- hclust(group_dist, method="average")
	order <- h$order
	
	n_order <- NULL
	for (i in 1:n_coms){
		if (i %% 2 == 0){
			n_order <- c(n_order, ceiling(n_coms / 2) + i / 2 )
		} else {
			n_order <- c(n_order, ceiling(i/2) )
		}
	}
	
	group_color <- data.frame(
		gp  = order,
		col = n_order
	)
	group_color <- group_color[order(group_color$gp),]
	
	#print(group_dist)
	#print(order)
	#print(n_order)
	#print(group_color$col)

	grays <- grays[group_color$col]

	ccol <- grays[com_m$membership + 1 - new_igraph]
}

if ( exists("saving_emf") || exists("saving_eps") ){
	use_alpha <- 0 
}

if (use_alpha == 1 && com_method != "none" && com_method != "twomode_g"){
	ccol_notrans <- ccol
	rgb <- col2rgb(ccol) / 256
	ccol <- rgb(
		red  =rgb[1,],
		green=rgb[2,],
		blue =rgb[3,],
		alpha=0.685
	)
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
if (view_coef == 1){
	edge_label <- substring(
		round(
			get.edge.attribute(n2,"weight"),
			digits=2
		),
		2,
		4
	)
}

font_fam <- NULL
if ( exists("PERL_font_family") ){
	font_fam <- PERL_font_family
}

# プロット
if (smaller_nodes ==1){
	par(mai=c(0,0,0,0), mar=c(0,0,1,1), omi=c(0,0,0,0), oma =c(0,0,0,0) )
} else {
	par(mai=c(0,0,0,0), mar=c(0,0,0,0), omi=c(0,0,0,0), oma =c(0,0,0,0) )
}
if ( length(get.vertex.attribute(n2,"name")) > 1 ){
	# ネットワークを描画
	if (fix_lab == 0){
		plot.igraph(
			n2,
			vertex.label        = "",
			#vertex.label       =colnames(d)
			#                    [ as.numeric( get.vertex.attribute(n2,"name") ) ],
			#vertex.label.cex   =f_size,
			#vertex.label.color ="black",
			#vertex.label.family= "", # Linux・Mac環境では必須
			#vertex.label.dist  =vertex_label_dist,
			vertex.color       =ccol,
			vertex.frame.color =com_col_v,
			vertex.size        =v_size,
			vertex.shape       =v_shape,
			edge.color         =edg_col,
			edge.lty           =edg_lty,
			edge.width         =edg_width,
			edge.label         =edge_label,
			edge.label.cex     =0.9,
			edge.label.family  =font_fam,
			layout             =lay_f,
			rescale            =F
		)
	}

# edit ------------------------------------------------------------
	if (fix_lab == 1){
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

		plot.igraph(
			n2,
			vertex.label        = "",
			#vertex.label       =colnames(d)
			#                    [ as.numeric( get.vertex.attribute(n2,"name") ) ],
			#vertex.label.cex   =f_size,
			#vertex.label.color ="black",
			#vertex.label.family= "", # Linux・Mac環境では必須
			#vertex.label.dist  =vertex_label_dist,
			vertex.color       =ccol,
			vertex.frame.color =com_col_v,
			vertex.size        =v_size,
			vertex.shape       =v_shape,
			edge.color         =edg_col,
			edge.lty           =edg_lty,
			edge.width         =edg_width,
			edge.label         =edge_label,
			edge.label.family  =font_fam,
			layout             =lay_f,
			rescale            =F,
			add = T
		)
		if_fixed <- 1
	}
# edit ------------------------------------------------------------








	# 語のラベルを追加
	lay_f_adj <- NULL
	if (smaller_nodes ==1){
		# [2011 10/19]
		# 小さいノードで表示する際にplot.igraph関数のvertex.label.distを指定
		# すると、長い（文字数が多い）語が離れすぎて綺麗でなかったので、手動
		# でラベルを追加. R 2.12.2 / igraph 0.5.5-2 
		if ( is.null(lay_f_adj) == 1){
			lay_f_adj <- cbind(lay_f_adj, lay_f[,1])
			lay_f_adj <- cbind(lay_f_adj, lay_f[,2] + ( max(lay_f[,2]) - min(lay_f[,2]) ) / 38 )
		}

		labels <- colnames(d)[ as.numeric( get.vertex.attribute(n2,"name") ) ]
		if ( (exists("target_words")) && (is.null(target_ids) == 0) ){
			text(
				lay_f[target_ids,1],
				lay_f[target_ids,2],
				labels = labels[target_ids],
				font = text_font,
				cex = f_size,
				col = "black"
			)
			labels[target_ids] <- ""
		}

		if ( exists("var_select") ){
			text(
				lay_f[var_select,1],
				lay_f[var_select,2],
				labels = labels[var_select],
				font = text_font,
				cex = f_size,
				col = "black"
			)
			labels[var_select] <- ""
		}

		text(
			lay_f_adj,
			labels = labels,
			pos = 4,
			offset = 0.25,
			font = text_font,
			cex = f_size,
			col = "black"
		)
	} else {
		if (
			( gray_scale == 1 ) && (
				   com_method == "com-b"
				|| com_method == "com-g"
				|| com_method == "com-r"
			)
		){
			library(TeachingDemos)
			shadowtext(
				lay_f,
				#labels = group_members,
				labels = colnames(d)
				         [ as.numeric( get.vertex.attribute(n2,"name") ) ],
				r = 0.2,
				theta =  seq(0, 2 * pi, length.out = 32),
				font = text_font,
				cex = f_size,
				col = "black",
				bg="white"
			)
		} else {
			text(
				lay_f,
				labels = colnames(d)
				         [ as.numeric( get.vertex.attribute(n2,"name") ) ],
				#pos = 4,
				#offset = 1,
				font = text_font,
				cex = f_size,
				col = "black"
			)
		}
	}

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