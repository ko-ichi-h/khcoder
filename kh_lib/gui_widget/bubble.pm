package gui_widget::bubble;
use base qw(gui_widget);
use strict;
use Tk;
use Jcode;

sub _new{
	my $self = shift;
	
	my $win = $self->parent->Frame();
	
	my $f1 = $win->Frame()->pack(-fill => 'x');
	
	$self->{check_bubble}    = 0   unless defined $self->{check_bubble};
	$self->{chk_resize_vars} = 1   unless defined $self->{chk_resize_vars};
	$self->{chk_std_radius}  = 1   unless defined $self->{chk_std_radius};
	$self->{num_size}        = 100 unless defined $self->{num_size};
	$self->{num_var}         = 100 unless defined $self->{num_var};
	
	$f1->Checkbutton(
		-text     => gui_window->gui_jchar('バブルプロット：'),
		-variable => \$self->{check_bubble},
		-command  => sub{ $self->refresh_std_radius;},
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);

	$self->{lab_size1} = $f1->Label(
		-text => gui_window->gui_jchar('バブルの大きさ'),
		-font => "TKFN",
	)->pack(-anchor => 'w', -side => 'left');

	$self->{ent_size} = $f1->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_size}->insert(0,$self->{num_size});
	gui_window->config_entry_focusin($self->{ent_size});
	$self->{ent_size}->bind("<Key-Return>", $self->{command})
		if defined( $self->{command} );


	$self->{lab_size2} = $f1->Label(
		-text => '%',
		-font => "TKFN",
	)->pack(-anchor => 'w', -side => 'left');


	if ($self->{type} eq 'corresp'){
		my $frm_std_radius = $win->Frame()->pack(
			-fill => 'x',
		);

		$frm_std_radius->Label(
			-text => '  ',
			-font => "TKFN",
		)->pack(-anchor => 'w', -side => 'left');

		$self->{chkw_resize_vars} = $frm_std_radius->Checkbutton(
				-text     => gui_window->gui_jchar('変数の値 / 見出しの大きさも可変に','euc'),
				-variable => \$self->{chk_resize_vars},
				-anchor => 'w',
				-state => 'disabled',
		)->pack(-anchor => 'w');
	}

	my $f2 = $win->Frame()->pack(
		-fill => 'x',
	);

	$f2->Label(
		-text => '  ',
		-font => "TKFN",
	)->pack(-anchor => 'w', -side => 'left');

	$self->{chkw_std_radius} = $f2->Checkbutton(
		-text     => gui_window->gui_jchar('バブルの大きさを標準化：','euc'),
		-variable => \$self->{chk_std_radius},
		-anchor => 'w',
		-state => 'disabled',
	)->pack(-anchor => 'w', -side => 'left');

	$self->{lab_var1} = $f2->Label(
		-text => gui_window->gui_jchar('分散'),
		-font => "TKFN",
	)->pack(-anchor => 'w', -side => 'left');

	$self->{ent_var} = $f2->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_var}->insert(0,$self->{num_var});
	gui_window->config_entry_focusin($self->{ent_var});
	$self->{ent_var}->bind("<Key-Return>", $self->{command})
		if defined( $self->{command} );

	$self->{lab_var2} = $f2->Label(
		-text => '%',
		-font => "TKFN",
	)->pack(-anchor => 'w', -side => 'left');


	$self->refresh_std_radius;
	$self->{win_obj} = $win;
	return $self;
}

sub refresh_std_radius{
	my $self = shift;
	
	my @temp = (
		$self->{chkw_std_radius},
		$self->{chkw_resize_vars},
		$self->{lab_size1},
		$self->{lab_size2},
		$self->{ent_size},
		$self->{lab_vaar1},
		$self->{lab_var2},
		$self->{ent_var},
	);
	
	my $state = 'disabled';
	$state = 'normal' if $self->{check_bubble};
	
	foreach my $i (@temp){
		$i->configure(-state => $state) if $i;
	} 

}


#----------------------#
#   設定へのアクセサ   #

sub check_bubble{
	my $self = shift;
	return gui_window->gui_jg( $self->{check_bubble} );
}

sub chk_resize_vars{
	my $self = shift;
	return gui_window->gui_jg( $self->{check_bubble} );
}

sub chk_std_radius{
	my $self = shift;
	return gui_window->gui_jg( $self->{chk_resize_vars} );
}

sub size{
	my $self = shift;
	return gui_window->gui_jg( $self->{ent_size}->get );
}

sub var{
	my $self = shift;
	return gui_window->gui_jg( $self->{ent_var}->get );
}



1;