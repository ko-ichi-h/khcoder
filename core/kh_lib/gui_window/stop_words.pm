package gui_window::stop_words;
use strict;
use base qw(gui_window);

use gui_window::stop_words::stemming_de;
use gui_window::stop_words::stemming_en;
use gui_window::stop_words::stemming_es;
use gui_window::stop_words::stemming_fr;
use gui_window::stop_words::stemming_it;
use gui_window::stop_words::stemming_nl;
use gui_window::stop_words::stemming_pt;

use gui_window::stop_words::stanford_en;
use gui_window::stop_words::stanford_cn;

use gui_window::stop_words::freeling_ca;
use gui_window::stop_words::freeling_de;
use gui_window::stop_words::freeling_en;
use gui_window::stop_words::freeling_fr;
use gui_window::stop_words::freeling_it;
use gui_window::stop_words::freeling_pt;
use gui_window::stop_words::freeling_ru;
use gui_window::stop_words::freeling_es;
use gui_window::stop_words::freeling_sl;

use kh_msg;

#------------------#
#   Windowを開く   #
#------------------#

sub _new{
	my $self = shift;

	# GUIの作成
	$self->{win_obj}->title(
		$self->gui_jt(
			kh_msg->get('stopwords','gui_window::sysconfig')
			.' '
			.$self->method_name
			.', '
			.$self->locale_name
		)
	);

	my $win = $self->{win_obj}->Frame(
		-borderwidth => 2,
		-relief      => "raised",
	)->pack(-fill => 'both', -expand => 1,-padx => 6, -pady => 6);
	
	$win->Label(
		-text => kh_msg->get('for_this_method'), #  Stopwords for the following method:
	)->pack(-anchor => 'w');
	
	$win->Label(
		-text =>
			"\t"
			.kh_msg->get('method','gui_widget::r_mds')
			."  "
			.$self->method_name,
	)->pack(-anchor => 'w');
	
	$win->Label(
		-text =>
			"\t"
			.kh_msg->get('lang')
			."  "
			.kh_msg->get( 'l_'.$self->locale_name, 'gui_window::sysconfig')
	)->pack(-anchor => 'w');
	
	$win->Label(
		-text => kh_msg->get('one_line2','gui_window::dictionary'),#"One stopword in each line:",
	)->pack(-anchor => 'w');
	
	my $t1 = $win->Scrolled(
		'Text',
		-scrollbars => 'se',
		-background => 'white',
		-height     => 18,
		-width      => 14,
		-wrap       => 'none',
		-font       => "TKFN",
	)->pack(-expand => 1, -fill => 'both', -padx => 2, -pady => 4);
	$t1->DropSite(
		-dropcommand => [\&Gui_DragDrop::read_TextFile_droped,$t1],
		-droptypes => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);
	$self->{text} = $t1;
	
	$win->Button(
		-text => kh_msg->get('select_all'),#'Select All',
		-borderwidth => 1,
		-command => sub{
			$self->{text}->focus;
			$self->{text}->selectAll;
		}
	)->pack(-anchor=>'w',-padx => 2,-pady => 4, -side => 'left');
	
	$win->Button(
		-text => kh_msg->gget('clear'),
		-borderwidth => 1,
		-command => sub{
			$self->{text}->focus;
			$self->{text}->delete('@0,0','end');
		}
	)->pack(-anchor=>'w',-side => 'left',-padx => 2, -pady => 2);
	
	my $f_t = $self->{win_obj}->Frame()->pack(-fill => "x");
	$f_t->Label(
		-text => kh_msg->get('change_will'), #"* Changes will take effect when you invoke\nthe \"Run Preprocessing\" command (again).",
		-justify => 'left'
	)->pack(-anchor => 'w', -padx => 2, -pady => 3);
	
	my $f_b = $self->{win_obj}->Frame()->pack(-fill => "x");
	
	$f_b->Button(
		-text => kh_msg->gget('cancel'),
		-font => 'TKFN',
		-width => 8,
		-command => sub{$self->close;}
	)->pack(-anchor=>'e',-side => 'right',-padx => 2);

	$f_b->Button(
		-text => kh_msg->gget('ok'),
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
	
	my $t = $self->{text}->get("1.0","end");
	$t =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
	
	foreach my $i (split /\n/, $t){
		$i =~ s/\x0D|\x0A//g;
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
