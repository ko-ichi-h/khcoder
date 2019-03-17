# Start KH Coder from command-line like below to automatically create
# a co-occurrences network from a text file.
# > kh_coder.exe -auto_run filename

# The "filename" must be full path. The co-occurrences network will be saved
# as "C:\khcoder\net.png." If the text file is already registered as a project,
# it will fail.

package auto_run;

sub plugin_config{

	# shall we run automatic analysis?
	if ( $ARGV[0] eq '-auto_run' && -e $ARGV[1] ){
		
		# specify file names
		my $file_target = $ARGV[1];
		my $file_save   = 'C:\khcoder3\net.png';

		# create a new project
		my $new = kh_project->new(
		    target => $file_target,
		    comment => 'auto',
		) or die("could not create a project\n");
		kh_projects->read->add_new($new) or die("could not save the project\n");

		# open the new project
		$new->open or die("could not open the project\n");

		# run pre-processing
		my $wait_window = gui_wait->start;
		&gui_window::main::menu::mc_morpho_exec;
		$wait_window->end(no_dialog => 1);

		# create a co-occurrences network
		my $win = gui_window::word_netgraph->open;
		$win->{net_obj}->{entry_edges_number}->delete('0','end');
		$win->{net_obj}->{entry_edges_number}->insert('end','120');
		$win->{net_obj}->{check_use_freq_as_size} = 1;
		$win->calc;

		# save the network
		my $win_result = $::main_gui->get('w_word_netgraph_plot');
		$win_result->{plots}[2]->save($file_save);

		# close the project
		$::main_gui->close_all;
		undef $::project_obj;

		# delete the project
		my $win_opn = gui_window::project_open->open;
		my $n = @{$win_opn->projects->list} - 1;
		$win_opn->{g_list}->selectionClear(0);
		$win_opn->{g_list}->selectionSet($n);
		$win_opn->delete;
		$win_opn->close;

		# exit KH Coder
		exit;
	
	}

	return undef;
}

1;
