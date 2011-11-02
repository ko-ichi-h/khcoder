package kh_msg;

use strict;
use YAML qw(LoadFile);

use utf8;
use Encode;

my $utf8 = find_encoding('utf8');

my $msg;
my $msg_fb;

sub get{
	# キー作成
	          shift;
	my $key = shift;
	$key = (caller)[0].'->'.$key;
	$key =~ s/::(linux|win32)//go;

	# メッセージをロード
	&load unless $msg;

	# メッセージを返す
	my $t = '';
	if ( length( $msg->{$key} ) ){
		$t = $msg->{$key};
	}
	elsif ( length($msg_fb->{$key}) ) {
		$t = $msg_fb->{$key};
		print "kh_msg: fall back: $key\n";
	} else {
		$t = 'error: no msg!';
		print "kh_msg: no msg: $key\n";
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
	$key = 'global->'.$key;
	
	# メッセージをロード
	&load unless $msg;

	# メッセージを返す
	my $t = '';
	if ( length( $msg->{$key} ) ){
		$t = $msg->{$key};
	}
	elsif ( length($msg_fb->{$key}) ) {
		$t = $msg_fb->{$key};
		print "kh_msg: fall back: $key\n";
	} else {
		$t = 'error: no msg!';
		print "kh_msg: no msg: $key\n";
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
	}
}


1;