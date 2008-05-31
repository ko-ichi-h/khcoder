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
			msg    => "分析対象ファイルが存在しません"
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
	my $hinshi = shift;
	$self->{dbname} = mysql_exec->create_new_db;
	$self->{dbh} = mysql_exec->connect_db($self->{dbname});
	$::project_obj = $self;
	
	# 品詞選択テーブル
	mysql_exec->do('
		create table hselection(
			khhinshi_id int primary key not null,
			ifuse       int,
			name        varchar(20) not null
		)
	',1);
	my %temp_h;
	my $sql4 = "INSERT INTO hselection (khhinshi_id,ifuse,name)\nVALUES ";
	foreach my $i (@{$hinshi}){
		if ($temp_h{$i->[0]}){
			next;
		} else {
			$temp_h{$i->[0]} = 1;
		}
		#if ($i->[1] eq "複合名詞"){
		#	$sql4 .= "($i->[0],0,'$i->[1]'),";
		#} 
		if ($i->[1] eq "HTMLタグ"){
			$sql4 .= "($i->[0],0,'$i->[1]'),";
		} else {
			$sql4 .= "($i->[0],1,'$i->[1]'),";
		}
	}
	$sql4 .= "(9999,0,'その他')";
	mysql_exec->do($sql4,1);
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
			status varchar(255)
		)
	',1);
	mysql_exec->do("
		INSERT INTO status_char (name, status)
		VALUES ('last_tani',''),('last_codf',''),('icode','$self->{icode}')
	",1);
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
	unless (-e $self->file_target){
		gui_errormsg->open(
			type   => 'msg',
			msg    => "分析対象ファイルが存在しません"
		);
		return 0;
	}
	
	# データベースを開く
	$self->{dbh} = mysql_exec->connect_db($self->{dbname});

	$::project_obj = $self;
	return $self;
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
sub use_sonota{
	return mysql_exec
		->select("SELECT ifuse FROM hselection where name = 'その他'",1)
			->hundle
				->fetch
					->[0]
	;
}

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
		#print "new: $new\n";
		mysql_exec->do(
			"UPDATE status_char SET status=\'$new\' WHERE name=\'last_codf\'"
		,1);
		return $new;
	} else {
		my $lst = mysql_exec
			->select("
				SELECT status FROM status_char WHERE name = 'last_codf'",1
			)->hundle->fetch->[0];
		$lst = Jcode->new($lst,'euc')->sjis if $::config_obj->os eq 'win32';
		#print "lst: $lst\n";
		return $lst;
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
sub file_WordList{
	my $self = shift;
	my $list = $self->file_datadir.'_wl.csv';
	$list = $::config_obj->os_path($list);
	return $list;
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
	my $pos = rindex($self->file_target,'/'); ++$pos;
	my $datadir = substr($self->file_target,0,"$pos");
	$datadir .= 'coder_data/';
	
	my $temp = $self->file_target;
	substr($temp,0,$pos) = '';
	$pos = rindex($temp,'.');
	$temp = substr($temp,0,$pos);
	$datadir .= $temp;
	$datadir = $::config_obj->os_path($datadir);
	return $datadir;
}

sub file_target{
	my $self = shift;
	my $t = $self->{target};
	my $icode = Jcode::getcode($t);
	$t = Jcode->new($t)->euc;
	$t =~ tr/\\/\//;
	$t = Jcode->new($t)->$icode unless $icode eq 'ascii';
	return($t);
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
	return basename($self->file_target);
}

sub file_dir{
	my $self = shift;
	return dirname($self->file_target);
}

1;
