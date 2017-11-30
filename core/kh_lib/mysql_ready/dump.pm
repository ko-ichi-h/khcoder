package mysql_ready::dump;
use strict;

#----------------------------------------#
#   長すぎる語があった場合のダンプ出力   #
#----------------------------------------#

sub word_length{
	my $file = $::project_obj->file_datadir.'_dmp.txt';
	open (DMP, '>encoding(utf8)', $file) or
		gui_errormsg->open(
			type => 'file',
			thefile => $file
		);

	my $t = mysql_exec->select("
		SELECT genkei
		FROM   rowdata
		WHERE  
			( char_length(hyoso) = 128 ) or ( char_length(genkei) = 128 )
	",1)->hundle;
	while (my $i = $t->fetch){
		print DMP "$i->[0]\n";
	}

	close (DMP);

	my $msg =
		 kh_msg->get('too_long_word1')
		.$::config_obj->uni_path($file)
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
