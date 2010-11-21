package gui_widget::words_bayes;
use base qw(gui_widget);
use strict;
use Tk;

sub _new{
	my $self = shift;

	my $left = $self->parent->Frame()->pack(-fill => 'both', -expand => 1);

	# ����ñ�̤�����
	unless ($self->{type} eq 'corresp'){
		my $l1 = $left->Frame()->pack(-fill => 'x', -pady => 2);
		$l1->Label(
			-text => gui_window->gui_jchar('��ʬ���ñ�̡�'),
			-font => "TKFN"
		)->pack(-side => 'left');
		my %pack = (
				-anchor => 'e',
				-pady   => 0,
				-side   => 'left'
		);
		$self->{tani_obj} = gui_widget::tani->open(
			parent => $l1,
			pack   => \%pack,
			command => sub{$self->load_ov;},
			#dont_remember => 1,
		);
	}

	# �����ѿ�������
	$self->{opt_frame} = $left->Frame()->pack(-fill => 'x', -pady => 2);
	$self->{opt_frame}->Label(
		-text => gui_window->gui_jchar('���ؽ����볰���ѿ���'),
		-font => "TKFN"
	)->pack(-side => 'left');

	# �Ǿ�������и���
	$left->Label(
		-text => gui_window->gui_jchar('���Ǿ�/���� �и����ˤ���μ������'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 2);
	my $l2 = $left->Frame()->pack(-fill => 'x', -pady => 2);
	$l2->Label(
		-text => gui_window->gui_jchar('�� ���Ǿ��и�����'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_min} = $l2->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_min}->insert(0,'1');
	$self->{ent_min}->bind("<Key-Return>",sub{$self->check;});
	gui_window->config_entry_focusin($self->{ent_min});
	
	$l2->Label(
		-text => gui_window->gui_jchar('�� ����и�����'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_max} = $l2->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_max}->bind("<Key-Return>",sub{$self->check;});
	gui_window->config_entry_focusin($self->{ent_max});

	# �Ǿ�������ʸ���
	$left->Label(
		-text => gui_window->gui_jchar('���Ǿ�/���� ʸ����ˤ���μ������'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 2);

	my $l3 = $left->Frame()->pack(-fill => 'x', -pady => 2);
	$l3->Label(
		-text => gui_window->gui_jchar('�� ���Ǿ�ʸ�����'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_min_df} = $l3->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_min_df}->insert(0,'1');
	$self->{ent_min_df}->bind("<Key-Return>",sub{$self->check;});
	gui_window->config_entry_focusin($self->{ent_min_df});

	$l3->Label(
		-text => gui_window->gui_jchar('�� ����ʸ�����'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_max_df} = $l3->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_max_df}->bind("<Key-Return>",sub{$self->check;});
	gui_window->config_entry_focusin($self->{ent_max_df});

	# ����ñ�̤�������б�ʬ���ѡ�
	my %pack = (
		-anchor => 'e',
		-pady   => 0,
		-side   => 'left'
	);
	if ($self->{type} eq 'corresp'){
		my $l1 = $left->Frame()->pack(-fill => 'x', -pady => 2);
		$l1->Label(
			-text => gui_window->gui_jchar('�� ��ʸ��ȸ��ʤ�ñ�̡�'),
			-font => "TKFN"
		)->pack(-side => 'left');
		$self->{tani_obj} = gui_widget::tani->open(
			parent => $l1,
			pack   => \%pack,
			dont_remember => 1,
		);
	}

	# �ʻ�ˤ��ñ��μ������
	$left->Label(
		-text => gui_window->gui_jchar('���ʻ�ˤ���μ������'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 2);
	my $l5 = $left->Frame()->pack(-fill => 'both',-expand => 1, -pady => 2);
	$l5->Label(
		-text => gui_window->gui_jchar('����'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left',-fill => 'y',-expand => 1);
	%pack = (
			-anchor => 'w',
			-side   => 'left',
			-pady   => 1,
			-fill   => 'y',
			-expand => 1
	);
	$self->{hinshi_obj} = gui_widget::hinshi->open(
		parent => $l5,
		pack   => \%pack
	);
	my $l4 = $l5->Frame()->pack(-fill => 'x', -expand => 'y',-side => 'left');
	$l4->Button(
		-text => gui_window->gui_jchar('��������'),
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $self->parent->after(10,sub{$self->{hinshi_obj}->select_all;});}
	)->pack(-pady => 3);
	$l4->Button(
		-text => gui_window->gui_jchar('���ꥢ'),
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $self->parent->after(10,sub{$self->{hinshi_obj}->select_none;});}
	)->pack();

	# �����å���ʬ
	$self->parent->Label(
		-text => gui_window->gui_jchar(
			 '�����ߤ������'
			.$self->{verb}
			.'������ο���'
		),
		-font => "TKFN"
	)->pack(-anchor => 'w');

	my $cf = $self->parent->Frame()->pack(-fill => 'x', -pady => 2);

	$cf->Label(
		-text => gui_window->gui_jchar('�� ��'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');

	$cf->Button(
		-text => gui_window->gui_jchar('�����å�'),
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $self->parent->after(10,sub{$self->check;});}
	)->pack(-side => 'left', -padx => 2);

	$self->{ent_check} = $cf->Entry(
		-font        => "TKFN",
		-background  => 'gray',
		-foreground  => 'black',
		-state       => 'disable',
	)->pack(-side => 'left', -fill => 'x', -expand => 1);
	gui_window->disabled_entry_configure($self->{ent_check});

	$self->{win_obj} = $left; # ?
	$self->settings_load;
	$self->load_ov;
	return $self;
}

#--------------------#
#   �����ѿ���ɽ��   #
sub load_ov{
	my $self = shift;
	unless ($self->{tani_obj}){return 0;}
	
	if ($self->{opt_body}){
		$self->{opt_body}->destroy;
	}
	
	# ���ѤǤ����ѿ������뤫�ɤ��������å�
	my %tani_check = ();
	foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
		$tani_check{$i} = 1;
		last if ($self->tani eq $i);
	}
	my $h = mysql_outvar->get_list;
	my @options;
	foreach my $i (@{$h}){
		if ($tani_check{$i->[0]}){
			push @options, [gui_window->gui_jchar($i->[1]), $i->[2]];
			#print "varid: $i->[2]\n";
		}
	}
	
	if (@options){
		$self->{opt_body} = gui_widget::optmenu->open(
			parent   => $self->{opt_frame},
			pack     => {-side => 'left', -padx => 2},
			options  => \@options,
			variable => \$self->{var_id},
			command  => sub{$self->rem_ov;},
		);
		if ( length($self->{last_var_id}) ){
			$self->{opt_body}->set_value( $self->{last_var_id} );
		}
	} else {
		$self->{opt_body} = gui_widget::optmenu->open(
			parent  => $self->{opt_frame},
			pack    => {-side => 'left', -padx => 2},
			options => 
				[
					[gui_window->gui_jchar('�����Բ�'), -1],
				],
			variable => \$self->{var_id},
		);
		$self->{opt_body}->configure(-state => 'disable');
	}
}

sub rem_ov{
	my $self = shift;
	$self->{last_var_id} = $self->{var_id};
}



#--------------#
#   �����å�   #

sub check{
	my $self = shift;
	
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => '�ʻ줬1�Ĥ����򤵤�Ƥ��ޤ���',
		);
		return 0;
	}
	
	my $tani2 = '';
	if ($self->{radio} == 0){
		$tani2 = gui_window->gui_jg($self->{high});
	}
	elsif ($self->{radio} == 1){
		if ( length($self->{var_id}) ){
			$tani2 = mysql_outvar::a_var->new(undef,$self->{var_id})->{tani};
		}
	}
	
	$self->{ent_check}->configure(-state => 'normal');
	$self->{ent_check}->delete(0,'end');
	$self->{ent_check}->insert(0,'counting...');
	$self->{ent_check}->configure(-state => 'disable');
	$self->{ent_check}->update;
	
	my $check = kh_nbayes->wnum(
		tani   => $self->tani,
		outvar => $self->outvar,
		hinshi => $self->hinshi,
		max    => $self->max,
		min    => $self->min,
		max_df => $self->max_df,
		min_df => $self->min_df,
	);
	
	$self->{ent_check}->configure(-state => 'normal');
	$self->{ent_check}->delete(0,'end');
	$self->{ent_check}->insert(0,$check);
	$self->{ent_check}->configure(-state => 'disable');
	
	return $check;
}

#--------------------------#
#   ������ɤ߹��ߡ���¸   #

sub settings_save{
	my $self = shift;
	my $settings;
	
	$settings->{min}    = $self->min;
	$settings->{max}    = $self->max;
	$settings->{min_df} = $self->min_df;
	$settings->{max_df} = $self->max_df;
	$settings->{tani}   = $self->tani;
	$settings->{hinshi} = $self->{hinshi_obj}->selection_get;
	
	$::project_obj->save_dmp(
		name => 'widget_words_bayes',
		var  => $settings,
	);
}

sub settings_load{
	my $self = shift;
	
	my $settings = $::project_obj->load_dmp(
		name => 'widget_words_bayes',
	) or return 0;
	
	$self->{hinshi_obj}->selection_set($settings->{hinshi});
	
	$self->min( $settings->{min} );
	$self->max( $settings->{max} );
	
	# ñ�̤�������ɤ߹��ޤʤ�
	# ��;��ǰ㤦�ͤ����ꤵ�줿�顢����ˤ��碌�롣
	# ���ޤ����ξ��ϡ�ʸ����פ�������ɤ߹��ޤʤ���
	if ( $self->tani eq $settings->{tani} ){
		$self->min_df( $settings->{min_df} );
		$self->max_df( $settings->{max_df} );
	}
	$self->check;
}


#--------------#
#   ��������   #

sub outvar{
	my $self = shift;
	return $self->{var_id};
}

sub min{
	my $self = shift;
	my $new  = shift;
	if ( defined($new) ){
		$self->{ent_min}->delete(0,'end');
		$self->{ent_min}->insert(0,$new);
	}
	return gui_window->gui_jg( $self->{ent_min}->get );
}
sub max{
	my $self = shift;
	my $new  = shift;
	if ( defined($new) ){
		$self->{ent_max}->delete(0,'end');
		$self->{ent_max}->insert(0,$new);
	}
	return gui_window->gui_jg( $self->{ent_max}->get );
}
sub min_df{
	my $self = shift;
	my $new  = shift;
	if ( defined($new) ){
		$self->{ent_min_df}->delete(0,'end');
		$self->{ent_min_df}->insert(0,$new);
	}
	return gui_window->gui_jg( $self->{ent_min_df}->get );
}
sub max_df{
	my $self = shift;
	my $new  = shift;
	if ( defined($new) ){
		$self->{ent_max_df}->delete(0,'end');
		$self->{ent_max_df}->insert(0,$new);
	}
	return gui_window->gui_jg( $self->{ent_max_df}->get );
}
sub tani{
	my $self = shift;
	return $self->{tani_obj}->tani;
}
sub hinshi{
	my $self = shift;
	return $self->{hinshi_obj}->selected;
}

1;