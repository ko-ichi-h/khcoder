package gui_widget::select_a_var;
use strict;
use Tk;
use Jcode;

sub open{
	my $self;
	my $class = shift;
	%{$self} = @_;
	bless $self, $class;
	
	$self->fill;
	
	return $self;
}

sub fill{
	my $self = shift;
	my @options;
	my %vars = ();
	
	# 見出し
	if ($self->{show_headings}){
		foreach my $i ("h1","h2","h3","h4","h5"){
			if (
				mysql_exec->select(
					"select status from status where name = \'$i\'",1
				)->hundle->fetch->[0]
			){
				my $t = substr($i,1,1);
				$t = '見出し'.$t;
				push @options, [gui_window->gui_jchar($t), $i];
				$vars{$i} = 1;
			}
			if ($i eq $self->{tani}){
				last;
			}
		}
	}
	
	# 外部変数
	my %tani_check = ();
	foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
		$tani_check{$i} = 1;
		last if ($self->{tani} eq $i);
	}
	my $h = mysql_outvar->get_list;
	
	foreach my $i (@{$h}){
		if ($tani_check{$i->[0]}){
			push @options, [gui_window->gui_jchar($i->[1]), $i->[2]];
			$vars{$i->[2]} = 1;
			#print "varid: $i->[2]\n";
		}
	}
	
	if ($self->{opt_body}){
		$self->{opt_body}->destroy;
	}
	
	# Widgetの作成
	if (@options){
		$self->{opt_body} = gui_widget::optmenu->open(
			parent  => $self->{parent},
			pack    => {-side => 'left', -padx => 2},
			options => \@options,
			variable => \$self->{var_id},
			command  => sub{$self->rem_ov;},
		);
		if (
			   length($self->{last_var_id})
			&& $vars{$self->{last_var_id}} 
		){
			$self->{opt_body}->set_value( $self->{last_var_id} );
		}
		$self->{if_vars} = 1;
	} else {
		$self->{opt_body} = gui_widget::optmenu->open(
			parent  => $self->{parent},
			pack    => {-side => 'left', -padx => 2},
			options => 
				[
					[gui_window->gui_jchar('利用不可'), -1],
				],
			variable => \$self->{var_id},
		);
		$self->{opt_body}->configure(-state => 'disable');
		$self->{if_vars} = 0;
	}

	if ($self->{if_disabled}){
		$self->{opt_body}->{win_obj}->configure(-state => "disabled");
	}
}

sub new_tani{
	my $self      = shift;
	$self->{tani} = shift;
	
	$self->fill;
}

sub disable{
	my $self = shift;
	$self->{opt_body}->{win_obj}->configure(-state => "disabled");
	$self->{if_disabled} = 1;
}

sub enable{
	my $self = shift;
	if ($self->{if_vars}){
		$self->{opt_body}->{win_obj}->configure(-state => "normal");
	}
	$self->{if_disabled} = 0;
}

sub rem_ov{
	my $self = shift;
	$self->{last_var_id} = $self->{var_id};
}

sub var_id{
	my $self = shift;
	return $self->{var_id};
}

1;
