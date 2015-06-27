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
	
	# データディレクトリが無かった場合は作成
	print $self->dir_CoderData."\n";
	unless (-d $self->dir_CoderData){
		mkdir $self->dir_CoderData or die;
	}
	return $self;
}

sub prepare_db{
	my $self   = shift;
	$self->{dbname} = mysql_exec->create_new_db;
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
	mysql_exec->do("
		INSERT INTO status_char (name, status)
		VALUES ('last_tani',''),('last_codf',''),('icode','$self->{icode}')
	",1);
}

sub read_hinshi_setting{
	my $self = shift;
	
	my $dbh_csv = DBI->connect("DBI:CSV:f_dir=./config");
	
	# 品詞設定の読み込み
	my $sql = "SELECT hinshi_id,kh_hinshi,condition1,condition2 FROM hinshi_";
	$sql .= $::config_obj->c_or_j;
	
	# Stanford POS Taggerの場合は言語ごとに異なる品詞設定ファイルを読む
	if ($::config_obj->c_or_j eq 'stanford'){
		$sql .= '_'.$::config_obj->stanford_lang;
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
	
	# 対象ファイルの存在を確認
	unless (-e $::config_obj->os_path( $self->file_target ) ){
		gui_errormsg->open(
			type   => 'msg',
			msg    => kh_msg->get('no_target_file')
		);
		return 0;
	}
	
	# データベースを開く
	$self->{dbh} = mysql_exec->connect_db($self->{dbname});
	$::project_obj = $self;
	
	my_threads->open_project;
	
	$self->check_up;
	$self->set_r_locale;
	
	return $self;
}

sub set_r_locale{
	my $self = shift;
	my $lang = $::project_obj->morpho_analyzer_lang;
	
	return 0 unless $::config_obj->os eq 'win32';
	return 0 unless $::config_obj->{R};
	
	if ($lang eq 'cn'){
		print "Set R locale: CN\n";
		$::config_obj->{R}->send('Sys.setlocale(category="LC_ALL",locale="Chinese")');
	} else {
		print "Set R locale: JP\n";
		$::config_obj->{R}->send('Sys.setlocale(category="LC_ALL",locale="Japanese_Japan.932")');
	}
	
}

sub morpho_analyzer{
	my $self = shift;
	my $v = shift;
	
	if (defined($v)){
		mysql_exec->do("
			DELETE
			FROM   status_char
			WHERE  name = \"morpho_analyzer\"
		",1);
		mysql_exec->do("
			INSERT INTO status_char (name, status)
			VALUES (\"morpho_analyzer\", \"$v\")
		",1);
		return $v;
	}
	
	my $h = mysql_exec->select("
		SELECT status FROM status_char WHERE name = \"morpho_analyzer\"
	",1)->hundle;
	
	unless ($h->rows){
		return 'chasen';
	}
	
	return $h->fetch->[0];
}

sub morpho_analyzer_lang{
	my $self = shift;
	my $v = shift;
	
	if (defined($v)){
		mysql_exec->do("
			DELETE
			FROM   status_char
			WHERE  name = \"morpho_analyzer_lang\"
		",1);
		mysql_exec->do("
			INSERT INTO status_char (name, status)
			VALUES (\"morpho_analyzer_lang\", \"$v\")
		",1);
		return $v;
	}
	
	my $h = mysql_exec->select("
		SELECT status FROM status_char WHERE name = \"morpho_analyzer_lang\"
	",1)->hundle;
	
	unless ($h->rows){
		return 'jp';
	}
	
	return $h->fetch->[0];
}

sub check_up{
	my $self = shift;
	
	# status_char.statusをvarcharからtextへ
	my $chk = mysql_exec->select(
		'show columns from status_char like \'status\'',
		1
	)->hundle->fetch->[1];
	if ($chk =~ /varchar/){
		mysql_exec->do(
			'ALTER TABLE status_char MODIFY status TEXT'
			,1
		);
		# print "Converted \"status_char.status\" to TEXT\n";
	}

	# プロジェクト情報をMySQL内にも保存
	my $chk_t = 0;
	my $st = mysql_exec->select(
		"SELECT status FROM status_char WHERE name = \"target\""
	)->hundle;
	if (my $i = $st->fetch){
		if ( length( $i->[0] ) ){
			$chk_t = 1;
		}
	}
	unless ($chk_t){
		my $target = $self->file_target;
		mysql_exec->do("
			INSERT INTO status_char (name,status)
			VALUES (\"target\", \"$target\")
		",1);
		# print "target: ", Jcode->new($target)->sjis, "\n";
	}

	my $chk_c = 0;
	my $st0 = mysql_exec->select(
		"SELECT status FROM status_char WHERE name = \"comment\""
	)->hundle;
	if (my $i = $st0->fetch){
		if ( $i->[0] eq $self->comment ){
			$chk_c = 1;
		}
	}
	unless ($chk_c){
		mysql_exec->do("
			DELETE FROM status_char
			WHERE name = \"comment\"
		",1);
		mysql_exec->do("
			INSERT INTO status_char (name,status)
			VALUES (\"comment\", \"".$self->comment."\")
		",1);
		# print "comment: ", Jcode->new($self->comment)->sjis, "\n";
	}

	# 外部変数用のテーブルを準備
	unless ( mysql_exec->table_exists('outvar') ){
		mysql_exec->do("create table outvar
			(
				name varchar(255) not null,
				tab varchar(255) not null,
				col varchar(255) not null,
				tani varchar(10) not null,
				id int auto_increment primary key not null
			)
		",1);
	}
	unless ( mysql_exec->table_exists('outvar_lab') ){
		mysql_exec->do("create table outvar_lab
			(
				var_id int not null,
				val varchar(255) not null,
				lab varchar(255) not null,
				id int auto_increment primary key not null
			)
		",1);
	}

	# 一時ファイル群を削除
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
	#$n = 0;
	#while (-e $self->file_datadir.'_temp'.$n.'.r'){
	#	unlink($self->file_datadir.'_temp'.$n.'.r');
	#	++$n;
	#}
}


#--------------#
#   アクセサ   #
#--------------#

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
		$new = Jcode->new($new,'sjis')->euc if $::config_obj->os eq 'win32';
		$new = Jcode->new($new,'utf8')->euc if $^O eq 'darwin';
		print "new: $new\n", Jcode->new($new)->icode, "\n";
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
                $lst = $::config_obj->os_path($lst,'euc');
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
sub file_HukugoList{
	my $self = shift;
	my $list = $self->file_datadir.'_hl.csv';
	$list = $::config_obj->os_path($list);
	return $list;
}

sub file_HukugoListTE{
	my $self = shift;
	my $list = $self->file_datadir.'_hlte.csv';
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
	my $pos = rindex($self->file_target,'/'); ++$pos;
	my $datadir = substr($self->file_target,0,"$pos");
	$datadir .= 'coder_data/';
	$datadir = $::config_obj->os_path($datadir);
	return $datadir;
}

sub file_datadir{
	my $self = shift;

	my $temp = $self->file_short_name;
	$temp = substr($temp,0,rindex($temp,'.'));

	return $self->dir_CoderData.$temp;
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

sub file_dir{
	my $self = shift;
	my $pos = rindex($self->file_target,'/');
	return substr($self->file_target,0,"$pos");

	#return dirname($self->file_target);
}

1;
