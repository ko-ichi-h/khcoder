package kh_clipboard;

use strict;
use utf8;

# Usage:
# kh_clipboard->string( $text_data );

sub string{
	my $class = shift;
	my $string = shift;

	if ( $::config_obj->os eq 'win32' ){
		$::main_gui->win_obj->clipboardClear;
		$::main_gui->win_obj->clipboardAppend($string);
	} else {
		require Clipboard;
		Clipboard->import() unless $Clipboard::driver;
		Clipboard->copy( Encode::encode($::config_obj->os_code,$string) );
	}

	return 1;
}


1;
