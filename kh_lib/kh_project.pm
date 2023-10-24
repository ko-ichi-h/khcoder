use utf8;

package kh_project;
use strict;
use File::Basename;
use DBI;
use mysql_exec;

sub new{
	my $class = shift;
	my %args = @_;
	my $self = \%args;
	bless $self, $class;
	
	unless (-e $self->file_target){
		gui_errormsg->open(
			type   => 'msg',
			msg    => kh_msg->get('no_target_file'), # 分析対象ファイルが存在しません
		);
		return 0;
	}
	
	return $self;
}

sub copy_and_convert_target_file{ # into inner structure
	my $self = shift;
	my %args = @_;
	
	# Copy
	my $original = $args{original};

	my $suf;
	if ($original =~ /(\.[a-zA-Z]+?)$/) {
		$suf = $1;
	}
	my $copied   = $self->file_datadir.'_tgt'.$suf;
	
	use File::Copy;
	copy($original, $copied) or
		gui_errormsg->open(
			type => 'file',
			thefile => $original,
		)
	;
	print "Specified target file is copied to: $copied\n";
	$self->status_source_file( $::config_obj->uni_path($original) );
	$self->status_copied_file( $::config_obj->uni_path($copied) );

	# Convert Excel
	my $t = $copied;
	if ($t =~ /(.+)\.(xls|xlsx|csv|tsv)$/i){
		# name of the new text file
		my $n = 0;
		while (-e $1."_txt$n.txt"){
			++$n;
		}
		my $file_text = $1."_txt$n.txt";
		
		# name of the new variable file
		$n = 0;
		while (-e $1."_var$n.txt"){
			++$n;
		}
		my $file_vars = $1."_var$n.txt";

		# make files
		my $sheet_obj = kh_spreadsheet->new($t);
		$sheet_obj->save_files(
			filet    => $file_text,
			filev    => $file_vars,
			selected => $args{column},
			lang     => $args{lang},
			#icode    => $self->{icode},
		);

		unless (-e $file_text){
			gui_errormsg->open(
				msg => kh_msg->get('gui_window::project_new->type_error'),
				type => 'msg',
				#window => \$self->{win_obj},
			);
			return 0;
		}

		# read variables
		mysql_outvar::read::tab->new(
			file        => $file_vars,
			tani        => 'h5',
			skip_checks => 1,
			icode       => 'utf8',
		)->read if -e $file_vars;

		# ignoring the separator string
		mysql_exec->do("
			INSERT INTO dmark (name) VALUES ('---cell---')
		",1);
		mysql_exec->do("
			INSERT INTO dstop (name) VALUES ('---cell---')
		",1);

		$self->last_tani('h5');
		$self->assigned_icode('utf8');
		$self->status_from_table(1);
		$self->status_var_file( $::config_obj->uni_path($file_vars) );
		$self->status_selected_coln( gui_window->gui_bmp($args{column_list}[$args{column}]) );
		$self->status_converted_file( $::config_obj->uni_path($file_text) );
	} else {
		$self->status_from_table(0);
	}
	
	# Convert Word/RTF files to plain text
	if (
		   $t =~ /(.+)\.docx$/i
		|| $t =~ /(.+)\.doc$/i
		|| $t =~ /(.+)\.rtf$/i
		|| $t =~ /(.+)\.odt$/i
	){
		use kh_docx;
		my $c = kh_docx->new($t);
		$c->conv;
		
		unless (-e $c->{converted}){
			gui_errormsg->open(
				msg => kh_msg->get('gui_window::project_new->type_error'),
				type => 'msg',
				#window => \$self->{win_obj},
			);
			return 0;
		}
		
		$self->status_converted_file( $::config_obj->uni_path($c->{converted}) );
	}
	
	return 1;
}

sub prepare_db{
	my $self   = shift;
	$self->{dbname} = mysql_exec->create_new_db($self->file_target);
	$self->{dbh} = mysql_exec->connect_db($self->{dbname});
	$::project_obj = $self;
	
	# 辞書テーブル
	mysql_exec->do('create table dmark ( name varchar(200) not null )',1);
	mysql_exec->do('create table dstop ( name varchar(200) not null )',1);
	# 状態テーブルの作成
	mysql_exec->do('
		create table status (
			name   varchar(200) not null,
			status INT not null
		)
	',1);
	mysql_exec->do("
		INSERT INTO status (name, status)
		VALUES ('morpho',0),('bun',0),('dan',0),('h5',0),('h4',0),('h3',0),('h2',0),('h1',0)
	",1);
	mysql_exec->do('
		create table status_char (
			name   varchar(255) not null,
			status text
		)
	',1);
	my $icode = '';
	$icode = $self->{icode} if defined($self->{icode});
	mysql_exec->do("
		INSERT INTO status_char (name, status)
		VALUES ('last_tani',''),('last_codf',''),('icode','$icode')
	",1);

	# 外部変数用のテーブルを準備
	mysql_exec->do("create table outvar
		(
			name varchar(255) not null,
			tab varchar(255) not null,
			col varchar(255) not null,
			tani varchar(10) not null,
			id int auto_increment primary key not null
		)
	",1);

	mysql_exec->do("create table outvar_lab
		(
			var_id int not null,
			val varchar(255) not null,
			lab varchar(255) not null,
			id int auto_increment primary key not null
		)
	",1);

	# 情報入力
	my $target = $::config_obj->uni_path( $self->file_target );
	mysql_exec->do("
		INSERT INTO status_char (name,status)
		VALUES (\"target\", \"$target\")
	",1);

	mysql_exec->do("
		INSERT INTO status_char (name,status)
		VALUES (\"comment\", \"".$self->comment."\")
	",1);

	# データディレクトリが無かった場合は作成
	print "Data dir: ".$self->dir_CoderData."\n";
	unless (-d $self->dir_CoderData){
		mkdir $self->dir_CoderData or die;
	}
}

sub read_hinshi_setting{
	my $self = shift;
	
	my $dbh_csv = DBI->connect("dbi:CSV:", undef, undef, {
		f_dir      => "./config",
		f_encoding => "UTF8",
		csv_eol    => "\n",
	}) or die;;

	# 品詞設定の読み込み
	my $sql = "SELECT hinshi_id,kh_hinshi,condition1,condition2 FROM hinshi_";
	$sql .= Encode::encode( 'ascii', $::config_obj->c_or_j );

	# Stanford POS TaggerとFreeLingの場合は言語ごとに異なる品詞設定ファイルを読む
	if (
		   $::config_obj->c_or_j eq 'stanford'
		|| $::config_obj->c_or_j eq 'freeling'
	){
		$sql .= Encode::encode( 'ascii', '_'.$::project_obj->morpho_analyzer_lang);
	}

	my $h = $dbh_csv->prepare($sql) or
		gui_errormsg->open(
			type => 'file',
			thefile => $sql,
		);
	$h->execute or
		gui_errormsg->open(
			type => 'file',
			thefile => $sql,
		);
	my $hinshi = $h->fetchall_arrayref or
		gui_errormsg->open(
			type => 'file',
			thefile => $sql,
		);

	# プロジェクト内の既存の品詞選択を取得
	my %current = ();
	if ( mysql_exec->table_exists('hselection') ){
		my $h =
			mysql_exec->select('SELECT name, ifuse FROM hselection')->hundle;
		while (my $i = $h->fetch){
			$current{$i->[0]} = $i->[1];
		}
	}

	# プロジェクト内へコピー(1)
	mysql_exec->drop_table('hselection');
	mysql_exec->do('
		create table hselection(
			khhinshi_id int primary key not null,
			ifuse       int,
			name        varchar(20) not null
		)
	',1);
	$sql = "INSERT INTO hselection (khhinshi_id,ifuse,name)\nVALUES ";
	my %temp_h = ();
	
	# morpho_analyzer
	my $other_hinshi = 'OTHER';
	if (
		   $::config_obj->c_or_j eq 'chasen'
		|| $::config_obj->c_or_j eq 'mecab'
	){
		$other_hinshi = 'その他';
	}
	
	foreach my $i (@{$hinshi}, [9999,$other_hinshi]){
		# 2重にInsertしないようにチェック
		if ($temp_h{$i->[0]}){
			next;
		} else {
			$temp_h{$i->[0]} = 1;
		}
		# 使う設定にするかどうか
		my $val = 1;
		if ( defined($current{$i->[1]}) ){
			$val = $current{$i->[1]};
		} else {
			$val = 0 if $i->[1] eq "HTMLタグ" || $i->[1] eq "HTML_TAG";
			$val = 0 if $i->[1] eq "その他"   || $i->[1] eq "OTHER";
			$val = 0 if $i->[1] eq "代名詞"
		}
		$sql .= "($i->[0],$val,'$i->[1]'),";
	}
	chop $sql;
	mysql_exec->do($sql,1);

	# プロジェクト内へコピー(2)
	mysql_exec->drop_table('hinshi_setting');
	mysql_exec->do('
		create table hinshi_setting(
			khhinshi_id int not null,
			khhinshi    varchar(255) not null,
			condition1  varchar(255) not null,
			condition2  varchar(255)
		)
	',1);
	$sql = "INSERT INTO hinshi_setting (khhinshi_id,khhinshi,condition1,condition2)\nVALUES ";
	foreach my $i (@{$hinshi}){
		$sql .= "($i->[0],'$i->[1]','$i->[2]','$i->[3]'),";
	}
	chop $sql;
	mysql_exec->do($sql,1);

	return 1;
}


sub temp{
	my $class = shift;
	my %args = @_;
	my $self = \%args;
	bless $self, $class;
	return $self;
}

sub open{
	my $self = shift;
	
	# open DB
	$self->{dbh} = mysql_exec->connect_db($self->{dbname}, $::config_obj->web_if);
	$::project_obj = $self;
	
	# check the target file
	$self->check_copied_and_converted;
	unless (-e $::config_obj->os_path( $self->file_target ) ){
		gui_errormsg->open(
			type   => 'msg',
			msg    => kh_msg->get('no_target_file')
		);
		return 0;
	}
	
	# reset font settings of R
	$kh_r_plot::if_font = 0;

	my_threads->open_project;
	
	$self->check_up;
	$::config_obj->c_or_j( $self->morpho_analyzer );
	
	return $self;
}

sub check_copied_and_converted{
	my $self = shift;
	
	if ( $self->status_copied_file() ){
		$self->{target} = $self->status_copied_file();
	}
	
	if ( $self->status_converted_file() ){
		$self->{target} = $self->status_converted_file();
	}
	
	return $self;
}


sub morpho_analyzer{
	my $self = shift;
	my $v = shift;
	
	my $name = $self->dbname.'.';
	
	if (defined($v)){
		mysql_exec->do("
			DELETE
			FROM   $name"."status_char
			WHERE  name = \"morpho_analyzer\"
		",1);
		mysql_exec->do("
			INSERT INTO $name"."status_char (name, status)
			VALUES (\"morpho_analyzer\", \"$v\")
		",1);
		$::config_obj->c_or_j($v);
		return $v;
	}
	
	my $h = mysql_exec->select("
		SELECT status FROM $name"."status_char WHERE name = \"morpho_analyzer\"
	",0)->hundle;
	
	unless ($h->rows){
		return ' MySQL Error';
	}
	my $r;
	unless ($r = $h->fetch){
		return ' MySQL Error';
	}
	return $r->[0];
}

sub morpho_analyzer_lang{
	my $self = shift;
	my $v = shift;
	
	my $name = $self->dbname.'.';
	
	if (defined($v)){
		mysql_exec->do("
			DELETE
			FROM   $name"."status_char
			WHERE  name = \"morpho_analyzer_lang\"
		",1);
		mysql_exec->do("
			INSERT INTO $name"."status_char (name, status)
			VALUES (\"morpho_analyzer_lang\", \"$v\")
		",1);
		return $v;
	}
	
	my $h = mysql_exec->select("
		SELECT status FROM $name"."status_char WHERE name = \"morpho_analyzer_lang\"
	",0)->hundle;
	
	
	unless ($h->rows){
		return ' MySQL Error';
	}
	my $r;
	unless ($r = $h->fetch){
		return ' MySQL Error';
	}
	return $r->[0];
}

sub spacer{
	my $self = shift;
	my $spacer = '';
	if (
		   $self->morpho_analyzer_lang eq 'jp'
		|| $self->morpho_analyzer_lang eq 'cn'
		|| $self->morpho_analyzer_lang eq 'kr'
	) {
		$spacer = '';
	} else {
		$spacer = ' ';
	}
	return $spacer;
}

# To sort Japanese words in the same order as prvious version (2.x)
sub mysql_sort{
	my $self = shift;
	my $t = shift;
	
	if ( $self->morpho_analyzer_lang eq 'jp' ) {
		return "CONVERT($t USING ujis)";
	} else {
		return $t;
	}
}

sub check_up{
	my $self = shift;
	
	# Create temp dir
	mkdir($self->dir_CoderData) unless -d $self->dir_CoderData;
	
	# For projects created by 3.alpha.06b or prior
	if (
		   mysql_exec->table_exists('bun')
		&! mysql_exec->table_exists('bun_length_nouse')
	){
		&mysql_ready::zero_length_headings;
	}

	# Delete temporarily files
	my $n;
	$n = 0;
	while (-e $self->file_datadir.'_temp'.$n.'.csv'){
		unlink($self->file_datadir.'_temp'.$n.'.csv');
		++$n;
	}
	$n = 0;
	while (-e $self->file_datadir.'_temp'.$n.'.xls'){
		unlink($self->file_datadir.'_temp'.$n.'.xls');
		++$n;
	}

}


#--------------#
#   アクセサ   #
#--------------#

# 開いていない（かもしれない）プロジェクトの言語・抽出方法を設定
sub lang_method{
	my $self       = shift;
	my $new_lang   = shift;
	my $new_method = shift;

	my $method = $self->morpho_analyzer($new_method);
	my $lang   = $self->morpho_analyzer_lang($new_lang);

	return [$lang, $method];
}


sub assigned_icode{
	my $self = shift;
	my $new = shift;
	my $r = 0;
	
	# プロジェクトを一時的に開く
	my $tmp_open;
	my $cu_project;
	if ($::project_obj){
		unless ($::project_obj->dbname eq $self->dbname){
			# 現在開いているプロジェクトを一時的に閉じて、他のプロジェクトを
			# 一時的に開く
			$cu_project = $::project_obj;
			undef $::project_obj;
			$self->open or die;
			$tmp_open = 1;
		}
	}
	else {
		# 何もプロジェクトを開いていなかった状態から、他のプロジェクトを一時
		# 的に開く
		$self->open or die;
		$tmp_open = 1;
	}
	
	if ( defined($new) ){                         # 新しい値を設定
		my $h = mysql_exec->select("
			SELECT status
			FROM   status_char
			WHERE  name= 'icode'
		",1)->hundle;
		if ($h->rows){
			mysql_exec->do("
				UPDATE status_char SET status='$new' WHERE name='icode'
			",1);
		} else {
			mysql_exec->do("
				INSERT INTO status_char (name, status)
				VALUES ('icode','$new')
			",1);
		}
		$r = $new;
	} else {                                      # 現在の値を参照
		my $h = mysql_exec->select("
			SELECT status
			FROM   status_char
			WHERE  name= 'icode'
		",1)->hundle;
		if ($h->rows){
			$r = $h->fetch->[0];
		}
	}
	
	# 一時的に開いたプロジェクトを閉じる
	if ($tmp_open){
		undef $::project_obj;
	}
	if ($cu_project){
		$cu_project->open;
	}
	
	return $r;
}

sub status_morpho{
	my $self = shift;
	my $new  = shift;
	
	if ( defined($new) ){
		mysql_exec->do("UPDATE status SET status=$new WHERE name='morpho'",1);
		return $new;
	} else {
		return mysql_exec
			->select("SELECT status FROM status WHERE name = 'morpho'",1)
				->hundle
					->fetch
						->[0]
		;
	}
}

sub use_hukugo{
	#return mysql_exec
	#	->select("SELECT ifuse FROM hselection where name = '複合名詞'",1)
	#		->hundle
	#			->fetch
	#				->[0]
	#;
	return 0;
}

#sub use_sonota{
#	return mysql_exec
#		->select("SELECT ifuse FROM hselection where name = 'その他'",1)
#			->hundle
#				->fetch
#					->[0]
#	;
#}

sub comment{
	my $self = shift;
	if (defined($_[0])){
		$self->{comment} = $_[0];
	}
	return $self->{comment};
}

sub dbh{
	my $self = shift;
	return $self->{dbh};
}

sub dbname{
	my $self = shift;
	return $self->{dbname};
}

sub last_tani{
	my $self = shift;
	my $new  = shift;
	
	if ($new){
		mysql_exec->do(
			"UPDATE status_char SET status=\'$new\' WHERE name=\'last_tani\'"
		,1);
		return $new;
	} else {
		my $temp = mysql_exec
			->select("
				SELECT status FROM status_char WHERE name = 'last_tani'",1
			)->hundle->fetch->[0];
		unless (length($temp) > 1){
			$temp = 'dan';
		}
		return $temp;
	}
}

sub last_codf{
	my $self = shift;
	my $new  = shift;
	
	if ($new){
		#$new = Jcode->new($new,'sjis')->euc if $::config_obj->os eq 'win32';
		#$new = Jcode->new($new,'utf8')->euc if $^O eq 'darwin';
		#print "new: $new\n", Jcode->new($new)->icode, "\n";
		mysql_exec->do(
			"UPDATE status_char SET status=\'$new\' WHERE name=\'last_codf\'"
		,1);
		return $new;
	} else {
		my $lst = mysql_exec
			->select("
				SELECT status FROM status_char WHERE name = 'last_codf'",1
			)->hundle->fetch->[0];
		#$lst = Jcode->new($lst,'euc')->sjis if $::config_obj->os eq 'win32';
		#print "lst: $lst\n";
		$lst = $::config_obj->os_path($lst);
		return $lst;
	}
}

sub save_dmp{
	my $self = shift;
	my %args = @_;
	
	use Data::Dumper;
	$Data::Dumper::Terse = 1;
	$Data::Dumper::Indent = 0;

	$args{var}  = Dumper($args{var});
	$args{var}  =~ s/\s//g;
	$args{var}  = mysql_exec->quote($args{var});
	$args{name} = mysql_exec->quote($args{name});
	
	if (
		mysql_exec->select(
			"SELECT * FROM status_char WHERE name = $args{name}",
			1
		)->hundle->rows > 0
	) {                                 # 既にエントリ（行）がある場合
		mysql_exec->do(
			"UPDATE status_char SET status=$args{var} WHERE name=$args{name}",
			1
		);
		# print "update: $args{var}\n";
	} else {                            # エントリ（行）を新たに作成
		mysql_exec->do(
			"INSERT INTO status_char (name, status)
			VALUES ($args{name}, $args{var})",
			1,
		);
		# print "new: $args{var}\n";
	}
}

sub load_dmp{
	my $self = shift;
	my %args = @_;
	
	$args{name} = mysql_exec->quote($args{name});
	
	if (
		mysql_exec->select(
			"SELECT * FROM status_char WHERE name = $args{name}",
			1
		)->hundle->rows > 0
	) {
		my $raw = mysql_exec->select(
			"SELECT status FROM status_char WHERE name = $args{name}",
			1
		)->hundle->fetch->[0];
		return eval($raw);
	} else {
		return undef;
	}
}

sub reloadable{
	my $self = shift;
	#return 0  unless $self->status_from_table;
	
	my $source = $::config_obj->os_path( $self->status_source_file );
	return 0 unless -e $source;
	
	my $target = $::config_obj->os_path( $self->file_target );
	
	if ( ( stat($target) )[9] < ( stat($source) )[9] ){
		return 1;
	} else {
		return 0;
	}
}

sub status_selected_coln{
	my $self = shift;
	my $new  = shift;
	return $self->_status_char_common('selected_coln', $new);
}

sub status_topic_tabulation_var{
	my $self = shift;
	my $new  = shift;
	return $self->_status_char_common('topic_tabulation_var', $new);
}

sub status_topic_tabulation_tani{
	my $self = shift;
	my $new  = shift;
	return $self->_status_char_common('topic_tabulation_tani', $new);
}

sub status_source_file{
	my $self = shift;
	my $new  = shift;
	my $name = $self->_status_char_common('source_file', $new);
	$name = $::config_obj->os_path($name);
	
	return $name;
}

sub status_var_file{
	my $self = shift;
	my $new  = shift;
	my $name = $self->_status_char_common('var_file', $new);
	$name = $::config_obj->os_path($name);
	
	# when instllation dir is moved
	if ( length($name) and not -e $name ){
		if ( $name =~ /.+(config\/khc.+)/ ) {
			$name = $::config_obj->cwd."/$1";
		}
		if (-e $name) {
			$self->_status_char_common('var_file', $::config_obj->uni_path($name));
			print "var file moved: ".$::config_obj->uni_path($name)."\n";
		}
	}

	return $name;
}

sub status_converted_file{
	my $self = shift;
	my $new  = shift;
	my $name = $self->_status_char_common('converted_file', $new );
	$name = $::config_obj->os_path($name);
	
	# when instllation dir is moved
	if ( length($name) and not -e $name ){
		if ( $name =~ /.+(config\/khc.+)/ ) {
			$name = $::config_obj->cwd."/$1";
		}
		if (-e $name) {
			$self->_status_char_common('converted_file', $::config_obj->uni_path($name) );
			print "converted file moved: ".$::config_obj->uni_path($name)."\n";
		}
	}

	return $name;
}

sub status_copied_file{
	my $self = shift;
	my $new  = shift;
	my $name = $self->_status_char_common('copied_file', $new);
	$name = $::config_obj->os_path($name);
	
	# when instllation dir is moved
	if ( length($name) and not -e $name ){
		if ( $name =~ /.+(config\/khc.+)/ ) {
			$name = $::config_obj->cwd."/$1";
		}
		if (-e $name) {
			$self->_status_char_common('copied_file', $::config_obj->uni_path($name));
			print "copied file moved: ".$::config_obj->uni_path($name)."\n";
		}
	}

	return $name;
}

sub _status_char_common{
	my $self = shift;
	my $key  = shift;
	my $new  = shift;
	
	# check if there is a row
	my $v = mysql_exec->quote($key);
	my $h = mysql_exec->select(
		"SELECT status FROM status_char WHERE name = $v",1
	)->hundle;
	my $current = '';
	if ($h->rows > 0) {
		$current = $h->fetch->[0];
	} else {
		
		mysql_exec->do("
			INSERT INTO status_char (name, status) VALUES ($v, '')"
		,1);
	}
	
	# when a new value is set
	if (defined($new)) {
		my $quoted = mysql_exec->quote($new);
		mysql_exec->do("
			UPDATE status_char SET status = $quoted WHERE name = $v"
		,1);
		$current = $new;
	}
	
	return $current;
}

sub status_from_table{
	my $self = shift;
	my $new  = shift;

	if ( defined($new) == 0 && defined($self->{status_from_table_cache}) ) {
		return $self->{status_from_table_cache};
	} else {
		$self->{status_from_table_cache} = $self->_status_common('from_table', $new);
		return $self->{status_from_table_cache};
	}
}

sub _status_common{
	my $self = shift;
	my $key  = shift;
	my $new  = shift;
	
	# check if there is a row
	my $v = mysql_exec->quote($key);
	my $h = mysql_exec->select(
		"SELECT status FROM status WHERE name = $v",1
	)->hundle;
	my $current = 0;
	if ($h->rows > 0) {
		$current = $h->fetch->[0];
	} else {
		mysql_exec->do("
			INSERT INTO status (name, status) VALUES ($v, $current)"
		,1);
	}
	
	# when a new value is set
	if (defined($new)) {
		mysql_exec->do("
			UPDATE status SET status = $new WHERE name = $v"
		,1);
		$current = $new;
	}
	
	return $current;
}

sub status_hb{
	my $self = shift;
	my $new  = shift;
	
	# 行があるかチェック
	my $h = mysql_exec->select(
		"SELECT status FROM status WHERE name = 'hb'",1
	)->hundle;
	my $current = 0;
	if ($h->rows > 0) {
		$current = $h->fetch->[0];
	} else {
		mysql_exec->do("
			INSERT INTO status (name, status) VALUES ('hb', $current)"
		,1);
	}
	
	if (defined($new)) {
		mysql_exec->do("
			UPDATE status SET status = $new WHERE name = 'hb'"
		,1);
		$current = $new;
	}
	
	return $current;
}

sub status_h5{
	my $self = shift; my $new  = shift;
	if ( defined($new) ){
		mysql_exec->do("UPDATE status SET status=$new WHERE name='h5'",1);
		return $new;
	} else {
		return mysql_exec
			->select("SELECT status FROM status WHERE name = 'h5'",1)
				->hundle->fetch->[0];
	}
}
sub status_h4{
	my $self = shift; my $new  = shift;
	if ( defined($new) ){
		mysql_exec->do("UPDATE status SET status=$new WHERE name='h4'",1);
		return $new;
	} else {
		return mysql_exec
			->select("SELECT status FROM status WHERE name = 'h4'",1)
				->hundle->fetch->[0];
	}
}
sub status_h3{
	my $self = shift; my $new  = shift;
	if ( defined($new) ){
		mysql_exec->do("UPDATE status SET status=$new WHERE name='h3'",1);
		return $new;
	} else {
		return mysql_exec
			->select("SELECT status FROM status WHERE name = 'h3'",1)
				->hundle->fetch->[0];
	}
}
sub status_h2{
	my $self = shift; my $new  = shift;
	if ( defined($new) ){
		mysql_exec->do("UPDATE status SET status=$new WHERE name='h2'",1);
		return $new;
	} else {
		return mysql_exec
			->select("SELECT status FROM status WHERE name = 'h2'",1)
				->hundle->fetch->[0];
	}
}
sub status_h1{
	my $self = shift; my $new  = shift;
	if ( defined($new) ){
		mysql_exec->do("UPDATE status SET status=$new WHERE name='h1'",1);
		return $new;
	} else {
		return mysql_exec
			->select("SELECT status FROM status WHERE name = 'h1'",1)
				->hundle->fetch->[0];
	}
}
sub status_bun{
	my $self = shift; my $new  = shift;
	if ( defined($new) ){
		mysql_exec->do("UPDATE status SET status=$new WHERE name='bun'",1);
		return $new;
	} else {
		return mysql_exec
			->select("SELECT status FROM status WHERE name = 'bun'",1)
				->hundle->fetch->[0];
	}
}
sub status_dan{
	my $self = shift; my $new  = shift;
	if ( defined($new) ){
		mysql_exec->do("UPDATE status SET status=$new WHERE name='dan'",1);
		return $new;
	} else {
		return mysql_exec
			->select("SELECT status FROM status WHERE name = 'dan'",1)
				->hundle->fetch->[0];
	}
}
#--------------------------#
#   ファイル名・パス関連   #


sub file_backup{
	my $self = shift;
	my $n = 0;
	
	while (-e $self->file_datadir."_bak$n.txt"){
		++$n;
	}
	
	my $temp = $self->file_datadir."_bak$n.txt";
	$temp = $::config_obj->os_path($temp);
	return $temp;
}

sub file_diff{
	my $self = shift;
	my $n = 0;
	
	while (-e $self->file_datadir."_diff$n.txt"){
		++$n;
	}
	
	my $temp = $self->file_datadir."_diff$n.txt";
	$temp = $::config_obj->os_path($temp);
	return $temp;
}

sub file_FormedText{
	my $self = shift;
	my $temp = $self->file_datadir.'_fm.csv';
	$temp = $::config_obj->os_path($temp);
	return $temp;
}

sub file_MorphoOut{
	my $self = shift;
	my $temp = $self->file_datadir.'_ch.txt';
	$temp = $::config_obj->os_path($temp);
	return $temp;
}
sub file_MorphoOut_o{
	my $self = shift;
	my $temp = $self->file_datadir.'_cho.txt';
	$temp = $::config_obj->os_path($temp);
	return $temp;
}

sub file_dropped{
	my $self = shift;
	my $temp = $self->file_datadir.'_dp.txt';
	$temp = $::config_obj->os_path($temp);
	return $temp;
}

sub file_m_target{
	my $self = shift;
	my $temp = $self->file_datadir.'_mph.txt';
	$temp = $::config_obj->os_path($temp);
	return $temp;
}

sub file_MorphoIn{ # file_m_targetと同じ
	my $self = shift;
	my $temp = $self->file_m_target;
	$temp = $::config_obj->os_path($temp);
	return $temp;
}
sub file_TempCSV{
	my $self = shift;
	my $n = 0;
	
	my $dir = $::config_obj->os_path( $self->file_datadir );

	while (-e $dir.'_temp'.$n.'.csv'){
		++$n;
	}
	my $f = $dir.'_temp'.$n.'.csv';
	
	# 空ファイルを作成しておく
	CORE::open (TOUT, ">$f");
	close (TOUT);
	
	return $f;
}
sub file_TempHTML{
	my $self = shift;
	my $n = 0;
	
	my $dir = $::config_obj->os_path( $self->file_datadir );

	while (-e $dir.'_temp'.$n.'.html'){
		++$n;
	}
	my $f = $dir.'_temp'.$n.'.html';
	
	# 空ファイルを作成しておく
	CORE::open (TOUT, ">$f");
	close (TOUT);
	
	return $f;
}
sub file_TempTXT{
	my $self = shift;
	my $n = 0;
	
	my $dir = $::config_obj->os_path( $self->file_datadir );

	while (-e $dir.'_temp'.$n.'.txt'){
		++$n;
	}
	my $f = $dir.'_temp'.$n.'.txt';
	
	# 空ファイルを作成しておく
	CORE::open (TOUT, ">$f");
	close (TOUT);
	
	return $f;
}
sub file_TempR{
	my $self = shift;
	
	
	use Cwd;
	my $n = 0;
	while (-e cwd.'/config/R-bridge/'.$::project_obj->dbname.'_temp'.$n.'.r'){
		++$n;
	}
	my $f = cwd.'/config/R-bridge/'.$::project_obj->dbname.'_temp'.$n.'.r';
	$f = $::config_obj->os_path($f);
	
	# 空ファイルを作成しておく
	CORE::open (TOUT, ">$f");
	close (TOUT);
	
	return $f;
}
sub file_TempExcel{
	my $self = shift;
	my $n = 0;
	
	my $dir = $::config_obj->os_path( $self->file_datadir );
	
	while (-e $dir.'_temp'.$n.'.xls'){
		++$n;
	}
	my $f = $dir.'_temp'.$n.'.xls';
	return $f;
}
sub file_TempExcelX{
	my $self = shift;
	my $n = 0;
	
	my $dir = $::config_obj->os_path( $self->file_datadir );
	
	while (-e $dir.'_temp'.$n.'.xlsx'){
		++$n;
	}
	my $f = $dir.'_temp'.$n.'.xlsx';
	return $f;
}

sub file_NounPhrases{
	my $self = shift;
	my $list = $self->file_datadir.'_np.xlsx';
	$list = $::config_obj->os_path($list);
	return $list;
}

sub file_HukugoList{
	my $self = shift;
	my $list = $self->file_datadir.'_hl.xlsx';
	$list = $::config_obj->os_path($list);
	return $list;
}

sub file_HukugoListTE{
	my $self = shift;
	my $list = $self->file_datadir.'_hlte.xlsx';
	$list = $::config_obj->os_path($list);
	return $list;
}

sub file_WordFreq{
	my $self = shift;
	my $list = $self->file_datadir.'_wf.sps';
	$list = $::config_obj->os_path($list);
	return $list;
}

sub file_ColorSave{
	my $self = shift;
	my $temp = $self->file_datadir;
	my $pos = rindex($temp,'/');
	my $color_save_file = substr($temp,'0',$pos);
	++$pos;
	substr($temp,'0',$pos) = '';
	$color_save_file .= '/color_save_'."$temp".'.dat';
	$color_save_file = $::config_obj->os_path($color_save_file);
	return $color_save_file;
}

sub dir_CoderData{
	my $self = shift;
	#my $pos = rindex($self->file_target,'/'); ++$pos;
	#my $datadir = substr($self->file_target,0,"$pos");
	#$datadir .= 'coder_data/';
	#$datadir = $::config_obj->os_path($datadir);
	#return $datadir;
	
	my $dir = cwd;
	$dir .= '/config/'.$self->dbname.'/';
	$dir = $::config_obj->os_path($dir);
	return $dir;
}

sub file_datadir{
	my $self = shift;
	return $self->dir_CoderData.$self->dbname;
}

sub file_target{
	my $self = shift;
	return $self->{target};
	#my $t = $self->{target};
	#my $icode = Jcode::getcode($t);
	#$t = Jcode->new($t)->euc;
	#$t =~ tr/\\/\//;
	#$t = Jcode->new($t)->$icode
	#	if ( length($icode) and ( $icode ne 'ascii' ) );
	#return($t);
}

sub file_base{
	my $self = shift;
	my $basefn = $self->file_target;
	my $pos = rindex($basefn,'.');
	$basefn = substr($basefn,0,$pos);
	$basefn = $::config_obj->os_path($basefn);
	return $basefn;
}

sub file_short_name{
	my $self = shift;
	
	my $pos = rindex($self->file_target,'/'); ++$pos;
	return substr(
		$self->file_target,
		$pos,
		length($self->file_target) - $pos
	);

	# return basename($self->file_target);
}

sub file_short_name_mw{ # Only for showing the source file name. NOT for processing.
	my $self = shift;
	my %args = @_;

	my $file = $self->file_target;
	if ($::project_obj) {
		if ($::project_obj->dbname eq $self->dbname) {
			if ( length( $self->status_source_file ) ){
				$file = $::config_obj->uni_path( $self->status_source_file );
			}
			if ( length( $self->status_selected_coln ) and not $args{no_col} ){
				$file .= " [".$self->status_selected_coln."]";
			}
		}
	}

	my $pos = rindex($file ,'/'); ++$pos;
	$file = substr(
		$file ,
		$pos,
		length($file) - $pos
	);

	$file = gui_window->gui_bmp( $file );
	return $file;
}

sub file_dir{
	my $self = shift;
	my $pos = rindex($self->file_target,'/');
	return substr($self->file_target,0,"$pos");

	#return dirname($self->file_target);
}

1;
