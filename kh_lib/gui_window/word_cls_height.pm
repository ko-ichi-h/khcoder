package gui_window::word_cls_height;
use strict;
use base qw(gui_window);

#------------------#
#   Windowを開く   #
#------------------#

sub _new{
	if ($::config_obj->os eq 'linux') {
		require Tk::PNG;
	}

	my $self = shift;
	my %args = @_;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$self->{plots} = $args{plots};
	$self->{type}  = $args{type};
	$self->{range} = 'last';

	#print "plots: $self->{plots}\n";
	#print "type: $self->{type}\n";
	#print "w_c: $self->{w_c}\n";

	$win->title($self->gui_jt('抽出語のクラスター分析：併合水準','euc'));

	$self->{photo} = $win->Label(
		-image => $win->Photo(
			-file => $self->{plots}{$self->{type}}{$self->{range}}->path
		),
		-borderwidth => 2,
		-relief => 'sunken',
	)->pack(-anchor => 'c');

	my $f1 = $win->Frame()->pack(-expand => 'y', -fill => 'x', -pady => 2);

	$f1->Label(
		-text => $self->gui_jchar(' プロット範囲： '),
		-font => "TKFN"
	)->pack(-anchor => 'e', -side => 'left');

	#$self->{optmenu} = gui_widget::optmenu->open(
	#	parent  => $f1,
	#	pack    => {-anchor=>'e', -side => 'left', -padx => 0},
	#	options =>
	#		[
	#			[$self->gui_jchar('最後50')  => 'last' ],
	#			[$self->gui_jchar('最初50')  => 'first'],
	#			[$self->gui_jchar('全体')    => 'all'  ],
	#		],
	#	variable => \$self->{range},
	#	command  => sub {$self->renew;},
	#);

	$self->{btn_first} = $f1->Button(
		-text => $self->gui_jchar('<< 最初50'),
		-font => "TKFN",
		#-width => 8,
		-borderwidth => '1',
		-command => sub{ $mw->after
			(
				10,
				sub {
					$self->{range} = 'first';
					$self->renew;
					$self->{btn_first}->configure(-state => 'disabled');
					$self->{btn_all}->configure(  -state => 'normal'  );
					$self->{btn_last}->configure( -state => 'normal'  );
					return $self;
				}
			);
		}
	)->pack(-side => 'left', -padx => 2);

	$self->{btn_all} = $f1->Button(
		-text => $self->gui_jchar('全体'),
		-font => "TKFN",
		#-width => 8,
		-borderwidth => '1',
		-command => sub{ $mw->after
			(
				10,
				sub {
					$self->{range} = 'all';
					$self->renew;
					$self->{btn_first}->configure(-state => 'normal'  );
					$self->{btn_all}->configure(  -state => 'disabled');
					$self->{btn_last}->configure( -state => 'normal'  );
					return $self;
				}
			);
		}
	)->pack(-side => 'left', -padx => 2);

	$self->{btn_last} = $f1->Button(
		-text => $self->gui_jchar('最後50 >>'),
		-font => "TKFN",
		#-width => 8,
		-borderwidth => '1',
		-state => 'disabled',
		-command => sub{ $mw->after
			(
				10,
				sub {
					$self->{range} = 'last';
					$self->renew;
					$self->{btn_first}->configure(-state => 'normal'  );
					$self->{btn_all}->configure(  -state => 'normal'  );
					$self->{btn_last}->configure( -state => 'disabled');
					return $self;
				}
			);
		}
	)->pack(-side => 'left', -padx => 2);

	$f1->Button(
		-text => $self->gui_jchar('閉じる'),
		-font => "TKFN",
		-width => 8,
		-borderwidth => '1',
		-command => sub{ $mw->after
			(
				10,
				sub {
					$self->close();
				}
			);
		}
	)->pack(-side => 'right');

	$f1->Button(
		-text => $self->gui_jchar('保存'),
		-font => "TKFN",
		#-width => 8,
		-borderwidth => '1',
		-command => sub{ $mw->after
			(
				10,
				sub {
					$self->save();
				}
			);
		}
	)->pack(-side => 'right', -padx => 4);

	return $self;
}

sub save{
	my $self = shift;

	# 保存先の参照
	my @types = (
		[ "Encapsulated PostScript",[qw/.eps/] ],
		#[ "Adobe PDF",[qw/.pdf/] ],
		[ "PNG",[qw/.png/] ],
		[ "R Source",[qw/.r/] ],
	);
	@types = ([ "Enhanced Metafile",[qw/.emf/] ], @types)
		if $::config_obj->os eq 'win32';

	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.eps',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt('プロットを保存'),
		-initialdir       => $self->gui_jchar($::config_obj->cwd)
	);

	$path = $self->gui_jg_filename_win98($path);
	$path = $self->gui_jg($path);
	$path = $::config_obj->os_path($path);

	# R Sourceを保存する場合には対策が必要？
	$self->{plots}->{$self->{type}}->save($path) if $path;

	return 1;
}

sub renew{
	my $self = shift;
	
	if ( defined($_[0]) ){
		$self->{type} = shift;
	}
	
	$self->{photo}->configure(
		-image =>
			$self->{win_obj}->Photo(
				-file => $self->{plots}{$self->{w_c}}[$self->{type}]{$self->{range}}->path
			)
	);
	
	$self->{photo}->update;
	return $self;
}

#--------------#
#   Window名   #

sub win_name{
	return 'w_word_cls_height';
}

1;
