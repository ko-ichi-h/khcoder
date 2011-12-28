package kh_msg;

use strict;
use YAML qw(LoadFile);

use utf8;
use Encode;

my $utf8 = find_encoding('utf8');

my $msg;
my $msg_fb;
my $debug = 1;

sub get{
	# キー作成
	          shift;
	my $key = shift;
	my $caller = shift;
	
	if ( length($caller) ){
	#	print "kh_msg: caller is specified: $caller, $key\n" if $debug;
	}
	$caller = (caller)[0]    unless length($caller);
	
	if ($key =~ /^(.+)\->(.+)$/){
		$key    = $2;
		$caller = $1;
		#print "kh_msg: caller is specified: $caller, $key\n" if $debug;
	}
		
	$caller =~ s/::(linux|win32)//go;

	# メッセージをロード
	&load unless $msg;

	# メッセージを返す
	my $t = '';
	if ( defined( $msg->{$caller}{$key} ) ){
		$t = $msg->{$caller}{$key};
	}
	elsif ( defined($msg_fb->{$caller}{$key}) ) {
		$t = $msg_fb->{$caller}{$key};
		print "kh_msg: fall back: $caller, $key\n";
	} else {
		$t = 'error: no msg!';
		print "kh_msg: no msg: $caller, $key\n";
	}
	
	unless ( utf8::is_utf8($t) ){
		$t = $utf8->decode($t);
	}
	return $t;
}

sub gget{
	# キー作成
	          shift;
	my $key = shift;
	my $caller = 'global';
	
	# メッセージをロード
	&load unless $msg;

	# メッセージを返す
	my $t = '';
	if ( defined( $msg->{$caller}{$key} ) ){
		$t = $msg->{$caller}{$key};
	}
	elsif ( defined($msg_fb->{$caller}{$key}) ) {
		$t = $msg_fb->{$caller}{$key};
		print "kh_msg: fall back: $caller, $key\n";
	} else {
		$t = 'error: no msg!';
		print "kh_msg: no msg: $caller, $key\n";
	}
	
	unless ( utf8::is_utf8($t) ){
		$t = $utf8->decode($t);
	}
	return $t;
}

sub load{
	my $file =
		Cwd::cwd
		.'/config/'
		.'msg.'
		.$::config_obj->msg_lang
	;
	if (-e $file){
		$msg = LoadFile($file) or die;
	}
	
	unless ($::config_obj->msg_lang eq 'jp'){
		my $file_fb =
			Cwd::cwd
			.'/config/'
			.'msg.'
			.'jp'
		;
		$msg_fb = LoadFile($file_fb) or die;
		
		if ($debug){
			# 足りないメッセージや重複をチェック
			my %chk = ();
			foreach my $i (keys %{$msg_fb}){
				++$chk{$i};
				unless ($chk{$i} == 1){
					print "Duplicated msg in ".$::config_obj->msg_lang.".msg: $i\n";
				}
				unless ( length( $msg->{$i} ) ){
					print "Missing from ".$::config_obj->msg_lang.".msg: $i\n";
				}
			}
			%chk = ();
			foreach my $i (keys %{$msg}){
				++$chk{$i};
				unless ($chk{$i} == 1){
					print "Duplicated msg in jp.msg: $i\n";
				}
				unless ( length( $msg_fb->{$i} ) ){
					print "Missing from jp.msg: $i\n";
				}
			}
		}
	}

}


1;