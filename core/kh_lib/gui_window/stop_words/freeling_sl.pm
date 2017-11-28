package gui_window::stop_words::freeling_sl;

use strict;
use base qw(gui_window::stop_words);

sub method{
	return 'freeling';
}

sub method_name{
	return 'FreeLing';
}

sub locale_name{
	return 'sl';
}

sub win_name{
	return 'w_stopwords_freeling_sl';
}
1;