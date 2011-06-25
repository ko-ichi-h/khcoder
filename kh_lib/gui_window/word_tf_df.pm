package gui_window::word_tf_df;

use base qw(gui_window);

use strict;
use Tk::PNG;
use gui_hlist;
use mysql_words;

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win= $self->{win_obj};
	$win->title($self->gui_jt('出現回数と文書数'));

	$self->{img} = $win->Photo();

	$self->{photo} = $win->Label(
		-image => $self->{img},
		-borderwidth => 2,
		-relief => 'sunken',
	)->pack(-anchor => 'c');

	my $f1 = $win->Frame()->pack(
		-expand => 'y',
		-fill   => 'x',
		-pady   => 2,
		-padx   => 2,
		-anchor => 's',
	);

	$f1->Label(
		-text => $self->gui_jchar('集計単位：'),
		-font => "TKFN"
	)->pack(-anchor => 'e', -side => 'left');
	my %pack = (-side => 'left');
	$self->{tani_obj} = gui_widget::tani->open(
		parent  => $f1,
		pack    => \%pack,
		command => sub {$self->count;},
	);

	$f1->Label(
		-text => $self->gui_jchar('  対数軸の使用：'),
		-font => "TKFN"
	)->pack(-anchor => 'e', -side => 'left');
	
	$self->{optmenu} = gui_widget::optmenu->open(
		parent  => $f1,
		pack    => {-anchor=>'e', -side => 'left', -padx => 0},
		options =>
			[
				[$self->gui_jchar('出現回数(X)')  => 1],
				[$self->gui_jchar('出現回数(X)と文書数(Y)') => 2],
				[$self->gui_jchar('なし') => 0],
			],
		variable => \$self->{ax},
		command  => sub {$self->renew;},
	);

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
	)->pack(-side => 'right');


	#$win->Button(
	#	-text => $self->gui_jchar('閉じる'),
	#	-font => "TKFN",
	#	-width => 8,
	#	-borderwidth => '1',
	#	-command => sub{ $mw->after
	#		(
	#			10,
	#			sub {
	#				$self->close();
	#			}
	#		);
	#	}
	#)->pack(-side => 'right',-padx => 2, -pady => 2);
	$self->count;
	return $self;
}

#----------------#
#   グラフ作成   #

sub count{
	my $self = shift;
	return 0 unless $self->{tani_obj};
	
	$self->{images} = undef;
	
	my $tani = $self->{tani_obj}->tani;
	my $h = mysql_exec->select("
		select num, f, genkei.name
		from genkei, hselection, df_$tani
		where
			genkei.khhinshi_id = hselection.khhinshi_id
			and genkei.id = df_$tani.genkei_id
			and genkei.nouse = 0
			and hselection.ifuse = 1
	",1)->hundle;
	
	my $rcmd = 'hoge <- matrix( c(';
	my $n = 0;
	while (my $i = $h->fetch){
		$rcmd .= "$i->[0],$i->[1],\"$i->[2]\",";
		++$n;
	}
	chop $rcmd;
	$rcmd .= "), nrow=$n, ncol=3, byrow=TRUE)";

	my %tani_name = (
		'bun' => '文',
		'dan' => '段落',
		'h1'  => 'H1',
		'h2'  => 'H2',
		'h3'  => 'H3',
		'h4'  => 'H4',
		'h5'  => 'H5',
	);
	my $tani_name = $tani;
	if ( $tani_name{$tani} ){
		$tani_name = $tani_name{$tani};
	}

	use kh_r_plot;
	kh_r_plot->clear_env;
	my $flg_error = 0;
	my $plot1 = kh_r_plot->new(
		name      => 'words_TF_DF1',
		command_f => 
			"$rcmd\n"
			.'plot(hoge[,1],hoge[,2],ylab="文書数（'.$tani_name.'）", xlab="出現回数")',
	) or $flg_error = 1;

	my $plot2 = kh_r_plot->new(
		name      => 'words_TF_DF2',
		command_f => 
			"$rcmd\n"
			.'plot(hoge[,1],hoge[,2],ylab="文書数（'.$tani_name.'）",xlab="出現回数",log="x")',
	) or $flg_error = 1;

	my $plot3 = kh_r_plot->new(
		name      => 'words_TF_DF3',
		command_f => 
			"$rcmd\n"
			.'plot(hoge[,1],hoge[,2],ylab="文書数（'.$tani_name.'）",xlab="出現回数",log="xy")',
	) or $flg_error = 0;

	if ($flg_error){
		$self->close;
	}

	$self->{images} = [$plot1,$plot2,$plot3];
	$self->renew;
}

sub renew{
	my $self = shift;
	return 0 unless $self->{optmenu};
	
	$self->{img}->read( $self->{images}[$self->{ax}]->path );
	
	$self->{photo}->update;
}

sub end{
	my $self = shift;
	$self->{images} = undef;
	$self->{img}->delete;
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

	$self->{images}[$self->{ax}]->save($path) if $path;

	return 1;
}

#--------------#
#   アクセサ   #


sub win_name{
	return 'w_word_tf_df';
}

1;