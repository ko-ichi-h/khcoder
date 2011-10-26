package gui_window::stop_words;
use strict;
use base qw(gui_window);

use gui_window::stop_words::stemming_en;

#------------------#
#   Windowを開く   #
#------------------#

sub _new{
	my $self = shift;

	# GUIの作成
	$self->{win_obj}->title(
		$self->gui_jt('Stopwords: '.$self->method_name.', '.$self->locale_name)
	);
	
	my $win = $self->{win_obj}->Frame(
		-borderwidth => 2,
		-relief      => "raised",
	)->pack(-fill => 'both', -expand => 1,-padx => 6, -pady => 6);
	
	$win->Label(
		-text => 'Stopwords for the following method:',
	)->pack(-anchor => 'w');
	
	$win->Label(
		-text => "\tMethod:\t".$self->method_name,
	)->pack(-anchor => 'w');
	
	$win->Label(
		-text => "\tLocale:\t".$self->locale_name,
	)->pack(-anchor => 'w');
	
	
	$win->Label(
		-text => "One stopword in each line:",
	)->pack(-anchor => 'w');
	
	my $t1 = $win->Scrolled(
		'Text',
		-scrollbars => 'se',
		-background => 'white',
		-height     => 18,
		-width      => 14,
		-wrap       => 'none',
		-font       => "TKFN",
	)->pack(-expand => 1, -fill => 'both', -padx => 2, -pady => 2);
	$t1->DropSite(
		-dropcommand => [\&Gui_DragDrop::read_TextFile_droped,$t1],
		-droptypes => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);
	$self->{text} = $t1;
	
	$win->Button(
		-text => 'Select All',
		-borderwidth => 1,
		-command => sub{
			$self->{text}->focus;
			$self->{text}->selectAll;
		}
	)->pack(-anchor=>'w',-padx => 2,-pady => 2, -side => 'left');
	
	$win->Button(
		-text => 'Clear',
		-borderwidth => 1,
		-command => sub{
			$self->{text}->focus;
			$self->{text}->delete('@0,0','end');
		}
	)->pack(-anchor=>'w',-side => 'left',-padx => 2, -pady => 2);
	
	my $f_t = $self->{win_obj}->Frame()->pack(-fill => "x");
	$f_t->Label(
		-text => "* Changes will take effect when you invoke\nthe \"Run Preprocessing\" command (again).",
	)->pack(-anchor => 'w');
	
	my $f_b = $self->{win_obj}->Frame()->pack(-fill => "x");
	
	$f_b->Button(
		-text => 'Cancel',
		-font => 'TKFN',
		-width => 8,
		-command => sub{$self->close;}
	)->pack(-anchor=>'e',-side => 'right',-padx => 2);

	$f_b->Button(
		-text => 'OK',
		-font => 'TKFN',
		-width => 8,
		-command => sub{$self->save;}
	)->pack(-anchor=>'e',-side => 'right');
	
	
	
	# 設定の読み取りと表示
	my $words = $::config_obj->stopwords(
		method => $self->method,
		locale => $self->locale_name
	);
	foreach my $i (@{$words}){
		$self->{text}->insert('end',"$i\n");
	}
	
	return $self;
}

sub save{
	my $self = shift;
	
	my @mark = ();
	my %check = ();
	foreach my $i (split /\n/, $self->{text}->get("1.0","end")){
		if (length($i) and not $check{$i}) {
			push @mark, $i;
			$check{$i} = 1;
		}
	}

	$::config_obj->stopwords(
		method => $self->method,
		locale => $self->locale_name,
		stopwords => \@mark,
	);
	
	$self->close;
}


1;
