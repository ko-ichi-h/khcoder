package screen_code::synonym_menu;
use strict;
use utf8;
use mysql_exec;

use screen_code::plugin_path;

#use encoding "cp932";
use gui_window::main::menu;
use File::Path;
use Encode qw/encode decode/;

sub add_menu_exec_plugin{
	my $self = shift;
	my $f = shift;
	my $menu1_ref = shift;
	
	if (-f &screen_code::plugin_path::synonym_path) {
		push @{$menu1_ref}, 'm_b2_synonym_plug';
			$self->{m_b2_synonym_plug} = $f->command(
			-label => kh_msg->get('screen_code::assistant->plugin_synonym'),
			-font => "TKFN",
			-command => sub{
				#バックアップテーブルが存在しない、もしくは作成以降に前処理が行われたか確認する
				my $check_result = checkDoPreprocess();
				#genkeiテーブルが存在しない場合は処理を行えないためエラーとする
				if ($check_result == -1) {
					print "プラグイン使用不可(前処理未実行)\n";
					return 0;
				}
				
				#バックアップテーブルを作成する
				create_backup_table() if ($check_result);
				
				my $t = mysql_exec->select('
					SELECT genkei_backup.name, genkei_backup.num, hselection.name, genkei_yomigana.yomigana
					FROM genkei_yomigana INNER JOIN genkei_backup ON genkei_yomigana.genkei_id = genkei_backup.id INNER JOIN hselection ON genkei_backup.khhinshi_id = hselection.khhinshi_id;',1)->hundle;
				
				my $row = 1;
				my @data = ();
				$data[0] = [
					"抽出語",
					"出現回数",
					"品詞",
					"よみがな"
				];
				while (my $i = $t->fetch){
					push @{$data[$row]}, $i->[0];
					push @{$data[$row]}, $i->[1];
					push @{$data[$row]}, $i->[2];
					push @{$data[$row]}, $i->[3];
					++$row;
				}
				
				my $worddata_file = &screen_code::plugin_path::assistant_option_folder."worddata.csv";
				unlink $worddata_file if -f $worddata_file;
				my $CSV_FILE;
				open ($CSV_FILE, '>:encoding(utf8)', $worddata_file) or return;

				foreach my $i (@data){
					my $c = 0;
					foreach my $h (@{$i}){
						print $CSV_FILE ',' if $c;
						print $CSV_FILE kh_csv->value_conv($h);
						++$c;
					}
					print $CSV_FILE "\n";
				}
				close ($CSV_FILE);
				
				my $previous_file = $::project_obj->dir_CoderData."prev_wordset.wset";
				my $filter_file = $::project_obj->dir_CoderData."type_filter.txt";
				my $font_str = gui_window->gui_jchar($::config_obj->font_main);
				$font_str =~ s/,.*//; #フォントサイズ情報は不要
				$font_str =~ tr/　！”＃＄％＆’（）＊＋，－．／０-９：；＜＝＞？＠Ａ-Ｚ［￥］＾＿｀ａ-ｚ｛｜｝/ -}/; #全角英字はコマンドラインで渡せないため一度半角に変換する
				
				my $plugin_rtn = -1;
				my $system_err = 0;
				$! = undef;
				$plugin_rtn = system(&screen_code::plugin_path::synonym_path, "$worddata_file", "$previous_file", "$filter_file", "$font_str");
				unlink $worddata_file;
				if ($plugin_rtn == 0) {
					print "プラグインのキャンセル\n";
					return 0;
				}
				$system_err = 1 if ($!);
				if ($system_err) {
					print "プラグインのエラー\n";
					return 0;
				}
				
				#my $temp_wordset = &screen_code::plugin_path::assistant_option_folder."temp_wordset";
				#unless (-f $temp_wordset) {$previous_file
				unless (-f $previous_file) {
					print "ワードセットファイルが存在しない\n";
					return 0;
				}
				read_wordset($previous_file);
				#unlink $temp_wordset;
				return(1);
			},
			-state => 'disable',
		);
	}
}

#バックアップテーブルが存在しない、もしくは作成以降に前処理が行われたか確認する
sub checkDoPreprocess{
	my $dbName = $::project_obj->dbname;
	return -1 unless mysql_exec->table_exists("$dbName.genkei"); #処理不能エラー
	
	my $check = mysql_exec->select("
		SELECT Create_time FROM information_schema.tables WHERE TABLE_SCHEMA = '$dbName' AND TABLE_NAME LIKE 'genkei_yomigana' ORDER BY Create_time DESC
	",1)->hundle;
	my $i = $check->fetch;
	return 1 unless $i; #バックアップテーブルが存在しないため作成の必要あり
	my $careta_genkei = $i->[0];
	
	$check = mysql_exec->select("
		SELECT Create_time FROM information_schema.tables WHERE TABLE_SCHEMA = '$dbName' AND TABLE_NAME LIKE 'hinshi'
	",1)->hundle;
	$i = $check->fetch;
	return 1 unless $i; #比較対象がない(この状況は起きない想定)
	my $do_prep = $i->[0];
	
	print "前処理実行日時：$do_prep バックアップ作成日時：$careta_genkei \n";
	if ($do_prep gt $careta_genkei ){
		return 1;
	} else {
		return 0;
	}
}

#バックアップテーブルを作成する
sub create_backup_table{
	my $dbName = $::project_obj->dbname;
	if (mysql_exec->table_exists("$dbName.genkei_backup")) {
		mysql_exec->do("DROP TABLE $dbName.genkei_backup",1);
	}
	mysql_exec->do("CREATE TABLE $dbName.genkei_backup LIKE $dbName.genkei",1);
	mysql_exec->do("INSERT INTO $dbName.genkei_backup SELECT * FROM $dbName.genkei",1);
	
	if (mysql_exec->table_exists("$dbName.hyoso_backup")) {
		mysql_exec->do("DROP TABLE $dbName.hyoso_backup",1);
	}
	mysql_exec->do("CREATE TABLE $dbName.hyoso_backup LIKE $dbName.hyoso",1);
	mysql_exec->do("INSERT INTO $dbName.hyoso_backup SELECT * FROM $dbName.hyoso",1);
	
	if (mysql_exec->table_exists("$dbName.genkei_yomigana")) {
		mysql_exec->do("DROP TABLE $dbName.genkei_yomigana",1);
	}
	my $t = mysql_exec->select('
		SELECT genkei.name, genkei.id
		FROM genkei INNER JOIN hselection ON genkei.khhinshi_id = hselection.khhinshi_id
		 WHERE 
		      hselection.name != "否定助動詞"
		  #and hselection.name != "未知語"
		  and hselection.name != "否定"
		  and hselection.name != "感動詞"
		  and hselection.name != "その他"
		  and hselection.name != "OTHER"
		  and hselection.name != "HTMLタグ"
		  and hselection.name != "HTML_TAG"
		  and hselection.ifuse = 1
		  and genkei.nouse = 0
	',1)->hundle;
	
	my $genkei_file = &screen_code::plugin_path::assistant_option_folder."plug4_origin.txt";
	my $analized_file = &screen_code::plugin_path::assistant_option_folder."plug4_katakana.txt";
	unlink $genkei_file if -f $genkei_file;
	unlink $analized_file if -f $analized_file;
	my $ORIGIN_FILE;
	my $code;
	if ($::config_obj->c_or_j eq 'chasen'){
		$code = 'encoding(shiftjis)';
	} elsif ($::config_obj->c_or_j eq 'mecab') {
		$code = 'encoding(utf8)';
	}
	open ($ORIGIN_FILE, ">:$code", $genkei_file) or return;
	
	my @id_order = ();
	while (my $i = $t->fetch){
		#否定形チェッカーとの連携を考える
		my $origin = $i->[0];
		$origin =~ s/\(.+\)$//g;
		print $ORIGIN_FILE $origin;
		print $ORIGIN_FILE "\n";
		push @id_order, $i->[1];
	}
	close ($ORIGIN_FILE);
	
	use kh_morpho;
	use kh_morpho::win32;
	use kh_morpho::linux;
	my $class = "kh_morpho";
	#print "class $class \n"; #kh_morpho
	$class .= '::'.$::config_obj->os;
	#print "class $class \n"; #kh_morpho::win32
	my %args = @_;
	my $dummy_self = {
		t_obj  => $::project_obj,
		target => $genkei_file,
		output => $analized_file,
		config => $::config_obj,
	};
	bless $dummy_self, $class;
	$dummy_self->_run;

	mysql_exec->do('
		CREATE TABLE genkei_yomigana(
			genkei_id INT primary key,
			yomigana CHAR(225)
		)',1);
	mysql_exec->do('
		INSERT INTO genkei_yomigana (genkei_id) 
		SELECT genkei.id
		FROM genkei INNER JOIN hselection ON genkei.khhinshi_id = hselection.khhinshi_id
		 WHERE 
		      hselection.name != "否定助動詞"
		  #and hselection.name != "未知語"
		  and hselection.name != "否定"
		  and hselection.name != "感動詞"
		  and hselection.name != "その他"
		  and hselection.name != "OTHER"
		  and hselection.name != "HTMLタグ"
		  and hselection.name != "HTML_TAG"
		  and hselection.ifuse = 1
		  and genkei.nouse = 0
		',1);
	
	my $FILE;
	open ($FILE, "<:$code", $analized_file) or return;
	my @splited;
	my $yomigana_temp;
	my $i = 0;
	while (my $line = <$FILE>) {
		chomp $line;
		if ($line =~ /EOS/) {
			$yomigana_temp = substr($yomigana_temp, 0, 225);
			mysql_exec->do("UPDATE genkei_yomigana SET yomigana = '$yomigana_temp' WHERE genkei_id = $id_order[$i]",1);
			
			$yomigana_temp = "";
			++$i;
		} else {
			@splited = split(/\t/, $line);
			$yomigana_temp = $yomigana_temp.$splited[1];
		}
	}
	close ($FILE);
	
	unlink $genkei_file if -f $genkei_file;
	unlink $analized_file if -f $analized_file;
	
	return(1);
}

sub add_menu_read_wordset{
	my $self = shift;
	my $f = shift;
	my $menu1_ref = shift;
	
	#if (-f &screen_code::plugin_path::rde_path) {
	if (0) {
		push @{$menu1_ref}, 'm_b2_synonym_read';
			$self->{m_b2_synonym_read} = $f->command(
			-label => 'use_synonym_read_wordset',
			-font => "TKFN",
			-command => sub{
			unless (mysql_exec->table_exists("genkei_backup")){
				print "genkeiバックアップテーブルが存在しない\n";
				return 0;
			}
			unless (mysql_exec->table_exists("hyoso_backup")) {
				print "hyosoバックアップテーブルが存在しない\n";
				return 0;
			}

			my @types = (
				["Text Files", '.txt' ],
				["All Files" , '*'    ]
			);
			my $path = $::main_gui->{win_obj}->getOpenFile(
				-filetypes  => \@types,
				-title      => 'screen_code::assistant->use_synonym_read_wordset', 
				-initialdir => gui_window->gui_jchar($::config_obj->cwd),
			);
			
			return 1 unless length($path);
			$path = gui_window->gui_jg_filename_win98($path);
			$path = gui_window->gui_jg($path);
			$path = $::config_obj->os_path($path);
			
			read_wordset($path);
			
			return 1;
			},
			-state => 'disable',
		);
	}
}

sub read_wordset{
	my $path = shift;
	my $config = {};
	my $FILE;
	open($FILE, "<:encoding(utf8)", $path);
	while (my $line = <$FILE>) {
		chop($line);
		my @temp_splited = split(/\t/, $line);
		next if @temp_splited != 2; #親子関係が記述されていない行は無視
		my $parent = $temp_splited[0];
		@temp_splited =  split(/,/, $temp_splited[1]);
		my @child_array;
		foreach my $i (@temp_splited){
			my @child_splited = split(/_/, $i);
			next if (@child_splited != 2); #原型_品詞 の形になっていないなら無視
			push(@child_array, {'genkei' => $child_splited[0], 'type' => $child_splited[1]});
		}
		$config->{$parent} = \@child_array if @child_array > 0;
	}
	
	#ワードセットが無い場合は初期状態に戻す処理とする
	#unless (%{$config}) {
	#	print "ワードセットファイルではないか、ワードセットが一件も存在しません \n";
	#	return 1;
	#}
	
	mysql_exec->do("DROP TABLE genkei",1);
	mysql_exec->do("CREATE TABLE genkei LIKE genkei_backup",1);
	mysql_exec->do("INSERT INTO genkei SELECT * FROM genkei_backup",1);
	
	mysql_exec->do("DROP TABLE hyoso",1);
	mysql_exec->do("CREATE TABLE hyoso LIKE hyoso_backup",1);
	mysql_exec->do("INSERT INTO hyoso SELECT * FROM hyoso_backup",1);
	

	# 親になる語（置換先の語）が存在するかどうかチェック
	
	#上記の例では「集約」が存在しないので、genkeiテーブル「失敗」行のname列が「集約」に置き換えられる
	#最初に見つかった親候補を置き換えるため、配列の先頭に出てくる「失敗」が対象になっている
	#keys関数によりハッシュのキー文字列をすべて取得する 上記の例の場合、$iに '友達' '愛に関連する語' 'ほげ' が入る
	#(品詞は見ていないがLIMIT1なので一件に絞られる 運が悪ければ間違った単語を原型としてしまうと思われる)
	foreach my $i (keys %{$config}){
		# 親を検索
		my @temp_splited = split(/_/, $i);
		my $parent_genkei = $temp_splited[0];
		my $parent_type = $temp_splited[1];
		#print "mother: $parent_genkei, $parent_type ";
		my $hdl2 = mysql_exec->select("
			SELECT genkei.id, genkei.num
			FROM   genkei INNER JOIN hselection ON genkei.khhinshi_id = hselection.khhinshi_id
			WHERE  genkei.name = '$parent_genkei' and hselection.name = '$parent_type'
			LIMIT 1
		",1)->hundle->fetch;

		if ($hdl2){            # 親あり
		} else {               # 親なし
			print "ng, ";
			my $child_id_exist = ''; #存在が確認された子のidを記憶し、親とする
			foreach my $h (@{$config->{$i}}){ # 親候補を探す
				
				my $child_genkei = $h->{'genkei'};
				my $child_type = $h->{'type'};
				#print "child: $child_genkei, $child_type ";
				
				my $hdl2 = mysql_exec->select("
					SELECT genkei.id, genkei.num
					FROM   genkei INNER JOIN hselection ON genkei.khhinshi_id = hselection.khhinshi_id
					WHERE  genkei.name = '$child_genkei' and hselection.name = '$child_type'
					LIMIT 1
				",1)->hundle->fetch;
				if ($hdl2){
					$child_id_exist = $h;
					last;
				}
			}
			if (length($child_id_exist)){                # 親候補あり
				my $temp_hdl = mysql_exec->select("
					SELECT khhinshi_id
					FROM   hselection 
					WHERE  name = '$parent_type'
				",1)->hundle->fetch;
				my $parent_hinshi_id = $temp_hdl->[0];
				mysql_exec->do("
					UPDATE genkei
					SET   genkei.name = '$parent_genkei', genkei.khhinshi_id = $parent_hinshi_id
					WHERE id = $child_id_exist
				",1);
				print "replaced\n";
			}
		}
	}

	# MySQLデータベース改変のために必要な情報を収集
	my ($hyoso, $genkei);
	foreach my $i (keys %{$config}){
		my @temp_splited = split(/_/, $i);
		my $parent_genkei = $temp_splited[0];
		my $parent_type = $temp_splited[1];
		# 親になる基本形のIDと出現数
		my $hdl = mysql_exec->select("
			SELECT genkei.id, genkei.num
			FROM   genkei INNER JOIN hselection ON genkei.khhinshi_id = hselection.khhinshi_id
			WHERE  genkei.name = '$parent_genkei' and hselection.name = '$parent_type'
			LIMIT 1
		",1)->hundle->fetch;

		next unless $hdl;

		$genkei->{$i}{'id'}  = $hdl->[0];
		$genkei->{$i}{'num'} = $hdl->[1];

		# 子ども達の表層語リスト
		my $sql = "
			SELECT hyoso.id
			FROM   genkei INNER JOIN hselection ON genkei.khhinshi_id = hselection.khhinshi_id INNER JOIN hyoso ON hyoso.genkei_id = genkei.id
			WHERE 
		";
		my $sql_w;
		my $n = 0;
		foreach my $h (@{$config->{$i}}){
			my $child_genkei = $h->{'genkei'};
			my $child_type = $h->{'type'};
			#print "child: $child_genkei, $child_type ";
			
			$sql_w .= " OR " if $n;
			$sql_w .= "(genkei.name = '$child_genkei' AND hselection.name = '$child_type')";
			++$n;
		}
		$sql = $sql .= "( $sql_w )";
		my $hdl = mysql_exec->select($sql,1)->hundle;
		#親単語ごとに子の hyoso.id のリストを作る
		while (my $h = $hdl->fetch){
			#print "\n hyoso_id $h->[0] \n";
			push @{$hyoso->{$i}}, $h->[0];
		}

		# 子ども達の出現数
		my $hdl = mysql_exec->select("
			SELECT sum(genkei.num)
			FROM   genkei INNER JOIN hselection ON genkei.khhinshi_id = hselection.khhinshi_id
			WHERE  $sql_w
		",1)->hundle->fetch;
		if ($hdl){
			$genkei->{$i}{add} = $hdl->[0];
		} else {
			$genkei->{$i}{add} = 0;
		}
	#print "add: $genkei->{$i}{add}\n";
	}
	
	# MySQLデータベースの改変を実行！
	foreach my $i (keys %{$config}){
	
		# 表層語テーブル
		#子の hyoso.id リストに載っているidの原型を親のものに変更している
		my $sql = '';
		$sql .= "
			UPDATE hyoso
			SET    genkei_id = $genkei->{$i}{id}
			WHERE 
		";
		my $n = 0;
		foreach my $h (@{$hyoso->{$i}}){
			$sql .= " OR " if $n;
			$sql .= "id = $h";
			++$n;
		}
		next unless $n;
		mysql_exec->do($sql,1);

		# 基本形テーブル (1)
		$sql = '';
		$sql .= "DELETE genkei FROM genkei INNER JOIN hselection ON genkei.khhinshi_id = hselection.khhinshi_id \n WHERE "; #子単語の行をすべて削除している これを下のように数だけ0にして残しておくと0除算によるエラーが出るため不適
		#$sql .= "UPDATE genkei SET num = 0\nWHERE ";
		my $n = 0;
		foreach my $h (@{$config->{$i}}){
			my $child_genkei = $h->{'genkei'};
			my $child_type = $h->{'type'};
			$sql .= " OR " if $n;
			$sql .= "(genkei.name = '$child_genkei' AND hselection.name = '$child_type')";
			++$n;
		}
		mysql_exec->do($sql,1);

		# 基本形テーブル (2)
		my $new_num = $genkei->{$i}{num} + $genkei->{$i}{add};
		$sql = '';
		$sql .= "
			UPDATE genkei
			SET    num = $new_num
			WHERE  id = $genkei->{$i}{id}
		";
		mysql_exec->do($sql,1);
	}

	#df_テーブルも更新する必要がある(渡す引数は仮のものでよい)
	my $dummy_self;
	mysql_ready::df->calc($dummy_self);

	$::main_gui->inner->refresh;

	return 1;
}

sub run_after_prep{
	my $previous_file = $::project_obj->dir_CoderData."prev_wordset.wset";
	#前回のワードセットがない場合は終了
	return unless -f $previous_file;
	#前処理実行後なのでこの時点でバックアップテーブルを作成する
	create_backup_table();
	#ファイルの一行目に特定の文言があれば、ワードセットを読み込む設定がなされているとする
	my $FILE;
	open($FILE, "<:encoding(utf8)", $previous_file);
	my $line;
	return unless $line = <$FILE>;
	if ($line =~ /#前処理後自動適用/) {
		print "前処理後自動適用\n";
		read_wordset($previous_file);
	}
	close($FILE);
}

1;