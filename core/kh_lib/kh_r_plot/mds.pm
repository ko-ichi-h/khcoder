package kh_r_plot::mds;
use base qw(kh_r_plot);

use strict;

sub _save_csv{
	my $self = shift;
	my $path = shift;

	my $temp_img =
		$::config_obj->cwd
		.'/config/R-bridge/'
		.$::project_obj->dbname
		.'_'
		.$self->{name}
		.'.tmp'
	;

	# open dvice
	$::config_obj->R->send("
		if ( exists(\"Cairo\") ){
			Cairo(width=640, height=640, unit=\"px\", file=\"$temp_img\", type=\"png\", bg=\"white\")
		} else {
			png(\"$temp_img\", width=640, height=480, unit=\"px\")
		}
	");
	$self->set_par;
	if ( length($self->{command_s}) ) {
		$::config_obj->R->send($self->{command_s});
	} else {
		$::config_obj->R->send($self->{command_f});
	}
	$::config_obj->R->send('dev.off()');
	
	# run save command
	my $r_command = &r_command_ready;
	$r_command .= "write.csv(out, file=\"$path\", fileEncoding = \"UTF-8\")";
	$::config_obj->R->send($r_command);
	
	# add BOM
	my $os_path = $::config_obj->os_path($path);
	my $temp_out = $::config_obj->cwd.'/config/R-bridge/temp.csv';
	$temp_out = $::config_obj->os_path($temp_out);
	if (-e $temp_out){
		unlink $temp_out or die("Could not delete file: $temp_out");
	}
	
	use File::BOM;
	open(my $fh_out, '>:encoding(UTF-8):via(File::BOM)', $temp_out) or
		gui_errormsg->open(
			type    => 'file',
			thefile => $temp_out,
		)
	;
	open(my $fh_in, "<:encoding(UTF-8)", $os_path) or
		gui_errormsg->open(
			type    => 'file',
			thefile => $os_path,
		)
	;
	while (<$fh_in>) {
		print $fh_out $_;
	}
	close $fh_in;
	close $fh_out;
	
	unlink ($os_path) or
		gui_errormsg->open(
			type    => 'file',
			thefile => $os_path,
		)
	;
	rename($temp_out, $os_path) or
		gui_errormsg->open(
			type    => 'file',
			thefile => $os_path,
		)
	;
	
	return 1;
}

sub r_command_ready{
	return '

# basic result
out <- data.frame(
	row.names = rownames(cl),
	dim1 = cl[,1]
)

if ( dim_n >= 2 ){
	out <- cbind( out, cl[,2] )
	colnames(out)[2] <- "dim2"
}

if ( dim_n >= 3 ){
	out <- cbind( out, cl[,3] )
	colnames(out)[3] <- "dim3"
}

# frequency
if ( exists("b_size_raw") ){
	out <- cbind( out, b_size_raw )
	colnames(out)[ length(colnames(out)) ] <- "frequency"
}

# cluster
if (n_cls > 0){
	out <- cbind( out, cutree(hcl, k=n_cls) )
	colnames(out)[ length(colnames(out)) ] <- "cluster"

	out <- cbind( out, col_bg_words_notrans)
	colnames(out)[ length(colnames(out)) ] <- "color"
}

';
}

1;