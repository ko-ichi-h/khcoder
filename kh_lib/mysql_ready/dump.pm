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
	$msg .= "KH Coderは当該の語を短縮した状態で認識します。\n";
	$msg .= "当該の語は以下のファイルに記録しました：\n$file\n\n";
	$msg .= "OKをクリックすると処理を続行します。";
	gui_errormsg->open(
		msg  => "$msg",
		type => 'msg',
	);

	#exit;

	return 1;
}

1;
