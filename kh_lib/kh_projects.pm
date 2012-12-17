package kh_projects;
use kh_project;
use strict;
use DBI;
use DBD::CSV;
use DBD::mysql;
use Jcode;

#--------------------------------------#
#   リスト読み込み（コンストラクタ）   #
#--------------------------------------#

sub read{
	my $class = shift;
	my $self;
	my $dbh = DBI->connect("DBI:CSV:f_dir=./config");
	$self->{dbh} = $dbh;
	bless $self, $class;

	# テーブルが存在しない場合は作成
	my $save_file = $::config_obj->history_file;
	unless (-e $save_file){
		$self->create_project_list;
	}

	# 読み込み                                    # euc-->sjis変換？
	my $st = $dbh->prepare("SELECT target,comment,dbname FROM projects")
		or die;
	$st->execute or die;
	my $n = 0;
	while (my $r = $st->fetch){
		$self->{project}[$n] =
			kh_project->temp(
				target  => $::config_obj->os_path($r->[0]),
				comment => $r->[1],
				dbname  => $r->[2]
			);
		++$n;
	}
	return $self;
}

sub create_project_list{
	my $self = shift;
	
	# ファイルが存在する場合は中止
	if (-e $::config_obj->history_file){
		print
			"kh_projects::create_project_list: Aborted!\n",
			"\tThe file exists.\n";
		return 0;
	}
	
	# SQLのSELECTでデータが帰ってくる場合も中止
	my $file_temp = $::config_obj->file_temp;     # エラー出力抑制
	open (STDERR,">$file_temp");
	
	my $st = $self->{dbh}->prepare(
		"SELECT target,comment,dbname FROM projects"
	);
	$st->execute;
	while (my $r = $st->fetch){
		if ( length($r->[0]) ){
			print
				"kh_projects::create_project_list: Aborted!\n",
				"\tSELECT command returned some data.\n";
			return 0;
		}
	}
	
	close (STDERR);                               # エラー出力復帰
	open(STDERR,'>&STDOUT') or die;
	unlink($file_temp);
	
	# テーブル作成
	print "creating project list... ";
	$self->dbh->do(                                 # ルーチン化？
		"CREATE TABLE projects (
			target CHAR(225),
			comment CHAR(225),
			dbname CHAR(225)
		)"
	) or die;
	print "ok\n";
}

#--------------------#
#   新規登録＆保存   #
#--------------------#

sub add_new{
	my $self = shift;
	my $new  = shift;

	# プロジェクト・テーブルが存在しない場合は作成
	my $save_file = $::config_obj->history_file;
	unless (-e $save_file){
		$self->create_project_list;
	}

	# 既にファイルが登録されていないかチェック
	foreach my $i (@{$self->list}){
		if ($i->file_target eq $new->file_target){
			gui_errormsg->open(
				type    => 'msg',
				msg     => kh_msg->get('already_registered') # "当該のファイルは既にプロジェクトとして登録されています"
			);
			return 0;
		}
	}

	# MySQL DBの整備
	$new->prepare_db;
	$new->read_hinshi_setting;

	# print "1: ", $new->file_target, "\n";

	# プロジェクトを登録
	my $sql = 'INSERT INTO projects (target, comment, dbname) VALUES (';
	$sql .= "'".Jcode->new($new->file_target)->euc."',";
	if ($new->comment){
		$sql .= $self->dbh->quote(Jcode->new($new->comment)->euc).",";
	} else {
		$sql .= "'no description',";
		$new->comment('no description');
	}
	$sql .= "'".$new->dbname."'";
	$sql .= ')';
	#$sql = Jcode->new($sql)->euc;
	$self->dbh->do($sql) or die;

	$new->{comment} = Jcode->new($new->comment)->euc;

	return 1;
}

#------------------#
#   コメント編集   #
#------------------#

sub edit{
	my $self = shift;
	my $edp = $self->a_project($_[0]);

	$edp->comment( Jcode->new($_[1])->euc );
	$edp->assigned_icode($_[2]);

	my $file    = Jcode->new($edp->file_target)->euc;
	my $comment = Jcode->new($edp->comment    )->euc;

	my $sql = "UPDATE projects SET comment=";
	if (length($edp->comment)){
		$sql .= $self->dbh->quote($comment);
	} else {
		$sql .= 'undef';
	}
	$sql .= " WHERE target = ";
	$sql .= "'".$file."'";
	$self->dbh->do($sql) or print $sql;
}

#----------#
#   削除   #
#----------#

sub delete{
	my $self = shift;
	my $del = $self->a_project($_[0]);

	my $sql = "DELETE FROM projects WHERE target = ";
	$sql .= "'".$del->file_target."'";
	$sql = Jcode->new($sql)->euc;
	$self->dbh->do($sql) or die;

	# ゴミ箱テーブルが存在しない場合は作成 
	my $save_file = $::config_obj->history_trush_file;
	unless (-e $save_file){
		$self->dbh->do(                                 # ルーチン化？
			"CREATE TABLE projects_trush (
				target CHAR(225),
				comment CHAR(225),
				dbname CHAR(225)
			)"
		) or die;
	}

	# ゴミ箱テーブルに追加
	$sql = 'INSERT INTO projects_trush (target, comment, dbname) VALUES (';
	$sql .= "'".$del->file_target."',";
	if ($del->comment){
		$sql .= "'".$del->comment."',";
	} else {
		$sql .= "undef,";
	}
	$sql .= "'".$del->dbname."'";
	$sql .= ')';
	$sql = Jcode->new($sql)->euc;
	$self->dbh->do($sql) or die;
	
	# MySQL DBを削除
	mysql_exec->drop_db($del->dbname);
}



#--------------#
#   アクセサ   #
#--------------#
sub a_project{
	my $self = shift;
	return $self->{project}[$_[0]];
}

sub dbh{
	my $self = shift;
	return $self->{dbh};
}

sub list{
	my $self = shift;
	if (defined(@{$self->{project}})){
		return \@{$self->{project}};
	} else {
		my @hoge;
		return \@hoge;
	}
}


1;
__END__
プロジェクトリストの
	・読み込み （すべてkh_project->temp）
	・編集
	・保存
