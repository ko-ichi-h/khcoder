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

	my $msg =
		 kh_msg->get('too_long_word1')
		.$file
		."\n\n"
		.kh_msg->get('too_long_word2')
	;

	gui_errormsg->open(
		msg  => "$msg",
		type => 'msg',
	);

	#exit;

	return 1;
}

1;
