package gui_window::r_plot_opt;
use base qw(gui_window);

use gui_window::r_plot_opt::word_cls;
use gui_window::r_plot_opt::word_corresp;
use gui_window::r_plot_opt::cod_cls;
use gui_window::r_plot_opt::cod_corresp;

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
	my $ff = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 4,
	);

	$ff->Label(
		-text => $self->gui_jchar('フォントサイズ：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_font_size} = $ff->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	
	if ($args{command_f} =~ /cex=([0-9\.]+)[, \)]/){
		my $cex = $1;
		$cex *= 100;
		$self->{entry_font_size}->insert(0,$cex);
	} else {
		$self->{entry_font_size}->insert(0,'80');
	}
	$self->{entry_font_size}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_font_size});

	$ff->Label(
		-text => $self->gui_jchar('%'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$ff->Label(
		-text => $self->gui_jchar('  プロットサイズ：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_plot_size} = $ff->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	if ($args{size}){
		$self->{entry_plot_size}->insert(0,$args{size});
	} else {
		$self->{entry_plot_size}->insert(0,'480');
	}
	$self->{entry_plot_size}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_plot_size});


	$self->{win_obj}->Button(
		-text => $self->gui_jchar('キャンセル'),
		-font => "TKFN",
		-width => 8,
		-command => sub{ $self->{win_obj}->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2, -pady => 2);

	$self->{win_obj}->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{ $self->{win_obj}->after(10,sub{$self->calc;});}
	)->pack(-side => 'right', -pady => 2);

	return $self;
}


1;