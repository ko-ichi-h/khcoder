package gui_airborne;
use strict;

use gui_airborne::win32;
use gui_airborne::linux;

use Tk;
use Tk::DockFrame;

#----------#
#   作成   #
#----------#

sub make{
	my $class = shift;
	$class .= '::'.$::config_obj->os;
	my %args = @_;
	my $self = \%args;
	bless $self, $class;
	
	$self->_make;
	return $self;
}

sub _make{
	my $self = shift;
	$self->tower->pack(-fill => 'x', -expand => '0');
	$self->{port} = $self->parent->DockPort();
	$self->port->pack(fill => 'both', -expand => 'y');
	
	$self->{frame} = $self->parent->DockFrame(
		'-dock' => $self->port,
		'-trimcount' => 0,
		'-sensitivity' => 10,
		'-decorate' => 1,
		'-trimgap' => 2
	);
	return $self;
}

sub make_control{
	my $self = shift;
	my $p = shift;

	$self->{b_airborne} = $p->Button(
		-text    => Jcode->new('離陸')->sjis,
		-command => sub {$self->airborne;},
		-font    => "TKFN"
	)->pack(-side => "right");

	$self->{b_land} = $p->Button(
		-text    => Jcode->new('着陸')->sjis,
		-command => sub {$self->land;},
		-font    => "TKFN",
		-state   => 'disable'
	)->pack(-side => "right");

}

sub start{
	my $self = shift;
	
	# 親Windowのバインド
	$self->parent->bind(
		'<Control-Key-q>',
		sub{ $self->close; }
	);
	$self->parent->protocol('WM_DELETE_WINDOW', sub{ $self->close; });

	# 初期化
	if ($::config_obj->win_gmtry($self->parent_name."_if_air")){
		$self->parent->geometry($::config_obj->win_gmtry($self->parent_name));
		$self->parent->update;
		$self->airborne;
	}
}


#--------------#
#   イベント   #
#--------------#

sub airborne{
	my $self = shift;

	# 親のジオメトリを保存
	$::config_obj->win_gmtry(
		$self->parent_name,
		$self->parent->geometry
	);
	my $h_w = $self->parent->height;

	# フレームのジオメトリ
	my $g;
	if ($::config_obj->win_gmtry($self->parent_name."_fr")){
		$g = $::config_obj->win_gmtry($self->parent_name."_fr");
	} else {
		$g = $self->frame->geometry;
	}

	# 切り離し
	$self->frame->undock();
	$self->frame->geometry($g);
	$self->frame->title($self->title);

	# ポートのジオメトリ
	my $g2;
	if ($::config_obj->win_gmtry($self->parent_name."_po")){
		$g2 = $::config_obj->win_gmtry($self->parent_name."_po");
	} else {
		my $h_f = $self->frame->height;
		$h_w -= $h_f;
		my $w_w = $self->parent->width;
		$g2 = "$w_w"."x"."$h_w";
		print "no save "
	}

	$self->port->pack(-fill => 'none', -expand => '0');
	$self->tower->pack(-fill => 'both', -expand => '1');
	$self->parent->geometry($g2);
	$self->parent->update;
	$self->frame->focus;
#	sleep (3);

	$self->b_airborne->configure(-state,'disable');
	$self->b_land->configure(-state,'normal');
	$::config_obj->save;

	$self->frame->bind(
		'<Control-Key-q>',
		sub{ $self->close; }
	);
	$self->frame->protocol('WM_DELETE_WINDOW', sub{ $self->close; });
	$self->{if_airborne} = 1;
}


sub land{
	my $self = shift;

	# ジオメトリ保存
	$::config_obj->win_gmtry(
		$self->parent_name."_fr",
		$self->frame->geometry
	);
	$::config_obj->win_gmtry(
		$self->parent_name."_po",
		$self->parent->geometry
	);

	# パックやり直し
	$self->port->pack(-fill => 'both', -expand => '1');
	$self->tower->pack(-fill => 'x', -expand => '0');

	# 親のリサイズ
	$self->parent->geometry( $::config_obj->win_gmtry($self->parent_name) );
	$self->parent->update;

	# フレームのリサイズ
	my $w = $self->parent->width;
	my $h = $self->parent->height - $self->tower->height;
	
	$self->frame->geometry("$w"."x"."$h");
	$self->frame->update;

	$self->frame->dock($self->port);

	$self->b_airborne->configure(-state,'normal');
	$self->b_land->configure(-state,'disable');
	$self->parent->update;
	$self->frame->update;
	$::config_obj->save;

	$self->{if_airborne} = 0;
}

sub close{
	my $self = shift;
	$::config_obj->win_gmtry(
		$self->parent_name."_if_air",
		$self->if_airborne
	);

	if ($self->if_airborne){
		$::config_obj->win_gmtry(
			$self->parent_name."_fr",
			$self->frame->geometry
		);
		$::config_obj->win_gmtry(
			$self->parent_name."_po",
			$self->parent->geometry
		);
	} else {
		$::config_obj->win_gmtry(
			$self->parent_name,
			$self->parent->geometry
		);
	}
	$self->parent->destroy;
	$::config_obj->save;
	print "close ";
}

#--------------#
#   アクセサ   #
#--------------#
sub if_airborne{
	my $self = shift;
	return $self->{if_airborne};
}
sub b_airborne{
	my $self = shift;
	return $self->{b_airborne};
}
sub b_land{
	my $self = shift;
	return $self->{b_land};
}
sub parent{
	my $self = shift;
	return $self->{parent};
}
sub tower{
	my $self = shift;
	return $self->{tower};
}
sub port{
	my $self = shift;
	return $self->{port};
}
sub frame{
	my $self = shift;
	return $self->{frame};
}
sub title{
	my $self = shift;
	return $self->{title};
}
sub parent_name{
	my $self = shift;
	return $self->{parent_name};
}

1;
