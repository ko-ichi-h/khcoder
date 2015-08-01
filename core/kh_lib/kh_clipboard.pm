package kh_clipboard;

use strict;
use utf8;

sub string{
	my $class = shift;
	my $string = shift;

	$::main_gui->win_obj->clipboardClear;
	$::main_gui->win_obj->clipboardAppend($string);

	return 1;
}


1;


# この方法では日本語Windowsで中国語（Unicode文字）を扱えない
# use Clipboard;
# Clipboard->copy( Encode::encode($::config_obj->os_code,$clip) );
