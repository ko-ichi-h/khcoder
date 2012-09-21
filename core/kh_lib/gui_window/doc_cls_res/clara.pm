package gui_window::doc_cls_res::clara;
use base qw(gui_window::doc_cls_res);

sub _new{
	my $self = shift;
	my %args = @_;
	$self->{tani} = $args{tani};
	$self->{command_f} = $args{command_f};
	$self->{plots} = $args{plots};
	$self->{merge_files} = $args{merge_files};

	my $mw = $::main_gui->mw;
	my $wmw= $self->{win_obj};
	$wmw->title($self->gui_jt(kh_msg->get('gui_window::doc_cls_res->win_title'))); # 文書のクラスター分析

	#--------------------------------#
	#   各クラスターに含まれる文書   #

	my $fr_top = $wmw->Frame()->pack(-fill => 'both', -expand => 'yes');

	my $fr_dcs = $fr_top->LabFrame(
		-label => kh_msg->get('gui_window::doc_cls_res->docs_in_clusters'), # 各クラスターに含まれる文書
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill=>'both', -expand => 1, -padx => 2, -pady => 2, -side => 'left');

	my $lis2 = $fr_dcs->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 1,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => 2,
		-padx             => 2,
		#-command          => sub{$self->cls_docs},
		-background       => 'white',
		-selectforeground   => $::config_obj->color_ListHL_fore,
		-selectbackground   => $::config_obj->color_ListHL_back,
		-selectborderwidth  => 0,
		-highlightthickness => 0,
		#-selectmode       => 'single',
		-height           => 10,
		-width            => 10,
	)->pack(-fill =>'both',-expand => 'yes');
	$lis2->header('create',0,-text => kh_msg->get('gui_window::doc_cls_res->h_cls_id')); # クラスター番号
	$lis2->header('create',1,-text => kh_msg->get('gui_window::doc_cls_res->h_doc_num')); # 文書数

	$lis2->bind("<Shift-Double-1>",sub{$self->cls_words;});
	$lis2->bind("<ButtonPress-3>",sub{$self->cls_words;});
	
	$lis2->bind("<Double-1>",sub{$self->cls_docs;});
	$lis2->bind("<Key-Return>",sub{$self->cls_docs;});
	$lis2->bind("<KP_Enter>",sub{$self->cls_docs;});

	my $fhl = $fr_dcs->Frame->pack(-fill => 'x');

	my $btn_ds = $fhl->Button(
		-text        => kh_msg->get('gui_window::doc_cls_res->docs'), # 文書検索
		-font        => "TKFN",
		-borderwidth => '1',
		-command     => sub {$self->cls_docs;}
	)->pack(-side => 'left', -padx => 2, -pady => 2, -anchor => 'c');

	$wmw->Balloon()->attach(
		$btn_ds,
		-balloonmsg => kh_msg->get('gui_window::doc_cls_res->bal_docs'), # クラスターに含まれる文書を検索\n[クラスターをダブルクリック]
		-font       => "TKFN"
	);

	my $btn_ass = $fhl->Button(
		-text        => kh_msg->get('gui_window::doc_cls_res->words'), # 特徴語
		-font        => "TKFN",
		-borderwidth => '1',
		-command     => sub {$self->cls_words;}
	)->pack(-side => 'left', -padx => 2, -pady => 2, -anchor => 'c');
	
	$wmw->Balloon()->attach(
		$btn_ass,
		-balloonmsg => kh_msg->get('gui_window::doc_cls_res->bal_words'), # クラスターの特徴をあらわす語を検索\n[Shift + クラスターをダブルクリック]
		-font       => "TKFN"
	);
	
	$self->{copy_btn} = $fhl->Button(
		-text        => kh_msg->gget('copy'), # コピー
		-font        => "TKFN",
		-borderwidth => '1',
		-command     => sub {gui_hlist->copy_all($self->list);}
	)->pack(-side => 'right', -padx => 2, -pady => 2, -anchor => 'c');

	#--------------------------#
	#   クラスター併合の過程   #
	
	my $fr_cls = $fr_top->LabFrame(
		-label => kh_msg->get('gui_window::doc_cls_res->agglm'), # クラスター併合の過程
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill=>'both', -expand => 1, -padx => 2, -pady => 2, -side => 'right');
	
	my $lis_f = $fr_cls->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 0,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => 1,
		-padx             => 2,
		#-command          => sub{$self->cls_docs},
		-background       => 'gray',
		-selectforeground   => $::config_obj->color_ListHL_fore,
		-selectbackground   => $::config_obj->color_ListHL_back,
		-selectborderwidth  => 0,
		-highlightthickness => 0,
		#-selectmode       => 'single',
		-height           => 10,
		-width            => 10,
	)->pack(-fill =>'both',-expand => 'yes');
	
	$lis_f->bind("<Double-1>",sub{$self->merge_docs;});
	
	my $fhr = $fr_cls->Frame->pack(-fill => 'x');

	my $mb = $fhr->Menubutton(
		-text        => kh_msg->get('gui_window::doc_cls_res->docs'), # 文書検索
		-tearoff     => 'no',
		-relief      => 'raised',
		-indicator   => 'no',
		-font        => "TKFN",
		#-width       => $self->{width},
		-borderwidth => 1,
		-state => 'disabled',
	)->pack(-side => 'left',-padx => 2, -pady => 2);

	$mb->command(
		-command => sub {$self->merge_docs();},
		-label   => kh_msg->get('gui_window::doc_cls_res->both'), # 1と2
	);

	$mb->command(
		-command => sub {$self->merge_docs('l');},
		-label   => kh_msg->get('gui_window::doc_cls_res->only1'), # 1のみ
	);

	$mb->command(
		-command => sub {$self->merge_docs('r');},
		-label   => kh_msg->get('gui_window::doc_cls_res->only2'), # 2のみ
	);

	$wmw->Balloon()->attach(
		$mb,
		-balloonmsg => kh_msg->get('gui_window::doc_cls_res->bal_agg_docs'), # [ダブルクリック]\n併合したクラスターに含まれる文書を検索
		-font       => "TKFN"
	);

	$self->{btn_prev} = $fhr->Button(
		-text => kh_msg->get('gui_window::word_conc->prev').'200', # 前200
		-font => "TKFN",
		-borderwidth => '1',
		-state => 'disabled',
		-command => sub {
			$self->{start} = $self->{start} - 200;
			$self->fill_list2;
		}
	)->pack(-side => 'left',-padx => 2, -pady => 2);

	$self->{btn_next} = $fhr->Button(
		-text => kh_msg->get('gui_window::word_conc->next').'200', # 次200
		-font => "TKFN",
		-borderwidth => '1',
		-state => 'disabled',
		-command => sub {
			$self->{start} = $self->{start} + 200;
			$self->fill_list2;
		}
	)->pack(-side => 'left',-padx => 2, -pady => 2);

	$fhr->Button(
		-text        => kh_msg->gget('copy'), # コピー
		-font        => "TKFN",
		-borderwidth => '1',
		-state => 'disabled',
		-command     => sub {
			return 0 unless $::config_obj->os eq 'win32';
			my $t = '';
			foreach my $i (@{$self->{merge}}){
				$t .= "$i->[0]\t$i->[1]\t$i->[2]\t$i->[3]\n";
			}
			require Win32::Clipboard;
			my $CLIP = Win32::Clipboard();
			$CLIP->Empty();
			$CLIP->Set("$t");
		}
	)->pack(-side => 'right', -padx => 2, -pady => 2);
	
	$fhr->Button(
		-text => kh_msg->gget('plot'), # プロット
		-font => "TKFN",
		-borderwidth => '1',
		-state => 'disabled',
		-command => sub {
			if ($::main_gui->if_opened('w_doc_cls_height')){
				$::main_gui->get('w_doc_cls_height')->renew(
					'_cluster_tmp'
				);
			} else {
				gui_window::cls_height::doc->open(
					plots => $self->{plots},
					type  => '_cluster_tmp'
				);
			}
		}
	)->pack(-side => 'right',-padx => 2, -pady => 2);
	
	
	#----------------#
	#   Window下部   #
	
	my $fb = $wmw->Frame()->pack(-fill => 'x', -padx => 2, -pady => 2);
	
	#my @opt = (
	#	[kh_msg->get('m_wrd'),   '_cluster_tmp_w'], # Ward法','euc
	#	[kh_msg->get('m_ave'), '_cluster_tmp_a'], # 群平均法','euc
	#	[kh_msg->get('m_clk'), '_cluster_tmp_c'], # 最遠隣法','euc
	#);
	
	#$self->{optmenu} = gui_widget::optmenu->open(
	#	parent  => $fb,
	#	pack    => {-side => 'left', -padx => 2},
	#	options => \@opt,
	#	variable => \$self->{tmp_out_var},
	#	command  => sub {$self->renew;},
	#);
	#$self->{optmenu}->set_value('_cluster_tmp_w');
	
	$fb->Button(
		-text => kh_msg->get('gui_window::doc_cls_res->config'), # 調整
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {
			gui_window::doc_cls_res_opt->open(
				command_f => $self->{command_f},
				tani      => $self->{tani},
			);
		}
	)->pack(-side => 'left',-padx => 5);

	$fb->Button(
		-text => kh_msg->get('gui_window::doc_cls_res->save'), # 分類結果の保存
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {
			gui_window::doc_cls_res_sav->open(
				var_from => '_cluster_tmp'
			);
		}
	)->pack(-side => 'right');

	$self->{list}  = $lis2;
	$self->{list2} = $lis_f;

	$self->renew;
	return $self;
}

1;