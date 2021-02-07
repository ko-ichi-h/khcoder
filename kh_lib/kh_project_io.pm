package kh_project_io;

use strict;
use MySQL::Backup_kh;
use MIME::Base64;
use YAML qw(DumpFile LoadFile);
use Archive::Zip qw( :ERROR_CODES );

sub export{
	my $savefile = $_[0];

	my $mb = new_from_DBH MySQL::Backup_kh($::project_obj->dbh);

	# MySQLのデータを格納
	my $file_temp_mysql = $::config_obj->file_temp;
	open (MYSQLO,'>:encoding(utf8)', $file_temp_mysql) or
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
	$info{'file_name'} = encode_base64(
		Encode::encode('utf8', $::project_obj->file_short_name_mw('no_col' => 1) ),
		''
	);
	$info{'comment'}   = encode_base64(
		Encode::encode('utf8', $::project_obj->comment),
		''
	);
	if ($::project_obj->status_var_file) {
		$info{'var_file'}   = encode_base64('1', '');
	} else {
		$info{'var_file'}   = encode_base64('0', '');
	}
	if ($::project_obj->status_selected_coln) {
		$info{'selected_coln'}   = encode_base64(
			Encode::encode('utf8', $::project_obj->status_selected_coln),
			''
		);
	}
	
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
	
	if ( -e $::project_obj->status_source_file ){
		$zip->addFile(
			$::config_obj->os_path( $::project_obj->status_source_file  ),
			'source'
		);
	} else {
		$zip->addFile(
			$::config_obj->os_path($::project_obj->file_target),
			'target'
		);
	}
	
	if ( -e $::project_obj->status_copied_file ){
		$zip->addFile(
			$::config_obj->os_path($::project_obj->status_copied_file),
			'copied'
		);
	}
	
	if ( -e $::project_obj->status_converted_file ){
		$zip->addFile(
			$::config_obj->os_path($::project_obj->status_converted_file),
			'converted'
		);
	}
	
	unless ( $zip->writeToFileNamed($savefile) == AZ_OK ) {
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
	unless ( $zip->read( $file_save ) == AZ_OK ) {
		print "Could not open zip file!\n";
		return undef;
	}
	my @names = $zip->memberNames();
	my %names = ();
	foreach my $i (@names){
		$names{$i} = 1;
	}

	my $file_temp_target = $::config_obj->file_temp;
	
	my $ext;
	if ($names{'source'}) {
		$ext = 'source';
	} else {
		$ext = 'target';
	}
	
	unless ( $zip->extractMember($ext, $file_temp_target) == AZ_OK ){
		print "Could not extract $ext file!\n";
		return undef;
	}
	rename($file_temp_target, $file_target) or
		gui_errormsg->open(
			type => 'file',
			file => $file_target
		)
	;	# 2バイト文字（駄目文字）がファイル名に含まれていると、解凍に失敗する！
		# ので、いったんtempファイルに解凍してからリネーム

	# プロジェクトの登録
	my $info = &get_info($file_save);
	my $new = kh_project->new(
		target  => $file_target,
		comment => $info->{comment},
		icode   => 0,
	) or return 0;
	
	$file_target = $::config_obj->uni_path( $file_target );
	if ( length($info->{selected_coln}) ) {
		my $target_for_projects .= "$file_target [".$info->{selected_coln}."]";
		$new->{target} = $target_for_projects;
	}
	kh_projects->read->add_new($new) or return 0; # このプロジェクトが開かれる

	# MySQLデータベースの準備（クリア）
	#mysql_exec->do("set global innodb_flush_log_at_trx_commit = 0");

	my @tables = mysql_exec->table_list;
	foreach my $i (@tables){
		mysql_exec->drop_table($i);
	}

	# MySQLデータベースの復帰
	my $file_temp_mysql = $::config_obj->file_temp;
	unless ( $zip->extractMember('mysql',$file_temp_mysql) == AZ_OK ){
		return undef;
	}
	my $mb = new_from_DBH MySQL::Backup_kh($::project_obj->dbh);
	$mb->run_restore_script($file_temp_mysql);
	unlink($file_temp_mysql);

	# save some info into MySQL status_char table
	mysql_exec->do("DELETE FROM status_char WHERE name = 'copied_file'");
	mysql_exec->do("DELETE FROM status_char WHERE name = 'converted_file'");
	mysql_exec->do("DELETE FROM status_char WHERE name = 'var_file'");
	mysql_exec->do("DELETE FROM status_char WHERE name = 'source_file'");
	mysql_exec->do("DELETE FROM status_char WHERE name = 'target'");

	mysql_exec->do("
		INSERT INTO status_char (name, status) VALUES ('target', "
		.mysql_exec->quote($file_target)
		.")"
	);

	if ($names{source}) {
		$::project_obj->status_source_file( $file_target );
	}
	
	if ( $info->{var_file} ){
		$::project_obj->status_var_file( $::config_obj->uni_path( $::project_obj->file_datadir.'_tgt_var0.txt' ));
	}
	
	# files in the inner structure
	if ($names{copied}) {
		my $suf;
		if ($file_target =~ /(\.[a-zA-Z]+?)$/) {
			$suf = $1;
		}
		my $copied   = $::project_obj->file_datadir.'_tgt'.$suf;
		
		unless ( $zip->extractMember('copied', $copied) == AZ_OK ){
			print "Could not extract copied file!\n";
			return undef;
		}
		$::project_obj->status_copied_file( $::config_obj->uni_path($copied) );
	}
	if ($names{converted}) {
		my $converted = $::project_obj->file_datadir.'_tgt_txt0.txt';
		
		unless ( $zip->extractMember('converted', $converted) == AZ_OK ){
			print "Could not extract converted file!\n";
			return undef;
		}
		$::project_obj->status_converted_file( $::config_obj->uni_path($converted) );
	}
	mysql_exec->flush;
	
	undef $::project_obj;
}


sub get_info{
	my $file = shift;
	
	# 解凍
	my $zip = Archive::Zip->new();
	unless ( $zip->read( $file ) == AZ_OK ) {
		return undef;
	}
	my $file_temp_info = $::config_obj->file_temp;
	unless ( $zip->extractMember('info',$file_temp_info) == AZ_OK ){
		return undef;
	}

	# 解釈
	my %info = LoadFile($file_temp_info) or return undef;
	foreach my $i (keys %info){
		$info{$i} = Encode::decode('utf8', decode_base64($info{$i}) )
	}
	unlink($file_temp_info);

	return \%info;
}




1;
