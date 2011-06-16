package gui_widget::chklist;
use base qw(gui_widget);
use strict;
use Tk;
use Jcode;

sub _new{
	my $self = shift;
	
	my $height = 6;
	if ( defined($self->{height}) ){
		$height = $self->{height};
	}
	
	my $win = $self->parent->Frame();
	
	my $win4buttons = $self->parent->Frame()->pack(
		-side => 'right',
		-padx => 2,
		-pady => 2,
	);
	
	my $win4hlist = $self->parent->Frame(
		-borderwidth        => 2,
		-relief             => 'groove',
	)->pack(
		-fill   => 'both',
		-expand => 1
	);
	

	$self->{button_all} = $win4buttons->Button(
		-text => gui_window->gui_jchar('すべて'),
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $self->parent->after(10,sub{$self->select_all;});}
	)->pack(-pady => 3);

	$self->{button_none} = $win4buttons->Button(
		-text => gui_window->gui_jchar('クリア'),
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $self->parent->after(10,sub{$self->select_none;});}
	)->pack();
	
	$self->{hlist} = $win4hlist->Scrolled(
		'HList',
		-scrollbars         => 'osoe',
		#-relief             => 'sunken',
		-font               => 'TKFN',
		-selectmode         => 'none',
		-indicator => 0,
		-highlightthickness => 0,
		-columns            => 1,
		-borderwidth        => 0,
		-height             => $height,
	)->pack(
		-fill   => 'both',
		-expand => 1
	);
	
	
	my $right = $self->hlist->ItemStyle('window',-anchor => 'w');
	my $row = 0;
	my @selection;
	
	#my $sth = mysql_exec->select("
	#	SELECT  name,khhinshi_id
	#	FROM    hselection
	#	WHERE   ifuse = 1
	#	ORDER BY khhinshi_id
	#",1)->hundle;
	
	#while (my $i = $sth->fetch){
	
	foreach my $i (@{$self->{options}}){
		if ( defined($self->{selection}) ){
			$selection[$row] = $self->{selection}{$i->[1]};
		} else {
			$selection[$row] = $self->{default};
		}
		$self->{name}{$row} = $i->[1];
		my $c = $self->hlist->Checkbutton(
			-text     => gui_window->gui_jchar($i->[0],'euc'),
			-variable => \$selection[$row],
			-anchor => 'w',
		);
		push @{$self->{check_wigets}}, $c;
		$self->hlist->add($row,-at => $row,);
		$self->hlist->itemCreate(
			$row,0,
			-itemtype  => 'window',
			-style => $right,
			-widget    => $c,
		);
		#$self->hlist->itemCreate(
		#	$row,1,
		#	-itemtype => 'text',
		#	-text     => gui_window->gui_jchar($i->[0],'euc')
		#);
		++$row;
	}
	$self->{checks} = \@selection;
	
	
	$self->{win_obj} = $win;
	$self->{win_obj2} = $win4buttons;
	$self->{win_obj3} = $win4hlist;
	
	return $self;
}

sub select_all{
	my $self = shift;
	foreach my $i (@{$self->{check_wigets}}){
		$i->select;
	}
}
sub select_none{
	my $self = shift;
	foreach my $i (@{$self->{check_wigets}}){
		$i->deselect;
	}
}

sub disable{
	my $self = shift;
	foreach my $i (
		@{$self->{check_wigets}},
		$self->{button_all},
		$self->{button_none},
		#$self->{hlist},
	){
		$i->configure(-state => 'disable');
	}
}

sub enable{
	my $self = shift;
	foreach my $i (
		@{$self->{check_wigets}},
		$self->{button_all},
		$self->{button_none},
		#$self->{hlist},
	){
		$i->configure(-state => 'normal');
	}
}

sub selected{
	my $self = shift;
	my @r;
	my $row = 0;
	foreach my $i (@{$self->{checks}}){
		if ($i){
			push @r, $self->{name}{$row};
		}
		++$row;
	}
	return \@r;
}

sub selection_get{
	my $self = shift;
	my $r;
	my $row = 0;
	foreach my $i (@{$self->{checks}}){
		$r->{$self->{name}{$row}} = $i;
		++$row;
	}
	return $r;
}

sub selection_set{
	my $self      = shift;
	my $selection = shift;

	my $row = 0;
	foreach my $i (@{$self->{check_wigets}}){
		if ($selection->{$self->{name}{$row}}){
			$i->select;
		} else {
			$i->deselect;
		}
		++$row;
	}


}

sub destroy{
	my $self = shift;
	$self->{win_obj}->destroy;
	$self->{win_obj2}->destroy;
	$self->{win_obj3}->destroy;
	$self = undef;
	return 1;
}

#--------------#
#   アクセサ   #

sub hlist{
	my $self = shift;
	return $self->{hlist};
}

1;