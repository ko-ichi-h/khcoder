package gui_window::cls_height::cod;
use strict;
use base qw(gui_window::cls_height);


sub win_title{
	my $self = shift;
	return $self->gui_jt( kh_msg->get('win_title') ); # コードのクラスター分析：併合水準
}

sub win_name{
	return 'w_cod_cls_height';
}

sub _save{
	my $self = shift;
	my $path = shift;
	
	$self->{plots}{$self->{type}}{$self->{range}}->{command_f}
		=~ s/\nplot\(hcl.+?\nrect\.hclust\(hcl.+?\n/\n/;
	
	$self->{plots}{$self->{type}}{$self->{range}}->save($path) if $path;
}

1;