package plotR::code_mat_line;

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

	# パラメーター設定（共通）
	$args{font_size} = 1 unless $args{font_size};      # フォントサイズ
	$r_command .= "cex <- $args{font_size}\n";

	if ( defined($self->{selection}) ){                # コード選択
		if ( $#{$self->{selection}} > -1 ){
			$r_command .= "c_names <- colnames(d)\n";
			
			my $t = '';
			foreach my $i (@{$self->{selection}}){
					$t .= "$i,";
			}
			chop $t;
			$r_command .= "d <- as.matrix(d[,c($t)])\n";
			$r_command .= "rsd <- as.matrix(rsd[,c($t)])\n";
			$r_command .= "colnames(d) <- c_names[c($t)]\n";
		}
	}

	# プロット作成
	
	my @plots = ();
	my $flg_error = 0;

	$plots[0] = kh_r_plot->new(
		name      => $args{plotwin_name}.'_1',
		command_f =>
			 $r_command
			.$self->r_plot_cmd_line,
		width     => 640,
		height    => 480,
	) or $flg_error = 1;


	kh_r_plot->clear_env;
	undef $self;
	undef %args;
	$self->{result_plots} = \@plots;
	
	return 0 if $flg_error;
	return $self;
}

sub r_plot_cmd_line{
	return '

library(grid)
library(ggplot2)
ggplot2_version <- sessionInfo()$otherPkgs$ggplot2$Version
ggplot2_version <- strsplit(x=ggplot2_version, split=".", fixed=T)
ggplot2_version <- unlist(     ggplot2_version )
ggplot2_version <- as.numeric( ggplot2_version )
ggplot2_version <- ggplot2_version[1] * 10 + ggplot2_version[2]

font_fam <- NULL
if ( is.null(dev.list()) ){
	font_fam <- 1
} else {
	if ( is.na(dev.list()["pdf"]) && is.na(dev.list()["postscript"]) ){
		font_fam <- 1
	}
}
if ( is.null(font_fam) == FALSE ){
	if ( grepl("darwin", R.version$platform) ){
		quartzFonts(HiraKaku=quartzFont(rep("Hiragino Kaku Gothic Pro W6",4)))
		font_fam <- "HiraKaku"
	} else {
		font_fam <- "'.$::config_obj->font_plot.'"
	}
}

if (ncol(d) > 9){
	d <- d[,1:6]
}

# preparing the data.frame
table <- NULL
for (r in 1:nrow(d)){
	for (l in 1:ncol(d)){
		table <- rbind(table, c(r, l, d[r,l]))
	}
}
table <- data.frame(
	x	= as.factor(table[,1]),
	y	= table[,3],
	c	= as.factor(table[,2])
)

# preparing x-axis labels
x.labels <- rownames(d)
x.cuts   <- 1:nrow(d)
if ( length(x.labels) > 21 ){
	cutting <- length(x.labels) / 20
	cutting <- ceiling(cutting)
	x.labels <- NULL
	x.cuts   <- NULL
	
	n <- 1
	while ( n <= nrow(d) ){
		x.cuts   <- c(x.cuts, n)
		x.labels <- c(x.labels, rownames(d)[n])
		n <- n + cutting
	}
}

# creating the plot
#if (ncol(d) > 1){
	p <- ggplot(
		table,
		aes_string(
			x = "x",
			y = "y",
			group="c",
			colour="c",
			shape="c"
		)
	)
#} else {
#	p <- ggplot(
#		table,
#		aes_string(
#			x = "x",
#			y = "y",
#			group="c"
#			#colour="c",
#			#shape="c"
#		)
#	)
#}

p <- p + geom_line()

p <- p + geom_point() 

p <- p + scale_shape_discrete(
	"",
	breaks = 1:ncol(d),
	labels = colnames(d)
)

p <- p + scale_colour_hue(
	name = "",
	breaks = 1:ncol(d),
	labels = colnames(d)
)

p <- p + scale_x_discrete(
	breaks = x.cuts,
	labels = x.labels
)

p <- p + scale_y_continuous(
	limits = c(0, ceiling( max(table$y) * 1.01 ))
)

p <- p + opts(
	axis.title.x     = theme_blank(),
	axis.title.y     = theme_blank(),
	axis.ticks       = theme_blank(),
	plot.margin =   unit(c(0.25, 0.01, 0.25, 0.25), "cm"),
	axis.text.x=theme_text(
		size=11 * cex,
		colour="black",
		angle=90,
		hjust=1
		#family=font_fam
	),
	axis.text.y=theme_text(
		size=11 * cex,
		colour="black",
		hjust=1
		#family=font_fam
	)
)

if ( is.null(font_fam) == FALSE ){
	p <- p + opts(
		axis.text.x=theme_text(
			size=12 * cex,
			colour="black",
			angle=90,
			hjust=1,
			family=font_fam
		),
		axis.text.y=theme_text(
			size=12 * cex,
			colour="black",
			hjust=1,
			family=font_fam
		),
		legend.text=theme_text(
			size=12 * cex,
			colour="black",
			family=font_fam
		)
	)
}

print(p)




	';
}


1;