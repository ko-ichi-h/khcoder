package gui_window::word_freq;
use base qw(gui_window);

use strict;
use gui_hlist;
use mysql_words;

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $wmw= $mw->Toplevel;
	$self->{win_obj} = $wmw;
	#$wmw->focus;
	$wmw->title($self->gui_jchar('出現数 分布'));
	
	$wmw->Label(
		-text => $self->gui_jchar('・記述統計'),
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
		-height           => 5,
		-width            => 30,
	)->pack();
	
	$wmw->Label(
		-text => $self->gui_jchar('・度数分布表'),
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
	
	$lis2->header('create',0,-text => $self->gui_jchar('出現数'));
	$lis2->header('create',1,-text => $self->gui_jchar('度数'));
	$lis2->header('create',2,-text => $self->gui_jchar('パーセント'));
	$lis2->header('create',3,-text => $self->gui_jchar('累積度数'));
	$lis2->header('create',4,-text => $self->gui_jchar('累積パーセント'));
	
	$wmw->Button(
		-text => $self->gui_jchar('コピー'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $mw->after(10,sub {gui_hlist->copy($self->list2);});} 
	)->pack(-side => 'left');

	$wmw->Button(
		-text => $self->gui_jchar('閉じる'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $mw->after(10,sub {$self->close;});} 
	)->pack(-side => 'right');

	$wmw->Button(
		-text => $self->gui_jchar('再計算'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $mw->after(10,sub {$self->count;});} 
	)->pack();

	$self->{list1} = $lis1;
	$self->{list2} = $lis2;
	return $self;
}

sub count{
	my $self = shift;
	my ($r1, $r2) = mysql_words->freq_of_f;
	
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
	
	if (0){
		chop $rcmd;
		$rcmd .= "), nrow=$row, ncol=3, byrow=TRUE)";
		my $path1 = $::project_obj->dir_CoderData.'word_freq1.png';
		my $path2 = $::project_obj->dir_CoderData.'word_freq2.png';
		$path1 =~ tr/\\/\//;
		$path2 =~ tr/\\/\//;
		
		$::config_obj->R->lock;
		$::config_obj->R->send($rcmd);
		$::config_obj->R->send("png(\"$path1\")");
		$::config_obj->R->send('matplot(hage[,1],hage[,2],type="b",lty=1,pch=1)');
		$::config_obj->R->send('dev.off()');
		$::config_obj->R->send("png(\"$path2\")");
		$::config_obj->R->send('matplot(hage[,1],hage[,3],type="b",lty=1,pch=1)');
		$::config_obj->R->send('dev.off()');
		
		#$::config_obj->R->unlock;
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
	return 'w_word_freq';
}

1;