package kh_project_io;
#use strict;
use MySQL::Backup_kh;

sub export{
	my $savefile = $_[0];

	my $mb = new_from_DBH MySQL::Backup_kh($::project_obj->dbh);

	# MySQLのデータを格納
	my $n = 0;
	my $file_temp_mysql = 'mysql.tmp'.$n;
	while (-e $file_temp_mysql){
		++$n;
		$file_temp_mysql = 'mysql.tmp'.$n;
	}

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




	print "OK\n";
}



1;
