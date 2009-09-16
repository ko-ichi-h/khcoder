package kh_sysconfig::linux::chasen;
use strict;
use base qw(kh_sysconfig::linux);
use gui_errormsg;

sub config_morph{
	my $self = shift;
	
	# Grammer.chaファイルの変更

	unless (-e $self->grammarcha_path){
		return 0;
	}
	# 読み込み
	my $grammercha = $self->grammarcha_path;
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
#	Jcode::convert(\$temp2,'sjis','euc');
	$temp .= "\n".'; by KH Coder, start.'."\n"."$temp2".'; by KH Coder, end.';

	# 書き出し
	my $temp_file = 'temp.txt';
	while (-e $temp_file){
		$temp_file .= '.tmp';
	}
	open (GRAO,">$temp_file") or
		gui_errormsg->open(
			type    => 'file',
			thefile => "$temp_file"
		);
	print GRAO "$temp";
	close (GRAO);

	unlink $grammercha;
	rename ($temp_file,$grammercha);

	# chasen.rcファイルの変更
	
	unless (-e $self->chasenrc_path){
		return 0;
	}
	# 読み込み
	my $chasenrc = $self->chasenrc_path;
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
	$temp2 = '(注釈 (("<" ">") (タグ)) )'."\n";
	if ($self->{use_hukugo}){
		$temp2 .= $self->hukugo_chasenrc;
	}
#	Jcode::convert(\$temp2,'sjis','euc');
	$temp .= "\n".'; by KH Coder, start.'."\n"."$temp2".'; by KH Coder, end.';

	# 書き出し
	$temp_file = 'temp.txt';
	while (-e $temp_file){
		$temp_file .= '.tmp';
	}
	open (GRAO,">$temp_file") or
		gui_errormsg->open(
			type    => 'file',
			thefile => "$temp_file"
		);
	print GRAO "$temp";
	close (GRAO);
	unlink $chasenrc;
	rename ("$temp_file","$chasenrc");
}

sub path_check{
	my $self = shift;
	if (-e $self->chasenrc_path && -e $self->grammarcha_path){
		return 1;
	} else {
		return 0;
	}
}

1;
