package kh_project_io;

use strict;
use MySQL::Backup_kh;
use MIME::Base64;
use YAML qw(DumpFile LoadFile);
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
	$mb->create_structure(*MYSQLO);
	$mb->data_backup(*MYSQLO);
	$mb->create_index_structure(*MYSQLO);
	close (MYSQLO);

	# MySQL::Backupはいろいろと修正する必要があった
	#   1. バックアップの挙動を、一行ずつの出力に変更       → OK
	#   2. バックアップの効率化                             → OK
	#   3. 複合Indexに対応                                  → OK
	#   4. リストアの挙動も、一行ずつ読み込んでの実行に変更 → OK

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

	return 1;
}

sub import{
	my $file_save   = shift;
	my $file_target = shift;

	# プロジェクトを開いている場合はクローズ
	$::main_gui->close_all;
	undef $::project_obj;
	$::main_gui->menu->refresh;
	$::main_gui->inner->refresh;

	# 分析対象ファイルの解凍
	my $zip = Archive::Zip->new();
	unless ( $zip->read( $file_save ) == "AZ_OK" ) {
		return undef;
	}
	unless ( $zip->extractMember('target',$file_target) == "AZ__OK" ){
		return undef;
	}

	# プロジェクトの登録
	my $info = &get_info($file_save);
	
	my $new = kh_project->new(
		target  => $file_target,
		comment => Jcode->new($info->{comment})->sjis,
		icode   => 0,
	) or return 0;
	kh_projects->read->add_new($new) or return 0; # このプロジェクトが開かれる

	# MySQLデータベースの準備（クリア）
	my @tables = mysql_exec->table_list;
	foreach my $i (@tables){
		mysql_exec->drop_table($i);
	}

	# MySQLデータベースの復帰
	my $file_temp_mysql = $::config_obj->file_temp;
	unless ( $zip->extractMember('mysql',$file_temp_mysql) == "AZ__OK" ){
		return undef;
	}
	my $mb = new_from_DBH MySQL::Backup_kh($::project_obj->dbh);
	$mb->run_restore_script($file_temp_mysql);
	unlink($file_temp_mysql);

	undef $::project_obj;
}


sub get_info{
	my $file = shift;
	
	# 解凍
	my $zip = Archive::Zip->new();
	unless ( $zip->read( $file ) == "AZ_OK" ) {
		return undef;
	}
	my $file_temp_info = $::config_obj->file_temp;
	unless ( $zip->extractMember('info',$file_temp_info) == "AZ__OK" ){
		return undef;
	}

	# 解釈
	my %info = LoadFile($file_temp_info) or return undef;
	foreach my $i (keys %info){
		$info{$i} = decode_base64($info{$i})
	}
	unlink($file_temp_info);

	return \%info;
}




1;
