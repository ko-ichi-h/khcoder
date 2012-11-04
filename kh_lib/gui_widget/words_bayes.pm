package gui_widget::words_bayes;
use base qw(gui_widget);
use strict;
use Tk;

sub _new{
	my $self = shift;

	my $left = $self->parent->Frame()->pack(-fill => 'both', -expand => 1);

	# 集計単位の選択
	unless ($self->{type} eq 'corresp'){
		my $l1 = $left->Frame()->pack(-fill => 'x', -pady => 2);
		$l1->Label(
			-text => kh_msg->get('unit'), # ・分類の単位：
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

	# 外部変数の選択
	$self->{opt_frame} = $left->Frame()->pack(-fill => 'x', -pady => 2);
	$self->{opt_frame}->Label(
		-text => kh_msg->get('var'), # ・学習する外部変数：
		-font => "TKFN"
	)->pack(-side => 'left');

	# 最小・最大出現数
	$left->Label(
		-text => kh_msg->get('gui_widget::words->by_tf'), # ・最小/最大 出現数による語の取捨選択
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 2);
	my $l2 = $left->Frame()->pack(-fill => 'x', -pady => 2);
	$l2->Label(
		-text => kh_msg->get('gui_widget::words->min_tf'), # 　 　最小出現数：
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_min} = $l2->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_min}->insert(0,'1');
	$self->{ent_min}->bind("<Key-Return>",sub{$self->check;});
	$self->{ent_min}->bind("<KP_Enter>",sub{$self->check;});
	gui_window->config_entry_focusin($self->{ent_min});
	
	$l2->Label(
		-text => kh_msg->get('gui_widget::words->max_tf'), # 　 最大出現数：
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_max} = $l2->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_max}->bind("<Key-Return>",sub{$self->check;});
	$self->{ent_max}->bind("<KP_Enter>",sub{$self->check;});
	gui_window->config_entry_focusin($self->{ent_max});

	# 最小・最大文書数
	$left->Label(
		-text => kh_msg->get('gui_widget::words->by_df'), # ・最小/最大 文書数による語の取捨選択
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 2);

	my $l3 = $left->Frame()->pack(-fill => 'x', -pady => 2);
	$l3->Label(
		-text => kh_msg->get('gui_widget::words->min_df'), # 　 　最小文書数：
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_min_df} = $l3->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_min_df}->insert(0,'1');
	$self->{ent_min_df}->bind("<Key-Return>",sub{$self->check;});
	$self->{ent_min_df}->bind("<KP_Enter>",sub{$self->check;});
	gui_window->config_entry_focusin($self->{ent_min_df});

	$l3->Label(
		-text => kh_msg->get('gui_widget::words->max_df'), # 　 最大文書数：
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_max_df} = $l3->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_max_df}->bind("<Key-Return>",sub{$self->check;});
	$self->{ent_max_df}->bind("<KP_Enter>",sub{$self->check;});
	gui_window->config_entry_focusin($self->{ent_max_df});

	# 集計単位の選択（対応分析用）
	my %pack = (
		-anchor => 'e',
		-pady   => 0,
		-side   => 'left'
	);
	if ($self->{type} eq 'corresp'){
		my $l1 = $left->Frame()->pack(-fill => 'x', -pady => 2);
		$l1->Label(
			-text => kh_msg->get('gui_widget::words->df_unit'), # 　 　文書と見なす単位：
			-font => "TKFN"
		)->pack(-side => 'left');
		$self->{tani_obj} = gui_widget::tani->open(
			parent => $l1,
			pack   => \%pack,
			dont_remember => 1,
		);
	}

	# 品詞による単語の取捨選択
	$left->Label(
		-text => kh_msg->get('gui_widget::words->by_pos'), # ・品詞による語の取捨選択
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 2);
	my $l5 = $left->Frame()->pack(-fill => 'both',-expand => 1, -pady => 2);
	$l5->Label(
		-text => '    ',
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
	$self->{hinshi_obj}->select_all;
	my $l4 = $l5->Frame()->pack(-fill => 'x', -expand => 'y',-side => 'left');
	$l4->Button(
		-text => kh_msg->gget('all'), # すべて
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{$self->{hinshi_obj}->select_all;}
	)->pack(-pady => 3);
	$l4->Button(
		-text => kh_msg->gget('clear'), # クリア
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{$self->{hinshi_obj}->select_none;}
	)->pack();

	# チェック部分
	$self->parent->Label(
		-text => kh_msg->get('gui_widget::words->check_desc1')
			.$self->{verb}
			. kh_msg->get('gui_widget::words->check_desc2'),
		-font => "TKFN"
	)->pack(-anchor => 'w');

	my $cf = $self->parent->Frame()->pack(-fill => 'x', -pady => 2);

	$cf->Label(
		-text => '     ',
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');

	$cf->Button(
		-text => kh_msg->get('gui_widget::words->check'), # チェック
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{$self->check;}
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
#   外部変数の表示   #
sub load_ov{
	my $self = shift;
	unless ($self->{tani_obj}){return 0;}
	
	if ($self->{opt_body}){
		$self->{opt_body}->destroy;
	}
	
	# 利用できる変数があるかどうかチェック
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
					[kh_msg->get('n_a'), -1], # 利用不可
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
#   チェック   #

sub check{
	my $self = shift;
	
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('gui_widget::words->no_pos_selected'),
		);
		return 0;
	}
	
	if ( $self->outvar == -1 ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('gui_window::bayes_learn->error_var'), # 外部変数の設定が不正です。
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
#   設定の読み込み・保存   #

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
	
	# 単位の設定は読み込まない
	# （余所で違う値に設定されたら、それにあわせる。
	# 　またその場合は「文書数」の設定も読み込まない）
	if ( $self->tani eq $settings->{tani} ){
		$self->min_df( $settings->{min_df} );
		$self->max_df( $settings->{max_df} );
	}
	$self->check;
}


#--------------#
#   アクセサ   #

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