package gui_window::word_som;
use base qw(gui_window);

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
		-label       => kh_msg->get('u_w'), # 集計単位と抽出語の選択
		-labelside   => 'acrosstop',
		-borderwidth => 2,
		-foreground  => 'blue',
	)->pack(-fill => 'both', -expand => 1, -side => 'left');

	my $lf = $win->LabFrame(
		-label       => kh_msg->get('opt'), # SOMのオプション
		-labelside   => 'acrosstop',
		-borderwidth => 2,
		-foreground  => 'blue',
	)->pack(-fill => 'both', -expand => 0);

	$self->{words_obj} = gui_widget::words->open(
		parent => $lf_w,
		verb   => kh_msg->get('cluster'), # 分類
	);

	# SOMのオプション
	$self->{som_obj} = gui_widget::r_som->open(
		parent       => $lf,
		command      => sub{ $self->calc; },
		pack    => { -anchor   => 'w'},
	);

	# フォントサイズ
	$self->{font_obj} = gui_widget::r_font->open(
		parent    => $lf,
		command   => sub{ $self->calc; },
		pack      => { -anchor   => 'w' },
		font_size => $::config_obj->r_default_font_size,
		show_bold => 1,
		plot_size => 640,
	);
	$self->{font_obj}->bold;

	$win->Checkbutton(
			-text     => kh_msg->gget('r_dont_close'),
			-variable => \$self->{check_rm_open},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	$win->Button(
		-text => kh_msg->gget('cancel'),
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->close;}
	)->pack(-side => 'right',-padx => 2, -pady => 2, -anchor => 'se');

	$win->Button(
		-text => kh_msg->gget('ok'),
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->calc;}
	)->pack(-side => 'right', -pady => 2, -anchor => 'se')->focus;

	return $self;
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

	if ($check_num < 3){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('gui_window::word_corresp->select_3words'), #'少なくとも3つ以上の抽出語を選択して下さい。',
		);
		return 0;
	}

	if ($check_num > 500){
		my $ans = $self->win_obj->messageBox(
			-message => $self->gui_jchar
				(
					kh_msg->get('gui_window::word_corresp->too_many1')
					.$check_num
					.kh_msg->get('gui_window::word_corresp->too_many2')
					."\n"
					.kh_msg->get('gui_window::word_corresp->too_many3')
					."\n"
					.kh_msg->get('gui_window::word_corresp->too_many4')
				),
			-icon    => 'question',
			-type    => 'OKCancel',
			-title   => 'KH Coder'
		);
		unless ($ans =~ /ok/i){ return 0; }
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
	)->run;

	# クラスター分析を実行するためのコマンド
	$r_command .= "d <- t(d)\n";
	$r_command .= "# END: DATA\n";

	&make_plot(
		$self->{som_obj}->params,
		font_size      => $self->{font_obj}->font_size,
		font_bold      => $self->{font_obj}->check_bold_text,
		plot_size      => $self->{font_obj}->plot_size,
		r_command      => $r_command,
		plotwin_name   => 'word_cls',
		data_number    => $check_num,
	);

	$w->end(no_dialog => 1);

	unless ( $self->{check_rm_open} ){
		$self->close;
	}

}

sub make_plot{
	my %args = @_;

	kh_r_plot->clear_env;

	my $fontsize = $args{font_size};
	my $r_command = $args{r_command};
	my $cluster_number = $args{cluster_number};

	my $old_simple_style = 0;
	if ( $args{cluster_color} == 0 ){
		$old_simple_style = 1;
	}

	my $bonus = 0;
	$bonus = 8 if $old_simple_style;

	if ($args{plot_size} =~ /auto/i){
		$args{plot_size} =
			int( ($args{data_number} * ( (20 + $bonus) * $fontsize) + 45) * 1 );
		if ($args{plot_size} < 480){
			$args{plot_size} = 480;
		}
		elsif ($args{plot_size} < 640){
			$args{plot_size} = 640;
		}
	}

	if ($cluster_number =~ /auto/i){
		$cluster_number = int( sqrt( $args{data_number} ) + 0.5)
	}

	my $par = 
		"par(
			mai=c(0,0,0,0),
			mar=c(1,2,1,0),
			omi=c(0,0,0,0),
			oma=c(0,0,0,0) 
		)\n"
	;

	$r_command .= "n_cls <- $cluster_number\n";
	$r_command .= "font_size <- $fontsize\n";
	
	$r_command .= "labels <- rownames(d)\n";
	$r_command .= "rownames(d) <- NULL\n";

	$r_command .= "freq <- NULL\n";
	$r_command .= "for (i in 1:nrow(d)) {\n";
	$r_command .= "	freq[i] = sum( d[i,] )\n";
	$r_command .= "}\n";

	if ($args{method_dist} eq 'euclid'){
		# 抽出語ごとに標準化
			# euclid係数を使う主旨からすると、標準化は不要とも考えられるが、
			# 標準化を行わないと連鎖の程度が激しくなり、クラスター分析として
			# の用をなさなくなる場合がまま見られる。
		$r_command .= "d <- t( scale( t(d) ) )\n";
	}
	$r_command .= "library(amap)\n";
	$r_command .= "dj <- Dist(d,method=\"$args{method_dist}\")\n";
	if ($args{method_dist} eq 'euclid'){
		$r_command .= "dj <- dj^2\n";
	}
	
	$r_command .= "try( library(flashClust) )\n";
	#$r_command .= "try( library(fastcluster) )\n";

	$r_command .=
		"$par"
		.'hcl <- hclust(dj, method="'.$args{method_mthd}.'")'."\n"
		.&r_command_plot($old_simple_style)
	;

	# プロット作成
	my $flg_error = 0;
	my $merges;
	
	my ($w,$h) = (480,$args{plot_size});
	($w,$h) = ($h,$w) if $old_simple_style;
	
	# Ward法
	my $plot1 = kh_r_plot->new(
		name      => $args{plotwin_name}.'_1',
		command_f => $r_command,
		width     => $w,
		height    => $h,
	) or $flg_error = 1;
	$plot1->rotate_cls if $old_simple_style;

	foreach my $i ('last','first','all'){
		$merges->{0}{$i} = kh_r_plot->new(
			name      => $args{plotwin_name}.'_1_'.$i,
			command_f =>  $r_command
			             ."pp_type <- \"$i\"\n"
			             .&r_command_height,
			command_a =>  "pp_type <- \"$i\"\n"
			             .&r_command_height,
			width     => 640,
			height    => 480,
		);
	}

	# プロットWindowを開く
	kh_r_plot->clear_env;
	my $plotwin_id = 'w_'.$args{plotwin_name}.'_plot';
	if ($::main_gui->if_opened($plotwin_id)){
		$::main_gui->get($plotwin_id)->close;
	}
	
	return 0 if $flg_error;
	
	my $plotwin = 'gui_window::r_plot::'.$args{plotwin_name};
	$plotwin->open(
		plots       => [$plot1],
		#no_geometry => 1,
		plot_size   => $args{plot_size},
		merges      => $merges,
	);

	return 1;
}

#--------------#
#   アクセサ   #


sub label{
	return kh_msg->get('win_title'); # 抽出語・クラスター分析：オプション
}

sub win_name{
	return 'w_word_som';
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

1;