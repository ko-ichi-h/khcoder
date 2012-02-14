package p2_d_concat_txt; # same as the file name
use strict;

#---------------------------#
#   Setting of this plugin  #

sub plugin_config{
	return {
		name     => 'Unify *.txt Files in the Folder',
		menu_cnf => 0,
		menu_grp => 'Data Preparation',
	};
}

#-------------#
#   command   #

sub exec{
	gui_window::concat_txt->open; # Open the Window
}


#------------------------------#
#   routine to open a window   #

package gui_window::concat_txt;
use base qw(gui_window);
use strict;
use Tk;

# creating a window
sub _new{
	my $self = shift;
	my $mw = $self->{win_obj};

	$mw->title(
		'Unify *.txt Files in the Folder'
	);

	$mw->Label(
		-text => 'Unify all *.txt files in the specified folder',
	)->pack(-anchor => 'w');

	my $fra_lab = $mw->LabFrame(
		-label       => 'Options',
		-labelside   => 'acrosstop',
		-borderwidth => 2
	)->pack(
		-expand => 'yes',
		-fill   => 'both'
	);

	# Frame for folder specification
	my $fra1 = $fra_lab->Frame()->pack(
		-anchor => 'c',
		-fill   => 'x',
		-expand => 'x',
	);

	$fra1->Label(
		-text => 'Folder: ',
	)->pack(
		-side => 'left',
	);

	$self->{btn1} = $fra1->Button(
		-text => 'Browse',
		-font => 'TKFN',
		-borderwidth => 1,
		-command => sub{ $mw->after
			(10,
				sub { $self->_get_folder; }
			);
		}
	)->pack(-padx => '2',-side => 'left');

	$self->{entry_folder} = $fra1->Entry()->pack(
		-side   => 'left',
		-fill   => 'x',
		-expand => 'x',
	);

	$self->{entry_folder}->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $self->{entry_folder},],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);

	# Frame for headings specification
	my $fra2 = $fra_lab->Frame()->pack(
		-anchor => 'c',
		-fill   => 'x',
		-expand => 'x',
	);

	$fra2->Label(
		-text => 'Heading level for describing filenames: ',
	)->pack(
		-side => 'left',
	);

	$self->{tani_obj} = gui_widget::optmenu->open(
		parent  => $fra2,
		pack    => {-side => 'left'},
		options =>
			[
				['H1', 'h1'],
				['H2', 'h2'],
				['H3', 'h3'],
				['H4', 'h4'],
				['H5', 'h5'],
			],
		variable => \$self->{tani},
	);
	$self->{tani_obj}->set_value('h2');

	# Checkbutton
	$self->{if_conv} = 1;
	$self->{check2} = $fra_lab->Checkbutton(
		-variable => \$self->{if_conv},
		-text     => 'convert "<" and ">" in the data to white space',
		-font     => "TKFN",
	)->pack(-anchor => 'w');

	# Buttons
	$mw->Button(
		-text    => 'Cancel',
		-font    => "TKFN",
		-width   => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(
		-side => 'right',
		-padx => 2
	);
	$mw->Button(
		-text    => 'OK',
		-width   => 8,
		-font    => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->_exec;});}
	)->pack(
		-side => 'right'
	);

	return $self;
}

sub _get_folder{
	my $self = shift;

	# We get a string with UTF8-Flag, but the string is actually CP932...
	# So we drop the UTF8-Flag.
	my $path = $self->{win_obj}->chooseDirectory;
	require Encode;
	$path = Encode::decode('cp932', "$path");
	$path = Encode::encode('cp932', $path);
	
	if ($path){
		$path = $self->gui_jg_filename_win98($path);
		$path = $self->gui_jg($path);
		$path = $::config_obj->os_path($path);
		$self->{entry_folder}->delete('0','end');
		$self->{entry_folder}->insert(0,$self->gui_jchar($path));
	}
	
	return $self;
}

sub _exec{
	my $self = shift;
	
	# Check the folder
	my $path = $self->gui_jg_filename_win98( $self->{entry_folder}->get() );
	$path = $self->gui_jg($path);
	$path = $::config_obj->os_path($path);
	unless (-d $path){
		gui_errormsg->open(
			type => 'msg',
			msg  => 'Could not find the Folder.',
		);
		return 0;
	}

	# file name
	my @types = (
		[ "text file",[qw/.txt/] ],
		["All files",'*']
	);
	my $save = $self->win_obj->getSaveFile(
		-defaultextension => '.txt',
		-filetypes        => \@types,
		-title            => 'Save the unified file as:'
	);
	unless ($save){
		return 0;
	}
	$save = gui_window->gui_jg_filename_win98($save);
	$save = gui_window->gui_jg($save);
	$save = $::config_obj->os_path($save);


	# execute
	my @files = ();
	open my $fh, '>', $save or
		gui_errormsg->open(
			type    => 'file',
			thefile => $save,
		);

	my $read_each = sub {
		# file name
		return if(-d $File::Find::name);
		return unless $_ =~ /.+\.txt$/;
		
		my $f = $File::Find::name;
		#print "$f, ";

		my $f_o = substr($f, length($path) + 1, length($f) - length($path));
		$f_o = Jcode->new($f_o)->euc;
		$f_o =~ s/\\/\//g;

		print $fh "<$self->{tani}>file:$f_o</$self->{tani}>\n";
		push @files, "file:$f_o";

		# start reading
		open (TEMP, $f) or
			gui_errormsg->open(
				type    => 'file',
				thefile => $f,
			);
		my $t     = '';
		my $n     = 0;
		my $icode = '';
		while ( <TEMP> ){
			$t .= $_;
			++$n;
			if ($n == 1000){
				$icode = &print_out($t, $icode, $fh, $self->{if_conv});
				$n = 0;
				$t = '';
			}
		}
		&print_out($t,$icode, $fh, $self->{if_conv});
		close (TEMP);
		print $fh "\n";
	};

	use File::Find;
	find($read_each, $path);
	close($fh);
	$fh = undef;
	if ($::config_obj->os eq 'win32'){
		kh_jchar->to_sjis($save);
	}

	# save filenames
	my $names = substr( $save,0, rindex($save,'.txt') );
	$names .= '_names.txt';
	open my $fhn, '>', $names or
		gui_errormsg->open(
			type    => 'file',
			thefile => $names,
		);
	foreach my $i (@files){
		print $fhn "$i\n";
	}
	close ($fhn);

	$self->close;
}

# 書き出し
sub print_out{
	my $t       = shift;
	my $icode   = shift;
	my $fh      = shift;
	my $if_conv = shift;

	unless ( length($t) ){
		print "empty!? ";
		return 1;
	}
	unless ($icode){
		$icode = Jcode->new($t)->icode;
		#print "$icode\n";
	}
	my $t = Jcode->new($t,$icode)->euc;
	if ($if_conv){
		$t =~ s/</ /g;
		$t =~ s/>/ /g;
	}
	print $fh $t;
	return $icode;
}

sub win_name{
	return 'w_concat_txt';
}

1;