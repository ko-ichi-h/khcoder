package gui_window::cod_out::spss;
use base qw(gui_window::cod_out);

use strict;

sub _save{
	my $self = shift;
	

}


sub win_label{
	return 'コーディング結果の出力：SPSSファイル';
}

sub win_name{
	return 'w_cod_save_spss';
}
1;