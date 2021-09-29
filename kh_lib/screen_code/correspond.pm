package screen_code::correspond;
use strict;

use screen_code::plugin_path;

use gui_window;
use gui_window::word_corresp;
use gui_window::cod_corresp;
use File::Path;
use Encode qw/encode decode/;

my $radius;
my $angle;

my $default_calc_temp;
my $default_code_calc_temp;

sub add_menu{
	if (-f &screen_code::plugin_path::assistant_path) {
		my $self = shift;
		my $lf2 = shift;
		my $isCode = shift;
		if ($isCode) {
			unless ($default_code_calc_temp) {
				$default_code_calc_temp = \&gui_window::cod_corresp::_calc;
				*gui_window::cod_corresp::_calc = \&plug_code_calc;
			}
		} else {
			unless ($default_calc_temp) {
				$default_calc_temp = \&gui_window::word_corresp::calc;
				*gui_window::word_corresp::calc = \&plug_calc;
			}
		}
		my $radiSetting = $lf2->Frame()->pack(
			-fill => 'x',
			-pady => 2,
		);
		
		$radiSetting->Checkbutton(
			-text     => kh_msg->get('screen_code::assistant->use_plugin'),
			-variable => \$self->{use_plugin},
			-command  => sub{refresh_plugin($self);},
		)->pack(
			-anchor => 'w',
			-side  => 'left',
		);

		my $radiFrame = $lf2->Frame()->pack(
			-fill => 'x',
		);
		
		#padxに10程度を指定しインデントすることもできる
		$radiFrame->Label(
			-text => kh_msg->get('screen_code::assistant->corresp_rad'),
			-font => "TKFN",
		)->pack(-side => 'left');

		$radius = '20';
		$self->{plugin_rad} = gui_widget::optmenu->open(
			parent  => $radiFrame,
			pack    => {-side => 'left'},
			options =>
				[
					[kh_msg->get('screen_code::assistant->corresp_drop_menu1'), '10'],
					[kh_msg->get('screen_code::assistant->corresp_drop_menu2'), '15' ],
					[kh_msg->get('screen_code::assistant->corresp_drop_menu3'),'20'],
					[kh_msg->get('screen_code::assistant->corresp_drop_menu4'), '25' ],
					[kh_msg->get('screen_code::assistant->corresp_drop_menu5'),'30'],
				],
			variable => \$radius,
		);

		#my $angFrame = $lf2->Frame()->pack(
		#	-fill => 'x',
		#);
		
		$radiFrame->Label(
			-text => kh_msg->get('screen_code::assistant->corresp_ang'),
			-font => "TKFN",
		)->pack(-side => 'left');

		$angle = '30';
		$self->{plugin_ang} = gui_widget::optmenu->open(
			parent  => $radiFrame,
			pack    => {-side => 'left'},
			options =>
				[
					[kh_msg->get('screen_code::assistant->corresp_drop_menu1'), '5'],
					[kh_msg->get('screen_code::assistant->corresp_drop_menu2'), '15' ],
					[kh_msg->get('screen_code::assistant->corresp_drop_menu3'),'30'],
					[kh_msg->get('screen_code::assistant->corresp_drop_menu4'), '45' ],
					[kh_msg->get('screen_code::assistant->corresp_drop_menu5'),'60'],
				],
			variable => \$angle,
		);
		
		
		refresh_plugin($self);
	}
}

sub plug_calc{
	my $self = shift;
	if ($self->{use_plugin}) {
		&calc_plugin_loop($self,0);
	} else {
		$default_calc_temp->($self);
	}
}

sub plug_code_calc{
	my $self = shift;
	if ($self->{use_plugin}) {
		&calc_plugin_loop($self,1);
	} else {
		$default_code_calc_temp->($self);
	}
}

sub refresh_plugin{
	my $self = shift;
	if ( $self->{use_plugin} ){
		$self->{plugin_rad}->configure(-state => 'normal');
		$self->{plugin_ang}->configure(-state => 'normal');
	} else {
		$self->{plugin_rad}->configure(-state => 'disabled');
		$self->{plugin_ang}->configure(-state => 'disabled');
	}
	return $self;
}

sub text_henkan{
	if (-f &screen_code::plugin_path::assistant_path) {
		my $rcom_gray_ref = shift;
		my $rcom_gray_a_ref = shift;
		my $rcom_color_ref = shift;
		
		unless ($radius) {
			$radius = 0;
		}
		unless ($angle) {
			$angle = 0;
		}
		
		my $DATAFILE;
		my $file_rcom_gray = &screen_code::plugin_path::assistant_option_folder."rcom_gray.txt";
		unlink $file_rcom_gray if -f $file_rcom_gray;
		my $file_rcom_gray_a = &screen_code::plugin_path::assistant_option_folder."rcom_gray_a.txt";
		unlink $file_rcom_gray_a if -f $file_rcom_gray_a;
		my $file_rcom_color = &screen_code::plugin_path::assistant_option_folder."rcom_color.txt";
		unlink $file_rcom_color if -f $file_rcom_color;
		my $file_origin = &screen_code::plugin_path::assistant_option_folder."origin_list.txt";
		unlink $file_origin if -f $file_origin;
		my $file_outvar = &screen_code::plugin_path::assistant_option_folder."outvar_list.txt";
		unlink $file_outvar if -f $file_outvar;
		open($DATAFILE, ">>", $file_rcom_gray);
		print $DATAFILE encode('utf8',$$rcom_gray_ref);
		close($DATAFILE);
		open($DATAFILE, ">>", $file_rcom_gray_a);
		print $DATAFILE encode('utf8',$$rcom_gray_a_ref);
		close($DATAFILE);
		open($DATAFILE, ">>", $file_rcom_color);
		print $DATAFILE encode('utf8',$$rcom_color_ref);
		close($DATAFILE);
		
		system(&screen_code::plugin_path::assistant_path, "1", "$radius", "$angle");
		
		open($DATAFILE, "<:utf8", $file_rcom_gray);
		{
			# 読み込む際のレコードセパレータをundefにすると
			# ファイルのすべての内容を一度に読み取ることができます。
			local $/ = undef; 
			$$rcom_gray_ref = readline $DATAFILE;
		}
		open($DATAFILE, "<:utf8", $file_rcom_gray_a);
		{
			local $/ = undef; 
			$$rcom_gray_a_ref = readline $DATAFILE;
		}
		close($DATAFILE);
		open($DATAFILE, "<:utf8", $file_rcom_color);
		{
			local $/ = undef; 
			$$rcom_color_ref = readline $DATAFILE;
		}
		close($DATAFILE);
	}
}

sub calc_plugin_loop{
	my $self = shift;
	my $isCode = shift;
	
	#プラグインライセンス確認
	return 0 unless(system(&screen_code::plugin_path::assistant_path, 0));
	
	$self->{config_param} = undef;
	while(1) {
		my $rtn;
		if ($isCode) {
			$rtn = calc_code_plugin($self);
		} else {
			$rtn = calc_plugin($self);
		}
		if (!$rtn) {
			last;
		}
	}
}

sub calc_plugin{
	my $self = shift;
	
	# 入力のチェック
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('gui_window::word_corresp->select_pos'), # 品詞が1つも選択されていません。
		);
		return 0;
	}

	my $tani2 = '';
	my $vars;
	if ($self->{radio} == 0){
		$tani2 = $self->gui_jg($self->{high});
	}
	elsif ($self->{radio} == 1){
		foreach my $i ( $self->{opt_body_var}->selectionGet ){
			push @{$vars}, $self->{vars}[$i][1];
		}
		
		unless ( @{$vars} ){
			gui_errormsg->open(
				type => 'msg',
				msg  => kh_msg->get('gui_window::word_corresp->select_var'), # 外部変数を1つ以上選択してください。
			);
			return 0;
		}
		
		foreach my $i (@{$vars}){
			if ($tani2){
				unless (
					$tani2
					eq mysql_outvar::a_var->new(undef,$i)->{tani}
				){
					gui_errormsg->open(
						type => 'msg',
						msg  => kh_msg->get('gui_window::word_corresp->check_var_unit'), # 現在の所、集計単位が異なる外部変数を同時に使用することはできません。
					);
					return 0;
				}
			} else {
				$tani2 = mysql_outvar::a_var->new(undef,$i)
					->{tani};
			}
		}
	}

	my $rownames = 0;
	$rownames = 1 if ($self->{radio} == 0 and $self->{biplot} == 1);

	my $check_num = mysql_crossout::r_com->new(
		tani     => $self->tani,
		tani2    => $tani2,
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
			msg  => kh_msg->gget('select_3words'), # 少なくとも3つ以上の抽出語を布置して下さい。
		);
		return 0;
	}

	if ($check_num > 200){
		my $ans = $self->win_obj->messageBox(
			-message => $self->gui_jchar
				(
					kh_msg->get('gui_window::word_corresp->too_many1') # 現在の設定では
					.$check_num
					.kh_msg->get('gui_window::word_corresp->too_many2') # 語が布置されます。
					."\n"
					.kh_msg->get('gui_window::word_corresp->too_many3') # 布置する語の数は100〜150程度におさえることを推奨します。
					."\n"
					.kh_msg->get('gui_window::word_corresp->too_many4') # 続行してよろしいですか？
				),
			-icon    => 'question',
			-type    => 'OKCancel',
			-title   => 'KH Coder'
		);
		unless ($ans =~ /ok/i){ return 0; }
	}

	$self->_settings_save;

	my $w = gui_wait->start;

	# データの取り出し
	my $r_command = mysql_crossout::r_com->new(
		tani   => $self->tani,
		tani2  => $tani2,
		hinshi => $self->hinshi,
		max    => $self->max,
		min    => $self->min,
		max_df => $self->max_df,
		min_df => $self->min_df,
		rownames => $rownames,
	)->run;
	
	$r_command .= "v_count <- 0\n";
	$r_command .= "v_pch   <- NULL\n";

	# 外部変数の付与
	if ($self->{radio} == 1){
		
		my $n_v = 0;
		foreach my $i (@{$vars}){
			my $var_obj = mysql_outvar::a_var->new(undef,$i);
			
			my $sql = '';
			$sql .= "SELECT $var_obj->{column} FROM $var_obj->{table} ";
			$sql .= "ORDER BY id";
			
			$r_command .= "v$n_v <- c(";
			my $h = mysql_exec->select($sql,1)->hundle;
			my $n = 0;
			while (my $i = $h->fetch){
				$i->[0] = Encode::decode('utf8', $i->[0]) unless utf8::is_utf8($i->[0]);
				if ( length( $var_obj->{labels}{$i->[0]} ) ){
					my $t = $var_obj->{labels}{$i->[0]};
					$t =~ s/"/ /g;
					$r_command .= "\"$t\",";
				} else {
					$r_command .= "\"$i->[0]\",";
				}
				++$n;
			}
			
			chop $r_command;
			$r_command .= ")\n";
			++$n_v;
		}
		
		$r_command .= &r_command_aggr($n_v);
	}

	# 外部変数が無かった場合
	$r_command .= '
		if ( length(v_pch) == 0 ) {
			v_pch   <- 3
			v_count <- 1
		}
	';

	# 空の行・空の列を削除
	$r_command .=
		"if ( length(v_pch) > 1 ){ v_pch <- v_pch[rowSums(d) > 0] }\n";
	$r_command .=
		"doc_length_mtr <- subset(doc_length_mtr, rowSums(d) > 0)\n";
	$r_command .=
		"d              <- subset(d,              rowSums(d) > 0)\n";
	$r_command .= "n_total <- doc_length_mtr[,2]\n";
	$r_command .= "d <- t(d)\n";
	$r_command .= "d <- subset(d, rowSums(d) > 0)\n";
	$r_command .= "d <- t(d)\n";
	$r_command .= "# END: DATA\n";

	my $biplot = 1;
	$biplot = 0 if $self->{radio} == 0 and $self->{biplot} == 0;

	#my $filter = 0;
	#if ( $self->{check_filter} ){
	#	$filter = $self->gui_jgn( $self->{entry_flt}->get );
	#}
	
	#my $filter_w = 0;
	#if ( $self->{check_filter_w} ){
	#	$filter_w = $self->gui_jgn( $self->{entry_flw}->get );
	#}
	
	&set_config_param($self);
	
	#config_paramに設定項目をまとめているので、以下は呼び出す必要が無くなる
	#$self->{xy_obj}->params, flt => $filter, flw => $filter_w, 
	#font_size => $self->{font_obj}->font_size, font_bold => $self->{font_obj}->check_bold_text, plot_size => $self->{font_obj}->plot_size,
	#bubble       => $self->{bubble_obj}->check_bubble, bubble_size  => $self->{bubble_obj}->size, resize_vars  => $self->{bubble_obj}->chk_resize_vars, use_alpha    => $self->{bubble_obj}->alpha,
	my $plot = &make_plot_plugin(
		&get_config_param($self),
		biplot       => $biplot,
		r_command    => $r_command,
		std_radius   => $self->{bubble_obj}->chk_std_radius,
		bubble_var   => $self->{bubble_obj}->var,
		plotwin_name => 'word_corresp',
	);

	$w->end(no_dialog => 1);
	return 0 unless $plot;
	
	$self->{plots} = $plot->{result_plots};
	$self->{plot_file_names} = $plot->{plot_file_names};
	$self->{plot_number} = $plot->{plot_number};

	unless ( $self->{check_rm_open} ){
		$self->withd;
	}
	
	my $rtn = 0;
	while(1) {
		save_option($self,'word');
		save_config($self);
		$! = undef;
		$rtn = system(&screen_code::plugin_path::assistant_path, "2");
		$rtn = 0 if ($!) ; #systemでエラーがあった場合
		if (read_config($self)) {
			last;
		}
		if (!$rtn) {
			last;
		} else {
			if (read_option($self)) {
				save($self);
			} else {
				last;
			}
		}
	}
	return $rtn;
}

sub calc_code_plugin{
	my $self = shift;

	#if ( $self->{radio} == 1 ){
	#	if ( $self->tani eq $self->{high} ){
	#		# この場合は上位見出しを取得しない
	#		$self->{radio} = 0;
	#	}
	#}

	my @selected = ();
	foreach my $i (@{$self->{checks}}){
		push @selected, $i->{name} if $i->{check};
	}

	my $vars;
	if ($self->{radio} == 2){
		foreach my $i ( $self->{opt_body_var}->selectionGet ){
			push @{$vars}, $self->{vars}[$i][1];
		}
		
		unless ( @{$vars} ){
			gui_errormsg->open(
				type => 'msg',
				msg  => kh_msg->get('gui_window::word_corresp->select_var'), # 外部変数を1つ以上選択してください。
			);
			return 0;
		}
		
		my $tani2 = '';
		foreach my $i (@{$vars}){
			if ($tani2){
				unless (
					$tani2
					eq mysql_outvar::a_var->new(undef,$i)->{tani}
				){
					gui_errormsg->open(
						type => 'msg',
						msg  => kh_msg->get('gui_window::word_corresp->check_var_unit'), # '現在の所、集計単位が異なる外部変数を同時に使用することはできません。',
					);
					return 0;
				}
			} else {
				$tani2 = mysql_outvar::a_var->new(undef,$i)
					->{tani};
			}
		}
	}

	my $d_x = $self->{xy_obj}->x;
	my $d_y = $self->{xy_obj}->y;

	my $wait_window = gui_wait->start;

	# データ取得
	my $r_command = '';
	unless ( $r_command =  kh_cod::func->read_file($self->cfile)->out2r_selected($self->tani,\@selected) ){ # 修正！ 2010 12/24
		gui_errormsg->open(
			type   => 'msg',
			window  => \$self->win_obj,
			msg    => kh_msg->get('gui_window::cod_corresp->er_zero'), # 出現数が0のコードは利用できません。
		);
		#$self->close();
		$wait_window->end(no_dialog => 1);
		return 0;
	}

	# データ整形
	$r_command .= "\n";
	$r_command .= "d <- t(d)\n";
	$r_command .= "row.names(d) <- c(";
	foreach my $i (@{$self->{checks}}){
		my $name = $i->{name};
		substr($name, 0, 1) = '';
		$r_command .= '"'.$name.'",'
			if $i->{check}
		;
	}
	chop $r_command;
	$r_command .= ")\n";
	$r_command .= "d <- t(d)\n";
	
	# 上位見出しの付与
	if ($self->{radio} == 1){
		my $tani_low  = $self->tani;
		my $tani_high = $self->{high};
		
		unless ($tani_high){
			gui_errormsg->open(
				type   => 'msg',
				window  => \$self->win_obj,
				msg    => kh_msg->get('gui_window::cod_corresp->er_unit'), # 集計単位の選択が不正です。
			);
			return 0;
		}
		
		my $sql = '';
		if ($tani_low eq $tani_high){
			$sql .= "SELECT $tani_high.id\n";
			$sql .= "FROM $tani_high\n";
			$sql .= "ORDER BY $tani_high.id\n";
		} else {
			$sql .= "SELECT $tani_high.id\n";
			$sql .= "FROM $tani_high, $tani_low\n";
			$sql .= "WHERE\n";
			my $n = 0;
			foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
				$sql .= "AND " if $n;
				$sql .= "$tani_low.$i"."_id = $tani_high.$i"."_id\n";
				++$n;
				if ($i eq $tani_high){
					last;
				}
			}
			$sql .= "ORDER BY $tani_low.id\n";
		}
		
		
		my $max = mysql_exec->select("SELECT MAX(id) FROM $tani_high",1)
			->hundle->fetch->[0];
		my %names = ();
		my $n = 1;
		my $headings = "hn <- c(";
		while ($n <= $max){
			$names{$n} = mysql_getheader->get($tani_high, $n);

			if (length($names{$n})){
				$names{$n} =~ s/"/ /g;
				$headings .= "\"$names{$n}\",";
			}

			++$n;
		}
		chop $headings;

		$r_command .= "v <- c(";
		my $h = mysql_exec->select($sql,1)->hundle;
		while (my $i = $h->fetch){
			$r_command .= "$i->[0],";
		}
		chop $r_command;
		$r_command .= ")\n";

		$r_command .= &r_command_aggr_str;

		if ( length($headings) > 7 ){
			$headings .= ")\n";
			#print Jcode->new($headings)->sjis, "\n";
			$r_command .= $headings;
			$r_command .= "d <- as.matrix(d)\n";
			$r_command .= "rownames(d) <- hn[as.numeric( rownames(d) )]\n";
		}
	}

	# 外部変数の付与
	$r_command .= "v_count <- 0\n";
	$r_command .= "v_pch   <- NULL\n";
	if ($self->{radio} == 2){
		my $tani = $self->tani;
		
		my $n_v = 0;
		foreach my $i (@{$vars}){
			my $var_obj = mysql_outvar::a_var->new(undef,$i);
			my $sql = '';
			if ( $var_obj->{tani} eq $tani){
				$sql .= "SELECT $var_obj->{column} FROM $var_obj->{table} ";
				$sql .= "ORDER BY id";
			} else {
				$sql .= "SELECT $var_obj->{table}.$var_obj->{column}\n";
				
				$sql .= "FROM $tani\n";
				$sql .= "LEFT JOIN $var_obj->{tani} ON\n";
				my $n = 0;
				foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
					$sql .= "\t";
					$sql .= "and " if $n;
					$sql .= "$var_obj->{tani}.$i"."_id = $tani.$i"."_id\n";
					++$n;
					last if ($var_obj->{tani} eq $i);
				}
				$sql .= "LEFT JOIN $var_obj->{table} ON $var_obj->{tani}.id = $var_obj->{table}.id\n";
				
				#$sql .= "FROM $tani, $var_obj->{tani}, $var_obj->{table}\n";
				#$sql .= "WHERE\n";
				#$sql .= "	$var_obj->{tani}.id = $var_obj->{table}.id\n";
				#foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
				#	$sql .= "	and $var_obj->{tani}.$i"."_id = $tani.$i"."_id\n";
				#	last if ($var_obj->{tani} eq $i);
				#}
				
				$sql .= "ORDER BY $tani.id";
				#print "$sql\n";
			}
		
			$r_command .= "v$n_v <- c(";
			my $h = mysql_exec->select($sql,1)->hundle;
			my $n = 0;
			while (my $i = $h->fetch){
				if ( length( $var_obj->{labels}{$i->[0]} ) ){
					my $t = $var_obj->{labels}{$i->[0]};
					$t =~ s/"/ /g;
					$r_command .= "\"$t\",";
				} else {
					$r_command .= "\"$i->[0]\",";
				}
				++$n;
			}
			#print "num1: $n\n";
			chop $r_command;
			$r_command .= ")\n";
			++$n_v;
		}
		$r_command .= &r_command_aggr_var($n_v);
	}
	# 外部変数が無かった場合
	$r_command .= '
		if ( length(v_pch) == 0 ) {
			v_pch   <- 3
			v_count <- 1
		}
	';

	# 対応分析実行のためのRコマンド
	$r_command .=
		"if ( length(v_pch) > 1 ){ v_pch <- v_pch[rowSums(d) > 0] }\n";
	$r_command .= "d <- subset(d, rowSums(d) > 0)\n";
	$r_command .= "d <- t(d)\n";
	$r_command .= "d <- subset(d, rowSums(d) > 0)\n";
	$r_command .= "d <- t(d)\n";
	$r_command .= "# END: DATA\n";

	#my $filter = 0;
	#if ( $self->{check_filter} ){
	#	$filter = $self->gui_jgn( $self->{entry_flt}->get );
	#}

	#my $filter_w = 0;
	#if ( $self->{check_filter_w} && $self->{radio} != 0){
	#	$filter_w = $self->gui_jgn( $self->{entry_flw}->get );
	#}

	my $biplot = 1;
	if ($self->{radio} == 1){
		$biplot = $self->gui_jg( $self->{biplot} );
	}
	
	&set_config_param($self);

	#config_paramに設定項目をまとめているので、以下は呼び出す必要が無くなる
	#$self->{xy_obj}->params, flt => $filter, flw => $filter_w, 
	#font_size => $self->{font_obj}->font_size, font_bold => $self->{font_obj}->check_bold_text, plot_size => $self->{font_obj}->plot_size,
	#bubble       => $self->{bubble_obj}->check_bubble, bubble_size  => $self->{bubble_obj}->size, resize_vars  => $self->{bubble_obj}->chk_resize_vars, use_alpha    => $self->{bubble_obj}->alpha,
	my $plot = &make_plot_plugin(
		&get_config_param($self),
		biplot       => $biplot,
		r_command    => $r_command,
		std_radius   => $self->{bubble_obj}->chk_std_radius,
		bubble_var   => $self->{bubble_obj}->var,
		plotwin_name => 'cod_corresp',
	);

	$wait_window->end(no_dialog => 1);
	return 0 unless $plot;
	
	$self->{plots} = $plot->{result_plots};
	$self->{plot_file_names} = $plot->{plot_file_names};
	$self->{plot_number} = $plot->{plot_number};

	# 後処理
	#unless ( $self->{radio} ){
	#	$self->{radio} = 1;
	#}
	
	unless ( $self->{check_rm_open} ){
		$self->withd;
	}
	
	my $rtn = 0;
	
	while(1) {
		save_option($self,'cod');
		save_config($self);
		$! = undef;
		$rtn = system(&screen_code::plugin_path::assistant_path, "2");
		$rtn = 0 if ($!) ; #systemでエラーがあった場合
		if (read_config($self)) {
			last;
		}
		if (!$rtn) {
			last;
		} else {
			if (read_option($self)) {
				save($self);
			} else {
				last;
			}
		}
	}
	return $rtn;
}

sub make_plot_plugin{
	my %args = @_;
	$args{flt} = 0 unless $args{flt};
	$args{flw} = 0 unless $args{flw};

	my $x_factor = 1;
	if ( $args{bubble} == 1 ){
		$x_factor = 1.285;
	}
	$args{height} = $args{plot_size};
	$args{width}  = int( $args{plot_size} * $x_factor );
	
	my $fontsize = $args{font_size};
	my $r_command = $args{r_command};
	$args{use_alpha} = 0 unless ( length($args{use_alpha}) );

	$r_command = $r_command;

	kh_r_plot::corresp->clear_env;

	if ($args{font_bold} == 1){
		$args{font_bold} = 2;
	} else {
		$args{font_bold} = 1;
	}
	$r_command .= "text_font <- $args{font_bold}\n";
	$r_command .= "r_max <- 150\n";
	$r_command .= "zoom_factor <- $args{zoom}\n";
	$r_command .= "d_x <- $args{d_x}\n";
	$r_command .= "d_y <- $args{d_y}\n";
	$r_command .= "flt <- $args{flt}\n";
	$r_command .= "flw <- $args{flw}\n";
	$r_command .= "bubble_plot <- $args{bubble}\n";
	$r_command .= "biplot <- $args{biplot}\n";
	$r_command .= "cex=$fontsize\n";
	$r_command .= "use_alpha <- $args{use_alpha}\n";
	$r_command .= "show_origin <- $args{show_origin}\n";
	$r_command .= "scaling <- \"$args{scaling}\"\n";
	$r_command .= "
		if ( exists(\"saving_emf\") || exists(\"saving_eps\") ){
			use_alpha <- 0 
		}
	";

	$r_command .= "name_dim <- '".kh_msg->pget('gui_window::word_corresp->dim')."'\n"; # 成分
	$r_command .= "name_eig <- '".kh_msg->pget('gui_window::word_corresp->eig')."'\n"; # 固有値
	$r_command .= "name_exp <- '".kh_msg->pget('gui_window::word_corresp->exp')."'\n"; # 寄与率

	$r_command .= "library(MASS)\n";

	$r_command .= &r_command_filter;

	$r_command .= "k <- c\$cor^2\n";
	$r_command .=
		"txt <- cbind( 1:length(k), round(k,4), round(100*k / sum(k),2) )\n";
	$r_command .= "colnames(txt) <- c(name_dim,name_eig,name_exp)\n";
	$r_command .= "print( txt )\n";
	$r_command .= "inertias <- round(k,4)\n";
	$r_command .= "k <- round(100*k / sum(k),2)\n";
	
	# プロットのためのRコマンド	
	my ($r_command_3a, $r_command_3);
	my ($r_command_2a, $r_command_2);
	my ($r_com_gray, $r_com_gray_a);
	
	# 初期化
	$r_command .= "font_size <- $fontsize\n";
	$r_command .= "resize_vars <- $args{resize_vars}\n";
	$r_command .= "bubble_size <- $args{bubble_size}\n";
	$r_command .= "labcd <- NULL\n\n";
	my $common = $r_command;
	
	# ドットのみ
	$r_command .= "plot_mode <- \"color\"\n";
	$r_command .= &r_command_bubble(%args);

	# カラー
	$r_command_2a .= "plot_mode <- \"dots\"\n";
	$r_command_2a .= &r_command_bubble(%args);
	$r_command_2  = $common.$r_command_2a;

	if ($args{biplot}){
		# 変数のみ
		$r_command_3a .= "plot_mode <- \"vars\"\n";
		$r_command_3a .= &r_command_bubble(%args);
		$r_command_3  = $common.$r_command_3a;
		
		# グレースケール
		$r_com_gray_a .= "plot_mode <- \"gray\"\n";
		$r_com_gray_a .= &r_command_bubble(%args);
		$r_com_gray = $common.$r_com_gray_a;
	}
	
	text_henkan(\$r_com_gray, \$r_com_gray_a, \$r_command);
	
	# プロット作成
	my $plot1 = kh_r_plot::corresp->new(
		name      => $args{plotwin_name}.'_1',
		command_f => $r_command,
		width     => int( $args{plot_size} * $x_factor ),
		height    => $args{plot_size},
		font_size => $args{font_size},
	) or return 0;

	my $plot2 = kh_r_plot::corresp->new(
		name      => $args{plotwin_name}.'_2',
		command_a => $r_command_2a,
		command_f => $r_command_2,
		width     => int( $args{plot_size} * $x_factor ),
		height    => $args{plot_size},
		font_size => $args{font_size},
	) or return 0;

	my ($plotg, $plotv);
	my @plots = ();
	my $plot_file_names;
	my $plot_number;
	if ($r_com_gray_a){
		$plotg = kh_r_plot::corresp->new(
			name      => $args{plotwin_name}.'_g',
			command_a => $r_com_gray_a,
			command_f => $r_com_gray,
			width     => int( $args{plot_size} * $x_factor ),
			height    => $args{plot_size},
			font_size => $args{font_size},
		) or return 0;
		
		$plotv = kh_r_plot::corresp->new(
			name      => $args{plotwin_name}.'_v',
			command_a => $r_command_3a,
			command_f => $r_command_3,
			width     => int( $args{plot_size} * $x_factor ),
			height    => $args{plot_size},
			font_size => $args{font_size},
		) or return 0;
		@plots = ($plot1,$plotg,$plotv,$plot2);
		$plot_file_names = "1,g,v,2";
		$plot_number = "0,1,2,3";
	} else {
		@plots = ($plot1,$plot2);
		$plot_file_names = "1,2";
		$plot_number = "0,1";
	}

	my $txt = $plot1->r_msg;
	if ( length($txt) ){
		print "-------------------------[Begin]-------------------------[R]\n";
		print "$txt\n";
		print "---------------------------------------------------------[R]\n";
	}

	#ここから下はKWICコンコーダンス呼び出し用の処理
	#処理が変更されたため、返り値もplot配列を含むデータをハッシュで持った変数になっている
	
	# write coordinates to a file
	my $csv = $::project_obj->file_TempCSV;
	$::config_obj->R->send("
		write.table(out_coord, file=\"".$::config_obj->uni_path($csv)."\", fileEncoding=\"UTF-8\", sep=\"\\t\", quote=F, col.names=F)\n
	");

	# get XY ratio
	$::config_obj->R->send("
		if (asp == 1){
			ratio = ( xlimv[2] - xlimv[1] ) / ( ylimv[2] - ylimv[1] )
		} else {
			ratio = 0
		}
		print( paste0('<ratio>', ratio ,'</ratio>') )
	");
	my $ratio = $::config_obj->R->read;
	if ( $ratio =~ /<ratio>(.+)<\/ratio>/) {
		$ratio = $1;
	}

	kh_r_plot::corresp->clear_env;

	my $plotR;
	$plotR->{result_plots} = \@plots,
	#coord にはcsvファイルのパス、ratioには画像のプロット範囲のX軸とY軸の長さの比率(どちらも同じ正方形の場合は0としている)
	#gui_window::r_plot::word_corresp にある renew_command (画像表示関数) でウィンドウのボタンを作成し、以下のコマンドを登録している
	#gui_window::r_plot KWICを呼び出しなどのコマンドがある
	$plotR->{coord} = $csv;
	$plotR->{ratio} = $ratio;
	$plotR->{plot_file_names} = $plot_file_names;
	$plotR->{plot_number} = $plot_number;

	return $plotR;
}

sub save{
	my $self = shift;

	my $path = $self->{path_o};
	my $plotnum = $self->{plot_o};

	$path = $::config_obj->os_path($path);
	$self->{plots}[$plotnum+0]->save($path) if $path;
	return 1;
}

sub read_option{
	my $self = shift;
	my $file_option = &screen_code::plugin_path::assistant_option_folder."option.txt";
	$self->{mode_o} = undef;
	if (-f $file_option) {
		open(my $IN, "<:encoding(utf8)", $file_option);
		my $path = undef;
		my $plotnum = undef;
		while (my $line = <$IN>) {
			my @splited = split(/=/, $line);
			my $temp = $splited[1];
			chomp($temp);
			if ($splited[0] eq "mode") {
				$self->{mode_o} = $temp;
			} elsif ($splited[0] eq "path") {
				$self->{path_o} = $temp;
			} elsif ($splited[0] eq "plot") {
				$self->{plot_o} = $temp;
			}
		}
		
		close($IN);
		unlink $file_option if -f $file_option;
		return (defined($self->{mode_o}));
	} else {
		return 0;
	}
}

sub save_option{
	my $self = shift;
	my $type = shift;
	my $file_option = &screen_code::plugin_path::assistant_option_folder."option.txt";
	unlink $file_option if -f $file_option;
	open(my $OUT, ">:encoding(utf8)", $file_option);
	my $dbn = $::project_obj->dbname;
	my $plot_file_names = $self->{plot_file_names};
	my $plot_number = $self->{plot_number};
	#プラグインの処理変更により必要なくなるかもしれない
	my $initial_display = $self->{plot_o};
	my $font_str = gui_window->gui_jchar($::config_obj->font_main);
	print $OUT "db_name=$dbn\n";
	print $OUT "type=$type\n";
	print $OUT "plot_file_names=$plot_file_names\n";
	print $OUT "plot_number=$plot_number\n";
	print $OUT "initial_display=$initial_display\n";
	print $OUT "font=$font_str\n";
	
	close($OUT);
}


sub read_config{
	my $self = shift;
	my $file_config = &screen_code::plugin_path::assistant_option_folder."config.txt";
	
	if (-f $file_config) {
		open(my $IN, "<:encoding(utf8)", $file_config);
		my $isChanged = 0;
		while (my $line = <$IN>) {
			my @splited = split(/=/, $line);
			my $temp = $splited[1];
			chomp($temp);
			if ($splited[0] eq "d_x") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{d_x});
				$self->{config_param}->{d_x} = $temp;
			} elsif ($splited[0] eq "d_y") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{d_y});
				$self->{config_param}->{d_y} = $temp;
			} elsif ($splited[0] eq "show_origin") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{show_origin});
				$self->{config_param}->{show_origin} = $temp;
			} elsif ($splited[0] eq "scaling") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{scaling});
				$self->{config_param}->{scaling} = $temp;
			} elsif ($splited[0] eq "check_zoom") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{check_zoom});
				$self->{config_param}->{check_zoom} = $temp;
			} elsif ($splited[0] eq "zoom") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{zoom});
				$self->{config_param}->{zoom} = $temp;
			} elsif ($splited[0] eq "check_filter") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{check_filter});
				$self->{config_param}->{check_filter} = $temp;
			} elsif ($splited[0] eq "filter") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{filter});
				$self->{config_param}->{filter} = $temp;
			} elsif ($splited[0] eq "check_filter_w") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{check_filter_w});
				$self->{config_param}->{check_filter_w} = $temp;
			} elsif ($splited[0] eq "filter_w") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{filter_w});
				$self->{config_param}->{filter_w} = $temp;
			} elsif ($splited[0] eq "bubble") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{bubble});
				$self->{config_param}->{bubble} = $temp;
			} elsif ($splited[0] eq "bubble_size") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{bubble_size});
				$self->{config_param}->{bubble_size} = $temp;
			} elsif ($splited[0] eq "resize_vars") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{resize_vars});
				#$self->{config_param}->{bubble_var} = $temp;
				$self->{config_param}->{resize_vars} = $temp;
			} elsif ($splited[0] eq "use_alpha") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{use_alpha});
				$self->{config_param}->{use_alpha} = $temp;
			} elsif ($splited[0] eq "font_size") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{font_size});
				$self->{config_param}->{font_size} = $temp;
			} elsif ($splited[0] eq "plot_size") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{plot_size});
				$self->{config_param}->{plot_size} = $temp;
			} elsif ($splited[0] eq "font_bold") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{font_bold});
				$self->{config_param}->{font_bold} = $temp;
			} elsif ($splited[0] eq "radius") {
				$isChanged = 1 if ($temp ne $radius);
				$radius = $temp;
			} elsif ($splited[0] eq "angle") {
				$isChanged = 1 if ($temp ne $angle);
				$angle = $temp;
			}
		}
		
		close($IN);
		unlink $file_config if -f $file_config;
		return ($isChanged);
	} else {
		return 0;
	}
}

sub save_config{
	my $self = shift;
	my $file_config = &screen_code::plugin_path::assistant_option_folder."config.txt";
	unlink $file_config if -f $file_config;
	open(my $OUT, ">:encoding(utf8)", $file_config);
	
	print $OUT "d_x=".$self->{config_param}->{d_x}."\n";
	print $OUT "d_y=".$self->{config_param}->{d_y}."\n";
	print $OUT "show_origin=".$self->{config_param}->{show_origin}."\n";
	print $OUT "scaling=".$self->{config_param}->{scaling}."\n";
	print $OUT "check_zoom=".$self->{config_param}->{check_zoom}."\n";
	print $OUT "zoom=".$self->{config_param}->{zoom}."\n";
	print $OUT "check_filter=".$self->{config_param}->{check_filter}."\n";
	print $OUT "filter=".$self->{config_param}->{filter}."\n";
	print $OUT "check_filter_w=".$self->{config_param}->{check_filter_w}."\n";
	print $OUT "filter_w=".$self->{config_param}->{filter_w}."\n";
	print $OUT "bubble=".$self->{config_param}->{bubble}."\n";
	print $OUT "bubble_size=".$self->{config_param}->{bubble_size}."\n";
	print $OUT "resize_vars=".$self->{config_param}->{resize_vars}."\n";
	print $OUT "use_alpha=".$self->{config_param}->{use_alpha}."\n";
	print $OUT "font_size=".$self->{config_param}->{font_size}."\n";
	print $OUT "plot_size=".$self->{config_param}->{plot_size}."\n";
	print $OUT "font_bold=".$self->{config_param}->{font_bold}."\n";
	print $OUT "radius=".$radius."\n";
	print $OUT "angle=".$angle."\n";
	
	close($OUT);
}

sub set_config_param{
	my $self = shift;
	if (!defined($self->{config_param})) {
		$self->{config_param} = {
			'd_x'            => $self->{xy_obj}->x,
			'd_y'            => $self->{xy_obj}->y,
			'show_origin'    => $self->{xy_obj}->origin,
			'scaling'        => $self->{xy_obj}->scale,
			'check_zoom'     => $self->{xy_obj}->{check_zoom},
			'zoom'           => 3,
			'check_filter'   => $self->{check_filter},
			'filter'         => $self->gui_jgn( $self->{entry_flt}->get),
			'check_filter_w' => $self->{check_filter_w},
			'filter_w'       => $self->gui_jgn( $self->{entry_flw}->get),
			'bubble'         => $self->{bubble_obj}->check_bubble,
			'bubble_size'    => $self->{bubble_obj}->size,
			'resize_vars'    => $self->{bubble_obj}->chk_resize_vars,
			'use_alpha'      => $self->{bubble_obj}->alpha,
			'font_size'      => $self->{font_obj}->font_size,
			'plot_size'      => $self->{font_obj}->plot_size,
			'font_bold'      => $self->{font_obj}->check_bold_text,
		};
	}
}

sub get_config_param{
	my $self = shift;
	my $zoom = $self->{config_param}->{zoom};
	if (!$self->{config_param}->{check_zoom}) {$zoom = 0;}
	my $filter = $self->{config_param}->{filter};
	if (!$self->{config_param}->{check_filter}){$filter = 0;}
	my $filter_w = $self->{config_param}->{filter_w};
	if (!$self->{config_param}->{check_filter_w}){$filter_w = 0;}
	return (
			'd_x'            => $self->{config_param}->{d_x},
			'd_y'            => $self->{config_param}->{d_y},
			'show_origin'    => $self->{config_param}->{show_origin},
			'scaling'        => $self->{config_param}->{scaling},
			#'check_zoom'     => $self->{config_param}->{check_zoom},
			'zoom'           => $zoom,
			#'check_filter'   => $self->{config_param}->{check_filter},
			'flt'            => $filter,
			#'check_filter_w' => $self->{config_param}->{check_filter_w},
			'flw'            => $filter_w,
			'bubble'         => $self->{config_param}->{bubble},
			'bubble_size'    => $self->{config_param}->{bubble_size},
			'resize_vars'    => $self->{config_param}->{resize_vars},
			'use_alpha'      => $self->{config_param}->{use_alpha},
			'font_size'      => $self->{config_param}->{font_size},
			'plot_size'      => $self->{config_param}->{plot_size},
			'font_bold'      => $self->{config_param}->{font_bold},
		);
}


sub r_command_aggr{
	my $n_v = shift;
	my $t =
		"name_nav <- '"
		.kh_msg->pget('nav')
		."'\n"; # 欠損値
	$t .= << 'END_OF_the_R_COMMAND';

aggregate_with_var <- function(d, doc_length_mtr, v) {
	d              <- aggregate(d,list(name = v), sum)
	doc_length_mtr <- aggregate(doc_length_mtr,list(name = v), sum)

	row.names(d) <- d$name
	d$name <- NULL
	row.names(doc_length_mtr) <- doc_length_mtr$name
	doc_length_mtr$name <- NULL

	d              <- d[              order(rownames(d             )), ]
	doc_length_mtr <- doc_length_mtr[ order(rownames(doc_length_mtr)), ]

	doc_length_mtr <- subset(
		doc_length_mtr,
		row.names(d) != name_nav & row.names(d) != "." & regexpr("^missing$", row.names(d), ignore.case = T, perl = T) == -1
	)
	d <- subset(
		d,
		row.names(d) != name_nav & row.names(d) != "." & regexpr("^missing$", row.names(d), ignore.case = T, perl = T) == -1
	)

	# doc_length_mtr <- subset(doc_length_mtr, rowSums(d) > 0)
	# d              <- subset(d,              rowSums(d) > 0)

	return( list(d, doc_length_mtr) )
}

dd <- NULL
nn <- NULL

END_OF_the_R_COMMAND

	$t .= "for (i in list(";
	for (my $i = 0; $i < $n_v; ++$i){
		$t .= "v$i,";
	}
	chop $t;
	$t .= ")){\n";

	$t .= << 'END_OF_the_R_COMMAND2';

	cur <- aggregate_with_var(d, doc_length_mtr, i)
	dd <- rbind(dd, cur[[1]])
	nn <- rbind(nn, cur[[2]])
	v_count <- v_count + 1
	v_pch <- c( v_pch, rep(v_count + 2, nrow(cur[[1]]) ) )
}

d              <- dd
doc_length_mtr <- nn

END_OF_the_R_COMMAND2

	return $t;
}

sub r_command_filter{
	my $t = << 'END_OF_the_R_COMMAND';

# Filter words by chi-square value
if ( (flw > 0) && (flw < ncol(d)) ){
	sort  <- NULL
	for (i in 1:ncol(d) ){
		# print( paste(colnames(d)[i], chisq.test( cbind(d[,i], n_total - d[,i]) )$statistic) )
		sort <- c(
			sort, 
			chisq.test( cbind(d[,i], n_total - d[,i]) )$statistic
		)
	}
	d <- d[,order(sort,decreasing=T)]
	d <- d[,1:flw]
	
	d <- subset(d, rowSums(d) > 0)
	if (exists("doc_length_mtr")){
		doc_length_mtr <- subset(doc_length_mtr, rowSums(d) > 0)
		n_total <- doc_length_mtr[,2]
	}
}

d_max <- min( nrow(d), ncol(d) ) - 1
if (d_x > d_max){
	d_x <- d_max
}
if (d_y > d_max){
	d_y <- d_max
}

c <- corresp(d, nf=d_max )

if (d_max == 1){
	c$cscore <- as.matrix( c$cscore )
	c$rscore <- as.matrix( c$rscore )
	colnames(c$cscore) <- c("X1")
	colnames(c$rscore) <- c("X1")
}

# Dilplay Labels only for distinctive words
if ( (flt > 0) && (flt < nrow(c$cscore)) ){
	sort  <- NULL
	limit <- NULL
	names <- NULL
	ptype <- NULL
	
	# compute distance from (0,0)
	for (i in 1:nrow(c$cscore) ){
		sort <- c(sort, c$cscore[i,d_x] ^ 2 + c$cscore[i,d_y] ^ 2 )
	}
	
	# Put labels to top words
	limit <- sort[order(sort,decreasing=T)][flt]
	for (i in 1:nrow(c$cscore) ){
		if ( sort[i] >= limit ){
			names <- c(names, rownames(c$cscore)[i])
			ptype <- c(ptype, 1)
		} else {
			names <- c(names, NA)
			ptype <- c(ptype, 2)
		}
	}
	rownames(c$cscore) <- names;
} else {
	ptype <- 1
}

pch_cex <- 1
if ( v_count > 1 ){
	pch_cex <- 1.25
}

# Zooming area near the origin

log_conv <- function(x, y, a){
	log_base <- 10
	
	# Find Cosine theta
	OA  <- sqrt( x^2 + y^2 )
	OA[OA == 0] <- 0.00000000000000000001
	Cos <- x / OA
	
	# Convert OA
	OA <- log(OA + 1, log_base)
	OA <- OA * a
	OA <- log(OA + 1, log_base)
	OA <- OA * a
	OA <- log(OA + 1, log_base)

	# Find OB
	OB <- Cos * OA
	
	# Find AB
	AB = sqrt( OA^2 - OB^2 )
	AB[y < 0] <- AB[y < 0] * -1
	
	cbind(OB, AB)
}

axp <- NULL
#screen plugin range#
if (zoom_factor >= 1 ){
	scaling <- "none"
	axp <- c(0,0,1)

	r <- log_conv( c$cscore[,d_x], c$cscore[,d_y], zoom_factor )
	c$cscore[,d_x] <- r[,1]
	c$cscore[,d_y] <- r[,2]

	r <- log_conv( c$rscore[,d_x], c$rscore[,d_y], zoom_factor )
	c$rscore[,d_x] <- r[,1]
	c$rscore[,d_y] <- r[,2]
}

# Scaling
asp <- 0
if (scaling == "sym"){
	for (i in 1:d_max){
		c$cscore[,i] <- c$cscore[,i] * c$cor[i]
		c$rscore[,i] <- c$rscore[,i] * c$cor[i]
	}
	asp <- 1
} else if (scaling == "symbi"){
	for (i in 1:d_max){
		c$cscore[,i] <- c$cscore[,i] * sqrt( c$cor[i] )
		c$rscore[,i] <- c$rscore[,i] * sqrt( c$cor[i] )
	}
	asp <- 1
}


END_OF_the_R_COMMAND
return $t;
}

sub r_command_bubble{
	my %args = @_;
	return '

library(ggplot2)

font_family <- "'.$::config_obj->font_plot_current.'"

if ( exists("PERL_font_family") ){
	font_family <- PERL_font_family
}

#unuse font_size 210638
#if ( exists("bs_fixed") == F ) {
#	bubble_size <- bubble_size / '.$args{font_size}.'
#	bs_fixed <- 1
#}

#-----------------------------------------------------------------------------#
#                           prepare label positions
#-----------------------------------------------------------------------------#

# compute label positions
if (biplot == 1 && plot_mode != "vars"){
	cb <- rbind(
		cbind(c$cscore[,d_x], c$cscore[,d_y], ptype),
		cbind(c$rscore[,d_x], c$rscore[,d_y], v_pch)
	)
} else if (plot_mode == "vars") {
	cb <- cbind(c$rscore[,d_x], c$rscore[,d_y], v_pch)
} else {
	cb <- cbind(c$cscore[,d_x], c$cscore[,d_y], ptype)
}

if ( (is.null(labcd) && plot_mode != "dots" ) || plot_mode == "vars"){

	png_width  <- '.$args{width}.'
	png_height <- '.$args{height}.' 
	png_width  <- png_width - 0.16 * bubble_size / 100 * png_width
	dpi <- 72 * min(png_width, png_height) / 640
	p_size <- 12 * dpi / 72;
	png("temp.png", width=png_width, height=png_height, unit="px", pointsize=p_size)
	

	#if ( exists("PERL_font_family") ){
	#	par(family=PERL_font_family) 
	#}

	plot(
		x=c(c$cscore[,d_x],c$rscore[,d_x]),
		y=c(c$cscore[,d_y],c$rscore[,d_y]),
		asp=asp
	)

	library(maptools)
	labcd <- pointLabel(
		x=cb[,1],
		y=cb[,2],
		labels=rownames(cb),
		cex=font_size,
		offset=0,
		doPlot=F
	)

	xorg <- cb[,1]
	yorg <- cb[,2]
	#cex  <- 1

	n_words_chk <- c( length(c$cscore[,d_x]) )
	if (flt > 0) {
		n_words_chk <- c(n_words_chk, flt)
	}
	if (flw > 0) {
		n_words_chk <- c(n_words_chk, flw)
	}
	if ( 
		   ( (biplot == 0) && (min(n_words_chk) < 300) )
		|| (
			   (biplot == 1)
			&& ( min(n_words_chk) < 300 )
			&& ( length(c$rscore[,d_x]) < r_max )
		)
	){

		library(wordcloud)
		'.&plotR::network::r_command_wordlayout.'

		cex <- font_size * 1.05
		if (font_size > 1){
			cex <- cex + (font_size - 1) * 1.05
		}
		nc <- wordlayout(
			labcd$x,
			labcd$y,
			rownames(cb),
			cex=cex * 1.05,
			xlim=c(  par( "usr" )[1], par( "usr" )[2] ),
			ylim=c(  par( "usr" )[3], par( "usr" )[4] )
		)

		xlen <- par("usr")[2] - par("usr")[1]
		ylen <- par("usr")[4] - par("usr")[3]

		segs <- NULL
		for (i in 1:length( rownames(cb) ) ){
			x <- ( nc[i,1] + .5 * nc[i,3] - labcd$x[i] ) / xlen
			y <- ( nc[i,2] + .5 * nc[i,4] - labcd$y[i] ) / ylen
			dst <- sqrt( x^2 + y^2 )
			if ( dst > 0.05 ){
				segs <- rbind(
					segs,
					c(
						nc[i,1] + .5 * nc[i,3], nc[i,2] + .5 * nc[i,4],
						xorg[i], yorg[i]
					) 
				)
			}
		}

		xorg <- labcd$x
		yorg <- labcd$y
		labcd$x <- nc[,1] + .5 * nc[,3]
		labcd$y <- nc[,2] + .5 * nc[,4]
	}
	
	text(labcd$x, labcd$y, rownames(cb))
	dev.off()
}


#-----------------------------------------------------------------------------#
#                              start plotting
#-----------------------------------------------------------------------------#

#-----------#
#   Words   #

b_size <- NULL
for (i in rownames(c$cscore)){
	if ( is.na(i) || is.null(i) || is.nan(i) ){
		b_size <- c( b_size, 1 )
	} else {
		b_size <- c( b_size, sum( d[,i] ) )
	}
}

col_bg_words <- NA
col_bg_vars  <- NA

if (plot_mode == "color"){
	col_dot_words <- "#00CED1"
	col_dot_vars  <- "#FF6347"
	if ( use_alpha == 1 ){
		col_bg_words <- "#48D1CC"
		col_bg_vars  <- "#FFA07A"
		
		rgb <- col2rgb(col_bg_words) / 255
		col_bg_words <- rgb( rgb[1], rgb[2], rgb[3])
		
		rgb <- rgb * 0.5
		col_dot_words <- "#87CAC6" #  <- rgb( rgb[1], rgb[2], rgb[3])
		
		rgb <- col2rgb(col_bg_vars) / 255
		col_bg_vars <- rgb( rgb[1], rgb[2], rgb[3])
	}
}

if (plot_mode == "gray"){
	col_dot_words <- "gray55"
	col_dot_vars  <- "gray30"
}

if (plot_mode == "vars"){
	col_dot_words <- "#ADD8E6"
	col_dot_vars  <- "red"
}

if (plot_mode == "dots"){
	col_dot_words <- "black"
	col_dot_vars  <- "black"
}

g <- ggplot()

df.words <- data.frame(
	x    = c$cscore[,d_x],
	y    = c$cscore[,d_y],
	size = b_size,
	type = ptype
)

df.words.sub <- subset(df.words, type==2)
df.words     <- subset(df.words, type==1)

if (bubble_plot == 1){
	g <- g + geom_point(
		data=df.words,
		aes(x=x, y=y, size=size),
		shape=21,
		#colour = NA,
		fill = col_bg_words,
		alpha=0.15
	)
	
	g <- g + geom_point(
		data=df.words,
		aes(x=x, y=y, size=size),
		shape=21,
		colour = col_dot_words,
		fill = NA,
		alpha=1,
		show.legend = F
	)
	
	g <- g + scale_size_area(
		max_size= 30 * bubble_size / 100,
		guide = guide_legend(
			title = "Frequency:",
			override.aes = list(colour="black", fill=NA, alpha=1),
			label.hjust = 1,
			order = 2
		)
	)
} else {
	g <- g + geom_point(
		data=df.words,
		aes(x=x, y=y),
		size = 2,
		shape=16,
		colour = col_dot_words,
		alpha=1,
		show.legend = F
	)
}

if ( nrow(df.words.sub) > 0 ){
	g <- g + geom_point(
		data=df.words.sub,
		aes(x=x, y=y),
		shape=19,
		size=2,
		colour = "#ADD8E6",
		alpha=1,
		show.legend = F
	)
}

#---------------#
#   Variables   #

if ( biplot == 1 ){
	df.vars <- data.frame(
		x    = c$rscore[,d_x],
		y    = c$rscore[,d_y],
		size = n_total * max(b_size) / max(n_total) * 0.6,
		type = v_pch
	)

	if ( (resize_vars == 1) && (bubble_plot == 1) ) {
		g <- g + geom_point(
			data=df.vars,
			aes(x=x, y=y, size=size, shape=factor(type) ),
			#colour = NA,
			fill = col_bg_vars,
			alpha=0.2,
			show.legend = F
		)

		g <- g + geom_point(
			data=df.vars,
			aes(x=x, y=y, size=size, shape=factor(type) ),
			colour = col_dot_vars,
			fill = NA,
			alpha=1,
			show.legend = F
		)
	} else {
		g <- g + geom_point(
			data=df.vars,
			aes(x=x, y=y, shape=factor(type) ),
			colour = NA,
			fill = col_bg_vars,
			alpha=0.2,
			size=3.5,
			show.legend = F
		)

		g <- g + geom_point(
			data=df.vars,
			aes(x=x, y=y, shape=factor(type) ),
			colour = col_dot_vars,
			fill = NA,
			alpha=1,
			size=3.5,
			show.legend = F
		)
	}

	g <- g + scale_shape_manual(
		values = c(22:25,0-6)
	)
}

#------------#
#   Labels   #

# label colors
if (plot_mode == "color"){
	#if (bubble_plot == 1){
		col_txt_words <- "black"
		col_txt_vars  <- "#DC143C"
	#} else {
	#	col_txt_words <- "black"
	#	col_txt_vars  <- "#FF6347"
	#}
}

if (plot_mode == "gray"){
	col_txt_words <- "black"
	col_txt_vars  <- "black"
}

if (plot_mode == "vars"){
	col_txt_words <- "black"
	col_txt_vars  <- "black"
}

if (plot_mode == "dots"){
	col_txt_words <- NA
	col_txt_vars  <- NA
}

if ( text_font == 1 ){
	font_face <- "plain"
} else {
	font_face <- "bold"
}

if ( exists("df.labels.save ") == F ){
	df.labels.save <- data.frame(
		x    = labcd$x,
		y    = labcd$y,
		labs = rownames(cb),
		cols = cb[,3]
	)
}

if (plot_mode != "dots") {
	df.labels <- data.frame(
		x    = labcd$x,
		y    = labcd$y,
		labs = rownames(cb),
		cols = cb[,3]
	)
	if ( plot_mode == "gray" ){
		df.labels.var  <- subset(df.labels, cols == 3)
		df.labels <- subset(df.labels, cols != 3)
		g <- g + geom_label(
			data=df.labels.var,
			family=font_family,
			fontface="bold",
			label.size=0.25 * font_size,
			size=4 * font_size,
			label.padding=unit(1.8 * font_size, "mm"),
			colour="white",
			fill="gray50",
			#alpha=0.7,
			aes(x=x, y=y,label=labs)
		)
		if ( (resize_vars == 0) || (bubble_plot == 0) ) {
			g <- g + geom_point(
				data=df.vars,
				aes(x=x, y=y, shape=factor(type) ),
				colour = col_dot_vars,
				fill = NA,
				alpha=1,
				size=3.5,
				show.legend = F
			)
		}
	}
	
	g <- g + geom_text(
		data=df.labels,
		aes(x=x, y=y,label=labs,colour=factor(cols)),
		size=4 * font_size,
		family=font_family,
		fontface=font_face
		#colour="black"
	)
	
	#label_legend <- guide_legend(
	#	title = "Labels:",
	#	key.theme   = element_rect(colour = "gray30"),
	#	override.aes = list(size=5),
	#	order = 1
	#)
	label_legend <- "none"
	
	g <- g + scale_color_manual(
		values = c(col_txt_words, col_txt_vars, col_txt_vars),
		breaks = c(1,3),
		labels = c("Words / Codes", "Variables"),
		guide = label_legend
	)

	
	
	if ( exists("segs") ){
		if ( is.null(segs) == F){
			colnames(segs) <- c("x1", "y1", "x2", "y2")
			segs <- as.data.frame(segs)
			g <- g + geom_segment(
				aes(x=x1, y=y1, xend=x2, yend=y2),
				data=segs,
				colour="gray60"
			)
		}
	}
}

if (plot_mode == "vars"){
	labcd <- NULL
}

#--------------------#
#   Configurations   #

#if ( asp == 1 ){
#	g <- g + coord_fixed()
#}

g <- g + labs(
	x=paste(name_dim,d_x,"  (",inertias[d_x],",  ", k[d_x],"%)",sep=""),
	y=paste(name_dim,d_y,"  (",inertias[d_y],",  ", k[d_y],"%)",sep="")
)
g <- g + theme_classic(base_family=font_family)
g <- g + theme(
	legend.key   = element_rect(colour = NA, fill= NA),
	axis.line.x    = element_line(colour = "black", size=0.5),
	axis.line.y    = element_line(colour = "black", size=0.5),
	axis.title.x = element_text(face="plain", size=11, angle=0),
	axis.title.y = element_text(face="plain", size=11, angle=90),
	axis.text.x  = element_text(face="plain", size=11, angle=0),
	axis.text.y  = element_text(face="plain", size=11, angle=0),
	legend.title = element_text(face="bold",  size=11, angle=0),
	legend.text  = element_text(face="plain", size=11, angle=0)
)

#---------------------#
#   show the origin   #

if (show_origin == 1){
	line_color <- "gray30"
	
	lim_chk <-ggplot_build(g)
	xlims <- lim_chk$panel$ranges[[1]]$x.range
	ylims <- lim_chk$panel$ranges[[1]]$y.range
	if ( is.null(xlims) ){
		xlims <- lim_chk$layout$panel_ranges[[1]]$x.range
		ylims <- lim_chk$layout$panel_ranges[[1]]$x.range
	}
	
	if (zoom_factor >= 1){
		g <- g + scale_x_continuous( limits=xlims, expand=c(0,0), breaks=c(0) )
		g <- g + scale_y_continuous( limits=ylims, expand=c(0,0), breaks=c(0) )
	} else {
		g <- g + scale_x_continuous( limits=xlims, expand=c(0,0) )
		g <- g + scale_y_continuous( limits=ylims, expand=c(0,0) )
	}
	
	m_x <- (xlims[2] - xlims[1]) * 0.03
	m_y <- (ylims[2] - ylims[1]) * 0.03
	
	g <- g + geom_segment(
		aes(x = xlims[1], y = 0, xend = m_x, yend = 0),
		size=0.25,
		linetype="dashed",
		colour=line_color
	)
	g <- g + geom_segment(
		aes(x = 0, y = ylims[1], xend = 0, yend = m_y),
		size=0.25,
		linetype="dashed",
		colour=line_color
	)
} else {
	if (zoom_factor >= 1){
		g <- g + scale_x_continuous( breaks=c(0) )
		g <- g + scale_y_continuous( breaks=c(0) )
	} 
}

#screen plugin2#

#-----------------------------#
#   for clickable image map   #

# fix range
if ( exists("xlimv") == F ){
	# for setting xlim & ylim
	out_coord <- cbind(
		c( df.labels.save$x, df.words$x),
		c( df.labels.save$y, df.words$y)
	)
	
	xlimv <- c(
		min( out_coord[,1] ) - 0.04 * ( max( out_coord[,1] ) - min( out_coord[,1] ) ),
		max( out_coord[,1] ) + 0.04 * ( max( out_coord[,1] ) - min( out_coord[,1] ) )
	)
	ylimv <- c(
		min( out_coord[,2] ) - 0.04 * ( max( out_coord[,2] ) - min( out_coord[,2] ) ),
		max( out_coord[,2] ) + 0.04 * ( max( out_coord[,2] ) - min( out_coord[,2] ) )
	)
	
	# for saving
	out_coord <- cbind(
		df.labels.save$x,
		df.labels.save$y
	)
	rownames(out_coord) <- df.labels.save$labs
}

# aspect ratio
if (asp == 1){
	g <- g + coord_fixed(
		xlim=xlimv,
		ylim=ylimv,
		expand = F
	)
} else {
	g <- g + coord_cartesian(
		xlim=xlimv,
		ylim=ylimv,
		expand = F
	)
}

# coordinates for saving
if (plot_mode == "color"){
	df.labels.save <- subset(df.labels.save, cols != 3)
	out_coord <- cbind(
		df.labels.save$x,
		df.labels.save$y
	)
	rownames(out_coord) <- df.labels.save$labs
	
	add <- -1 * xlimv[1]
	div <- add + xlimv[2]
	out_coord[,1] <- ( out_coord[,1] + add ) / div

	
	add <- -1 *  ylimv[1]
	div <- add + ylimv[2]
	out_coord[,2] <- ( out_coord[,2] + add ) / div

}

# fixing width of legends to 22%
library(grid)
library(gtable)
g <- ggplotGrob(g)

if ( bubble_plot == 0 ){
	saving_file <- 1
}

if ( exists("saving_file") ){
	if ( saving_file == 0){
		target_legend_width <- convertX(
			unit( image_width * 0.22, "in" ),
			"mm"
		)
		if ( as.numeric( substr( packageVersion("ggplot2"), 1, 3) ) <= 2.1 ){ # ggplot2 <= 2.1.0
			diff_mm <- diff( c(
				convertX( g$widths[5], "mm" ),
				target_legend_width
			))
			if ( diff_mm > 0 ){
				g <- gtable_add_cols(g, unit(diff_mm, "mm"))
			}
		} else { # ggplot2 >= 2.2.0
			
			diff_mm <- diff( c(
				convertX( g$widths[7], "mm", valueOnly=T ) + convertX( g$widths[8], "mm", valueOnly=T ),
				target_legend_width
			))
			if ( diff_mm > 0 ){
				print(diff_mm)
				g <- gtable_add_cols(g, unit(diff_mm, "mm"))
			}
		}
	}
}

# fixing width of left spaces to 4.25 char
if ( as.numeric( substr( packageVersion("ggplot2"), 1, 3) ) <= 2.1 ){ # ggplot2 <= 2.1.0
	diff_char <- diff( c(
		convertX( g$widths[1] + g$widths[2] + g$widths[3], "char" ),
		unit(4.25, "char")
	))
	if ( diff_char > 0 ){
		g <- gtable_add_cols(g, unit(diff_char, "char"), pos=0)
	}
}


grid.draw(g)
';
}


sub r_command_aggr_var{
	my $n_v = shift;
	my $t = << 'END_OF_the_R_COMMAND';

# aggregate
aggregate_with_var <- function(d, doc_length_mtr, v) {
	d       <- aggregate(d,list(name = v), sum)
	n_total <- as.matrix( table(v) )

	row.names(d) <- d$name
	d$name <- NULL

	d       <- d[       order(rownames(d      )), ]
	n_total <- n_total[ order(rownames(n_total)), ]

	n_total <- subset(
		n_total,
		row.names(d) != "欠損値" & row.names(d) != "." & regexpr("^missing$", row.names(d), ignore.case = T, perl = T) == -1
	)
	d <- subset(
		d,
		row.names(d) != "欠損値" & row.names(d) != "." & regexpr("^missing$", row.names(d), ignore.case = T, perl = T) == -1
	)
	n_total <- as.matrix(n_total)
	return( list(d, n_total) )
}

dd <- NULL
nn <- NULL

END_OF_the_R_COMMAND

	$t .= "for (i in list(";
	for (my $i = 0; $i < $n_v; ++$i){
		$t .= "v$i,";
	}
	chop $t;
	$t .= ")){\n";

	$t .= << 'END_OF_the_R_COMMAND2';

	cur <- aggregate_with_var(d, doc_length_mtr, i)
	dd <- rbind(dd, cur[[1]])
	nn <- rbind(nn, cur[[2]])
	v_count <- v_count + 1
	v_pch <- c( v_pch, rep(v_count + 2, nrow(cur[[1]]) ) )
}

d       <- dd

n_total <- nn
n_total <- subset(n_total, rowSums(d) > 0)
n_total <- n_total[,1]

END_OF_the_R_COMMAND2

	return $t;
}


sub r_command_aggr_str{
	my $t = << 'END_OF_the_R_COMMAND';

# aggregate
n_total <- table(v)
d <- aggregate(d,list(name = v), sum)
row.names(d) <- d$name
d$name <- NULL
d       <- d[       order(rownames(d      )), ]
n_total <- n_total[ order(rownames(n_total))  ]
n_total <- subset(n_total,rowSums(d) > 0)

END_OF_the_R_COMMAND
return $t;
}

1;