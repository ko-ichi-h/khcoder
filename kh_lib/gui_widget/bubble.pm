package gui_widget::bubble;
use base qw(gui_widget);
use strict;
use Tk;
use utf8;
use Jcode;

sub _new{
	my $self = shift;
	
	my $win = $self->parent->Frame();
	
	my $f1 = $win->Frame()->pack(-fill => 'x');
	
	$self->{check_bubble}    = 0   unless defined $self->{check_bubble};
	$self->{chk_resize_vars} = 1   unless defined $self->{chk_resize_vars};
	$self->{chk_std_radius}  = 0   unless defined $self->{chk_std_radius};
	$self->{num_size}        = 100 unless defined $self->{num_size};
	$self->{num_var}         = 100 unless defined $self->{num_var};
	$self->{use_alpha}       = 1   unless defined $self->{use_alpha};
	
	$self->{chkw_main} = $f1->Checkbutton(
		-text     => kh_msg->get('bubble'), # バブルプロット：
		-variable => \$self->{check_bubble},
		-command  => sub{ $self->refresh_std_radius;},
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);

	$self->{lab_size1} = $f1->Label(
		-text => kh_msg->get('size'), # バブルの大きさ
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
	$self->{ent_size}->bind("<KP_Enter>", $self->{command})
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
				-text     => kh_msg->get('variable'), # 変数の値 / 見出しの大きさも可変に
				-variable => \$self->{chk_resize_vars},
				-anchor => 'w',
				-state => 'disabled',
		)->pack(-anchor => 'w');
	}

	if ($self->{type} eq 'corresp'){
	
		my $frm_alpha = $win->Frame()->pack(
			-fill => 'x',
		);

		$frm_alpha->Label(
			-text => '  ',
			-font => "TKFN",
		)->pack(-anchor => 'w', -side => 'left');

		$self->{chkw_alpha} = $frm_alpha->Checkbutton(
			-variable => \$self->{use_alpha},
			-text     => kh_msg->get('gui_window::word_mds->r_alpha'), 
		)->pack(-anchor => 'w');
	}

	if ($self->{breaks}) {
		my $frm_breaks = $win->Frame()->pack(
			-fill => 'x',
			-expand => 1,
		);
		
		$frm_breaks->Label(
			-text => '  ',
			-font => "TKFN",
		)->pack(-anchor => 'w', -side => 'left');
		
		$self->{lab_breaks} = $frm_breaks->Label(
			-text => kh_msg->get('breaks'),
			-font => "TKFN",
		)->pack(-anchor => 'w', -side => 'left');
		
		$self->{ent_breaks} = $frm_breaks->Entry(
			-font       => "TKFN",
			-width      => 15,
			-background => 'white',
		)->pack(-side => 'left', -fill => 'x', -expand => 1, -padx => 2, -pady => 2);
		
		$self->{ent_breaks}->insert(0,$self->{breaks});
		
		$self->{ent_breaks}->bind("<Key-Return>", $self->{command})
			if defined( $self->{command} );
		$self->{ent_breaks}->bind("<KP_Enter>", $self->{command})
			if defined( $self->{command} );
	}
	
	
	$self->refresh_std_radius;
	$self->{win_obj} = $win;
	return $self;
}

sub refresh_std_radius{
	my $self = shift;
	
	my @temp = (
		#$self->{chkw_std_radius},
		$self->{chkw_resize_vars},
		$self->{lab_size1},
		$self->{lab_size2},
		$self->{ent_size},
		#$self->{lab_var1},
		#$self->{lab_var2},
		#$self->{ent_var},
		$self->{chkw_alpha},
	);
	
	if ($self->{breaks}) {
		push @temp, $self->{lab_breaks} if $self->{lab_breaks};
		push @temp, $self->{ent_breaks} if $self->{ent_breaks};
	}
	
	my $state = 'disabled';
	$state = 'normal' if $self->{check_bubble};
	
	foreach my $i (@temp){
		$i->configure(-state => $state) if $i;
	}

	if ($self->{command2}) {
		&{$self->{command2}};
	}


	#if ( $self->{check_bubble} == 1 && $self->{chk_std_radius} == 0 ){
	#	foreach my $i ($self->{lab_var1},$self->{lab_var2},$self->{ent_var}){
	#		$i->configure(-state => 'disable') if $i;
	#	}
	#}
}


#----------------------#
#   設定へのアクセサ   #

sub check_bubble{
	my $self = shift;
	return gui_window->gui_jg( $self->{check_bubble} );
}

sub chk_resize_vars{
	my $self = shift;
	return gui_window->gui_jg( $self->{chk_resize_vars} );
}

sub chk_std_radius{
	my $self = shift;
	return 0;
}

sub size{
	my $self = shift;
	return gui_window->gui_jgn( $self->{ent_size}->get );
}

sub breaks{
	my $self = shift;
	if ($self->{breaks}) {
		return gui_window->gui_jgn( $self->{ent_breaks}->get );
	} else {
		return undef;
	}
}

sub var{
	my $self = shift;
	return 100;
}

sub alpha{
	my $self = shift;
	return gui_window->gui_jg( $self->{use_alpha} );
}


1;