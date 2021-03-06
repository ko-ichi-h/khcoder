package gui_window::topic_perplexity;
use base qw(gui_window);
use utf8;

use strict;
use Tk;

use gui_widget::words;
use mysql_crossout;
use kh_r_plot;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt($self->label));

	my $lf_w = $win->LabFrame(
		-label       => kh_msg->get('gui_window::word_cls->u_w'), # 集計単位と抽出語の選択
		-labelside   => 'acrosstop',
		-borderwidth => 2,
		-foreground  => 'blue',
	)->pack(-fill => 'both', -expand => 0, -side => 'left',-anchor => 'w');

	my $rf = $win->Frame()
		->pack(-fill => 'x', -expand => 1, -anchor => 'n');

	my $lf = $rf->LabFrame(
		-label       => kh_msg->get('opt'), # トピックモデルと探索のオプション
		-labelside   => 'acrosstop',
		-borderwidth => 2,
		-foreground  => 'blue',
	)->pack(-fill => 'x', -expand => 1, -anchor => 'n');

	$self->{words_obj} = gui_widget::words->open(
		parent => $lf_w,
		verb   => kh_msg->get('gui_window::doc_cls->verb'), # 使用
		sampling     => 1,
		command      => sub{
			$self->calc;
		},
	);

	# Perplexity計算のオプション

	my $f_f = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);

	$f_f->Label(
		-text => kh_msg->get('method'), # 方法
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{method} = 'perplexity';
	$self->{method_widget} = gui_widget::optmenu->open(
		parent  => $f_f,
		pack    => {-side => 'left', -pady => 2},
		options =>
			[
				['Perplexity', 'perplexity' ],
				['ldatuning',  'ldatuning'],
			],
		variable => \$self->{method},
		command => sub{ $self->refresh_fold; },
	);

	$self->{label_folds} = $f_f->Label(
		-text => '  ', # Folds
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{label_folds} = $f_f->Label(
		-text => kh_msg->get('folds'), # Folds
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_folds} = $f_f->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);

	$self->{entry_folds}->insert(0, '5');
	$self->{entry_folds}->bind("<Key-Return>", sub{ $self->calc; });
	$self->{entry_folds}->bind("<KP_Enter>", sub{ $self->calc; });
	gui_window->config_entry_focusin( $self->{entry_folds} );

	$self->refresh_fold;
	
	my $f_c = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);

	$f_c->Label(
		-text => kh_msg->get('candidates'), # トピック数の候補
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_candidates} = $f_c->Entry(
		-font       => "TKFN",
		-width      => 30,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2, -fill => 'x', -expand => 1);
	$self->{entry_candidates}->insert(0,'seq(2, 35, by=3), 40, 45, 50, 60, 70');
	$self->{entry_candidates}->bind("<Key-Return>",sub{ $self->calc; });
	$self->{entry_candidates}->bind("<KP_Enter>", sub{ $self->calc; });


	# フォントサイズ
	$self->{font_obj} = gui_widget::r_font->open(
		parent    => $lf,
		command   => sub{ $self->calc; },
		pack      => { -anchor   => 'w', -pady => 4 },
		show_bold => 0,
		plot_size => $::config_obj->plot_size_codes,
	);

	$rf->Checkbutton(
			-text     => kh_msg->gget('r_dont_close'),
			-variable => \$self->{check_rm_open},
			-anchor => 'nw',
	)->pack(-anchor => 'nw');

	$win->Button(
		-text => kh_msg->gget('cancel'),
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->withd;}
	)->pack(-side => 'right',-padx => 2, -pady => 2, -anchor => 'se');

	$win->Button(
		-text => kh_msg->gget('ok'),
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->calc;}
	)->pack(-side => 'right', -pady => 2, -anchor => 'se')->focus;

	return $self;
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

sub refresh_fold{
	my $self = shift;
	if ( $self->{method} eq 'perplexity') {
		$self->{label_folds}->configure(-state => 'normal');
		$self->{entry_folds}->configure(-state => 'normal');
	} else {
		$self->{label_folds}->configure(-state => 'disabled');
		$self->{entry_folds}->configure(-state => 'disabled');
	}
}

#----------#
#   実行   #

sub calc{
	my $self = shift;
	
	# 入力のチェック
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('gui_window::word_corresp->select_pos'), # '品詞が1つも選択されていません。',
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

	if ($check_num < 10){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->gget('select_3words'), #'少なくとも3つ以上の抽出語を選択して下さい。',
		);
		return 0;
	}

	$self->{words_obj}->settings_save;

	my $w = gui_wait->start;

	# データの取り出し
	my $r_command = mysql_crossout::r_com->new(
		tani   => $self->tani,
		tani2  => $self->tani,
		hinshi => $self->hinshi,
		max    => $self->max,
		min    => $self->min,
		max_df => $self->max_df,
		min_df => $self->min_df,
		rownames => 0,
		sampling => $self->{words_obj}->sampling_value,
	)->run;

	# クラスター分析を実行するためのコマンド
	#$r_command .= "d <- t(d)\n";
	$r_command .= "# END: DATA\n";

	my $plot = &make_plot(
		#$self->{cls_obj}->params,
		method         => $self->{method},
		fold           => gui_window->gui_jgn( $self->{entry_folds}->get ),
		candidates     => gui_window->gui_jgn( $self->{entry_candidates}->get ),
		font_size      => $self->{font_obj}->font_size,
		plot_size      => $self->{font_obj}->plot_size,
		r_command      => $r_command,
		plotwin_name   => 'topic_n_'.$self->{method},
		#data_number    => $check_num,
	);

	$w->end(no_dialog => 1);
	return 0 unless $plot;

	unless ( $self->{check_rm_open} ){
		$self->withd;
	}

}

sub make_plot{
	my %args = @_;

	kh_r_plot->clear_env;

	my $width;
	my $r_command = $args{r_command};
	$r_command .= "\ncex <- $args{font_size}\n";
	
	if ($args{method} eq 'perplexity'){
		$r_command .= &r_command_perp($args{fold}, $args{candidates});
		$width = $args{plot_size};
	} else {
		$r_command .= &r_command_ldatuning($args{candidates});
		$width = int($args{plot_size} * 4 / 3);
	}
	
	# make the plot
	my $plot1 = kh_r_plot->new(
		name      => $args{plotwin_name}.'_1',
		command_f => $r_command,
		width     => $width,
		height    => $args{plot_size},
		font_size => $args{font_size},
	) or return 0;
	
	# プロットWindowを開く
	kh_r_plot->clear_env;
	my $plotwin_id = 'w_'.$args{plotwin_name}.'_plot';
	if ($::main_gui->if_opened($plotwin_id)){
		$::main_gui->get($plotwin_id)->close;
	}
	
	my $plotwin = 'gui_window::r_plot::'.$args{plotwin_name};
	$plotwin->open(
		plots       => [$plot1],
		#no_geometry => 1,
		plot_size   => $args{plot_size},
	);

	return 1;
}

#--------------#
#   アクセサ   #


sub label{
	return kh_msg->get('win_title'); # 抽出語・クラスター分析：オプション
}

sub win_name{
	return 'w_topic_perplexity';
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

sub r_command_perp{
	my $fold       = shift;
	my $candidates = shift;
	
	my $t = '
#dtm <- t(d)
dtm <- d
rownames(dtm) <- 1:nrow(dtm)
dtm <- dtm[rowSums(dtm) > 0,]

library(topicmodels)

folds <- trunc( runif( nrow(dtm) ) * '.$fold.' ) + 1
perp <- NULL

my_perp <- function(k){
	current <- NULL
	for (i in 1:'.$fold.') {
		test_result_lda <- topicmodels::LDA(dtm[folds!=i,], k = k, method = "Gibbs", control = list(seed = 1234567,  burnin = 1000))
		current[i] <- topicmodels::perplexity(test_result_lda, newdata = dtm[folds==i,], use_theta = TRUE, estimate_theta = TRUE)
	}
	current <- matrix(current,nrow=1)
	rownames(current) <- k
	return(current)
}

library(parallel)
cl <- parallel::makeCluster(parallel::detectCores())
parallel::setDefaultCluster(cl)
parallel::clusterExport(varlist = c("my_perp", "dtm", "folds"), envir = environment())

perp <- parallel::parLapply(
	cl,
	c('.$candidates.'),
	my_perp
)

perp <- do.call("rbind", perp)

# プロット
perpp <- NULL
perpk <- NULL
for (i in 1:ncol(perp)){
	perpp <- c(perpp, perp[,i])
	perpk <- c(perpk, as.numeric( rownames(perp) ) )
}
perppl <- data.frame(perplexity = perpp, k = perpk)

# dpi: short based

col_dot_words <- "#74add1"

library(ggplot2)
font_family <- "'.$::config_obj->font_plot_current.'"
if ( exists("PERL_font_family") ){
	font_family <- PERL_font_family
}
print( ggplot(perppl, aes(x = k, y = perplexity)) +
	geom_point(colour = col_dot_words) +
	geom_smooth(se = F, colour = "black" ) +
	labs(x = "number of topics", y = "perplexity") +
	theme_classic(base_family=font_family) +
	theme(
	legend.key   = element_rect(colour = NA, fill= NA),
	axis.line.x    = element_line(colour = "black", size=0.5),
	axis.line.y    = element_line(colour = "black", size=0.5),
	axis.title.x = element_text(face="plain", size=11 * cex, angle=0),
	axis.title.y = element_text(face="plain", size=11 * cex, angle=90),
	axis.text.x  = element_text(face="plain", size=11 * cex, angle=0),
	axis.text.y  = element_text(face="plain", size=11 * cex, angle=0),
	legend.title = element_text(face="bold",  size=11 * cex, angle=0),
	legend.text  = element_text(face="plain", size=11 * cex, angle=0)
	))

';
return $t;
}

sub r_command_ldatuning{
	my $candidates = shift;
	
	my $t = '
#dtm <- t(d)
dtm <- d
rownames(dtm) <- 1:nrow(dtm)
dtm <- dtm[rowSums(dtm) > 0,]

library(topicmodels)
library(ldatuning)

result_tps <- FindTopicsNumber(
	dtm,
	topics   = c('.$candidates.'),
	metrics  = c("Griffiths2004", "CaoJuan2009", "Arun2010", "Deveaud2014"),
	method   = "Gibbs",
	control  = list(seed = 1234567,  burnin = 1000)
	#verbose = T
)

# dpi: short based

FindTopicsNumber_plot(result_tps)

';
return $t;
}


1;