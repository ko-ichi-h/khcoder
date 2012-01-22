package kh_sysconfig::win32::chasen;
use strict;
use base qw(kh_sysconfig::win32);
use gui_errormsg;

sub config_morph{
	my $self = shift;
	my $pos = rindex($self->{chasen_path},'\\');
	$self->{grammercha} = substr($self->{chasen_path},0,$pos);
	$self->{chasenrc} = "$self->{grammercha}".'\\dic\chasenrc';
	$self->{dic_dir} =  "$self->{grammercha}".'\\dic';
	$self->{grammercha} .= '\dic\grammar.cha';
	
	$self->{dic_dir} = Jcode->new($self->{dic_dir},'sjis')->euc;
	$self->{dic_dir} =~ s/\\/\//g;
	
	#-------------------------------#
	#   Grammer.chaファイルの変更   #
	
	# 読み込み
	my $grammercha = $self->{grammercha};
	my $temp = ''; my $khflg = 0;
	open (GRA,"$grammercha") or 
		gui_errormsg->open(
			type    => 'file',
			thefile => $grammercha
		);
	while (<GRA>){
		chomp;
		if ($_ eq '; by KH Coder, start.'){
			$khflg = 1;
			next;
		}
		elsif ($_ eq '; by KH Coder, end.'){
			$khflg = 0;
			next;
		}
		if ($khflg){
			next;
		} else {
			$temp .= "$_\n";
		}
	}
	close (GRA);
	
	# 編集
	my $temp2 = '(複合名詞)'."\n".'(タグ)'."\n";
	Jcode::convert(\$temp2,'sjis','euc');
	$temp .= '; by KH Coder, start.'."\n"."$temp2".'; by KH Coder, end.';
	
	# 書き出し
	my $temp_file = 'grammercha.tmp';
	while (-e $temp_file){
		$temp_file .= '.tmp';
	}
	open (GRAO,">$temp_file") or
		gui_errormsg->open(
			type    => 'file',
			thefile => $temp_file
		);
	print GRAO "$temp";
	close (GRAO);
	
	# もとファイルの待避
	my $n = 0;
	while (-e $grammercha.".$n.tmp"){
		++$n;
	}
	rename($grammercha, $grammercha.".$n.tmp") or 
		gui_errormsg->open(
			type    => 'file',
			thefile => $grammercha.".$n.tmp"
		)
	;
	
	# 新ファイルのコピー
	rename ("$temp_file","$grammercha") or 
		gui_errormsg->open(
			type    => 'file',
			thefile => $grammercha
		)
	;

	# 待避ファイルを削除
	unlink($grammercha.".$n.tmp");

	#-----------------------------#
	#   chasen.rcファイルの変更   #

	my $chasenrc = $self->{chasenrc};

	# 読み込み
	$temp = ''; $khflg = 0;
	open (GRA,"$chasenrc") or
		gui_errormsg->open(
			type    => 'file',
			thefile => "$chasenrc"
		);
	while (<GRA>){
		chomp;
		if ($_ eq '; by KH Coder, start.'){
			$khflg = 1;
			next;
		}
		elsif ($_ eq '; by KH Coder, end.'){
			$khflg = 0;
			next;
		}
		if ($khflg){
			next;
		} else {
			$temp .= "$_\n";
		}
	}
	close (GRA);
	
	# 編集
	$temp2  = "(文法ファイル  \"$self->{dic_dir}\")\n";
	$temp2 .= '(注釈 (("<" ">") (タグ)) )'."\n";
	if ($self->{use_hukugo}){
		$temp2 .= $self->hukugo_chasenrc;
		#print Jcode->new($self->hukugo_chasenrc)->sjis;
	}
	Jcode::convert(\$temp2,'sjis','euc');
	$temp .= '; by KH Coder, start.'."\n"."$temp2".'; by KH Coder, end.';

	# 書き出し
	$temp_file = 'chasenrc.tmp';
	while (-e $temp_file){
		$temp_file .= '.tmp';
	}
	open (GRAO,">$temp_file") or
		gui_errormsg->open(
			type    => 'file',
			thefile => $temp_file
		);
	print GRAO "$temp";
	close (GRAO);
	
	# もとファイルの待避
	my $n = 0;
	while (-e $chasenrc.".$n.tmp"){
		++$n;
	}
	rename($chasenrc, $chasenrc.".$n.tmp") or 
		gui_errormsg->open(
			type    => 'file',
			thefile => "Rename: ".$chasenrc.".$n.tmp"
		)
	;
	
	# 新ファイルのコピー
	rename ("$temp_file","$chasenrc") or 
		gui_errormsg->open(
			type    => 'file',
			thefile => "Rename: ".$chasenrc
		)
	;

	# 待避先ファイルの削除
	unlink($chasenrc.".$n.tmp");

	return 1;
}

sub path_check{
	if ($::config_obj->os ne 'win32'){
		return 1;
	}

	my $self = shift;
	my $path = $self->chasen_path;

	if (not (-e $path) or not ($path =~ /chasen\.exe\Z/i) ){
		gui_errormsg->open(
			type   => 'msg',
			window => \$gui_sysconfig::inis,
			msg    => kh_msg->get('path_error'),
		);
		return 0;
	}
	return 1;
}


1;
__END__

1;
