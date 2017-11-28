package gui_window::stop_words::stanford_en;

use strict;
use base qw(gui_window::stop_words);





#--------------#
#   アクセサ   #

sub method{
	return 'stanford';
}

sub method_name{
	return 'Stanford POS Tagger';
}

sub locale_name{
	return 'en';
}

sub win_name{
	return 'w_stopwords_stanford_en';
}
1;