package gui_widget::mail_config;
use base qw(gui_widget);

# WinとLinux共通の設定項目

sub _new{
	my $self = shift;

	my $win = $self->parent->Frame();

	my $lf2 = $win->LabFrame(
		-label => kh_msg->get('display'),# 画面表示
		-labelside => 'acrosstop',
		-borderwidth => 2,
		-foreground => 'blue',
	)->pack(-fill => 'x');

	my $f4 = $lf2->Frame()->pack(-fill => 'x', -pady => 2);
	$f4->Label(
		-text => kh_msg->get('font'),#$gui_window->gui_jchar('フォント設定：','euc'),
		-font => "TKFN",
	)->pack(-side => 'left');
	$self->{e_font} = $f4->Entry(
		-font       => "TKFN",
		-width      => 25,
		#-state      => 'disable',
		-background => 'gray',
		-foreground => 'black',
	)->pack(-side => 'right');
	$f4->Button(
		-text  => kh_msg->get('config'),#$gui_window->gui_jchar('変更'),
		-font  => "TKFN",
		-command => sub { $self->font_change(); }
	)->pack(-padx => '2',-side => 'right');


	my $fds = $lf2->Frame()->pack(-fill => 'x', -pady => 2);
	$fds->Label(
		-text => kh_msg->get('plot_size1'),# plot size1
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_plot_size1} = $fds->Entry(
		-font       => "TKFN",
		-width      => 5,
		-background => 'white',
	)->pack(-side => 'left');

	$fds->Label(
		-text => kh_msg->get('plot_size2'),# plot size2
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_plot_size2} = $fds->Entry(
		-font       => "TKFN",
		-width      => 5,
		-background => 'white',
	)->pack(-side => 'left');


	my $fdf = $lf2->Frame()->pack(-fill => 'x', -pady => 2);
	$fdf->Label(
		-text => kh_msg->get('font_size'),# plot font size
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_plot_font} = $fdf->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left');

	$fdf->Label(
		-text => '%',
		-font => "TKFN",
	)->pack(-side => 'left');


	$self->{entry_plot_size1}->bind("<Key-Return>",$self->{command})
		if defined( $self->{command} );
	$self->{entry_plot_size1}->bind("<KP_Enter>", $self->{command})
		if defined( $self->{command} );
	gui_window->config_entry_focusin($self->{entry_plot_size1});

	$self->{entry_plot_size2}->bind("<Key-Return>",$self->{command})
		if defined( $self->{command} );
	$self->{entry_plot_size2}->bind("<KP_Enter>", $self->{command})
		if defined( $self->{command} );
	gui_window->config_entry_focusin($self->{entry_plot_size2});

	$self->{entry_plot_font}->bind("<Key-Return>",$self->{command})
		if defined( $self->{command} );
	$self->{entry_plot_font}->bind("<KP_Enter>", $self->{command})
		if defined( $self->{command} );
	gui_window->config_entry_focusin($self->{entry_plot_font});


	my $lf = $win->LabFrame(
		-label => kh_msg->get('other'),# その他
		-labelside => 'acrosstop',
		-borderwidth => 2,
		-foreground => 'blue',
	)->pack(-fill => 'x');

	$self->{check2} = $lf->Checkbutton(
		-variable => \$self->{if_heap},
		-text     => kh_msg->get('use_heap'),#$gui_window->gui_jchar('前処理効率化のためにデータをRAMに読み出す'),
		-font     => "TKFN",
		-command  => sub{$self->update;}
	)->pack(-anchor => 'w');

	$self->{check} = $lf->Checkbutton(
		-variable => \$self->{if_mail},
		-text     => kh_msg->get('sendmail'),#$gui_window->gui_jchar('前処理の完了をメールで通知する'),
		-font     => "TKFN",
		-command  => sub{$self->update;}
	)->pack(-anchor => 'w');
	
	my $f1 = $lf->Frame()->pack(-fill => 'x');
	$self->{lab1} = $f1->Label(
		-text => kh_msg->get('smtp'),#$'    SMTP Server: ',
		-font => "TKFN",
	)->pack(-side => 'left');
	$self->{e1} = $f1->Entry(
		-font  => "TKFN",
		-width => 25,
	)->pack(-side => 'right');
	
	my $f2 = $lf->Frame()->pack(-fill => 'x');
	$self->{lab2} = $f2->Label(
		-text => kh_msg->get('from'),#$'    From: ',
		-font => "TKFN",
	)->pack(-side => 'left');
	$self->{e2} = $f2->Entry(
		-font  => "TKFN",
		-width => 25,
	)->pack(-side => 'right');

	my $f3 = $lf->Frame()->pack(-fill => 'x');
	$self->{lab3} = $f3->Label(
		-text => kh_msg->get('to'),#$'    To: ',
		-font => "TKFN",
	)->pack(-side => 'left');
	$self->{e3} = $f3->Entry(
		-font  => "TKFN",
		-width => 25,
	)->pack(-side => 'right');

	$self->fill_in;
	
	$self->{win_obj} = $win;
	return $self;
}

sub fill_in{
	my $self = shift;

	$self->{entry_plot_size1}->insert(0, $::config_obj->plot_size_words);
	$self->{entry_plot_size2}->insert(0, $::config_obj->plot_size_codes);
	$self->{entry_plot_font}->insert(0, $::config_obj->plot_font_size);
	
	$self->{e1}->insert(0,$::config_obj->mail_smtp() );
	$self->{e2}->insert(0,$::config_obj->mail_from() );
	$self->{e3}->insert(0,$::config_obj->mail_to() );
	
	$self->{e_font}->insert(
		0,
		gui_window->gui_jchar($::config_obj->font_main,'euc')
	);
	$self->{e_font}->configure(-state => 'disable');
	
	if ($::config_obj->use_heap){
		$self->{check2}->select;
	}
	
	if ($::config_obj->mail_if){
		$self->{if_mail} = 1;
		$self->{check}->select;
	} else {
		$self->update;
	}
}

sub update{
	my $self = shift;
	
	if ( $self->{if_mail} ){
		foreach my $i ("lab1","lab2","lab3"){
			$self->{$i}->configure(-foreground => 'black');
		}
		foreach my $i ("e1","e2","e3"){
			$self->{$i}->configure(-state => 'normal',-background => 'white');
		}
	} else {
		foreach my $i ("lab1","lab2","lab3"){
			$self->{$i}->configure(-foreground => 'darkgray');
		}
		foreach my $i ("e1","e2","e3"){
			$self->{$i}->configure(-state => 'disable',-background => 'gray');
		}
	}
}

sub font_change{
	my $self = shift;
	
	use Tk::Font;
	use Tk::FontDialog_kh;
	
	my $font = $self->parent->FontDialog(
		-title            => gui_window->gui_jt(kh_msg->get('change_font')),#$'フォントの変更'),
		-familylabel      => kh_msg->get('select_font'),#$gui_window->gui_jchar('フォント：'),
		-sizelabel        => kh_msg->get('size'),#$gui_window->gui_jchar('サイズ：'),
		-cancellabel      => kh_msg->gget('cancel'),#$gui_window->gui_jchar('キャンセル'),
		-nicefontsbutton  => 0,
		-fixedfontsbutton => 0,
		-fontsizes        => [8,9,10,11,12,13,14,15,16,17,18,19,20],
		-sampletext       => kh_msg->get('note_fs'),#$gui_window->gui_jchar('KH Coderは計量テキスト分析を実践するためのツールです。'),
		-initfont         => ,"TKFN"
	)->Show;
	return unless $font;

	#print "1: ", $font->configure(-family), "\n";

	my $font_conf = $font->configure(-family);

	$font_conf .= ",";
	$font_conf .= $font->configure(-size);
	
	$self->{e_font}->configure(-state => 'normal');
	$self->{e_font}->delete('0','end');
	$self->{e_font}->insert(0, $font_conf);
	$self->{e_font}->configure(-state => 'disable');
}


#--------------------------#
#   設定値を返すアクセサ   #

sub plot_font{
	my $self = shift;
	return gui_window->gui_jg( $self->{entry_plot_font}->get );
}

sub plot_size1{
	my $self = shift;
	return gui_window->gui_jg( $self->{entry_plot_size1}->get );
}

sub plot_size2{
	my $self = shift;
	return gui_window->gui_jg( $self->{entry_plot_size2}->get );
}

sub if_heap{
	my $self = shift;
	return gui_window->gui_jg( $self->{if_heap} );
}

sub if{
	my $self = shift;
	return gui_window->gui_jg( $self->{if_mail} );
}
sub smtp{
	my $self = shift;
	return gui_window->gui_jg( $self->{e1}->get );
}
sub from{
	my $self = shift;
	return gui_window->gui_jg( $self->{e2}->get );
}
sub to{
	my $self = shift;
	return gui_window->gui_jg( $self->{e3}->get );
}
sub font{
	my $self = shift;
	return gui_window->gui_jg( $self->{e_font}->get );
}

1;