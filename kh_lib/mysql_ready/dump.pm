package mysql_ready::dump;
use strict;

#----------------------------------------#
#   長すぎる語があった場合のダンプ出力   #
#----------------------------------------#

sub word_length{
	my $file = $::project_obj->file_datadir.'_dmp.txt';
	open (DMP,">$file") or
		gui_errormsg->open(
			type => 'file',
			thefile => $file
		);

	my $t = mysql_exec->select("
		SELECT genkei
		FROM   rowdata
		WHERE  
			( length(hyoso) = 255 ) or ( length(genkei) = 255 )
	",1)->hundle;
	while (my $i = $t->fetch){
		print DMP "$i->[0]\n";
	}

	close (DMP);
	
	
	my $msg = "制限を超える長さの語（形態素）が茶筌によって抽出されました。\n";
	$msg .= "KH Coderが扱えるの語の長さは全角127文字までです。\n\n";
	$msg .= "前処理を中断してKH Coderを終了します。\n\n";
	$msg .= "問題の語は以下のファイルに記録しました：\n$file";
	gui_errormsg->open(
		msg  => "$msg",
		type => 'msg',
	);

	exit;
}

1;
