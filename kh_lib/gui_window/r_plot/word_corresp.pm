package gui_window::r_plot::word_corresp;
use base qw(gui_window::r_plot);

sub option1_options{
	return [
		'抽出語とドット',
		'ドット',
	] ;
}

sub option1_name{
	return ' 表示：';
}

sub win_title{
	return '抽出語・対応分析';
}

sub win_name{
	return 'w_word_corresp_plot';
}

sub base_name{
	return 'word_corresp';
}

1;