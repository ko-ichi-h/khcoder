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
	#print "$self->{dic_dir}\n";
	
	# Grammer.chaファイルの変更
	
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
	my $temp_file = 'temp.txt';
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
	
	unlink $grammercha;
	rename ("$temp_file","$grammercha");
	
	my $chasenrc = $self->{chasenrc};
	
	
	# chasen.rcファイルの変更
	
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
		$temp2 .= '(連結品詞'."\n";
		$temp2 .= "\t".'((複合名詞)'."\n";
		$temp2 .= "\t\t".'(名詞)'."\n";
		$temp2 .= "\t\t".'(接頭詞名詞接続)'."\n";
		$temp2 .= "\t\t".'(接頭詞数接続)'."\n";
		$temp2 .= "\t\t".'(記号 一般)'."\n";
		$temp2 .= "\t".')'."\n";
		$temp2 .= ')'."\n";
	}
	Jcode::convert(\$temp2,'sjis','euc');
	$temp .= '; by KH Coder, start.'."\n"."$temp2".'; by KH Coder, end.';

	# 書き出し
	$temp_file = 'temp.txt';
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
	unlink $chasenrc;
	rename ("$temp_file","$chasenrc");
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
			msg    => "Chasen.exeのパスが不正です"
		);
		return 0;
	}
	return 1;
}


1;
__END__

1;
