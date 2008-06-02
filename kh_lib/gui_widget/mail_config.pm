package gui_widget::mail_config;
use base qw(gui_widget);

# WinとLinux共通の設定項目

sub _new{
	my $self = shift;

	my $lf = $self->parent->LabFrame(
		-label => 'Other Settings',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x');
	$self->{win_obj} = $lf;

	$self->{check2} = $lf->Checkbutton(
		-variable => \$self->{if_heap},
		-text     => gui_window->gui_jchar('前処理効率化のためにデータをRAMに読み出す'),
		-font     => "TKFN",
		-command  => sub{$self->update;}
	)->pack(-anchor => 'w');

	$self->{check} = $lf->Checkbutton(
		-variable => \$self->{if_mail},
		-text     => gui_window->gui_jchar('前処理の完了をメールで通知する'),
		-font     => "TKFN",
		-command  => sub{$self->update;}
	)->pack(-anchor => 'w');
	
	my $f1 = $lf->Frame()->pack(-fill => 'x');
	$self->{lab1} = $f1->Label(
		-text => '    SMTP Server: ',
		-font => "TKFN",
	)->pack(-side => 'left');
	$self->{e1} = $f1->Entry(
		-font  => "TKFN",
		-width => 25,
	)->pack(-side => 'right');
	
	my $f2 = $lf->Frame()->pack(-fill => 'x');
	$self->{lab2} = $f2->Label(
		-text => '    From: ',
		-font => "TKFN",
	)->pack(-side => 'left');
	$self->{e2} = $f2->Entry(
		-font  => "TKFN",
		-width => 25,
	)->pack(-side => 'right');

	my $f3 = $lf->Frame()->pack(-fill => 'x');
	$self->{lab3} = $f3->Label(
		-text => '    To: ',
		-font => "TKFN",
	)->pack(-side => 'left');
	$self->{e3} = $f3->Entry(
		-font  => "TKFN",
		-width => 25,
	)->pack(-side => 'right');
	
	my $f4 = $lf->Frame()->pack(-fill => 'x', -pady => 2);
	$f4->Label(
		-text => gui_window->gui_jchar('フォント設定：','euc'),
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
		-text  => gui_window->gui_jchar('変更'),
		-font  => "TKFN",
		-command => sub{ $self->parent->after
			(10,
				sub { $self->font_change(); }
			)
		}
	)->pack(-padx => '2',-side => 'right');
	
	$self->fill_in;
	
	return $self;
}

sub fill_in{
	my $self = shift;
	
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
		-title            => gui_window->gui_jt('フォントの変更'),
		-familylabel      => gui_window->gui_jchar('フォント：'),
		-sizelabel        => gui_window->gui_jchar('サイズ：'),
		-cancellabel      => gui_window->gui_jchar('キャンセル'),
		-nicefontsbutton  => 0,
		-fixedfontsbutton => 0,
		-fontsizes        => [8,9,10,11,12,13,14,15,16,17,18,19,20],
		-sampletext       => gui_window->gui_jchar('KH Coderは計量テキスト分析を実践するためのツールです。'),
		-initfont         => ,"TKFN"
	)->Show;
	return unless $font;

	#print "1: ", $font->configure(-family), "\n";

	my $font_conf = $font->configure(-family);
	
	# Win9x & Perl/Tk 804用の特殊処理
	if (
		        ( $] > 5.008 )
		and     ( $^O eq 'MSWin32' )
		and not ( Win32::IsWinNT() )
	){
		# 変換なし
	} else {
		$font_conf = gui_window->gui_jg($font_conf);
	}

	#print "2: $font_conf\n";

	$font_conf .= ",";
	$font_conf .= $font->configure(-size);
	
	$self->{e_font}->configure(-state => 'normal');
	$self->{e_font}->delete('0','end');
	$self->{e_font}->insert(0,gui_window->gui_jchar($font_conf,'sjis'));
	$self->{e_font}->configure(-state => 'disable');
}


#--------------------------#
#   設定値を返すアクセサ   #

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