# Run MDS with "metaMDS()" command of "vegan" package.

# Setting of this plugin
package p1_sample5_mds;

sub plugin_config{
	return {
		name     => 'MDS (metaMDS)',
		menu_grp => 'Sample',
		menu_cnf => 2,
	};
}

# command
sub exec{
	gui_window::mds->open;                        # open the GUI
}

# set up the GUI
package gui_window::mds;
use base qw(gui_window);
my $selection;

sub _new{
	my $self = shift;
	
	$selection = gui_widget::words->open(         # Selection of words
		parent => $self->win_obj,
		verb   => 'plot'
	);

	$self->win_obj->Button(                       # OK button
		-text => 'OK',
		-command => sub{ $self->make_mds; }
	)->pack;

	return $self;
}

sub win_name{
	return 'w_plugin_mds';                        # specify a name
}

# use "metaMDS" command to run MDS
sub make_mds{
	my $self = shift;

	my $file_r   = 'plugin_jp/mds.r';             # *.r file with MDS commands
	my $file_pdf = 'mds.pdf';                     # save file

	use Cwd;                                      # make full path
	$file_r   = cwd.'/'.$file_r;
	$file_pdf = cwd.'/'.$file_pdf;

	my $r_command = mysql_crossout::r_com->new(   # documents x words matrix
		$selection->params,
		rownames => 0,
	)->run;

	$r_command .= "\n";                           # make R commands
	$r_command .= "source(\"$file_r\")";

	my $plot = kh_r_plot->new(                    # run the analysis
	  name      => 'plugin_mds',                  # (specify a name)
	  command_f => $r_command
	);

	$plot->save( $file_pdf );                       # save as a pdf file
	system("cmd /c start \"title\" \"$file_pdf\""); # open the pdf file

	$self->close;                                 # close the GUI
}

1;