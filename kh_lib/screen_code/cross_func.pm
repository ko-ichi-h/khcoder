package screen_code::cross_func;
use strict;

use kh_cod::func;
use screen_code::plugin_path;

use utf8;
use File::Path;
use Clone qw(clone);
use Encode qw/encode decode/;

my $replace_flag;
my $version_num = 0;



sub checkPluginFileVersion{
	if ($version_num == 0) {
		my $rtn = system(&screen_code::plugin_path::assistant_path, "0");
		
		if ($rtn == 0) {
			$version_num =  1;
		} else {
			$version_num =  $rtn / 256;
		}
	}

	return $version_num;
}

sub add_menu{
	if (-f &screen_code::plugin_path::assistant_path) {
		my $self = shift;
		my $rf = shift;
		unless ($replace_flag) {
			$replace_flag = 1;
			*kh_cod::func::outtab = \&outtab;
			*kh_cod::func::tab = \&tab;
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

#----------------------------#
#   章・節・段落ごとの集計   #

sub tab{
	my $self  = shift;
	my $tani1 = shift;
	my $tani2 = shift;
	my $cell  = shift;
	
	$self->code($tani1) or return 0;
	unless ($self->valid_codes){ return 0; }
	$self->cumulate if @{$self->{valid_codes}} > 29;
	
	# 集計用SQL文の作製
	my $sql;
	$sql .= "SELECT $tani2.id, ";
	foreach my $i (@{$self->{valid_codes}}){
		$sql .= "sum( IF(".$i->res_table.".".$i->res_col.",1,0) ),";
	}
	$sql .= " count(*) \n";
	$sql .= "FROM $tani1\n";
	foreach my $i (@{$self->tables}){
		$sql .= "LEFT JOIN $i ON $tani1.id = $i.id\n";
	}
	$sql .= "LEFT JOIN $tani2 ON ";
	my ($flag1,$n);
	foreach my $i ("bun","dan","h5","h4","h3","h2","h1"){
		if ($tani2 eq $i){
			$flag1 = 1;
		}
		if ($flag1){
			if ($n){$sql .= " AND ";}
			$sql .= "$tani1.$i".'_id = '."$tani2.$i".'_id ';
			++$n;
		}
	}
	$sql .= "\n";
	$sql .= "\nGROUP BY ";
	my $flag2 = 0;
	foreach my $i ("bun","dan","h5","h4","h3","h2","h1"){
		if ($tani2 eq $i){
			$flag2 = 1;
		}
		if ($flag2){
			$sql .= "$tani1.$i".'_id,';
		}
	}
	chop $sql;
	$sql .= "\nORDER BY $tani2.id";
	
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
	push @head, kh_msg->get('kh_cod::func->n_cases'); # ケース数
	push @result, \@head;

	# 中身
	my @sum = ( kh_msg->get('kh_cod::func->total') ); # 合計
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
		
		unless ( length($i->[0]) ){next;}
		foreach my $h (@c){
			if ($n == 0){                         # 行ヘッダ
				if (index($tani2,'h') == 0){
					my $t_name = gui_window->gui_jchar( # Decoding
						mysql_getheader->get($tani2, $h),
						'cp932'
					);
					push @current, $t_name;
					push @current_for_plot, $t_name;
				} else {
					push @current, $h;
					push @current_for_plot, $h;
				}
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
		push @for_plot,  \@current_for_plot;
		
		#SCREEN Plugin
		push @arr_temp, $nd;
		push @arr, \@arr_temp if @arr_temp;
	}
	# 合計行
	print "kh_cod tab(Monkin) sum\n".join("\n", @sum)."\n";
	my @c = @sum;
	my @current;
	my @arr_retsu; #SCREEN Plugin
	$n = 0;
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
	#「合計」行を追加する前にp値の計算処理をRで行うべきか
	push @arr_retsu, $total;
	push @arr, \@arr_retsu;
	
	# chi-square test
	my ($chisq, $rsd, $chisq_value_array, $col_p_value_array, $cell_p_value_array) = _chisq_test(\@current, \@for_chisq);
	push @result, $chisq if $chisq;

	my $ret;
	$ret->{display} = \@result;
	$ret->{plot}    = \@for_plot;
	$ret->{t_rsd}   = $rsd;
	$ret->{chisq_value_array} = $chisq_value_array;
	$ret->{col_p_value_array} = $col_p_value_array;
	$ret->{cell_p_value_array} = $cell_p_value_array;

	#SCREEN Plugin
	&screen_code::cross_func::func_ratio($ret,\@arr);
	#SCREEN Plugin
	
	return $ret;
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
	my @current;
	my @arr_retsu; #SCREEN Plugin
	my $n = 0;
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
	my ($chisq, $rsd, $chisq_value_array, $col_p_value_array, $cell_p_value_array, $ESw_array, $fisher_array) = _chisq_test(\@current, \@for_chisq);
	push @result, $chisq if $chisq;
	
	my $ret;
	$ret->{display}  = \@result;
	$ret->{plot}     = \@for_plot;
	$ret->{t_rsd}    = $rsd;
	$ret->{chisq_value_array} = $chisq_value_array;
	$ret->{col_p_value_array} = $col_p_value_array;
	$ret->{cell_p_value_array} = $cell_p_value_array;
	$ret->{ESw_array} = $ESw_array;
	$ret->{fisher_array} = $fisher_array;

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
			} elsif ($temp >= 1.65) {
				push @symbol_temp, "90";
			} elsif ($temp <= -2.58) {
				push @symbol_temp, "1";
			} elsif ($temp <= -1.96) {
				push @symbol_temp, "5";
			} elsif ($temp <= -1.65) {
				push @symbol_temp, "10";
			} else {
				push @symbol_temp, "";
			}
			$col_num++;
		}
		push @hiritsu_array, \@rowary;
		push @symbol_array, \@symbol_temp;
		$row_num++;
	}
	
	#記号ありのカイ二乗値は削除
	pop @result_;
	push @result_, $ret->{chisq_value_array};
	push @result_, $ret->{col_p_value_array};
	push @result_, $ret->{ESw_array};
	push @result_, $ret->{fisher_array};
	
	$ret->{hrt} = \@hiritsu_array;
	$ret->{symbol} = \@symbol_array;
	$ret->{display_for_plugin} = \@result_;
}


#列ごとのカイ二乗値とp値を追加で取得するため、kh_cod::func::_chisq_test()を変更する必要がある
sub _chisq_test{
	my @current   = @{$_[0]};
	my @for_chisq = @{$_[1]};
	
	my @chisq = ();
	my @rsd   = ();
	my @chisq_value_array = ();#有意水準の記号をつけていないカイ二乗値を保存
	my @col_p_value_array = ();#列ごとのp値を保存
	my @cell_p_value_array = ();#各セルのp値を保存
	my @ESw_array = ();#列ごとの効果量を保存
	my @fisher_array = ();#フィッシャーの正確検定を保存
	
	my $R_debug = 0;
	if ($::config_obj->R){
		@chisq = ( kh_msg->get('kh_cod::func->chisq') ); # カイ2乗値
		@chisq_value_array = ( kh_msg->get('kh_cod::func->chisq') ); # カイ2乗値
		@col_p_value_array = ( kh_msg->get('screen_code::assistant->p_value') ); # 有意確率
		@ESw_array = ( kh_msg->get('screen_code::assistant->ESw') ); # 効果量
		@fisher_array = ( kh_msg->get('screen_code::assistant->fisher') ); # フィッシャーの正確検定
		my $n = @current - 2;
		$::config_obj->R->lock;
		for (my $c = 0; $c < $n; ++$c){
			my $cmd = 'dosu <- matrix( c(';
			my $nrow = 0;
			foreach my $i (@for_chisq){
				$cmd .= "$i->[$c][0],";
				$cmd .= "$i->[$c][1], ";
				++$nrow;
			}
			chop $cmd; chop $cmd;
			$cmd .=  "), nrow=$nrow, ncol=2, byrow=TRUE)\n";
			$cmd .=  "chi <- chisq.test(dosu, correct=TRUE)\n";
			$cmd .=  "N <- sum( dosu )\n";

			# 残差・調整済み残差・p値も取得
			$cmd .= '
				c_rsd <- paste(chi$statistic,chi$p.value,sep="=")
				for (i in 1:nrow(chi$residuals)){
					c_rsd <- paste(c_rsd, chi$residuals[i,1],sep="=")
				}
				for (i in 1:nrow(chi$stdres)){
					c_rsd <- paste(c_rsd, chi$stdres[i,1],sep="=")
				}
				for (i in 1:nrow(chi$stdres)){
					c_rsd <- paste(c_rsd, pnorm(abs(chi$stdres[i,1]), lower.tail=FALSE)*2,sep="=")
				}
				print ( paste( "khc", c_rsd, "khcend", sep="=" ))
				options(scipen=2)
				kai2 <- chi$sta
				ESw <- round(sqrt( kai2/N ),5)
				print ( paste( "ESw", ESw, "ESwend", sep="=" ))
				fisTest <- fisher.test( dosu )
				fis <- round(fisTest$p.v, 4)
				print ( paste( "fis", fis, "fisend", sep="=" ))
			';
			print "send: $cmd ..." if $R_debug;
			$::config_obj->R->send($cmd);

			my $rtnTemp = $::config_obj->R->read();
			my $rtn = $rtnTemp;
			#カイ二乗値とp値を計算しているので、この結果を変数で持っておけばプラグインに渡すことができる
			if ($rtn =~ /khc=(.+)=khcend/){
				$rtn = $1;
				my @rtnarray = split /=/, $rtn;
				
				# カイ二乗値
				my $stat    = shift @rtnarray;
				my $p_value = shift @rtnarray;
				
				my @rtn_rsd = splice(@rtnarray, 0, $nrow);
				my @rtn_srdres = splice(@rtnarray, 0, $nrow);
				my @rtn_p = splice(@rtnarray, 0, $nrow);
				
				if ( $stat =~ /na/i ){
					push @chisq, 'na';
				} else {
					$stat =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
					$stat =~ s/ //g;
					$stat = sprintf("%.3f", $stat);
					
					push @chisq_value_array, $stat;
					push @col_p_value_array, sprintf('%.3f', $p_value);
					if ($stat > 0){
						if ($p_value < 0.01){
							$stat .= '**';
						}
						elsif ($p_value < 0.05){
							$stat .= '*';
						}
						elsif ($p_value < 0.10){
							$stat .= '†';
						}
					}
					push @chisq, $stat;
				}
				
				push @rsd, \@rtn_rsd;
				#@cell_p_value_arrayは出力処理のため行→列である必要があり、このデータは一列のデータであるため、入れ方を考える必要がある
				#行数分の配列がないなら先に追加する
				my $length = @cell_p_value_array;
				while ($length < $nrow) {
					my @void_ary = ();
					push @cell_p_value_array, \@void_ary;
					$length = @cell_p_value_array;
				}
				for (my $row = 0; $row < $nrow; ++$row) {
					push @{$cell_p_value_array[$row]}, sprintf('%.3f', $rtn_p[$row]);
				}
			} else {
				warn "Could not read the output of R.\n$rtn\n";
				push @chisq, '---';
			}
			
			$rtn = $rtnTemp;
			if ($rtn =~ /ESw=(.+)=ESwend/){
				$rtn = $1;
				push @ESw_array, $rtn
				#print $rtn." ESw\n";
			}
			
			$rtn = $rtnTemp;
			if ($rtn =~ /fis=(.+)=fisend/){
				$rtn = $1;
				push @fisher_array, $rtn
				#print $rtn." fis\n";
			}
		}
		$::config_obj->R->unlock;
		push @chisq, ' ';
	}
	
	return (\@chisq, \@rsd, \@chisq_value_array, \@col_p_value_array, \@cell_p_value_array, \@ESw_array, \@fisher_array);
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
	
	print "calc_plugin_loop start\n";
	delete $self->{row_sort};
	delete $self->{col_sort};
	
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
		print "plot_plugin no result return 0\n";
		return 0;
	}
	#プラグインによる計算で必要なデータがあるか確認
	unless ($self->{result}{hrt}){
		print "plot_plugin no hrt return 0\n";
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
	my $threshold;
	if (!defined($self->{config_param})) {
		$threshold = &screen_code::plugin_path::read_inifile("report_threshold", 0.05);
	} else {
		$threshold = $self->{config_param}->{threshold};
	}
	
	foreach my $col_p_value (@{$self->{result}{col_p_value_array}}){
		my $temp = "";
		if ($col_p_value < 0.01 && $col_p_value < $threshold){
			$temp .= ' **';
		}
		elsif ($col_p_value < 0.05 && $col_p_value < $threshold){
			$temp .= ' *';
		}
		elsif ($col_p_value < 0.10 && $col_p_value < $threshold){
			$temp .= '†';
		}
		else {
			$temp .= ' n.s.';
		}
		push @p_symbol, $temp;
	}
	#先頭を削除
	shift @p_symbol;
	
	#foreach my $i (@last_row){
	#	my $temp = "";
	#	if ($i =~ /\*\*/) {
	#		$temp = "p<.01 **"
	#	} elsif ($i =~ /\*/) {
	#		$temp = "p<.05 *"
	#	} else {
	#		$temp = "n.s."
	#	}
	#	push @p_symbol, $temp;
	#}
	#先頭と末尾を削除
	#shift @p_symbol; pop @p_symbol;
	
	$rcom .= "p_symbol <- c(";
	foreach my $i (@p_symbol){
		$rcom .= "\"$i\",";
	}
	chop $rcom;
	$rcom .= ")\n";
	$rcom .= "colnames(d) <- paste(colnames(d), p_symbol)\n";
	
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
	#my $bubble_size = int( min($bs_h, $bs_w) / ( $::config_obj->plot_font_size / 100 ) );
	my $bubble_size = int( min($bs_h, $bs_w) / ( $::config_obj->plot_font_size / 100 ) * 10 ) / 10;
	
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
			} elsif ($splited[0] eq "threshold") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{threshold});
				$self->{config_param}->{threshold} = $temp;
			} elsif ($splited[0] eq "displayLevel") {
				$isChanged = 1 if ($temp ne $self->{config_param}->{displayLevel});
				$self->{config_param}->{displayLevel} = $temp;
			}
		}
		
		#プラグインで設定されたコンフィグを読み込んだ時点で、p値の設定をiniファイルに記録する
		&screen_code::plugin_path::save_inifile("report_threshold", $self->{config_param}->{threshold});
		&screen_code::plugin_path::save_inifile("report_displayLevel", $self->{config_param}->{displayLevel});
		
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
	print $OUT "threshold=".$self->{config_param}->{threshold}."\n";
	print $OUT "displayLevel=".$self->{config_param}->{displayLevel}."\n";

	close($OUT);
}

sub set_config_param{
	my $self = shift;
	my $bubble_size = shift;
	my $height_f = shift;
	my $width_f = shift;
	#iniファイルからp値の設定を取得
	my $threshold_default = &screen_code::plugin_path::read_inifile("report_threshold", 0.05);
	my $displayLevel_default = &screen_code::plugin_path::read_inifile("report_displayLevel", 0);
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
			'threshold'      => $threshold_default,
			'displayLevel'   => $displayLevel_default,
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
			'threshold'      => $self->{config_param}->{threshold},
			'displayLevel'   => $self->{config_param}->{displayLevel},
		);
}

sub write_display_data{
	my $self = shift;
	
	$,="\t";
	my $DATAFILE, my $PVALEUFILE, my $SYMBOLFILE;
	my $file_display = &screen_code::plugin_path::assistant_option_folder."crs_display.txt";
	unlink $file_display if -f $file_display;
	my $file_p_value = &screen_code::plugin_path::assistant_option_folder."crs_p_value.txt";
	unlink $file_p_value if -f $file_p_value;
	my $file_symbol = &screen_code::plugin_path::assistant_option_folder."crs_symbol.txt";
	unlink $file_symbol if -f $file_symbol;
	
	open($PVALEUFILE, ">:encoding(utf8)", $file_p_value);
	open($SYMBOLFILE, ">:encoding(utf8)", $file_symbol);
	
	my $p_value_ary = $self->{result}{cell_p_value_array};
	my $symbol_ary = $self->{result}{symbol};
	
	my @row_sort;
	my @col_sort;
	
	#ソート配列は1から開始する番号の配列
	if (!($self->{row_sort})) {
		@row_sort = (1 .. int(@{$symbol_ary}));
	} else {
		@row_sort = split(/,/, $self->{row_sort});
	}
	if (!($self->{col_sort})) {
		@col_sort = (1 .. int(@{$symbol_ary->[0]}));
	} else {
		@col_sort = split(/,/, $self->{col_sort});
	}
	
	for (my $i = 0; $i < @row_sort; $i++) {
		for (my $j = 0; $j < @col_sort; $j++) {
			#1列目以外は間にタブを入れる
			if ($j) {
				print $SYMBOLFILE "\t";
				print $PVALEUFILE "\t";
			}
			#シンボルやp値の配列と、表示データの配列で、見出しの有無がことなるため、配列中の位置を指すために番号-1する
			print $SYMBOLFILE $symbol_ary->[$row_sort[$i]-1][$col_sort[$j]-1];
			print $PVALEUFILE $p_value_ary->[$row_sort[$i]-1][$col_sort[$j]-1];
		}
		print $SYMBOLFILE "\n";
		print $PVALEUFILE "\n";
	}
	close($SYMBOLFILE);
	close($PVALEUFILE);
	
	my $data_ary = $self->{result}{display_for_plugin};
	open($DATAFILE, ">:encoding(utf8)", $file_display);
	
	#並び替え対象の行以外に、先頭に見出し行、末尾に合計・統計情報がある(統計情報は増える可能性がある)
	#最初にある見出しや通常データ行以降はそのままにするため、ソート配列の先頭と末尾にそのままの数値の並びを追加する
	#「@変数名」で配列のサイズの値を取れる ソート配列のサイズ＝先に0を追加しているため最後の数＋１が取れる
	#つまり通常データ行＋１から統計情報の終わる行まで順番の数値の並びとなる
	unshift(@row_sort, 0);
	push @row_sort, (@row_sort .. @{$data_ary}-1);
	
	#並び替え対象の列以外に、先頭に見出し列、末尾にケース数がある
	unshift(@col_sort, 0);
	push @col_sort, (int(@col_sort));
	
	#旧バージョン対応
	my $versionRevise = 0;
	if (checkPluginFileVersion == 1) {
		$versionRevise = 3;
	}
	for (my $i = 0; $i < @row_sort - $versionRevise; $i++) {
		for (my $j = 0; $j < @col_sort; $j++) {
			#1列目以外は間にタブを入れる
			if ($j) {
				print $DATAFILE "\t";
			}
			print $DATAFILE $data_ary->[$row_sort[$i]][$col_sort[$j]];
		}
		print $DATAFILE "\n";
	}
	close($DATAFILE);
	$,="";
}
1;