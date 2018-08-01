package gui_window::r_plot_opt::doc_cls;
use base qw(gui_window::r_plot_opt);
use strict;

sub innner{
	my $self = shift;
	my $lf  = $self->{labframe};
	my $lf1 = $lf->Frame()->pack(-pady => 2, -fill => 'x');

	# Get info from R commands
	if ( $self->{command_f} =~ /ggplot2/ ){
		$self->{check_color_cls} = 1;
	} else {
		$self->{check_color_cls} = 0;
	}
	if ( $self->{command_f} =~ /\n# UNIT: (.+?)\n/ ){
		$self->{tani} = $1;
	}
	if ( $self->{command_f} =~ /# added labels: (.+?)\n/ ){
		$self->{label} = $1;
	}
	
	# Case labels
	$lf1->Label(
			-text     => kh_msg->get('doc_label'),
			-anchor => 'w',
	)->pack(-anchor => 'w', -side => 'left');

	my @options;
	$self->{default_label} = '';
	unless (
		   $self->{tani} eq 'bun'
		|| $self->{tani} eq 'dan'
		|| $::project_obj->status_from_table == 1
	) {
		push @options, [kh_msg->get('heading'), 'heading'];
		$self->{default_label} = 'heading';
	}
	push @options, [kh_msg->get('number'), 'number'];
	$self->{default_label} = 'number' unless $self->{default_label};
	
	my $h = mysql_outvar->get_list;
	foreach my $i (@{$h}){
		if (substr($i->[1], 0, 1) eq '_'){
			next;
		}
		if ($i->[0] eq $self->{tani}){
			push @options, [$i->[1], $i->[2]];
		}
	}
	
	$self->{label_menu} = gui_widget::optmenu->open(
		parent  => $lf1,
		#width   => 19,
		pack    => { -side => 'left', -padx => 2, -pady => 2},
		options => \@options,
		variable => \$self->{label},
		command => sub {}
	);

	# Color
	$lf1->Label(
			-text     => '  ',
			-anchor => 'w',
	)->pack(-anchor => 'w', -side => 'left');

	$lf1->Checkbutton(
			-text     =>
				kh_msg->get('gui_widget::r_cls->color'), # クラスターの色分け
			-variable => \$self->{check_color_cls},
			-anchor => 'w',
	)->pack(-anchor => 'w', -side => 'left');

	return $self;
}

sub calc{
	my $self = shift;
	$self->_configure_mother;

	my $r_command = '';
	if ($self->{command_f} =~ /\A(.+)# start dendro.+/s){
		$r_command = $1;
		#$r_command = Jcode->new($r_command)->euc
		#	if $::config_obj->os eq 'win32';
	} else {
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->gget('r_net_msg_fail'), # 調整に失敗しましました。
		);
		print "$self->{command_f}\n";
		$self->close;
		return 0;
	}

	# Delete older added labels
	$r_command =~ s/\n.+? # added labels: .*?\n/\n/g;
	
	# Add case label
	my $label = '';
	unless ( $self->{label} eq $self->{default_label} ){
		# Number
		if ($self->{label} eq 'number') {
			$label = "d_labels <- as.character( 1:length(d_selection) )";
		}
		# Heading
		elsif ($self->{label} eq 'heading') {
			my $midashi = mysql_getheader->get_selected(tani => $self->{tani});
			$label = "d_labels <- c(";
			foreach my $i (@{$midashi}){
				$label .= "\"$i\",";
			}
			chop $label;
			$label .= ")";
		}
		# Variable
		elsif ($self->{label}){
			my $var_obj = mysql_outvar::a_var->new(undef,$self->{label});
			
			my $sql = '';
			$sql .= "SELECT $var_obj->{column} FROM $var_obj->{table} ";
			$sql .= "ORDER BY id";
			
			$label = "d_labels <- c(";
			my $h = mysql_exec->select($sql,1)->hundle;
			my $n = 0;
			while (my $i = $h->fetch){
				$i->[0] = Encode::decode('utf8', $i->[0]) unless utf8::is_utf8($i->[0]);
				if ( length( $var_obj->{labels}{$i->[0]} ) ){
					my $t = $var_obj->{labels}{$i->[0]};
					$t =~ s/"/ /g;
					$label .= "\"$t\",";
				} else {
					$label .= "\"$i->[0]\",";
				}
				++$n;
			}
			
			chop $label;
			$label .= ")";
		}
		$label .= " # added labels: $self->{label}\n\n";
		$label .= "d_labels <- d_labels[d_selection] # added labels: $self->{label}\n";
	}
	$r_command .= $label;

	my ($w, $h) = ($::config_obj->plot_size_codes, $self->{font_obj}->plot_size);

	my $size_variable = $h;
	if ($self->{check_color_cls}){
		$r_command .= &gui_window::doc_cls::r_command_dendro2(
			$self->{font_obj}->font_size
		);
	} else {
		$r_command .= &gui_window::doc_cls::r_command_dendro1(
			$self->{font_obj}->font_size
		);
		($w, $h) = ($h, $w);
	}

	my $wait_window = gui_wait->start;

	my $plot = kh_r_plot->new(
		name      => 'doc_cls_dendro',
		command_f => $r_command,
		width     => $w,
		height    => $h,
		font_size => $self->{font_obj}->font_size,
	) or return 0;
	$plot->rotate_cls unless $self->{check_color_cls};

	if ($::main_gui->if_opened('w_doc_cls_plot')){
		$::main_gui->get('w_doc_cls_plot')->close;
	}

	gui_window::r_plot::doc_cls->open(
		plots       => [$plot],
		ax          => $self->{ax},
		plot_size   => $size_variable,
	);

	$plot = undef;
	$self->{command_f} = undef;

	$wait_window->end(no_dialog => 1);
	$self->close;
	return 1;

}

sub win_title{
	return kh_msg->get('win_title'); # 抽出語・クラスター分析：調整
}

sub win_name{
	return 'w_doc_cls_plot_opt';
}

1;