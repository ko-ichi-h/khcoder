package p1_sample2_exec_sql; # same as the file name
use strict;

#---------------------------#
#   Setting of this plugin  #

sub plugin_config{
	return {
		name     => 'Execute SQL Queries',           # command name on the menu
		menu_grp => 'Sample',                        # group name on the menu
		menu_cnf => 2,                               # menu setting
			# 0: whenever executable
			# 1: executable if a project is opened
			# 2: executable if pre-processing of the project is complete
	};
}

#-------------#
#   command   #

sub exec{

	#----------------------------#
	#   some SQL queries to run  #
	
	# most frequent words (Norm)
	my $sql1 .= "
		SELECT genkei.name, genkei.num
		FROM genkei, khhinshi
		WHERE
		  genkei.khhinshi_id = khhinshi.id
		  AND khhinshi.name = 'Noun'
		ORDER BY genkei.num DESC
		LIMIT 10
	";

	# most frequent POSs (KH Coder)
	my $sql2 = "
		SELECT khhinshi.name, count(*) as kotonari, sum(genkei.num) as sousu
		FROM khhinshi, genkei
		WHERE
		  genkei.khhinshi_id = khhinshi.id
		GROUP BY khhinshi.id
		ORDER BY kotonari DESC
		LIMIT 10
	";

	# most frequent POSs (Tagger)
	my $sql3 = "
		SELECT hinshi.name, count(distinct genkei.id) as kotonari, count(*) as sousu
		FROM hyosobun, hyoso, genkei, hinshi
		WHERE
		        hyosobun.hyoso_id = hyoso.id
		    AND hyoso.genkei_id   = genkei.id
		    AND hyoso.hinshi_id   = hinshi.id
		GROUP BY hinshi.id
		ORDER BY kotonari DESC
		LIMIT 10
	";

	#-------------------------#
	#   execute SQL queries   #

	my ($result1, $result2, $result3);

	my $h = mysql_exec->select($sql1)->hundle;
	while (my $i = $h->fetch){
		$result1 .= "\t$i->[0] ($i->[1])\n";
	}

	$h = mysql_exec->select($sql2)->hundle;
	while (my $i = $h->fetch){
		$result2 .= "\t$i->[0] ($i->[1], $i->[2])\n";
	}

	$h = mysql_exec->select($sql3)->hundle;
	while (my $i = $h->fetch){
		$result3 .= "\t$i->[0] ($i->[1], $i->[2])\n";
	}

	#-----------------------------#
	#   modify output for print   #
	
	foreach my $i ($sql1, $sql2, $sql3){
		substr($i,0,1)  = '';
		substr($i,-2,2) = '';
	}

	my $msg;
	
	$msg .= "* most frequent norms: top 10\n";
	$msg .= "sql:\n$sql1\n";
	$msg .= "result:\n$result1\n";
	
	$msg .= "* most frequent POS: top 10 (KH Coder)\n";
	$msg .= "sql:\n$sql2\n";
	$msg .= "result: (types, tokens)\n$result2\n";

	$msg .= "* most frequent POS: top 10 (Tagger)\n";
	$msg .= "sql:\n$sql3\n";
	$msg .= "result: (types, tokens)\n$result3\n";

	$msg =~ s/\t\t/\t/g;

	#----------------------------------#
	#   open a window to show result   #

	gui_window::sample_sql->open(
		msg  => $msg
	);
	return 1;
}

#------------------------------#
#   routine to open a window   #

package gui_window::sample_sql;
use base qw(gui_window);
use strict;
use Tk;

## creating a window
sub _new{
	# initialize
	my $self = shift;
	my %args = @_;
	my $mw = $self->win_obj; # window object

	# window title
	$mw->title( gui_window->gui_jchar('SQL Queries and Results') );

	# a label
	$mw->Label(
		-text => gui_window->gui_jchar(' Executed following SQL Queries:'),
	)->pack(
		-anchor => 'w',
		-pady => 5
	);

	# read-only text widget
	my $text_widget = $mw->Scrolled(
		"ROText",
		-scrollbars => 'osoe',
		-height     => 20,
		-width      => 66,
	)->pack(
		-padx   => 2,
		-fill   => 'both',
		-expand => 'yes'
	);

	# put message to text widget
	$text_widget->insert(
		'end',
		$args{msg}
	);

	# "close" button
	$mw->Button(
		-text    => 'close',
		-command => sub{ $self->close; }
	)->pack(
		-pady => 2
	)->focus;

	return $self;
}

## internal name of the window
sub win_name{
	return 'w_sample_sql';
}

1;
