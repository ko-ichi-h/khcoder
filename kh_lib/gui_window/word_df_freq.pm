package gui_window::word_df_freq;
use base qw(gui_window);

use strict;
use gui_hlist;
use mysql_words;

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $wmw= $self->{win_obj};
	#$self->{win_obj} = $wmw;
	#$wmw->focus;
	$wmw->title($self->gui_jchar('文書数：分布'));
	
	$wmw->Label(
		-text => $self->gui_jchar('■記述統計'),
		-font => "TKFN"
	)->pack(-anchor => 'w');
	
	my $lis1 = $wmw->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 0,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => 2,
		-padx             => 2,
		#-background       => 'white',
		#-selectforeground => 'brown',
		#-selectbackground => 'cyan',
		-indicator => 0,
		-borderwidth        => 0,
		-highlightthickness => 0,
		-selectmode       => 'none',
		-height           => 4,
		-width            => 30,
	)->pack();
	
	$wmw->Label(
		-text => $self->gui_jchar('■度数分布表'),
		-font => "TKFN"
	)->pack(-anchor => 'w');

	my $lis2 = $wmw->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 1,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => 5,
		-padx             => 2,
		-background       => 'white',
		-selectforeground => 'brown',
		#-selectbackground => 'cyan',
		-selectmode       => 'extended',
		-height           => 10,
	)->pack(-fill =>'both',-expand => 'yes');
	
	$lis2->header('create',0,-text => $self->gui_jchar('文書数'));
	$lis2->header('create',1,-text => $self->gui_jchar('度数'));
	$lis2->header('create',2,-text => $self->gui_jchar('パーセント'));
	$lis2->header('create',3,-text => $self->gui_jchar('累積度数'));
	$lis2->header('create',4,-text => $self->gui_jchar('累積パーセント'));
	
	$wmw->Button(
		-text => $self->gui_jchar('コピー'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $mw->after(10,sub {gui_hlist->copy($self->list2);});} 
	)->pack(-side => 'left',-padx => 5);

	if ($::config_obj->R){
		$wmw->Button(
			-text => $self->gui_jchar('プロット'),
			-font => "TKFN",
			-borderwidth => '1',
			-command => sub{ $mw->after(10,sub {
				$self->plot;
			});} 
		)->pack(-side => 'left');
	}

	$wmw->Label(
		-text => $self->gui_jchar('  集計単位：'),
		-font => "TKFN"
	)->pack(-side => 'left');

	my %pack = (
			#-anchor => 'e',
			#-pady   => 1,
			-side   => 'left'
	);
	$self->{tani_obj} = gui_widget::tani->open(
		parent  => $wmw,
		pack    => \%pack,
		command => sub {$self->count;},
	);

	$wmw->Button(
		-text => $self->gui_jchar('閉じる'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $mw->after(10,sub {$self->close;});} 
	)->pack(-side => 'right');

	$self->{list1} = $lis1;
	$self->{list2} = $lis2;
	return $self;
}

sub count{
	my $self = shift;
	return 0 unless $self->{tani_obj};
	my ($r1, $r2) = mysql_words->freq_of_df($self->{tani_obj}->tani);
	
	# 記述統計
	$self->list1->delete('all');
	my $numb_style = $self->list1->ItemStyle(
		'text',
		-anchor => 'e',
		-font => "TKFN"
	);
	my $row = 0;
	foreach my $i (@{$r1}){
		$self->list1->add($row,-at => "$row");
		$self->list1->itemCreate(
			$row,
			0,
			-text  => $self->gui_jchar($i->[0]),
		);
		$self->list1->itemCreate(
			$row,
			1,
			-text  => $i->[1],
			-style => $numb_style
		);
		++$row;
	}
	
	# 度数分布表
	$self->list2->delete('all');
	$numb_style = $self->list1->ItemStyle(
		'text',
		-anchor => 'e',
		-font => "TKFN"
	);
	my $rcmd = 'hage <- matrix( c(';
	my $row = 0;
	foreach my $i (@{$r2}){
		$rcmd .= "$i->[0],$i->[3],$i->[1],";
		$self->list2->add($row,-at => "$row");
		my $col = 0;
		foreach my $h (@{$i}){
			$self->list2->itemCreate(
				$row,
				$col,
				-text  => $h,
				-style => $numb_style
			);
			++$col;
		}
		++$row;
	}
	chop $rcmd;
	$rcmd .= "), nrow=$row, ncol=3, byrow=TRUE)";
	$self->{rcmd} = $rcmd;
	
	if ($::main_gui->if_opened('w_word_df_freq_plot')){
		$self->plot;
		$self->{win_obj}->focus;
	}
	
	return $self;
}

sub plot{
	# プロットを作成してから表示用Windowを開く
	my $self = shift;
	return 0 unless $::config_obj->R;
	
	my $icode = Jcode::getcode($::project_obj->dir_CoderData);
	my $dir   = Jcode->new($::project_obj->dir_CoderData, $icode)->euc;
	$dir =~ tr/\\/\//;
	$dir = Jcode->new($dir,'euc')->$icode unless $icode eq 'ascii';
	
	my $path1 = $dir.'words_DF_freq1';
	my $path2 = $dir.'words_DF_freq2';
	my $path3 = $dir.'words_DF_freq3';
	
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	$::config_obj->R->send($self->{rcmd});
	# 通常
	$path1 = $::config_obj->R_device($path1);
	$::config_obj->R->send('plot(hage[,1],hage[,3],type="b",lty=1,pch=1,ylab="Freqency", xlab="DF")');
	$::config_obj->R->send('dev.off()');
	# x軸を対数に
	$path2 = $::config_obj->R_device($path2);
	$::config_obj->R->send('plot(hage[,1],hage[,3],type="b",lty=1,pch=1,log="x",ylab="Freqency", xlab="DF")');
	$::config_obj->R->send('dev.off()');
	# xy軸を対数に
	$path3 = $::config_obj->R_device($path3);
	$::config_obj->R->send('plot(hage[,1],hage[,3],log="xy",ylab="Freqency", xlab="DF")');
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	if ($::main_gui->if_opened('w_word_df_freq_plot')){
		$::main_gui->get('w_word_df_freq_plot')->renew;
	} else {
		gui_window::word_df_freq_plot->open(
			images => [$path1,$path2,$path3]
		);
	}
}

#--------------#
#   アクセサ   #

sub list2{
	my $self = shift;
	return $self->{list2};
}
sub list1{
	my $self = shift;
	return $self->{list1};
}
sub win_name{
	return 'w_word_df_freq';
}

1;