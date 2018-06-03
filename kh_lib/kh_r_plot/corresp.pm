package kh_r_plot::corresp;
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
	$::config_obj->R->send($self->{command_f});
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
std <- function(vect){
	vect <- sqrt(vect)
	vect <- vect / sd(vect)
	vect <- vect - mean(vect)
	vect <- vect * 10 + 50
	r <- NULL
	for (i in vect){
		if (i < 1){
			i <- 1
		}
		r <- c(r, i)
	}
	return( r )
}

c_size <- std( colSums(d) )
r_size <- std( n_total )

out <- rbind(
	data.frame(
		type = "col",
		frequency = colSums(d),
		size = c_size,
		c$cscore,
		row.names = rownames(c$cscore)
	),
	data.frame(
		type = "row",
		frequency = n_total,
		size = r_size,
		c$rscore,
		row.names = rownames(c$rscore)
	)
)

	';
}
1;