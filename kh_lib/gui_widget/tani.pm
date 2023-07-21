package gui_widget::tani;
use base qw(gui_widget);
use strict;
use Tk;
use Jcode;

use kh_msg;

my %name = (
	"bun" => kh_msg->gget('sentence'),
	"dan" => kh_msg->gget('paragraph'),
	"h5"  => "H5",
	"h4"  => "H4",
	"h3"  => "H3",
	"h2"  => "H2",
	"h1"  => "H1",
);

my %value = (
	kh_msg->gget('sentence') => "bun",
	kh_msg->gget('paragraph') => "dan",
	"H5"  => "h5",
	"H4"  => "h4",
	"H3"  => "h3",
	"H2"  => "h2",
	"H1"  => "h1",
);

sub _new{
	my $self = shift;
	my @list0 = ("bun","dan","h5","h4","h3","h2","h1");

	my $len = 0;
	my @list1;
	my %cases = ();

	foreach my $i (@list0){
		my $flag1 = 0;
		if (
			mysql_exec->select(
				"select status from status where name = \'$i\'",1
			)->hundle->fetch->[0]
		){
			$flag1 = 1;
		}
		
		my $flag2 = 0;
		if ( $self->{tani_gt_1} && $flag1 ) {     # Check if there are 2 or more cases,
			$cases{$i} = mysql_exec->select(      # when "tani_gt_1" is ON.
				"select count(*) from $i",        # ("bun" will go thru this check)
				1                                 #
			)->hundle->fetch->[0];                #
			if ($cases{$i} > 1) {                 #
				$flag2 = 1;                       #
			}                                     #
		}                                         #
		elsif ( (! $self->{tani_gt_1}) ) {
			$flag2 = 1;
		}

		if ($i eq 'bun') {
			$flag2 = 1;
		}

		if ($flag1 && $flag2) {
			push @list1, $i;
			$len = length( $name{$i} )
				if $len < length( $name{$i} );
		}
	}
	
	if (
		   $::config_obj->msg_lang eq 'jp'
		|| $::config_obj->msg_lang eq 'kr'
		|| $::config_obj->msg_lang eq 'cn'
	) {
		$len = 4;
	}

	$self->{win_obj} = $self->parent->Menubutton(
		-text        => '',
		-tearoff     => 'no',
		-relief      => 'raised',
		-indicator   => 'yes',
		-font        => "TKFN",
		-width       => $len,
		-borderwidth => 1,
	)->pack();
	foreach my $i (@list1){
		$self->{win_obj}->radiobutton(
			-label    => gui_window->gui_jchar(" $name{$i}"),
			-variable => \$self->{raw_opt},
			-value    => "$i",
			-font     => "TKFN",
			-command  => sub{$self->mb_refresh}
		);
	}

	$self->{raw_opt} = $::project_obj->last_tani;
	
	# check if there are 2 or more cases: default "h5" or "dan"
	if ( $self->{tani_gt_1} ){
		if ($cases{$self->{raw_opt}} < 2) {
			if ( $self->{raw_opt} eq 'h5' ){
				if ($cases{dan} < 50 && $cases{bun} > $cases{dan} ) {
					$self->{raw_opt} = 'bun';
				}
				elsif ($cases{dan} < 2) {
					$self->{raw_opt} = 'bun';
				}
				else {
					$self->{raw_opt} = 'dan';
				}
			}
			elsif ( $self->{raw_opt} eq 'dan' ){
				$self->{raw_opt} = 'bun';
			}
			print "The default unit (tani) is modified to \"$self->{raw_opt}\".\n";
		}
	}

	return $self;
}

sub tani{
	my $self = shift;
	return gui_window->gui_jg( $self->{raw_opt} );
}
sub start{
	my $self = shift;
	$self->mb_refresh;
}
sub mb_refresh{
	my $self = shift;
	$self->{win_obj}->configure(
		-text,
		gui_window->gui_jchar( $name{$self->{raw_opt}} )
	);
	$self->{win_obj}->update;
	$::project_obj->last_tani($self->{raw_opt})
		unless $self->{dont_remember};
	if ( defined($self->{command}) and not (defined($_[0]) && $_[0] == 5) ){
		&{$self->{command}};
	}
}

1;
