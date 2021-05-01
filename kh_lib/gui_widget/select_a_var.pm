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
	
	if ( $self->{add_position} ){
		push @options, [
			kh_msg->get('pos'),
			'pos'
		];
	}
	
	# 見出し
	if ($self->{show_headings}){
		foreach my $i ("h1","h2","h3","h4","h5"){
			if ( $self->{higher_headings} && $i eq $self->{tani} ){
				last;
			}
			if ( $i eq "h5" && $::project_obj->status_from_table ){
				next;
			}
			
			if (
				mysql_exec->select(
					"select status from status where name = \'$i\'",1
				)->hundle->fetch->[0]
			){
				my $t = substr($i,1,1);
				$t = kh_msg->get('heading').$t; # 見出し
				push @options, [$t, $i];
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
		if ($i->[1] =~ /^_topic_[0-9]+$|^_topic_docid$/ && $self->{no_topics}) {
			next;
		}
		
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
	$self->{var_id} = undef;
	unless ($self->{pack}){
		$self->{pack} = {-anchor => 'w', -padx => 2};
	}
	if (@options){
		$self->{opt_body} = gui_widget::optmenu->open(
			parent  => $self->{parent},
			pack    => $self->{pack},
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
			pack    => $self->{pack},
			options => 
				[
					[ kh_msg->get('na') , -1], # 利用不可
				],
			variable => \$self->{var_id},
		);
		$self->{opt_body}->configure(-state => 'disable');
		$self->{if_vars} = 0;
	}

	if ($self->{if_disabled}){
		$self->{opt_body}->{win_obj}->configure(-state => "disabled");
	}
	
	$self->{options} = \@options;
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
	
	if ( defined($self->{command}) ){
		&{$self->{command}};
	}
}

sub var_id{
	my $self = shift;
	return $self->{var_id};
}

1;
