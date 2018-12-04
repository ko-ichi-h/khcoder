package screen_code::cross_func;
use strict;

use kh_cod::func;
use screen_code::plugin_path;

use File::Path;
use Clone qw(clone);
use Encode qw/encode decode/;

my $replace_flag;

sub add_menu{
	if (-f &screen_code::plugin_path::assistant_path) {
		my $self = shift;
		my $rf = shift;
		unless ($replace_flag) {
			$replace_flag = 1;
			*kh_cod::func::outtab = \&outtab;
		}
		$rf->Label(
			-text     => kh_msg->get('screen_code::assistant->cross_map_label'),
		)->pack(-side => 'left');
		my $button = $rf->Button(
			-text     => kh_msg->get('gui_window::r_plot::cod_mat->fluc'),
			-font => "TKFN",
			-borderwidth => '1',
			-command => sub { calc_plugin_loop($self); }
		)->pack(-anchor => 'e', -pady => 2, -padx => 2, -side => 'left');
		
	}
}

sub outtab{
	my $self  = shift;
	my $tani = shift;
	my $var_id = shift;
	my $cell  = shift;
	
	# コーディングの実行
	$self->code($tani) or return 0;
	unless ($self->valid_codes){ return 0; }
	$self->cumulate if @{$self->{valid_codes}} > 29;
	
	# 外部変数のチェック
	my $heap = 'TYPE=HEAP';
	$heap = '' unless $::config_obj->use_heap;
	my ($outvar_tbl,$outvar_clm);
	my $var_obj = mysql_outvar::a_var->new(undef,$var_id);
	if ( $var_obj->{tani} eq $tani){
		$outvar_tbl = $var_obj->{table};
		$outvar_clm = $var_obj->{column};
	} else {
		$outvar_tbl = 'ct_outvar_cross';
		$outvar_clm = 'value';
		mysql_exec->drop_table('ct_outvar_cross');
		mysql_exec->do("
			CREATE TABLE ct_outvar_cross (
				id int primary key not null,
				value varchar(255)
			) $heap
		",1);
		my $sql;
		$sql .= "INSERT INTO ct_outvar_cross\n";
		$sql .= "SELECT $tani.id, $var_obj->{table}.$var_obj->{column}\n";
		$sql .= "FROM $tani, $var_obj->{tani}, $var_obj->{table}\n";
		$sql .= "WHERE\n";
		$sql .= "	$var_obj->{tani}.id = $var_obj->{table}.id\n";
		foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
			$sql .= "	and $var_obj->{tani}.$i"."_id = $tani.$i"."_id\n";
			last if ($var_obj->{tani} eq $i);
		}
		$sql .= "ORDER BY $tani.id";
		#print "$sql\n\n";
		mysql_exec->do("$sql",1);
	}
	
	
	# 集計用SQL文の作製
	my $sql;
	$sql .= "SELECT if ( outvar_lab.lab is NULL, $outvar_tbl.$outvar_clm, outvar_lab.lab) as name,";
	foreach my $i (@{$self->{valid_codes}}){
		$sql .= "sum( IF(".$i->res_table.".".$i->res_col.",1,0) ),";
	}
	$sql .= " count(*) \n";
	$sql .= "FROM $outvar_tbl\n";
	foreach my $i (@{$self->tables}){
		$sql .= "LEFT JOIN $i ON $outvar_tbl.id = $i.id\n";
	}
	$sql .= "LEFT JOIN outvar_lab ON ( outvar_lab.var_id = $var_id AND outvar_lab.val = $outvar_tbl.$outvar_clm )\n";
	$sql .= "\nGROUP BY name";
	$sql .= "\nORDER BY ".$::project_obj->mysql_sort('name');
	#print "$sql\n";
	
	my $h = mysql_exec->select($sql,1)->hundle;
	
	# 結果出力の作製
	my @result;
	my @for_chisq;
	my @for_plot;
	
	# 一行目
	my @head = ('');
	foreach my $i (@{$self->{valid_codes}}){
		push @head, gui_window->gui_jchar($i->name);
	}
	push @for_plot, clone(\@head);
	push @head, kh_msg->get('kh_cod::func->n_cases');
	push @result, \@head;
	# 中身
	my @sum = ( kh_msg->get('kh_cod::func->total') );
	my $total;
	my @arr; #SCREEN Plugin
	while (my $i = $h->fetch){
		my $n = 0;
		my @current;
		my @current_for_chisq;
		my @current_for_plot;
		my @c = @{$i};
		my $nd = pop @c;
		my @arr_temp; #SCREEN Plugin
		
		$var_obj->{labels}{$c[0]} = ''
			unless defined($var_obj->{labels}{$c[0]});
		
		next if
			   length($i->[0]) == 0
			or $c[0] eq '.'
			or $c[0] eq '欠損値'
			or $c[0] =~  /^missing$/i
			or $var_obj->{labels}{$c[0]} eq '.'
			or $var_obj->{labels}{$c[0]} eq '欠損値'
			or $var_obj->{labels}{$c[0]} =~ /^missing$/i
		;
		
		foreach my $h (@c){
			if ($n == 0){                         # 行ヘッダ（1列目）
				push @current,          gui_window->gui_jchar($h);
				push @current_for_plot, gui_window->gui_jchar($h);
			} else {                              # 中身
				$sum[$n] += $h;
				my $p = sprintf("%.2f",($h / $nd ) * 100);
				push @current_for_chisq, [$h, $nd - $h];
				push @current_for_plot, ($h / $nd) * 100;
				if ($cell == 0){
					my $pp = "($p"."%)";
					$pp = '  '.$pp if length($pp) == 7;
					push @current, "$h $pp";
				}
				elsif ($cell == 1){
					push @current, $h;
				} else {
					push @current, "$p"."%";
				}
				push @arr_temp, $h; #SCREEN Plugin
			}
			++$n;
		}
		$total += $nd;
		push @current, $nd;
		push @result, \@current;
		push @for_chisq, \@current_for_chisq if @current_for_chisq;
		push @for_plot, \@current_for_plot;
		
		#SCREEN Plugin
		push @arr_temp, $nd;
		push @arr, \@arr_temp if @arr_temp;
	}
	# 合計行
	my @c = @sum;
	my @current; my $n = 0;
	my @arr_retsu; #SCREEN Plugin
	foreach my $i (@sum){
		if ($n == 0){
			push @current, $i;
		} else {
			my $p = sprintf("%.2f", ($i / $total) * 100);
			if ($cell == 0){
				my $pp = "($p"."%)";
				$pp = '  '.$pp if length($pp) == 7;
				push @current, "$i $pp";
			}
			elsif ($cell == 1){
				push @current, $i;
			} else {
				push @current, "$p"."%";
			}
			push @arr_retsu, $i; #SCREEN Plugin
		}
		++$n;
	}
	push @current, $total;
	push @result, \@current;
	
	#SCREEN Plugin
	push @arr_retsu, $total;
	push @arr, \@arr_retsu;
	
	# chi-square test
	my ($chisq, $rsd) = &kh_cod::func::_chisq_test(\@current, \@for_chisq);
	push @result, $chisq if $chisq;
	
	my $ret;
	$ret->{display}  = \@result;
	$ret->{plot}     = \@for_plot;
	$ret->{t_rsd}    = $rsd;

	#SCREEN Plugin
	&screen_code::cross_func::func_ratio($ret,\@arr);
	#SCREEN Plugin
	
	return $ret;
}

sub func_ratio{
	my $ret = shift;
	my $arr_ref = shift;
	my @arr = @{$arr_ref};
	my $result_copy = clone($ret->{display});
	my @result_ = @{$result_copy};
	
	#&_rsd_copy(\@arr);
	
	my $row_num = 0;
	my $col_num = 0;
	foreach my $row(@result_) {
		$col_num = 0;
		if ($row_num > 0 && $row_num < @result_ - 1) {
			foreach my $cell(@{$row}) {
				if ($col_num) {
					$result_[$row_num][$col_num] = $arr[$row_num-1][$col_num-1];
				}
				$col_num++;
			}
		}
		$row_num++;
	}
	
	my $retsu_hiritsu_ref = pop @arr;
	my @retsu_hiritsu = @{$retsu_hiritsu_ref};
	my $total = pop @retsu_hiritsu;
	
	my @gyou_hiritsu;
	foreach my $row(@arr) {
		my $sum = pop @{$row};
		push @gyou_hiritsu, $sum;
	}
	
	foreach my $i (@gyou_hiritsu) {
		$i = $i / $total;
	}
	
	foreach my $i (@retsu_hiritsu) {
		$i = $i / $total;
	}
	
	my @hiritsu_array;
	my @symbol_array;
	$row_num = 0;
	$col_num = 0;
	foreach my $row (@gyou_hiritsu) {
		my @rowary;
		
		my @symbol_temp;
		$col_num = 0;
		
		foreach my $col (@retsu_hiritsu) {
			my $hiritsu = sqrt((1 - $row) * (1 - $col));
			push @rowary, $hiritsu;
			
			my $temp = $ret->{t_rsd}[$col_num][$row_num] / $hiritsu;
			if ($temp >= 2.58) {
				push @symbol_temp, "99";
			} elsif ($temp >= 1.96) {
				push @symbol_temp, "95";
			} elsif ($temp <= -2.58) {
				push @symbol_temp, "1";
			} elsif ($temp <= -1.96) {
				push @symbol_temp, "5";
			} else {
				push @symbol_temp, "";
			}
			$col_num++;
		}
		push @hiritsu_array, \@rowary;
		push @symbol_array, \@symbol_temp;
		$row_num++;
	}
	
	$ret->{hrt} = \@hiritsu_array;
	$ret->{symbol} = \@symbol_array;
	$ret->{display_for_plugin} = \@result_;
}


sub _rsd_copy{
	my $arref   = clone($_[0]);
	my @arr   = @{$arref};
	
	pop @arr; #最終行は列合計が入っているため除外する
	my @rsd   = ();
	
	my $R_debug = 0;
	if ($::config_obj->R){
		$::config_obj->R->lock;
		my $cmd = 'chi <- chisq.test(matrix( c(';
		my $col_count;
		foreach my $row (@arr) {
			$col_count = 0;
			my $row_sum = pop @{$row};
			foreach my $cell (@{$row}) {
				$cmd .= "$cell,";
				$row_sum -= $cell;
				$col_count++;
			}
			$cmd .= "$row_sum,";
			$col_count++;
		}
		chop $cmd;
		$cmd .=  "), nrow=".@arr.", ncol=$col_count, byrow=TRUE), correct=TRUE)\n";
		#総ケース数についての計算結果が要らない場合は chi$residuals[,-ncol(chi$residuals)] のように最終列を除外しそれを出力する
		#pasteの引数 collapse で集合データをひとつの文字列にまとめることができる そのときデータ間に指定した文字が入る
		
		#KHCoderではRからの出力を受け取ると行番号([1][2]･･･)は必ず付加されるため(ダブルクォーテーションは quote=F で消せる)、それを削除する必要がある
		#たとえば、pasteで目印となる文字列を前後に付加し、正規表現でマッチした文字列を取り出し( ~= /header(.+)footer/  $data = $1)てデータのみを取得するという方法がある
		$cmd .= '
			c_rsd <- chi$residuals[,-ncol(chi$residuals)]
			write.table(c_rsd, "C:/khcoder3/screen/test/rsdtest.txt", sep=",", quote=F, append=F, row.names=F, col.names=F)
			out <- paste(c_rsd, sep="",collapse=",")
			print(out,quote=F)
		';
		#print "\n";
		#print "$cmd";
		#print "\n";
		$::config_obj->R->send($cmd);
		#my $rtn = $::config_obj->R->read();
		#print "\n";
		#print "$rtn";
		#print "\n";
	}
}

sub calc_plugin_loop{
	my $self = shift;
	
	#プラグインライセンス確認
	return 0 unless(system(&screen_code::plugin_path::assistant_path, 0));
	
	$self->{config_param} = undef;
	while(1) {
		my $rtn = plot_plugin($self);
		if (!$rtn) {
			last;
		}
	}
}

sub plot_plugin{
	my $self   = shift;
	#my $ax     = shift; ヒート・バブルの指定でありプラグインはバブルのみなので不要
	#my $selection = shift; コードを選択してプロットする機能 調整ボタンから指定している
	my $selection;
	
	unless ($self->{result}){
		return 0;
	}
	#プラグインによる計算で必要なデータがあるか確認
	unless ($self->{result}{hrt}){
		return 0;
	}
	
	
	my $wait_window = gui_wait->start;
	
	my @matrix    = @{$self->{result}{plot}};
	my @col_names = @{shift @matrix};
	shift @col_names;
	my $nrow = @matrix;
	my $ncol = @col_names;

	# データ行列
	my $rcom = 'd <- matrix( c(';
	my @row_names;
	foreach my $row (@matrix){
		my $n = 0;
		foreach my $h (@{$row}){
			if ($n == 0){
				push @row_names, $h;
			} else {
				$rcom .= "$h,";
			}
			++$n;
		}
	}
	chop $rcom;
	$rcom .= "), byrow=T, nrow=$nrow, ncol=$ncol )\n";
	
	# 残差行列
	$rcom .= 'rsd <- matrix( c(';
	foreach my $row (@{$self->{result}{t_rsd}}){
		foreach my $cell (@{$row}){
			$rcom .= "$cell,"
		}
	}
	chop $rcom;
	$rcom .= "), byrow=T, nrow=$ncol, ncol=$nrow )\n";
	$rcom .= "rsd <- t(rsd)\n";
	
	#クロス集計に記号付加
	$rcom .= 'hrt <- matrix( c(';
	foreach my $row (@{$self->{result}{hrt}}){
		foreach my $cell (@{$row}){
			$rcom .= "$cell,"
		}
	}
	chop $rcom;
	$rcom .= "), byrow=T, nrow=$nrow, ncol=$ncol )\n";
	$rcom .= "array <- rsd / hrt\n";
	
	# 列名
	foreach my $i (@col_names){ # 行頭の「＊」を削除（データはdecode済み）
		substr($i,0,1) = '';
	}
	$rcom .= "colnames(d) <- c(";
	my $count = 0;
	foreach my $i (@col_names){
		$rcom .= "\"$i\",";
		$count++;
	}
	chop $rcom;
	$rcom .= ")\n";
	
	#画像の列名見出しにp値の基準を追加する
	my @last_row = @{${$self->{result}{display}}[-1]};
	my @p_symbol;
	foreach my $i (@last_row){
		my $temp = "";
		if ($i =~ /\*\*/) {
			$temp = "p<.01 **"
		} elsif ($i =~ /\*/) {
			$temp = "p<.05 *"
		} else {
			$temp = "n.s."
		}
		push @p_symbol, $temp;
	}
	#先頭と末尾を削除
	shift @p_symbol; pop @p_symbol;
	$rcom .= "p_symbol <- c(";
	foreach my $i (@p_symbol){
		$rcom .= "\"$i\",";
	}
	chop $rcom;
	$rcom .= ")\n";
	$rcom .= "colnames(d) <- paste(p_symbol, colnames(d))\n";
	
	# 行名
	$rcom .= "rownames(d) <- c(";
	foreach my $i (@row_names){
		$rcom .= "\"$i\",";
	}
	chop $rcom;
	$rcom .= ")\n";
	
	$rcom .= "# END: DATA\n\n";

	$rcom .= "# dpi: short based\n";

	# マップの高さ
	my $label_length = 0;
	foreach my $i (@row_names){
		my $t = Encode::encode('cp932', $i);
		if ( $label_length < length($t) ){
			$label_length = length($t);
		}
	}
	my $height = int( ( 30 * $ncol + $label_length * 14 ) * ($::config_obj->plot_size_codes / 480));
	if ($height < $::config_obj->plot_size_codes){
		$height = $::config_obj->plot_size_codes;
	}
	
	my $bs_h = 1;
	my $bs_w = 1;
	my $height_f = int( ( 20 * $ncol + $label_length * 14 ) * ($::config_obj->plot_size_codes / 480));
	if ($height_f < $::config_obj->plot_size_codes){
		$height_f = $::config_obj->plot_size_codes;
		$bs_h = (480 - $label_length * 14) / $ncol / 25;
	}
	
	# マップの幅
	$label_length = 0;
	foreach my $i (@col_names){
		my $t = Encode::encode('cp932', $i);
		if ( $label_length < length($t) ){
			$label_length = length($t);
		}
	}
	my $width_f = int( (18 * $nrow + $label_length * 14 + 25) * ($::config_obj->plot_size_words / 640) );
	if ($width_f < $::config_obj->plot_size_words){
		$width_f = $::config_obj->plot_size_words;
		$bs_w = (640 - 10 - $label_length * 14) / ($nrow + 1) / 25;
	}
	use List::Util 'min';
	my $bubble_size = int( min($bs_h, $bs_w) / ( $::config_obj->plot_font_size / 100 ) );
	
	&set_config_param($self,$bubble_size,$height_f,$width_f);
	
	
	# プロット作成
	my $plot;
	use screen_code::plugin_code_mat;
	#config_paramに設定項目をまとめているので、以下は呼び出す必要が無くなる
	#plot_size_maph      => $height_f, plot_size_mapw      => $width_f,
	#bubble_size         => $bubble_size,font_size           => $::config_obj->plot_font_size / 100,
	#以下の項目はヒートマップ用なので不要
	#heat_dendro_c       => 1,
	#heat_cellnote       => $nrow < 10 ? 1 : 0,
	#plot_size_heat      => $height,
	$plot = screen_code::plugin_code_mat->new(
		&get_config_param($self),
		r_command           => $rcom,
		plotwin_name        => 'code_mat',
		#plot_size_heat      => $height,
		selection           => $selection,
		row_sort            => $self->{row_sort},
		col_sort            => $self->{col_sort},
	);
	
	$wait_window->end(no_dialog => 1);
	
	#if ($::main_gui->if_opened('w_cod_mat_plot')){
	#	$::main_gui->get('w_cod_mat_plot')->close;
	#}
	
	return 0 unless $plot;
	
	#gui_window::r_plot::cod_mat->open(
	#	plots       => $plot->{result_plots},
	#	ax          => $ax,
	#	no_geometry => 1,
	#);
	
	$self->{plots} = $plot->{result_plots};
	$self->{plot_file_names} = $plot->{plot_file_names};
	$self->{plot_number} = $plot->{plot_number};

	write_display_data($self);
	my $rtn;
	while(1) {
		save_option($self);
		save_config($self);
		save_sort_file($self);
		$! = undef;
		$rtn = system(&screen_code::plugin_path::assistant_path, "6");
		$rtn = 0 if ($!) ; #systemでエラーがあった場合
		if (read_config($self)) {
			last;
		}
		if (read_sort_file($self)) {
			read_option($self);
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
		
	$self->{plots} = undef;
	$self->{plot_file_names} = undef;
	$self->{plot_number} = undef;


	$plot = undef;
	
	return $rtn;
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
		return ($self->{mode_o} eq "save");
	} else {
		return 0;
	}
}

sub save_option{
	my $self = shift;
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
	print $OUT "plot_file_names=$plot_file_names\n";
	print $OUT "plot_number=$plot_number\n";
	print $OUT "initial_display=$initial_display\n";
	print $OUT "font=$font_str\n";
	
	close($OUT);
}

sub read_sort_file{
	my $self = shift;
	my $file_sort = &screen_code::plugin_path::assistant_option_folder."cls_sort.txt";
	if (-f $file_sort) {
		open(my $IN, "<:encoding(utf8)", $file_sort);
		my $isChanged = 0;
		while (my $line = <$IN>) {
			my @splited = split(/=/, $line);
			my $temp = $splited[1];
			chomp($temp);
			if ($splited[0] eq "row_sort") {
				$isChanged = 1 if ($temp ne $self->{row_sort});
				$self->{row_sort} = $temp;
			} elsif ($splited[0] eq "col_sort") {
				$isChanged = 1 if ($temp ne $self->{col_sort});
				$self->{col_sort} = $temp;
			}
		}
		
		close($IN);
		unlink $file_sort if -f $file_sort;
		return $isChanged;
	} else {
		return 0;
	}
}

sub save_sort_file{
	my $self = shift;
	if ($self->{row_sort} || $self->{col_sort}) {
		my $file_sort = &screen_code::plugin_path::assistant_option_folder."cls_sort.txt";
		unlink $file_sort if -f $file_sort;
		open(my $OUT, ">:encoding(utf8)", $file_sort);
		my $row_sort = $self->{row_sort};
		my $col_sort = $self->{col_sort};
		print $OUT "row_sort=$row_sort\n";
		print $OUT "col_sort=$col_sort\n";
		
		close($OUT);
	}
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
			if ($splited[0] eq "bubble_size") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{bubble_size});
				$self->{config_param}->{bubble_size} = $temp;
			} elsif ($splited[0] eq "bubble_shape") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{bubble_shape});
				$self->{config_param}->{bubble_shape} = $temp;
			} elsif ($splited[0] eq "color_rsd") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{color_rsd});
				$self->{config_param}->{color_rsd} = $temp;
			} elsif ($splited[0] eq "color_fix") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{color_fix});
				$self->{config_param}->{color_fix} = $temp;
			} elsif ($splited[0] eq "color_maxv") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{color_maxv});
				$self->{config_param}->{color_maxv} = $temp;
			} elsif ($splited[0] eq "font_size") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{font_size});
				$self->{config_param}->{font_size} = $temp;
			} elsif ($splited[0] eq "plot_size_maph") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{plot_size_maph});
				$self->{config_param}->{plot_size_maph} = $temp;
			} elsif ($splited[0] eq "plot_size_mapw") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{plot_size_mapw});
				$self->{config_param}->{plot_size_mapw} = $temp;
			} elsif ($splited[0] eq "symbol_rate") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{symbol_rate});
				$self->{config_param}->{symbol_rate} = $temp;
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
	
	print $OUT "bubble_size=".$self->{config_param}->{bubble_size}."\n";
	print $OUT "bubble_shape=".$self->{config_param}->{bubble_shape}."\n";
	print $OUT "color_rsd=".$self->{config_param}->{color_rsd}."\n";
	print $OUT "color_fix=".$self->{config_param}->{color_fix}."\n";
	print $OUT "color_maxv=".$self->{config_param}->{color_maxv}."\n";
	print $OUT "font_size=".$self->{config_param}->{font_size}."\n";
	print $OUT "plot_size_maph=".$self->{config_param}->{plot_size_maph}."\n";
	print $OUT "plot_size_mapw=".$self->{config_param}->{plot_size_mapw}."\n";
	print $OUT "symbol_rate=".$self->{config_param}->{symbol_rate}."\n";

	close($OUT);
}

sub set_config_param{
	my $self = shift;
	my $bubble_size = shift;
	my $height_f = shift;
	my $width_f = shift;
	if (!defined($self->{config_param})) {
		$self->{config_param} = {
			'bubble_size'    => $bubble_size,
			'bubble_shape'   => 0,
			'color_rsd'      => 1,
			'color_fix'      => 0,
			'color_maxv'     => 10,
			'font_size'      => $::config_obj->plot_font_size / 100,
			'plot_size_maph' => $height_f,
			'plot_size_mapw' => $width_f,
			'symbol_rate'    => 100,
		};
	}
}

sub get_config_param{
	my $self = shift;
	return (
			'bubble_size'    => $self->{config_param}->{bubble_size},
			'bubble_shape'   => $self->{config_param}->{bubble_shape},
			'color_rsd'      => $self->{config_param}->{color_rsd},
			'color_fix'      => $self->{config_param}->{color_fix},
			'color_maxv'     => $self->{config_param}->{color_maxv},
			'font_size'      => $self->{config_param}->{font_size},
			'plot_size_maph' => $self->{config_param}->{plot_size_maph},
			'plot_size_mapw' => $self->{config_param}->{plot_size_mapw},
			'symbol_rate'    => $self->{config_param}->{symbol_rate},
		);
}

sub write_display_data{
	my $self = shift;
	
	$,="\t";
	my $DATAFILE;
	my $file_display = &screen_code::plugin_path::assistant_option_folder."crs_display.txt";
	unlink $file_display if -f $file_display;
	my $file_symbol = &screen_code::plugin_path::assistant_option_folder."crs_symbol.txt";
	unlink $file_symbol if -f $file_symbol;
	open($DATAFILE, ">:encoding(utf8)", $file_symbol);
	
	my $ary = $self->{result}{symbol};
	
	my @row_sort;
	my @col_sort;
	
	if (!($self->{row_sort})) {
		@row_sort = (1 .. int(@{$ary}));
	} else {
		@row_sort = split(/,/, $self->{row_sort});
	}
	if (!($self->{col_sort})) {
		@col_sort = (1 .. int(@{$ary->[0]}));
	} else {
		@col_sort = split(/,/, $self->{col_sort});
	}
	
	for (my $i = 0; $i < @row_sort; $i++) {
		for (my $j = 0; $j < @col_sort; $j++) {
			if ($j) {
				print $DATAFILE "\t";
			}
			print $DATAFILE $ary->[$row_sort[$i]-1][$col_sort[$j]-1];
		}
		print $DATAFILE "\n";
	}
	close($DATAFILE);
	
	$ary = $self->{result}{display_for_plugin};
	open($DATAFILE, ">:encoding(utf8)", $file_display);
	
	#並び替え対象の行以外に、先頭に見出し行、末尾に合計・統計情報がある(統計情報は増える可能性がある)
	unshift(@row_sort, 0);
	push @row_sort, (@row_sort .. @{$ary}-1);
	
	#並び替え対象の列以外に、先頭に見出し列、末尾にケース数がある
	unshift(@col_sort, 0);
	push @col_sort, (int(@col_sort));
	
	for (my $i = 0; $i < @row_sort; $i++) {
		for (my $j = 0; $j < @col_sort; $j++) {
			if ($j) {
				print $DATAFILE "\t";
			}
			print $DATAFILE $ary->[$row_sort[$i]][$col_sort[$j]];
		}
		print $DATAFILE "\n";
	}
	close($DATAFILE);
	$,="";
}
1;