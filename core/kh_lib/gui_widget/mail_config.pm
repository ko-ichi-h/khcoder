package gui_widget::mail_config;
use base qw(gui_widget);

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
		-text     => Jcode->new('前処理効率化のためにデータをRAMに読み出す')->sjis,
		-font     => "TKFN",
		-command  => sub{$self->update;}
	)->pack(-anchor => 'w');

	$self->{check} = $lf->Checkbutton(
		-variable => \$self->{if_mail},
		-text     => Jcode->new('前処理の完了をメールで通知する')->sjis,
		-font     => "TKFN",
		-command  => sub{$self->update;}
	)->pack(-anchor => 'w');
	
	my $f1 = $lf->Frame()->pack(fill => 'x');
	$self->{lab1} = $f1->Label(
		-text => '    SMTP Server: ',
		-font => "TKFN",
	)->pack(-side => 'left');
	$self->{e1} = $f1->Entry(
		-font  => "TKFN",
		-width => 25,
	)->pack(-side => 'right');
	
	my $f2 = $lf->Frame()->pack(fill => 'x');
	$self->{lab2} = $f2->Label(
		-text => '    From: ',
		-font => "TKFN",
	)->pack(-side => 'left');
	$self->{e2} = $f2->Entry(
		-font  => "TKFN",
		-width => 25,
	)->pack(-side => 'right');

	my $f3 = $lf->Frame()->pack(fill => 'x');
	$self->{lab3} = $f3->Label(
		-text => '    To: ',
		-font => "TKFN",
	)->pack(-side => 'left');
	$self->{e3} = $f3->Entry(
		-font  => "TKFN",
		-width => 25,
	)->pack(-side => 'right');
	
	$self->fill_in;
	
	return $self;
}

sub fill_in{
	my $self = shift;
	
	$self->{e1}->insert(0,$::config_obj->mail_smtp() );
	$self->{e2}->insert(0,$::config_obj->mail_from() );
	$self->{e3}->insert(0,$::config_obj->mail_to() );
	
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

#--------------------------#
#   設定値を返すアクセサ   #

sub if_heap{
	my $self = shift;
	return $self->{if_heap};
}

sub if{
	my $self = shift;
	return $self->{if_mail};
}
sub smtp{
	my $self = shift;
	return $self->{e1}->get;
}
sub from{
	my $self = shift;
	return $self->{e2}->get;
}
sub to{
	my $self = shift;
	return $self->{e3}->get;
}

1;