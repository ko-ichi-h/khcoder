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
	
	# データベース名決定
	my $drh;
	unless ( $drh = DBI->install_driver("mysql") ){
		gui_errormsg->open(
			type => 'mysql',
			sql  => 'install_driver'
		);
		return 0;
	}
	my %dbs;
	foreach my $i ($drh->func('','','_ListDBs')){
		$dbs{$i} = 1;
	}
	my $n = 0;
	while ( $dbs{"khc$n"} ){
		++$n;
	}
	$self->{dbname} = "khc$n";

	return $self;
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
	$self->{dbh} = DBI->connect("DBI:mysql:$self->{dbname}",undef,undef)
		or gui_errormsg->open(type => 'mysql', sql => 'connect');
	$::project_obj = $self;

	
	# 茶筌（複合名詞）の設定を確認
	$::config_obj->use_hukugo($self->use_hukugo);
	$::config_obj->save;

	return $self;
}

#--------------#
#   アクセサ   #
#--------------#
sub use_hukugo{
	return mysql_exec
		->select("SELECT ifuse FROM hselection where name = '複合名詞'",1)
			->hundle
				->fetch
					->[0]
	;
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


#--------------------------#
#   ファイル名・パス関連   #

sub file_m_target{
	my $self = shift;
	my $temp = $self->file_datadir.'_mph.txt';
	$temp = $::config_obj->os_path($temp);
	return $temp;
}

sub file_backup{
	my $self = shift;
	my $temp = $self->file_base.'.bak';
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

sub file_MorphoIn{
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
	$t =~ tr/\\/\//;
#	$t = $::config_obj->os_path($t);
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
