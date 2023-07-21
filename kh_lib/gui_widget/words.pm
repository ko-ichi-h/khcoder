package gui_widget::words;
use base qw(gui_widget);
use strict;
use utf8;
use Tk;

sub _new{
	my $self = shift;

	$self->{type} = '' unless defined( $self->{type} );

	my $left = $self->parent->Frame()->pack(-fill => 'both', -expand => 1);

	# 集計単位の選択
	unless ($self->{type} eq 'corresp'){
		my $l1 = $left->Frame()->pack(-fill => 'x', -pady => 2);
		$l1->Label(
			-text => kh_msg->get('unit'), # 集計単位：
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
			command => sub{
				&{$self->{tani_command}} if $self->{tani_command};
				$self->sampling_config;
			},
			#dont_remember => 1,
			tani_gt_1 => $self->{tani_gt_1},
		);
		if ($self->{sampling}) {
			$self->{sampling_obj} = gui_widget::sampling->open(
				parent => $l1,
				pack   => { -side => 'left' },
				command => $self->{command},
			);
		}
		$self->sampling_config;
	}
	
	# 最小・最大出現数
	$left->Label(
		-text => kh_msg->get('by_tf'), # 最小/最大 出現数による語の取捨選択
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 2);
	my $l2 = $left->Frame()->pack(-fill => 'x', -pady => 2);
	$l2->Label(
		-text => kh_msg->get('min_tf'), # 　 　最小出現数：
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
		-text => kh_msg->get('max_tf'), # 　 最大出現数：
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
		-text => kh_msg->get('by_df'), # 最小/最大 文書数による語の取捨選択
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 2);

	my $l3 = $left->Frame()->pack(-fill => 'x', -pady => 2);
	$l3->Label(
		-text => kh_msg->get('min_df'), #      最小文書数：
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
		-text => kh_msg->get('max_df'), #    最大文書数：
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
			-text => kh_msg->get('df_unit'), #      文書と見なす単位：
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
		-text => kh_msg->get('by_pos'), # 品詞による語の取捨選択
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 2);
	my $l5 = $left->Frame()->pack(-fill => 'both',-expand => 1, -pady => 2);
	$l5->Label(
		-text => '     ',
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
		-text => kh_msg->gget('all'), # すべて
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{$self->{hinshi_obj}->select_all;}
	)->pack(-pady => 2);

	$l4->Button(
		-text => kh_msg->gget('default'), # 既定値
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{$self->{hinshi_obj}->select_default;}
	)->pack(-pady => 2);

	$l4->Button(
		-text => kh_msg->gget('clear'), # クリア
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{$self->{hinshi_obj}->select_none;}
	)->pack(-pady => 2);

	# チェック部分
	$self->parent->Label(
		-text =>
			 kh_msg->get('check_desc1') # 現在の設定で
			.$self->{verb}
			.kh_msg->get('check_desc2') # される語の数：
		,
		-font => "TKFN"
	)->pack(-anchor => 'w');

	my $cf = $self->parent->Frame()->pack(-fill => 'x', -pady => 2);

	$cf->Label(
		-text => '     ',
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');

	$cf->Button(
		-text => kh_msg->get('check'), # チェック
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

	$self->{win_obj} = $left;
	$self->{win_obj}->update;
	$self->settings_load;

	gui_hlist->update4scroll($self->{hinshi_obj}->hlist);

	return $self;
}

sub sampling_config{
	my $self = shift;
	if ($self->{tani_obj} && $self->{sampling_obj}) {
		my $tani = $self->{tani_obj}->tani;
		my $n = mysql_exec->select("select count(*) from $tani",1)->hundle->fetch->[0];
		$self->{sampling_obj}->onoff($n);
	}
}

#--------------#
#   チェック   #
sub check{
	my $self = shift;
	
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('no_pos_selected'), # 品詞が1つも選択されていません。
		);
		return 0;
	}
	
	#my $tani2 = '';
	#if ($self->{radio} == 0){
	#	$tani2 = gui_window->gui_jg($self->{high});
	#}
	#elsif ($self->{radio} == 1){
	#	if ( length($self->{var_id}) ){
	#		$tani2 = mysql_outvar::a_var->new(undef,$self->{var_id})->{tani};
	#	}
	#}
	
	my $check = mysql_crossout::r_com->new(
		tani   => $self->tani,
		#tani2  => $tani2,
		hinshi => $self->hinshi,
		max    => $self->max,
		min    => $self->min,
		max_df => $self->max_df,
		min_df => $self->min_df,
	)->wnum;
	
	$self->{ent_check}->configure(-state => 'normal');
	$self->{ent_check}->delete(0,'end');
	$self->{ent_check}->insert(0,$check);
	$self->{ent_check}->configure(-state => 'disable');
}

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
		name => 'widget_words',
		var  => $settings,
	);
}

sub settings_load{
	my $self = shift;
	
	my $settings = $::project_obj->load_dmp(
		name => 'widget_words',
	);
	
	if ($settings){
		$self->{hinshi_obj}->selection_set($settings->{hinshi}) if $settings->{hinshi};
		
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
	} else {
		# print "Getting the default min-freq value...\n";
		my $target = 75;
		if ( $::project_obj->morpho_analyzer_lang ne 'jp' ){
			$target = 120;
		}
		
		if ($::config_obj->web_if) {
			$target = 60;
			if ( $::project_obj->morpho_analyzer_lang ne 'jp' ){
				$target = 85;
			}
		}
		
		my $freq = mysql_crossout::r_com->new(
			tani   => $self->tani,
			hinshi => $self->hinshi,
			max    => $self->max,
			min    => $self->min,
			max_df => $self->max_df,
			min_df => $self->min_df,
		)->get_default_freq($target);
		$freq = 2 if $freq <= 1;
		
		$self->min( $freq );
		
		$self->check;
	}
}


#--------------#
#   アクセサ   #

sub sampling_value{
	my $self = shift;
	if ( $self->{sampling_obj} ) {
		return $self->{sampling_obj}->parameter;
	} else {
		return 0;
	}
}

sub min{
	my $self = shift;
	my $new  = shift;
	if ( defined($new) ){
		$self->{ent_min}->delete(0,'end');
		$self->{ent_min}->insert(0,$new);
	}
	return gui_window->gui_jgn( $self->{ent_min}->get );
}
sub max{
	my $self = shift;
	my $new  = shift;
	if ( defined($new) ){
		$self->{ent_max}->delete(0,'end');
		$self->{ent_max}->insert(0,$new);
	}
	return gui_window->gui_jgn( $self->{ent_max}->get );
}
sub min_df{
	my $self = shift;
	my $new  = shift;
	if ( defined($new) ){
		$self->{ent_min_df}->delete(0,'end');
		$self->{ent_min_df}->insert(0,$new);
	}
	return gui_window->gui_jgn( $self->{ent_min_df}->get );
}
sub max_df{
	my $self = shift;
	my $new  = shift;
	if ( defined($new) ){
		$self->{ent_max_df}->delete(0,'end');
		$self->{ent_max_df}->insert(0,$new);
	}
	return gui_window->gui_jgn( $self->{ent_max_df}->get );
}
sub tani{
	my $self = shift;
	return $self->{tani_obj}->tani;
}
sub hinshi{
	my $self = shift;
	return $self->{hinshi_obj}->selected;
}
sub params{
	my $self = shift;
	return (
		tani   => $self->tani,
		tani2  => $self->tani,
		max    => $self->max,
		min    => $self->min,
		max_df => $self->max_df,
		min_df => $self->min_df,
		hinshi => $self->hinshi,
	);
}


1;