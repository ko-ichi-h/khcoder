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
	open (GRAO,">temp.txt") or
		gui_errormsg->open(
			type    => 'file',
			thefile => 'temp.txt'
		);
	print GRAO "$temp";
	close (GRAO);

	unlink $grammercha;
	rename ("temp.txt","$grammercha");

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
		$temp2 .= '(連結品詞'."\n";
		$temp2 .= "\t".'((複合名詞)'."\n";
		$temp2 .= "\t\t".'(名詞)'."\n";
		$temp2 .= "\t\t".'(接頭詞名詞接続)'."\n";
		$temp2 .= "\t\t".'(接頭詞数接続)'."\n";
		$temp2 .= "\t\t".'(記号 一般)'."\n";
		$temp2 .= "\t".')'."\n";
		$temp2 .= ')'."\n";
	}
#	Jcode::convert(\$temp2,'sjis','euc');
	$temp .= "\n".'; by KH Coder, start.'."\n"."$temp2".'; by KH Coder, end.';

	# 書き出し
	open (GRAO,">temp.txt") or
		gui_errormsg->open(
			type    => 'file',
			thefile => "temp.txt"
		);
	print GRAO "$temp";
	close (GRAO);
	unlink $chasenrc;
	rename ("temp.txt","$chasenrc");
}

sub path_check{
	return 1;
}


1;
__END__

1;
