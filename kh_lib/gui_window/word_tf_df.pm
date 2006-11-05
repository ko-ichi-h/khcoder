package gui_window::word_tf_df;
use base qw(gui_window);

use strict;
use gui_hlist;
use mysql_words;

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win= $self->{win_obj};
	$win->title($self->gui_jchar('出現回数と文書数'));

	$self->{photo} = $win->Label(
		-image => $win->Photo(-file => $self->{images}[1]),
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
	
	my $tani = $self->{tani_obj}->tani;
	my $h = mysql_exec->select("
		select num,f
		from genkei, hselection, df_$tani
		where
			genkei.khhinshi_id = hselection.khhinshi_id
			and genkei.id = df_$tani.genkei_id
			and genkei.nouse = 0
			and hselection.ifuse = 1
	",1)->hundle;
	
	my $rcmd = 'hage <- matrix( c(';
	my $n = 0;
	while (my $i = $h->fetch){
		$rcmd .= "$i->[0],$i->[1],";
		++$n;
	}
	chop $rcmd;
	$rcmd .= "), nrow=$n, ncol=2, byrow=TRUE)";
	#print "$rcmd\n";
	
	my $path1 = $::project_obj->dir_CoderData.'words_TF_DF1.bmp';
	my $path2 = $::project_obj->dir_CoderData.'words_TF_DF2.bmp';
	my $path3 = $::project_obj->dir_CoderData.'words_TF_DF3.bmp';
	$path1 =~ tr/\\/\//;
	$path2 =~ tr/\\/\//;
	$path3 =~ tr/\\/\//;
	$self->{images} = [$path1,$path2,$path3];
	
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	$::config_obj->R->send($rcmd);
	# 通常
	$::config_obj->R->send("bmp(\"$path1\")");
	$::config_obj->R->send('plot(hage[,1],hage[,2],ylab="DF", xlab="TF")');
	$::config_obj->R->send('dev.off()');
	# x軸を対数に
	$::config_obj->R->send("bmp(\"$path2\")");
	$::config_obj->R->send('plot(hage[,1],hage[,2],log="x",ylab="DF", xlab="TF")');
	$::config_obj->R->send('dev.off()');
	# xy軸を対数に
	$::config_obj->R->send("bmp(\"$path3\")");
	$::config_obj->R->send('plot(hage[,1],hage[,2],log="xy",ylab="DF", xlab="TF")');
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	$self->renew;
}

sub renew{
	my $self = shift;
	return 0 unless $self->{optmenu};
	
	$self->{photo}->configure(
		-image => $self->{win_obj}->Photo(-file => $self->{images}[$self->{ax}])
	);
	$self->{photo}->update;
}

#--------------#
#   アクセサ   #


sub win_name{
	return 'w_word_tf_df';
}

1;