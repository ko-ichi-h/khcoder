package gui_window::r_plot_opt;
use base qw(gui_window);

use gui_window::r_plot_opt::word_cls;
use gui_window::r_plot_opt::word_corresp;
use gui_window::r_plot_opt::word_mds;
use gui_window::r_plot_opt::word_netgraph;
use gui_window::r_plot_opt::word_som;
use gui_window::r_plot_opt::cod_cls;
use gui_window::r_plot_opt::cod_corresp;
use gui_window::r_plot_opt::cod_mds;
use gui_window::r_plot_opt::cod_netg;
use gui_window::r_plot_opt::cod_som;
use gui_window::r_plot_opt::cod_mat;
use gui_window::r_plot_opt::selected_netgraph;
use gui_window::r_plot_opt::doc_cls;

sub _new{
	my $self = shift;
	my %args = @_;
	
	$self->{command_f} = $args{command_f};
	
	$self->{win_obj}->title($self->gui_jt( $self->win_title ));
	
	my $lf = $self->{win_obj}->LabFrame(
		-label => 'Options',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x', -expand => 0);
	
	$self->{labframe} = $lf;
	$self->innner;

	# フォントサイズ
	$self->{font_obj} = gui_widget::r_font->open(
		parent       => $lf,
		command      => sub{ $self->calc; },
		pack    => {
			-anchor   => 'w',
		},
		r_com     => $args{command_f},
		plot_size => $args{size},
	);

	# OK, Cancel
	$self->{win_obj}->Button(
		-text => kh_msg->gget('cancel'), # キャンセル
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->close;}
	)->pack(-side => 'right',-padx => 2, -pady => 2);

	$self->{win_obj}->Button(
		-text => kh_msg->gget('ok'),
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->calc;}
	)->pack(-side => 'right', -pady => 2);

	return $self;
}


1;