package gui_widget::r_font;
use base qw(gui_widget);
use strict;
use utf8;
use Tk;
use Jcode;

sub _new{
	my $self = shift;
	
	my $win = $self->parent->Frame();
	my $ff = $win->Frame()->pack(-fill => 'x');
	
	# Default values
	$self->{check_bold_text} = 0   unless defined $self->{check_bold_text};
	$self->{show_bold}       = 0   unless defined $self->{show_bold};
	$self->{plot_size}       = $::config_obj->plot_size_words
		unless defined $self->{plot_size};
	$self->{font_size}       = $::config_obj->plot_font_size
		unless defined $self->{font_size};
	
	# Get values from the R code
	if ( length $self->{r_com} ){
		#if (
		#	   $self->{r_com} =~ /cex=([0-9\.]+)[, \)]/
		#	|| $self->{r_com} =~ /cex <- ([0-9\.]+)\n/
		#){
		#	$self->{font_size} = $1;
		#	$self->{font_size} *= 100;
		#	#print "font size: $self->{font_size}\n";
		#}
		#if ( $self->{r_com} =~ /font_size <- ([0-9\.]+)\n/ ){
		#	$self->{font_size} = $1;
		#	$self->{font_size} *= 100;
		#	#print "font size: $self->{font_size}\n";
		#}
		if ( $self->{r_com} =~ /text_font <\- ([0-9]+)\n/ ){
			if ($1 == 2 ){
				$self->{check_bold_text} = 1;
			} else {
				$self->{check_bold_text} = 0;
			}
			$self->{show_bold} = 1;
		}
		$self->{r_com} = undef;
	}


	$ff->Label(
		-text => kh_msg->get('font_size'), # フォントサイズ：
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_font_size} = $ff->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);


	$self->{entry_font_size}->insert(0,$self->{font_size});


	$self->{entry_font_size}->bind("<Key-Return>",$self->{command})
		if defined( $self->{command} );
	$self->{entry_font_size}->bind("<KP_Enter>", $self->{command})
		if defined( $self->{command} );
	gui_window->config_entry_focusin($self->{entry_font_size});

	$ff->Label(
		-text => kh_msg->get('pcnt'), # %
		-font => "TKFN",
	)->pack(-side => 'left');

	if ( $self->{show_bold} ){
		$ff->Checkbutton(
				-text     => kh_msg->get('bold'), # 太字
				-variable => \$self->{check_bold_text},
				-anchor => 'w',
		)->pack(-anchor => 'w', -side => 'left');
	}

	$ff->Label(
		-text => kh_msg->get('plot_size'), #  プロットサイズ：
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_plot_size} = $ff->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);


	$self->{entry_plot_size}->insert(0,$self->{plot_size});

	$self->{entry_plot_size}->bind("<Key-Return>",$self->{command})
		if defined( $self->{command} );
	$self->{entry_plot_size}->bind("<KP_Enter>", $self->{command})
		if defined( $self->{command} );
	gui_window->config_entry_focusin($self->{entry_plot_size});

	$self->{win_obj} = $win;
	return $self;
}

sub bold{
	my $self = shift;
	$self->{check_bold_text} = 1;
	return 1;
}

#----------------------#
#   設定へのアクセサ   #

sub font_size{
	my $self = shift;
	my $n = $self->{entry_font_size}->get;
	$n =~ tr/０-９/0-9/;
	return gui_window->gui_jg( $n ) / 100;
}


sub check_bold_text{
	my $self = shift;
	return gui_window->gui_jg( $self->{check_bold_text} );
}

sub plot_size{
	my $self = shift;
	my $n = $self->{entry_plot_size}->get;
	$n =~ tr/０-９/0-9/;
	return gui_window->gui_jg( $n );
}

1;