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
	
	# Delete commands to draw the dendrogram (normal)
	$self->{plots}{$self->{type}}{$self->{range}}->{command_f}
		=~ s/\nplot\(hcl.+?\n/\n\n/;
	$self->{plots}{$self->{type}}{$self->{range}}->{command_f}
		=~ s/\trect.hclust.+?\n/\n/;

	# Delete commands to draw the dendrogram (ggplot2)
	$self->{plots}{$self->{type}}{$self->{range}}->{command_f}
		=~ s/\n\tprint.+?\n/\n/g;
	$self->{plots}{$self->{type}}{$self->{range}}->{command_f}
		=~ s/\tgrid\..+?\n/\n/g;
	$self->{plots}{$self->{type}}{$self->{range}}->{command_f}
		=~ s/\tquartzFonts.+?\n/\n/g;
	$self->{plots}{$self->{type}}{$self->{range}}->{command_f}
		=~ s/show_bar <\- 1/show_bar <\- 0/g;
	
	$self->{plots}{$self->{type}}{$self->{range}}->save($path) if $path;
}

1;