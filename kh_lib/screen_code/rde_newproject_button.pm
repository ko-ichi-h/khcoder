package screen_code::rde_newproject_button;
use strict;

use screen_code::plugin_path;

#use encoding "cp932";
use gui_window::project_new;
use File::Path;
use Encode qw/encode decode/;
use screen_code::rde_excel_to_csv;
use rde_kh_spreadsheet;

sub add_button{
	my $self = shift;
	my $mw = shift;
	
	if (-f &screen_code::plugin_path::rde_path) {
		$self->{plugin_btn} = $mw->Button(
			-text => kh_msg->get('plugin_raw_data_editor'),
			-width => 25,
			-font => "TKFN",
			-command => sub{
					my $t = $::config_obj->os_path(
						$self->gui_jg(
							$self->e1->get
						)
					);
					
					my $inner_name = decode('cp932', $t);
					my $file_option = 'screen/temp/option.txt';
					my $font_str = gui_window->gui_jchar($::config_obj->font_main);
					my $plugin_rtn;
					if ($t =~ /\.(xls|xlsx)$/i){
						mkpath('screen/temp');
						
						my $file_vars = $::config_obj->cwd."/screen/temp/vardata.csv";
						unlink $file_vars if -f $file_vars;
						
						print $file_vars."\n";
						my $sheet_obj = rde_kh_spreadsheet->new($t);
						my $header = screen_code::rde_excel_to_csv::save_excel_to_csv(
							$sheet_obj,
							filev    => $file_vars,
							selected => $self->{column},
							lang     => $self->{lang},
							);
						unlink $file_option if -f $file_option;
						open(my $DATAFILE, ">:utf8", $file_option);
						print $DATAFILE "type=excel\n";
						print $DATAFILE "target=$inner_name\n";
						print $DATAFILE "vardata=$file_vars\n";
						print $DATAFILE "colnumber=$header\n";
						print $DATAFILE "font=$font_str\n";
						close($DATAFILE);
						
						$mw->iconify;
						$::main_gui->{win_obj}->iconify;
						my $system_err = 0;
						$! = undef;
						$plugin_rtn = system(&screen_code::plugin_path::rde_path, "$file_option");
						$system_err = 1 if ($!) ;
						
						if ($plugin_rtn != 0 && $system_err == 0) {
							open($DATAFILE, "<", $file_option) if -f $file_option;
							#if (my $line = <$DATAFILE>) { # higuchi
							my $line = <$DATAFILE>;        # higuchi
							if ( defined($line) ) {        # higuchi
								$self->{column} = $line;
							}
							$self->check_path($t);
						}
						$::main_gui->{win_obj}->deiconify;
						$mw->deiconify;
						unlink $file_vars if -f $file_vars;
						unlink $file_option if -f $file_option;
					} else {
						open(my $DATAFILE, ">:utf8", $file_option);
						print $DATAFILE "type=other\n";
						print $DATAFILE "target=$inner_name\n";
						print $DATAFILE "colnumber=$self->{column}\n";
						print $DATAFILE "font=$font_str\n";
						close($DATAFILE);
						
						$mw->iconify;
						$::main_gui->{win_obj}->iconify;
						my $system_err = 0;
						$! = undef;
						$plugin_rtn = system(&screen_code::plugin_path::rde_path, "$file_option");
						$system_err = 1 if ($!) ;
						
						if ($plugin_rtn != 0 && $system_err == 0) {
							open($DATAFILE, "<", $file_option) if -f $file_option;
							#if (my $line = <$DATAFILE>) { # higuchi
							my $line = <$DATAFILE>;        # higuchi
							if ( defined($line) ) {        # higuchi
								$self->{column} = $line;
							}
							$self->check_path($t);
						}
						$::main_gui->{win_obj}->deiconify;
						$mw->deiconify;
						unlink $file_option if -f $file_option;
					}
					
				}
		)->pack(-side => 'right');
		
		$self->{plugin_btn}->configure( -state => 'disabled' );
	}
}
1;