package gui_window::stop_words::freeling_ca;

use strict;
use base qw(gui_window::stop_words);





#--------------#
#   アクセサ   #

sub method{
	return 'freeling';
}

sub method_name{
	return 'FreeLing';
}

sub locale_name{
	return 'ca';
}

sub win_name{
	return 'w_stopwords_freeling_ca';
}
1;