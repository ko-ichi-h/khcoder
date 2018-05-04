package screen_code::cluster;
use strict;

use utf8;
use screen_code::plugin_path;
use screen_code::check_package;

use gui_window;
use gui_window::word_cls;
use gui_window::cod_cls;
use File::Path;
use Encode qw/encode decode/;

my $default_calc_temp;
my $default_code_calc_temp;

sub add_menu{
	if (-f &screen_code::plugin_path::assistant_path) {
		my $self = shift;
		my $lf = shift;
		my $isCode = shift;
		if ($isCode) {
			unless ($default_code_calc_temp) {
				$default_code_calc_temp = \&gui_window::cod_cls::_calc;
				*gui_window::cod_cls::_calc = \&plug_code_calc;
			}
		} else {
			unless ($default_calc_temp) {
				$default_calc_temp = \&gui_window::word_cls::calc;
				*gui_window::word_cls::calc = \&plug_calc;
			}
		}
		my $setting = $lf->Frame()->pack(
			-fill => 'x',
			-pady => 2,
		);
		
		$setting->Checkbutton(
			-text     => kh_msg->get('screen_code::assistant->use_plugin'),
			-variable => \$self->{use_plugin},
		)->pack(
			-anchor => 'w',
			-side  => 'left',
		);
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

sub text_henkan{
	if (-f &screen_code::plugin_path::assistant_path) {
		my $r_command_ref = shift;
		my $r_command_add_ref = shift;
		
		my $DATAFILE;
		my $file_rcom = &screen_code::plugin_path::assistant_option_folder."rcom_clu.txt";
		unlink $file_rcom if -f $file_rcom;
		my $file_rcom_add = &screen_code::plugin_path::assistant_option_folder."rcom_clu_add.txt";
		unlink $file_rcom_add if -f $file_rcom_add;
		open($DATAFILE, ">>", $file_rcom);
		print $DATAFILE encode('utf8',$$r_command_ref);
		close($DATAFILE);
		open($DATAFILE, ">>", $file_rcom_add);
		print $DATAFILE encode('utf8',$$r_command_add_ref);
		close($DATAFILE);
		
		system(&screen_code::plugin_path::assistant_path_system, "3");
		
		open($DATAFILE, "<:utf8", $file_rcom);
		{
			local $/ = undef; 
			$$r_command_ref = readline $DATAFILE;
		}
		close($DATAFILE);
		open($DATAFILE, "<:utf8", $file_rcom_add);
		{
			local $/ = undef; 
			$$r_command_add_ref = readline $DATAFILE;
		}
		close($DATAFILE);
	}
}

sub calc_plugin_loop{
	my $self = shift;
	my $isCode = shift;
	
	#packageのインストール確認
	unless (&screen_code::check_package::check_install) {
		unless (&screen_code::check_package::install_package) {
			return 0;
		}
	}
	
	#プラグインライセンス確認
	return 0 unless(system(&screen_code::plugin_path::assistant_path_system, 0));
	
	reset_plot_hash($self);
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

	&set_config_param($self);

	#config_paramに設定項目をまとめているので、以下は呼び出す必要が無くなる
	#$self->{cls_obj}->params,font_size => $self->{font_obj}->font_size,plot_size => $self->{font_obj}->plot_size, 
	my $plot = &make_plot_plugin(
		&get_config_param($self),
		font_bold      => $self->{font_obj}->check_bold_text,
		r_command      => $r_command,
		plotwin_name   => 'word_cls',
		data_number    => $check_num,
		plots          => $self->{plots},
		add_plot       => $self->{add_plot},
		leatest_plot   => $self->{leatest_plot},
		plot_file_names=> $self->{plot_file_names},
		plot_number    => $self->{plot_number},
		maked_merges   => $self->{maked_merges}
	);
	
	$w->end(no_dialog => 1);
	return 0 unless $plot;

	$self->{plots} = $plot->{result_plots};
	$self->{plot_file_names} = $plot->{plot_file_names}.",";
	$self->{plot_number} = $plot->{plot_number}.",";
	$self->{leatest_plot} = $plot->{leatest_plot} + 1;
	if (!$self->{maked_merges}) {
		$self->{merges0} = $plot->{merges0};
	}
	$self->{maked_merges} = 1;
	
	$self->{config_param}->{plot_size} = $plot->{plot_size};
	
	if ($plot->{initial_add_flag}) {
		$self->{add_plot} = $self->{config_param}->{cluster_number};
		#初期表示プロットを指定クラスター数のものに変える必要はあるか
		#$self->{plot_o} = $self->{config_param}->{cluster_number};
		return 1;
	}

	unless ( $self->{check_rm_open} ){
		$self->withd;
	}
	
	my $rtn = 0;
	while(1) {
		save_option($self,'word');
		save_config($self);
		$! = undef;
		$rtn = system(&screen_code::plugin_path::assistant_path_system, "4");
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


# プロット作成＆表示
sub calc_code_plugin{
	my $self = shift;

	my @selected = ();
	foreach my $i (@{$self->{checks}}){
		push @selected, $i->{name} if $i->{check};
	}
	my $selected_num = @selected;
	if ($selected_num < 3){
		gui_errormsg->open(
			type   => 'msg',
			window  => \$self->win_obj,
			msg    => kh_msg->get('gui_window::cod_corresp->sel3'), # 'コードを3つ以上選択してください。'
		);
		return 0;
	}

	my $wait_window = gui_wait->start;

	# データ取得
	my $r_command;
	unless ( $r_command =  kh_cod::func->read_file($self->cfile)->out2r_selected($self->tani,\@selected) ){
		gui_errormsg->open(
			type   => 'msg',
			window => \$self->win_obj,
			msg    => kh_msg->get('gui_window::cod_corresp->er_zero'),
		);
		#$self->close();
		$wait_window->end(no_dialog => 1);
		return 0;
	}
	
	# クラスター分析実行のためのRコマンド
	$r_command .= "\n";
	$r_command .= "d <- t(d)\n";
	$r_command .= "row.names(d) <- c(";
	foreach my $i (@{$self->{checks}}){
		my $name = $i->{name};
		#旧バージョンはMySQLのエンコードがeuc-jp
		$name = Encode::decode('euc-jp', $i->{name});
		substr($name, 0, 1) = '';
		$r_command .= '"'.$name.'",'
			if $i->{check}
		;
	}
	chop $r_command;
	$r_command .= ")\n";
	$r_command .= "# END: DATA\n";

	&set_config_param($self);

	#config_paramに設定項目をまとめているので、以下は呼び出す必要が無くなる
	#$self->{cls_obj}->params,font_size => $self->{font_obj}->font_size,plot_size => $self->{font_obj}->plot_size, 
	my $plot = &make_plot_plugin(
		&get_config_param($self),
		font_bold      => $self->{font_obj}->check_bold_text,
		r_command      => $r_command,
		plotwin_name   => 'cod_cls',
		data_number    => $selected_num,
		plots          => $self->{plots},
		add_plot       => $self->{add_plot},
		leatest_plot   => $self->{leatest_plot},
		plot_file_names=> $self->{plot_file_names},
		plot_number    => $self->{plot_number},
		maked_merges   => $self->{maked_merges}
	);

	$wait_window->end(no_dialog => 1);
	return 0 unless $plot;
	
	$self->{plots} = $plot->{result_plots};
	$self->{plot_file_names} = $plot->{plot_file_names}.",";
	$self->{plot_number} = $plot->{plot_number}.",";
	$self->{leatest_plot} = $plot->{leatest_plot} + 1;
	if (!$self->{maked_merges}) {
		$self->{merges0} = $plot->{merges0};
	}
	$self->{maked_merges} = 1;
	
	$self->{config_param}->{plot_size} = $plot->{plot_size};
	
	if ($plot->{initial_add_flag}) {
		$self->{add_plot} = $self->{config_param}->{cluster_number};
		#$self->{plot_o} = $self->{config_param}->{cluster_number};
		return 1;
	}
	
	unless ( $self->{check_rm_open} ){
		$self->withd;
	}
	
	my $rtn = 0;
	while(1) {
		save_option($self,'cod');
		save_config($self);
		$! = undef;
		$rtn = system(&screen_code::plugin_path::assistant_path_system, "4");
		$rtn = 0 if ($!) ; #systemでエラーがあった場合
		read_config($self);
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

	kh_r_plot->clear_env;

	#my $fontsize = $args{font_size};
	my $fontsize = 1;
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
		$args{plot_size} = int( $args{plot_size} * ( $::config_obj->plot_size_codes / 480 ) );
		
		if ($args{plot_size} < $::config_obj->plot_size_codes){
			$args{plot_size} = $::config_obj->plot_size_codes;
		}
		elsif ($args{plot_size} < $::config_obj->plot_size_words){
			$args{plot_size} = $::config_obj->plot_size_words;
		}
	}

	my $setting_cls_num = 0;
	my $default_cls_num = int( sqrt( $args{data_number} ) + 0.5);
	#プラグイン起動時または調整で設定変更時に、クラスター数が指定されているか(推奨値の他に指定されたクラスター数のプロットも行う必要がある)
	my $initial_add_flag = 0;
	if($args{add_plot})  {
		$setting_cls_num = $args{add_plot};
		$cluster_number = $args{add_plot};
	}
	if ($cluster_number =~ /auto/i){
		$cluster_number = int( sqrt( $args{data_number} ) + 0.5)
	} else {
		if(!$setting_cls_num) {
			$initial_add_flag = 1;
		#	$setting_cls_num = $cluster_number;
		}
	}
	#指定されたクラスター数がKHCoder推奨値と同値
	if ($cluster_number == $default_cls_num) {
		$initial_add_flag = 0;
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

	$r_command .= "

if (exists(\"doc_length_mtr\")){
	leng <- as.numeric(doc_length_mtr[,2])
	leng[leng ==0] <- 1
	d <- t(d)
	d <- d / leng
	d <- d * 1000
	d <- t(d)
}

" unless $args{method_dist} eq 'binary';

	if ($args{method_dist} eq 'euclid'){
		$r_command .= "d <- t( scale( t(d) ) )\n";
	}
	# euclidの場合は抽出語ごとに標準化
		# euclid係数を使う主旨からすると、標準化は不要とも考えられるが、
		# 標準化を行わないと連鎖の程度が激しくなり、クラスター分析として
		# の用をなさなくなる場合がまま見られる。

	$r_command .= "method_dist <- \"$args{method_dist}\"\n";
	$r_command .= "method_clst <- \"$args{method_mthd}\"\n";

	$r_command .= '
library(amap)
dj <- Dist(d,method=method_dist)

if (
	   ( as.numeric( R.Version()$major ) >= 3 )
	&& ( as.numeric( R.Version()$minor ) >= 1.0)
){                                                      # >= R 3.1.0
	if (method_clst == "ward"){
		method_clst  <-  "ward.D2"
	}
	hcl <- hclust(dj,method=method_clst)
} else {                                                # <= R 3.0
	if (method_clst == "ward"){
		dj <- dj^2
		hcl <- hclust(dj,method=method_clst)
		hcl$height <- sqrt( hcl$height )
	} else {
		hcl <- hclust(dj,method=method_clst)
	}
}'
	;

	$r_command .= "\n$par";
	my $r_command_plot .= &r_command_plot($old_simple_style);

	# make plots
	my $merges;
	
	my ($w,$h) = ($::config_obj->plot_size_codes, $args{plot_size});
	($w,$h) = ($h,$w) if $old_simple_style;
	
	# dendrogram
	#my $plot1 = kh_r_plot->new(
	#	name      => $args{plotwin_name}.'_1',
	#	command_f => $r_command,
	#	width     => $w,
	#	height    => $h,
	#	font_size => $args{font_size},
	#) or return 0;
	#$plot1->rotate_cls if $old_simple_style;
	
	my $r_command_add = &r_command_height;
	
	&text_henkan(\$r_command_plot, \$r_command_add);
	$r_command .= $r_command_plot;
	
	my $plots = $args{plots};
	my $plot1;
	my $first = 1;
	my $leatest_plot = $args{leatest_plot};
	my $plot_file_names = $args{plot_file_names};
	my $plot_number = $args{plot_number};
	#デフォルト分割数とプラグインの分割数が同じ場合
	my $default_duplicate = 0;
	while(1) {
		my $r_command_a;
		#一度プラグインに行った後はもう一度$r_commandが必要
		if ($first) {
			$r_command_a = $r_command;
			$first = 0;
		} else {
			$r_command_a = $r_command_plot;
		}
		my $pattern_num = $leatest_plot;
		$pattern_num += $default_duplicate;
		#追加プロットでクラスター数が設定されていないという状況はありえないという想定
		if ($setting_cls_num) {
			$pattern_num = -1;
		}
		$plot1 = kh_r_plot->new(
			name      => $args{plotwin_name}.'_'.$leatest_plot,
			command_a => "pattern_num <- $pattern_num\n leatest_plot <- $leatest_plot\n".$r_command_a,
			command_f => "pattern_num <- $pattern_num\n leatest_plot <- $leatest_plot\n".$r_command,
			width     => $w,
			height    => $h,
			font_size => $args{font_size},
		) or return 0;
		$plot1->rotate_cls if $old_simple_style;

		$plot_file_names = $plot_file_names."$leatest_plot".",";
	
		my $r_msg = $plot1->{r_msg};
		#分割数がAutoで無い場合は一枚だけプロットする
		if ($setting_cls_num) {
			push @{$plots}, $plot1;
			$plot_number = $plot_number."$setting_cls_num".",";
			last;
		#
		} elsif ($r_msg eq '') {
			push @{$plots}, $plot1;
			$plot_number = $plot_number."$cluster_number".",";
			last;
		}
		#R処理から返すメッセージでKHCoderデフォルトの推奨値をプロットしたかどうかを判定
		if ($r_msg =~ /^\[1\] default.*/) {
			
			#デフォルト判定文字列を消去し、プラグインが判定した推奨分割数を検証する
			#推奨分割数が無い場合(直線に近い併合水準だとありえる)はループ処理を抜ける判定をする
			if ($r_msg =~ /\n/) {
				$r_msg =~ s/^.*[\n]//;
			} else {
				$r_msg = "";
			}
			$plot_number = $plot_number."$default_cls_num"." (KHCoder),";
			push @{$plots}, $plot1;
			my @splited = split(/\s+/,$r_msg);
			if (@splited <= 1) {
				last;
			}
			if ($splited[$leatest_plot + 1] eq $default_cls_num) {
				$default_duplicate = 1;
			}
			if ($default_duplicate  && @splited == 2) {
				last;
			}
		} else {
			my @splited = split(/\s+/,$r_msg);
			$plot1->{cls_num} = $splited[$leatest_plot + $default_duplicate];
			$plot_number = $plot_number."$splited[$leatest_plot + $default_duplicate]"." (Monkin),";
			#指定されたクラスター数がプラグイン推奨値と同値
			if ($cluster_number == int($splited[$leatest_plot + $default_duplicate])) {
				$initial_add_flag = 0;
			}
			push @{$plots}, $plot1;
			
			if ($splited[$leatest_plot + 1] eq $default_cls_num) {
				$default_duplicate = 1;
			}
			if (@splited <= $leatest_plot + 1 + $default_duplicate) {
				last;
			}
		
		}
		$leatest_plot++;
	}

	# write coordinates to a file
	#my $csv;
	#unless ($old_simple_style) {
	#	$csv = $::project_obj->file_TempCSV;
	#	$::config_obj->R->send("
	#		write.table(coord, file=\"".$::config_obj->uni_path($csv)."\", fileEncoding=\"UTF-8\", sep=\"\\t\", quote=F, col.names=F)\n
	#	");
	#}

	
	my $plotR;
	# heights
	#プロット画像が常に 1_名前 だが、デフォルトを0番でプロットするように変更したので 0_名前 でもいいかもしれない(処理に影響はしない)
	if (!$args{maked_merges}) {
		foreach my $i ('last','first','all'){
			my $r_command_f = $r_command."pp_type <- \"$i\"\n"."default_cls <- $default_cls_num\n".$r_command_add;
			height_command_f_edit(\$r_command_f);
			$merges->{0}{$i} = kh_r_plot->new(
				name      => $args{plotwin_name}.'_1_'.$i,
				command_f =>  $r_command_f,
				command_a =>  "pp_type <- \"$i\"\n"
				             ."default_cls <- $default_cls_num\n"
				             .$r_command_add,
				width     => $::config_obj->plot_size_words,
				height    => $::config_obj->plot_size_codes,
				font_size => $args{font_size},
			) or return 0;
		}
		$plotR->{merges0} = $merges->{0};
	}
	
	
	$plotR->{result_plots} = $plots,
	chop($plot_file_names);
	chop($plot_number);
	$plotR->{plot_file_names} = $plot_file_names;
	$plotR->{plot_number} = $plot_number;
	$plotR->{leatest_plot} = $leatest_plot;
	$plotR->{plot_size} = $args{plot_size};
	#指定されたクラスター数で追加プロットが必要か
	$plotR->{initial_add_flag} = $initial_add_flag;
	return $plotR;
}

sub save{
	my $self = shift;

	my $path = $self->{path_o};
	my $plot_key = $self->{plot_o};
	$path = $::config_obj->os_path($path);
	
	if($plot_key =~ /^[0-9]+$/) {
		$self->{plots}[$plot_key+0]->save($path) if $path;
	} else {
		$self->{merges0}{$plot_key}->save($path) if $path;
	}
	return 1;
}

sub read_option{
	my $self = shift;
	my $file_option = &screen_code::plugin_path::assistant_option_folder."option.txt";
	$self->{mode_o} = undef;
	$self->{plot_o} = undef;
	$self->{add_plot} = undef;
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
				if ($self->{mode_o} eq "save") {
					$self->{plot_o} = $temp;
				} elsif ($self->{mode_o} eq "add_plot") {
					$self->{add_plot} = $temp;
					$self->{plot_o} = $temp;
				}
			}
		}
		
		close($IN);
		unlink $file_option if -f $file_option;
		return ($self->{mode_o} eq "save");
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
	#追加プロット処理の関係で末尾に不要なコンマがあるため削除する
	chop($plot_file_names);chop($plot_number);
	#プラグインの処理変更により必要なくなるかもしれない
	my $initial_display;
	if ($self->{add_plot}) {
		$initial_display = $self->{leatest_plot} - 1;
	} else {
		$initial_display = $self->{plot_o};
	}
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
		my $isAdd = 0;
		while (my $line = <$IN>) {
			my @splited = split(/=/, $line);
			my $temp = $splited[1];
			chomp($temp);
			if ($splited[0] eq "font_size") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{font_size});
				$self->{config_param}->{font_size} = $temp;
			} elsif ($splited[0] eq "plot_size") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{plot_size});
				$self->{config_param}->{plot_size} = $temp;
			} elsif ($splited[0] eq "cluster_number") {
				$isAdd = 1 if ($temp ne $self->{config_param}->{cluster_number});
				$self->{config_param}->{cluster_number} = $temp;
			} elsif ($splited[0] eq "cluster_color") {
				if ($temp eq "0") {
					if ($self->{config_param}->{cluster_color} != 0) {
						$isChanged = 1;
					}
					$self->{config_param}->{cluster_color} = 0;
				} elsif ($temp ne "0") {
					if ($self->{config_param}->{cluster_color} == 0) {
						$isChanged = 1;
					}
					$self->{config_param}->{cluster_color} = 1;
				}
			} elsif ($splited[0] eq "method_dist") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{method_dist});
				$self->{config_param}->{method_dist} = $temp;
			} elsif ($splited[0] eq "method_mthd") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{method_mthd});
				$self->{config_param}->{method_mthd} = $temp;
			}
		}
		
		if ($isChanged) {
			reset_plot_hash($self);
		} elsif ($isAdd) {
			$self->{add_plot} = $self->{config_param}->{cluster_number};
			$self->{plot_o} = $self->{config_param}->{cluster_number};
		}
		close($IN);
		unlink $file_config if -f $file_config;
		return ($isChanged || $isAdd);
	} else {
		return 0;
	}
}

sub save_config{
	my $self = shift;
	my $file_config = &screen_code::plugin_path::assistant_option_folder."config.txt";
	unlink $file_config if -f $file_config;
	open(my $OUT, ">:encoding(utf8)", $file_config);
	
	print $OUT "font_size=".$self->{config_param}->{font_size}."\n";
	print $OUT "plot_size=".$self->{config_param}->{plot_size}."\n";
	print $OUT "cluster_number=".$self->{config_param}->{cluster_number}."\n";
	print $OUT "cluster_color=".$self->{config_param}->{cluster_color}."\n";
	print $OUT "method_dist=".$self->{config_param}->{method_dist}."\n";
	print $OUT "method_mthd=".$self->{config_param}->{method_mthd}."\n";
	
	close($OUT);
}

sub set_config_param{
	my $self = shift;
	if (!defined($self->{config_param})) {
		$self->{config_param} = {
			'font_size' => $self->{font_obj}->font_size,
			'plot_size' => $self->{font_obj}->plot_size,
			'cluster_number' => $self->{cls_obj}->cluster_number,
			'cluster_color' => $self->{cls_obj}->cluster_color,
			'method_dist' => $self->{cls_obj}->method_dist,
			'method_mthd' => $self->{cls_obj}->method_mthd,
		};
	}
}
sub get_config_param{
	my $self = shift;
	return (
			'font_size' => $self->{config_param}->{font_size},
			'plot_size' => $self->{config_param}->{plot_size},
			'cluster_number' => $self->{config_param}->{cluster_number},
			'cluster_color' => $self->{config_param}->{cluster_color},
			'method_dist' => $self->{config_param}->{method_dist},
			'method_mthd' => $self->{config_param}->{method_mthd},
		);
}

sub height_command_f_edit{
	my $r_command_f_ref = shift;
	
	# Delete commands to draw the dendrogram (normal)
	$$r_command_f_ref =~ s/\nplot\(hcl.+?\n/\n\n/;
	$$r_command_f_ref =~ s/\trect.hclust.+?\n/\n/;

	# Delete commands to draw the dendrogram (ggplot2)
	$$r_command_f_ref =~ s/\n\tprint.+?\n/\n/g;
	$$r_command_f_ref =~ s/\tgrid\..+?\n/\n/g;
	$$r_command_f_ref =~ s/\tquartzFonts.+?\n/\n/g;
	$$r_command_f_ref =~ s/show_bar <\- 1/show_bar <\- 0/g;
	
	
	$$r_command_f_ref =~ s/\n\s+print.+?\n/\n/g;
}

sub reset_plot_hash{
	my $self = shift;
	my @plots;
	$self->{plots} = \@plots;
	#print "self->{plots} = ".$self->{plots}."\n";
	$self->{add_plot} = 0;
	$self->{plot_o} = "";
	$self->{leatest_plot} = 0;
	$self->{plot_file_names} = "";
	$self->{plot_number} = "";
	$self->{maked_merges} = 0;
}


sub r_command_height{
	my $t = '

# プロットの準備開始
pp_focus  <- 50     # 最初・最後の50回の併合をプロット
pp_kizami <-  5     # クラスター数のきざみ（5個おきに表示）

# 併合水準を取得
det <- hcl$merge
det <- cbind(1:nrow(det), nrow(det):1, det, hcl$height)
colnames(det) <- c("u_n", "cls_n", "u1", "u2", "height")

# タイプ別の処理：必要な部分の併合データ切出し・表記・クラスター数表示のきざみ
if (pp_type == "last"){
	n_start <- nrow(det) - pp_focus + 1
	if (n_start < 1){ n_start <- 1 }
	det <- det[nrow(det):n_start,]
	
	str_xlab <- paste(" (最後の",pp_focus,"回)",sep="")
} else if (pp_type == "first") {
	if ( pp_focus > nrow(det) ){
		pp_focus <- nrow(det)
	}
	det <- det[pp_focus:1,]
	
	str_xlab <- paste(" (最初の",pp_focus,"回)",sep="")
} else if (pp_type == "all") {
	det <- det[nrow(det):1,]
	pp_kizami <- nrow(det) / 8
	pp_kizami <- pp_kizami - ( pp_kizami %% 5 ) + 5
	
	str_xlab <- ""
}

# クラスター数のマーカーを入れる準備
p_type <- NULL
p_nums <- NULL
#screen plugin2 start#
for (i in 1:nrow(det)){
	if ( (det[i,"cls_n"] %%  pp_kizami == 0) | (det[i,"cls_n"] == 1)){
		p_type <- c(p_type, 16)
		p_nums <- c(p_nums, det[i,"cls_n"])
	} else {
		p_type <- c(p_type, 1)
		p_nums <- c(p_nums, "")
	}
}
#screen plugin2 end#

# プロット
par(mai=c(0,0,0,0), mar=c(4,4,1,1), omi=c(0,0,0,0), oma =c(0,0,0,0) )
plot(
	det[,"u_n"],
	det[,"height"],
	type = "b",
	pch  = p_type,
	bty = "l",
	xlab = paste("クラスター併合の段階",str_xlab,sep = ""),
	ylab = "併合水準（非類似度）",
	#screen plugin p_col#
)

text(
	x      = det[,"u_n"],
	y      = det[,"height"]
	         - ( max(det[,"height"]) - min(det[,"height"]) ) / 40,
	labels = p_nums,
	pos    = 4,
	offset = .2,
	cex    = .8,
	#screen plugin p_col#
)

legend(
	min(det[,"u_n"]),
	max(det[,"height"]),
	legend = c("※プロット内の数値ラベルは\n　併合後のクラスター総数"),
	#pch = c(16),
	cex = .9,
	box.lty = 0
)

';
return $t;
}

sub r_command_plot{
	my $simple = shift;
	my $t;
	if ($simple){
		$t = &r_command_plot_simple;
	} else {
		$t = &r_command_plot_ggplot2;
	}
	#print "simple ".$simple."\nt \n".$t."\n";
	return $t;
}


sub r_command_plot_simple{
	my $t = << 'END_OF_the_R_COMMAND';

#screen plugin1#
hcl$labels <- labels
plot(hcl,ann=0,cex=font_size, hang=-1)
if (n_cls > 1){
	rect.hclust(hcl, k=n_cls, border="#FF8B00FF")
}
#screen plugin represent_word_symple#
END_OF_the_R_COMMAND
return $t;
}

sub r_command_plot_ggplot2{

	my $t = '

library(grid)
library(ggplot2)
library(ggdendro)

ddata <- dendro_data(as.dendrogram(hcl), type="rectangle")

p <- NULL
p <- ggplot()

font_family <- "'.&font_plot_current.'"
if ( exists("PERL_font_family") ){
	font_family <- PERL_font_family
}

if ( exists("saving_eps") ){
	if (saving_eps == 1) {
		font_family <- "Japan1GothicBBB"
	}
}
if ( exists("saving_pdf") ){
	if (saving_pdf == 1) {
		font_family <- "Japan1GothicBBB"
	}
}

#screen plugin1#

# クラスターごとのカラー設定

if (n_cls > 1){
	memb <- cutree(hcl,k=n_cls)
	# 全体の色設定
	p <- p + scale_colour_hue(l=40, c=100)
	# 切り離し線(1)
	cutpoint <- mean(
		c(
			rev(hcl$height)[n_cls-1],
			rev(hcl$height)[n_cls]
		)
	)
	# 色の順番を決定
	n <- length( unique(memb[hcl$order]) )
	new_col <- NULL
	for (i in 1:ceiling(n / 2) ){
		new_col <- c(new_col, i)
		if (i + ceiling(n / 2) <= n){
			new_col <- c(new_col, i + ceiling(n / 2))
		}
	}
	# クラスター番号→色名の変換用ベクトル作成（col_vec）
	col_tab <- cbind(
		unique(memb[hcl$order]),
		new_col
	)
	colnames(col_tab) <- c("org","new")
	col_vec <- NULL
	for (i in col_tab[order(col_tab[,1]),2]){
		c <- as.character(i)
		while (nchar(c) < 3){
			c <- paste("0",c,sep="")
		}
		col_vec <- c(col_vec, c)
	}
	# 線の色分け
	seg_bl <- NULL
	seg_cl <- NULL
	colnames(ddata$segment) <- c(
		"x0",
		"y0",
		"x1",
		"y1"
	)
	colnames(ddata$labels) <- c(
		"x",
		"y",
		"text"
	)
	
	for ( i in 1:nrow( ddata$segment ) ) {
		if (
			   ddata$segment$y0[i] > cutpoint
			|| ddata$segment$y1[i] > cutpoint
			|| (
				   ddata$segment$y0[i] >= cutpoint
				&& ddata$segment$y1[i] >= cutpoint
			   )
		) {
			seg_bl <- c(
				seg_bl,
				ddata$segment$x0[i],
				ddata$segment$y0[i],
				ddata$segment$x1[i],
				ddata$segment$y1[i]
			)
		} else {
			seg_cl <- c(
				seg_cl,
				ddata$segment$x0[i],
				ddata$segment$y0[i],
				ddata$segment$x1[i],
				ddata$segment$y1[i],
				#col_vec[
					memb[hcl$order][
						floor(
							mean(
								ddata$segment$x0[i],
								ddata$segment$x1[i]) 
							)
					]
				#]
			)
		}
	}
	seg_bl = matrix(seg_bl, byrow=T, ncol=4 )
	seg_cl = matrix(seg_cl, byrow=T, ncol=5 )
	
	if (is.null(seg_bl) == F){
		colnames(seg_bl) <- c("x0", "y0", "x1", "y1")
		seg_bl <- as.data.frame(seg_bl)
		# 切り離し線(2)
		if ( max(seg_bl$y1) > cutpoint ){
			p <- p + geom_hline(
				yintercept = cutpoint,
				colour="black",
				linetype=5,
				size=0.5
			)
		}
	}
	colnames(seg_cl) <- c("x0", "y0", "x1", "y1", "c")
	seg_cl <- as.data.frame(seg_cl)
	seg_cl$c <- col_vec[seg_cl$c]

	p <- p + geom_text(
		data=data.frame(                    # ラベル
			x=label(ddata)$x,
			y=label(ddata)$y,
			text=labels[ as.numeric( as.vector( ddata$labels$text ) ) ],
			cols= col_vec[ memb[ as.numeric( as.vector( ddata$labels$text ) ) ] ]
		),
		aes_string(
			x="x",
			y="y",
			label="text",
			colour="cols"
		),
		hjust=1,
		angle =0,
		family = font_family,
		fontface = "bold",
		size = 5 * 0.85 * font_size
	)

	p <- p + geom_segment(
		data=seg_cl,
		aes_string(x="x0", y="y0", xend="x1", yend="y1", colour="c"),
		size=0.5
	)
} else {
	memb <- rep( c("a"), length(labels) )
	p <- p + scale_colour_manual(values=c("black"))
	seg_bl <- ddata$segment
	col_vec <- c("001")
	p <- p + geom_text(
		data=data.frame(                    # ラベル
			x=label(ddata)$x,
			y=label(ddata)$y,
			text=labels[ as.numeric( as.vector( ddata$labels$text ) ) ],
			cols= col_vec[ memb[ as.numeric( as.vector( ddata$labels$text ) ) ] ]
		),
		aes_string(
			x="x",
			y="y",
			label="text",
			colour="cols"
		),
		hjust=1,
		angle =0,
		family = font_family,
		fontface = "bold",
		size = 5 * 0.85 * font_size
	)
}

if (is.null(seg_bl) == F){
	p <- p + geom_segment(
		data=seg_bl,
		aes_string(x="x0", y="y0", xend="x1", yend="y1"),
		color="gray50",
		linetype=1,
	)
}

p <- p + geom_text(
	data=data.frame(                    # ラベル変換
		x=label(ddata)$x,
		y=label(ddata)$y,
		text=labels[ as.numeric( as.vector( ddata$labels$text ) ) ],
		cols= col_vec[ memb[ as.numeric( as.vector( ddata$labels$text ) ) ] ]
	),
	aes_string(
		x="x",
		y="y",
		label="text",
		colour="cols"
	),
	hjust=1,
	angle =0,
	family = font_family,
	fontface = "bold",
	size = 5 * 0.85 * font_size
)

# 語やコードの長さにあわせて余白の大きさを設定
y_max <- max( ddata$segment$y1 )
y_min <- 0.2
# "strwidth" crashes if the device is cairo_pdf or cairo_ps 
if (
	is.na(dev.list()["cairo_pdf"])
	&& is.na(dev.list()["cairo_ps"])
){
	y_min <- max(
		strwidth(
			labels[ as.numeric( as.vector( ddata$labels$text ) ) ],
			units = "figure",
			font = 2
		)
	)
}
y_min <- ( 6 * y_max * y_min ) / ( 5 - 6 * y_min )
y_min <- y_min * 1.1
if (y_min > y_max * 2){
	y_min <- y_max * 2
}
y_min <- y_min * -1

# 目盛の位置を設定
b1 <- 0
for (i in 1:1000){
	b1 <- signif(y_max * 0.875, i)
	if (b1 < y_max){
		break
	}
}

p <- p + coord_flip()
p <- p + scale_x_reverse(
	expand = c(0,0),
	breaks = NULL,
	limits=c( length(ddata$labels$text) + 0.5 , 1 - 0.5 )
)
p <- p + scale_y_continuous(
	limits=c(y_min,y_max),
	breaks=c(0,b1/2,b1),
	expand = c(0.02,0.02)
)

p <- p + theme(
	axis.title.y = element_blank(),
	axis.title.x = element_blank(),
	axis.ticks   = element_line(colour="gray60"),
	axis.text.y  = element_text(size=12,colour="gray40"),
	axis.text.x  = element_text(size=12,colour="gray40"),
	legend.position="none"
)

if (n_cls <= 1){
	p <- p + theme(
		axis.text.y  = element_blank(),
		axis.text.x  = element_text(size=12,colour="black"),
		axis.ticks = element_line(colour="black"),
		#panel.grid.major = theme_blank(),
		#panel.grid.minor = theme_blank(),
		#panel.background = theme_blank(),
		axis.line = element_line(colour = "black")
	)
}

show_bar <- 1

if (show_bar == 1){
	p <- p + theme(
		axis.ticks  = element_blank(),
		axis.text.y = element_blank()
	)
	p <- p + theme(
		plot.margin = unit(c(0,0,0,0), "lines")
	)

	bard <- data.frame(
		nm <- labels[ as.numeric( as.vector( ddata$labels$text ) ) ],
		ht <- freq[ as.numeric( as.vector( ddata$labels$text ) ) ],
		cl <- col_vec[ memb[ as.numeric( as.vector( ddata$labels$text ) ) ] ],
		od <- nrow(d):1
	)

	if (n_cls <= 1){
		bard$cl <- "001"
	}

	p2 <- NULL
	p2 <- ggplot()
	p2 <- p2 + geom_bar(
		stat="identity",
		position = "identity",
		width=0.75,
		data=bard,
		aes(
			x=reorder(od,od),
			y=ht,
			fill=cl
		)
	)
	p2 <- p2 + coord_flip()
	p2 <- p2 + scale_y_reverse( expand = c(0,0))
	p2 <- p2 + scale_x_discrete( expand = c(0,0) )
	p2 <- p2 + theme(
		axis.title.y     = element_blank(),
		axis.title.x     = element_blank(),
		axis.ticks       = element_blank(),
		axis.text.y      = element_blank(),
		axis.text.x      = element_text(size=12,colour="white"),
		legend.position  = "none",
		panel.background = element_rect(fill="white", colour="white"),
		panel.grid.major = element_blank(),
		panel.grid.minor = element_blank()
	)

	margin <- 0.002 * nrow(d) + 0.00001 * nrow(d)^2 - 0.12
	p2 <- p2 + theme(
		plot.margin = unit(c(0.25,0,0.25,0), "lines") # r: -0.75
	)


	#screen plugin represent_word#
	
	grid.newpage()
	pushViewport(viewport(layout=grid.layout(1,2, width=c(1,5)) ) )
	print(p,  vp= viewport(layout.pos.row=1, layout.pos.col=2) )
	print(p2, vp= viewport(layout.pos.row=1, layout.pos.col=1) )
} else {
	print(p)
}

if (
	is.na(dev.list()["pdf"])
	&& is.na(dev.list()["postscript"])
	&& is.na(dev.list()["cairo_pdf"])
	&& is.na(dev.list()["cairo_ps"])
){
	if ( grepl("darwin", R.version$platform) ){
		quartzFonts(HiraKaku=quartzFont(rep("'.&font_plot_current.'",4)))
		grid.gedit("GRID.text", grep=TRUE, global=TRUE, gp=gpar(fontfamily="HiraKaku"))
	}
}

detach("package:ggdendro", unload=T)

# for clickable image map
exp <- (y_max - y_min ) * 0.02
coord <- cbind(
	(1 / 6 + 5 / 6 * -1 * (y_min - exp) / ( (y_max + exp) - (y_min - exp) )) * 1.03,
	1:length(ddata$labels$text) / length(ddata$labels$text)
)
rownames(coord) <-
	labels[ as.numeric( as.vector( ddata$labels$text ) ) ]

';


return $t;
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