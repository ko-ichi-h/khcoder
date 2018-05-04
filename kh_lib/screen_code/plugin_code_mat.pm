package screen_code::plugin_code_mat;

use screen_code::plugin_path;

use strict;
use utf8;
use File::Path;
use Encode qw/encode decode/;

use kh_r_plot;

sub new{
	my $class = shift;
	my %args = @_;

	#print "$class\n";

	#このselfは有効活用されていないため要らないかもしれない(ほぼすべてargsを使っている)
	my $self = \%args;
	bless $self, $class;

	kh_r_plot->clear_env;

	my $r_command = $args{r_command};
	

	#selectionで一部のコードのみ表示する機能？ 記号を追加するための行列も同様の処理を行えば適用可能か
	# パラメーター設定（共通）
	$args{font_size} = $::config_obj->plot_font_size / 100 unless $args{font_size}; # フォントサイズ
	#$r_command .= "cex <- $args{font_size}\n";
	$r_command .= "cex <- 1\n";

	#if ( defined($self->{selection}) ){                # コード選択
	#	if ( $#{$self->{selection}} > -1 ){
	#		$r_command .= "c_names <- colnames(d)\n";
	#		
	#		my $t = '';
	#		foreach my $i (@{$self->{selection}}){
	#				$t .= "$i,";
	#		}
	#		chop $t;
	#		$r_command .= "d <- as.matrix(d[,c($t)])\n";
	#		$r_command .= "rsd <- as.matrix(rsd[,c($t)])\n";
	#		$r_command .= "colnames(d) <- c_names[c($t)]\n";
	#	}
	#}

	#並び替えは処理的にコード選択と同時に行えない
	if ($args{row_sort}) {
		$r_command .= "d <- as.matrix(d[c($args{row_sort}),])\n";
		$r_command .= "rsd <- as.matrix(rsd[c($args{row_sort}),])\n";
		$r_command .= "array <- as.matrix(array[c($args{row_sort}),])\n";
	}
	if ($args{col_sort}) {
		$r_command .= "d <- as.matrix(d[,c($args{col_sort})])\n";
		$r_command .= "rsd <- as.matrix(rsd[,c($args{col_sort})])\n";
		$r_command .= "array <- as.matrix(array[,c($args{col_sort})])\n";
	}

	
	# パラメーター設定（バブルプロット）
	$args{plot_size_maph} = $::config_obj->plot_size_codes unless $args{plot_size_maph};
	$args{plot_size_mapw} = $::config_obj->plot_size_words unless $args{plot_size_mapw};
	
	$args{bubble_shape} = 0 unless length($args{bubble_shape});
	$r_command .= "bubble_shape <- $args{bubble_shape}\n";
	
	$args{bubble_size} = 1 unless $args{bubble_size};
	$args{bubble_size} = int( $args{bubble_size} * 100 + 0.5) / 100;
	$r_command .= "bubble_size <- $args{bubble_size}\n";

	$args{color_rsd} = 1 unless length($args{color_rsd});
	$r_command .= "color_rsd <- $args{color_rsd}\n";

	#$args{color_gry} = 0 unless length($args{color_gry});
	#$r_command .= "color_gry <- $args{color_gry}\n";

	$args{color_maxv} = 10 unless length( $args{color_maxv} );
	$r_command .= "maxv <- $args{color_maxv}\n";
	
	$args{color_fix} = 0 unless length( $args{color_fix} );
	$r_command .= "color_fix <- $args{color_fix}\n";
	
	$args{symbol_rate} = 100 unless length( $args{symbol_rate} );
	$r_command .= "symbol_rate <- $args{symbol_rate}\n";
	
	
	$r_command .= "color_universal_design <- 1\n";
	
	my $r_command_fluc = $self->r_plot_cmd_fluc;
	my $r_command_fluc_plug = $r_command_fluc;
	&text_henkan(\$r_command_fluc_plug);
	
	# プロット作成
	
	my @plots = ();
	
	my @plot_names;
	my $plot_file_names;
	my $plot_number;
	my @plot_coloring;
	my @fluc_array;
	my $plot_num;
	if ($args{color_rsd}) {
		@plot_names = ('_1','_2','_3','_4');
		@plot_coloring = ("color_gry <- 0\n","color_gry <- 1\n","color_gry <- 0\n","color_gry <- 1\n");
		@fluc_array = (\$r_command_fluc_plug,\$r_command_fluc_plug,\$r_command_fluc,\$r_command_fluc);
		$plot_file_names = "1,2,3,4";
		$plot_number = "0,1,2,3";
		$plot_num = 4;
	} else {
		@plot_names = ('_1','_2');
		@plot_coloring = ("color_gry <- 1\n","color_gry <- 1\n");
		@fluc_array = (\$r_command_fluc_plug,\$r_command_fluc);
		$plot_file_names = "1,2";
		$plot_number = "0,1";
		$plot_num = 2;
	}

	my $plot;
	for (my $i = 0; $i < $plot_num; $i++) {

		$plot = kh_r_plot->new(
			name      => $args{plotwin_name}.$plot_names[$i],
			command_f =>
				 $r_command
				.$plot_coloring[$i]
				.${$fluc_array[$i]},
			width     => $args{plot_size_mapw},
			height    => $args{plot_size_maph},
			font_size => $args{font_size},
		) or return 0;
		push @plots, $plot;
	}

	kh_r_plot->clear_env;
	undef $self;
	undef %args;
	$self->{result_plots} = \@plots;
	$self->{plot_file_names} = $plot_file_names;
	$self->{plot_number} = $plot_number;
	
	return $self;
}


sub text_henkan{
	if (-f &screen_code::plugin_path::assistant_path) {
		my $r_com_ref = shift;
		
		my $DATAFILE;
		my $file_rcom = &screen_code::plugin_path::assistant_option_folder."rcom_crs.txt";
		unlink $file_rcom if -f $file_rcom;
		open($DATAFILE, ">>", $file_rcom);
		print $DATAFILE encode('utf8',$$r_com_ref);
		close($DATAFILE);
		
		system(&screen_code::plugin_path::assistant_path_system, "5");
		
		open($DATAFILE, "<:utf8", $file_rcom);
		{
			local $/ = undef; 
			$$r_com_ref = readline $DATAFILE;
		}
		close($DATAFILE);
	}
}


sub r_plot_cmd_fluc{
	my $self = shift;
	return '

alpha_value <- 0.5

bubble_size <- bubble_size / '.$self->{font_size}.'

if ( exists("saving_emf") || exists("saving_eps") ){
	alpha_value <- 1
}

library(grid)
library(ggplot2)

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
		quartzFonts(HiraKaku=quartzFont(rep("'.&font_plot_current.'",4)))
		font_fam <- "HiraKaku"
	} else {
		font_fam <- "'.&font_plot_current.'"
	}
}

#screen plugin1 start#
ggfluctuation_my <- function (mat, rsd, maxv){
	if (nrow(mat) > 1){
		mat <- mat[nrow(mat):1,]
		rsd <- rsd[nrow(rsd):1,]
	}
	
	# preparing the data.frame
	table <- NULL
	for (r in 1:nrow(mat)){
		for (l in 1:ncol(mat)){
			table <- rbind(table, c(r, l, mat[r,l], rsd[r,l]))
		}
	}
	table <- data.frame(
		x	  = as.factor(table[,2]),
		y	  = as.factor(table[,1]),
		result = table[,3],
		rsd    = table[,4]
	)
	
	table <- subset(table, result > 0)
	#screen plugin1 end#

	if (color_fix == 1){
		table$rsd[table$rsd >  maxv     ] <- maxv
		table$rsd[table$rsd <  maxv * -1] <- maxv * -1
	}

	# Set up the plot
	p <- ggplot(
		table,
		aes_string(
			x = "x",
			y = "y",
			size = "result",
			fill = "rsd"
		)
	)

	# Basic points
	if (color_rsd == 1){
		p <- p + geom_point(
			shape=ifelse(bubble_shape==0, 22, 21),
			colour = "black",
			alpha=alpha_value
		)
	} else {
		p <- p + geom_point(
			shape=ifelse(bubble_shape==0, 22, 21),
			colour="black",
			fill="gray30",
			alpha=alpha_value
		)
	}

	# Fill color
	if (color_rsd == 1){
		limv = max( abs( table$rsd ) )
		if ( color_fix == 1 ){
			limv <- maxv
		}
		if (color_gry == 1){
			p <- p + scale_fill_gradientn(
				colours = paste("gray",95:1, sep=""),
				limits = c( limv * -1, limv ),
				guide = guide_legend(
					title = "Pearson rsd.",
					order = 1,
					override.aes = list(size=6, shape=22),
					label.hjust = 1,
					reverse = TRUE,
					keyheight = unit(1.5,"line")
				)
			)
		}
		else if (color_universal_design == 0){
			p <- p + scale_fill_gradientn(
				colours = cm.colors(99),
				limits = c( limv * -1, limv ),
				guide = guide_legend(
					title = "Pearson rsd.",
					order = 1,
					override.aes = list(size=6, shape=22),
					label.hjust = 1,
					reverse = TRUE,
					keyheight = unit(1.5,"line")
				)
			)
		} else {
			library(RColorBrewer)
			myPalette <- colorRampPalette(rev(brewer.pal(5, "RdYlBu"))) #Spectral
			
			p <- p + scale_fill_gradientn(
				colours = myPalette(100),
				limits = c( limv * -1, limv ),
				na.value = "black",
				guide = guide_colourbar(
					title = "Pearson rsd.:\n",
					title.theme = element_text(
						face="bold",
						size=11,
						lineheight=0.4,
						angle=0
					),
					label.hjust = 1,
					order = 1
				)
			)
		}
	}

	p <- p + scale_size_area(
		limits = c(0.05, ceiling(max(table$result))),
		max_size = 15*bubble_size,
		guide = guide_legend(
			title = "\nPercent:",
			override.aes = list(alpha = 1, fill=NA),
			label.hjust = 1,
			order = 2
		)
	)

	# labels of axis
	p <- p + scale_x_discrete(
		breaks = 1:ncol(mat),
		labels = colnames(mat),
		expand = c(0.015, 0.5)
	)
	p <- p + scale_y_discrete(
		breaks = 1:nrow(mat),
		labels = rownames(mat),
		expand = c(0.015, 0.5)
	)

	# other cofigs of the plot
	nx <- length(levels(table$x))
	ny <- length(levels(table$y))
	p <- p + theme_classic()
	p <- p + theme(
		#aspect.ratio = ny/nx,
		#legend.background=element_rect(fill="gray96",colour = NA),
		legend.key=element_rect(fill=NA,colour = NA),
		legend.title = element_text(face="bold",  size=11, angle=0),
		legend.text  = element_text(face="plain", size=11, angle=0),
		plot.margin =   unit(c(0.25, 0.01, 0.25, 0.25), "cm"),
		axis.line.x    = element_line(colour = "black", size=0.5),
		axis.line.y    = element_line(colour = "black", size=0.5),
		panel.grid.major = element_line(
			colour = "gray50",
			size=0.25
		),
		panel.grid.major.x = element_line(
			colour = "gray50",
			size=0.25
		),
		panel.grid.major.y = element_line(
			colour = "gray50",
			size=0.25
		),
		axis.title.y     = element_blank(),
		axis.title.x     = element_blank(),
		axis.ticks       = element_blank(),
		axis.text.x=element_text(
			size=12 * cex,
			colour="black",
			angle=90,
			hjust=1
			#family=font_fam
		),
		axis.text.y=element_text(
			size=12 * cex,
			colour="black",
			hjust=1
			#family=font_fam
		)
	)

	if ( is.null(font_fam) == FALSE ){
		p <- p + theme(
			axis.text.x=element_text(
				size=12 * cex,
				colour="black",
				angle=90,
				hjust=1,
				family=font_fam
			),
			axis.text.y=element_text(
				size=12 * cex,
				colour="black",
				hjust=1,
				family=font_fam
			)
		)
	}
	
	#screen plugin2#
	print(p)
}


#screen plugin3 start#
ggfluctuation_my(  t( as.matrix(d) ),  t( as.matrix(rsd) ), maxv ) 
#screen plugin3 end#
	';
}


sub font_plot_current{
	my $self = $::config_obj;

	# 中国語 / 韓国語プロジェクトを開いている時だけ中 / 韓フォントを返す
	if ($::project_obj) {
		my $lang = $::project_obj->morpho_analyzer_lang;
		if ($lang eq 'cn') {
			return $self->font_plot_cn;
		}
		elsif ($lang eq 'kr'){
			return $self->font_plot_kr;
		}
		elsif ($lang eq 'ru'){
			return $self->font_plot_ru;
		}
	}
	return $self->font_plot;
}

1;