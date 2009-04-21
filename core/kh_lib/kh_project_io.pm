package kh_project_io;
use strict;
use MySQL::Backup_kh;
use MIME::Base64;
use YAML::XS qw(DumpFile LoadFile);               # XSのままで良い？
use Archive::Zip;

sub export{
	my $savefile = $_[0];

	my $mb = new_from_DBH MySQL::Backup_kh($::project_obj->dbh);

	# MySQLのデータを格納
	my $file_temp_mysql = $::config_obj->file_temp;
	open (MYSQLO,">$file_temp_mysql") or
		gui_errormsg->open(
			type => 'file',
			file => $file_temp_mysql
		)
	;
	print MYSQLO $mb->create_structure();
	print MYSQLO $mb->data_backup();
	close (MYSQLO);

	# MySQL::Backupはいろいろと修正する必要がある
	# 1. ファイルハンドルを渡して、そこに書き込ませる形にしないとメモリがパンク
	# 2. 複合Indexに対応していない
	#    →primary key以外のindexは、データをinsertした後に作成するように
	# 3. リストアするときもファイル全体を一気に読まず、1行づつに

	# 情報ファイルを作成
	my $file_temp_info = $::config_obj->file_temp;
	my %info;
	$info{'file_name'} = encode_base64($::project_obj->file_short_name,'');
	$info{'comment'}   = encode_base64($::project_obj->comment,'');
	DumpFile($file_temp_info, %info) or
		gui_errormsg->open(
			type => 'file',
			file => $file_temp_info
		)
	;

	# Zipファイルに固める
	my $zip = Archive::Zip->new();
	
	$zip->addFile( $file_temp_mysql, 'mysql' );
	$zip->addFile( $file_temp_info,  'info' );
	$zip->addFile( $::project_obj->file_target, 'target');
	
	unless ( $zip->writeToFileNamed($savefile) == "AZ_OK" ) {
		gui_errormsg->open(
			type => 'file',
			file => $savefile
		)
	}

	# 一時ファイルを削除
	unlink ($file_temp_mysql, $file_temp_info);

	print "OK\n";
}



1;
