package gui_widget::hinshi;
use base qw(gui_widget);
use strict;
use utf8;
use Tk;

sub _new{
	my $self = shift;
	
	my $height = 12;
	if ( defined($self->{height}) ){
		$height = $self->{height};
	}
	
	my $win = $self->parent->Frame(
		-borderwidth        => 2,
		-relief             => 'sunken',
	);
	
	$self->{hlist} = $win->Scrolled(
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
	my %default;
	
	my $sth = mysql_exec->select("
		SELECT  name,khhinshi_id
		FROM    hselection
		WHERE   ifuse = 1
		ORDER BY khhinshi_id
	",1)->hundle;
	
	#use Data::Dumper;
	#print Dumper($self->{selection});
	
	while (my $i = $sth->fetch){
		if (
			   $i->[0] =~ /B$/
			|| $i->[0] eq '否定助動詞'
			|| $i->[0] eq '形容詞（非自立）'
		){
			$default{$i->[1]} = 0;
		} else {
			$default{$i->[1]} = 1;
		}
	
		if ( defined($self->{selection}) ){
			$selection[$row] = $self->{selection}{$i->[1]};
			#print "$i->[1]: $self->{selection}{$i->[1]}\n";
		} else {
			$selection[$row]  = $default{$i->[1]};
		}
		$self->{name}{$row} = $i->[1];
		my $c = $self->hlist->Checkbutton(
			-text     => gui_window->gui_jchar($i->[0]),
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

		++$row;
	}
	$self->{checks} = \@selection;
	$self->{default} = \%default;
	
	#gui_hlist->update4scroll($self->hlist);
	
	$self->{win_obj} = $win;
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
sub select_default{
	my $self = shift;
	$self->selection_set( $self->{default} );
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

#--------------#
#   アクセサ   #

sub hlist{
	my $self = shift;
	return $self->{hlist};
}

1;