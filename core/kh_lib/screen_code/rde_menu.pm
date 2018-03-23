package screen_code::rde_menu;
use strict;

use screen_code::plugin_path;

use encoding "cp932";
use gui_window::main::menu;
use File::Path;
use Encode qw/encode decode/;

sub add_menu{
	my $self = shift;
	my $f = shift;
	my $menu0_ref = shift;
	
	if (-f &screen_code::plugin_path::rde_path) {
		push @{$menu0_ref}, 'm_b2_plugin';
			$self->{m_b2_plugin} = $f->command(
			-label => kh_msg->get('plugin_raw_data_editor'),
			#-image => $mw->Photo('window_icon',
			#		-file =>   Tk->findINC('acre.gif')
			#	),
			-font => "TKFN",
			-command => sub{
				my $font_str = gui_window->gui_jchar($::config_obj->font_main);
				
				mkpath('screen/temp');
				my $short_name = $::project_obj->file_short_name;
				my $dbName = $::project_obj->dbname;
				my $t_file = $::project_obj->file_target;
				my $sql_file = $::config_obj->cwd."/screen/temp/mysql_output.csv";
				my $varTableNum;
				unlink $sql_file if -f $sql_file;
				if (-f $sql_file) {
					return 0;
				}
				
				my $outvarhundle = mysql_exec->select("SELECT tab FROM $dbName.outvar",1)->hundle;
				if ($outvarhundle->rows > 0) {
					$varTableNum = $outvarhundle->fetch->[0];
					my $SQL = "SELECT * FROM $dbName.$varTableNum ORDER BY id INTO OUTFILE '$sql_file' FIELDS TERMINATED BY ',' ENCLOSED BY '\"' ESCAPED BY '\"' LINES TERMINATED BY '\r\n'";
					mysql_exec->do($SQL,1);
				} else {
					$varTableNum = 0;
				}
				
				print $t_file."\n";
				if (!$t_file){
					gui_errormsg->open(
						type   => 'msg',
						msg    => kh_msg->get('err_not_exist'),
					);
					return 0;
				}
				if ($varTableNum && !(-f $sql_file)) {
					gui_errormsg->open(
						type   => 'msg',
						msg    => kh_msg->get('err_output_from_db'),
					);
					return 0;
				}
				
				print $varTableNum."\n";
				my $csv_file = "";
				my $DATAFILE;
				if ($varTableNum) {
					$csv_file = $::config_obj->cwd."/screen/temp/vardata.csv";
					unlink $csv_file if -f $csv_file;
					open($DATAFILE, "+>>", $csv_file);
					my $h = mysql_exec->select("SELECT name FROM $dbName.outvar ORDER BY id",1)->hundle;
					while (my $i = $h->fetch){
						print $DATAFILE encode('utf8',"$i->[0],");
						$i++;
					}
					print $DATAFILE "id\n";
					open(my $IN, "<", $sql_file);
					my @sql_file_data = <$IN>;
					print $DATAFILE @sql_file_data;
					close($DATAFILE);
					close($IN);
				}
				my $file_option = 'screen/temp/option.txt';
				open($DATAFILE, ">:utf8", $file_option);
				print $DATAFILE "type=project\n";
				print $DATAFILE "textdata=$t_file\n";
				print $DATAFILE "vardata=$csv_file\n";
				print $DATAFILE "font=$font_str\n";
				close($DATAFILE);
				
				my $plugin_rtn = -1;
				
				$::main_gui->{win_obj}->iconify;
				my $system_err = 0;
				$! = undef;
				$plugin_rtn = system(&screen_code::plugin_path::rde_path_system, "$file_option");
				$system_err = 1 if ($!) ;
				$::main_gui->{win_obj}->deiconify;
				if ($plugin_rtn != 0 && $varTableNum && $system_err == 0) {
					if (mysql_exec->table_exists("$dbName.outvarcopy")) {
						mysql_exec->drop_table("$dbName.outvarcopy");
					}
					mysql_exec->do("CREATE TABLE $dbName.outvarcopy LIKE $dbName.outvar",1);
					mysql_exec->do("INSERT INTO $dbName.outvarcopy SELECT * FROM $dbName.outvar",1);
					mysql_exec->do("DELETE FROM $dbName.outvar",1);
					if (mysql_exec->table_exists("$dbName.${varTableNum}copy")) {
						mysql_exec->drop_table("$dbName.${varTableNum}copy");
					}
					mysql_exec->do("RENAME TABLE $dbName.$varTableNum TO $dbName.${varTableNum}copy",1);
					#my $SQLres = mysql_outvar::read::tab->new(
					#	file        => $csv_file,
					#	tani        => 'h5',
					#	skip_checks => 1,
					#)->read if -e $csv_file;
					my $SQLres = 0;
					eval {
						$SQLres = mysql_outvar::read::tab->new(
							file        => $csv_file,
							tani        => 'h5',
							skip_checks => 1,
						)->read if -e $csv_file;
					};
					if ($SQLres != 1 || $@) {
						gui_errormsg->open(
							type   => 'msg',
							msg    => kh_msg->get('err_edit'),
						);
						if (mysql_exec->table_exists("$dbName.outvar")) {
							mysql_exec->do("DELETE FROM $dbName.outvar",1);
						}
						if (mysql_exec->table_exists("$dbName.$varTableNum")) {
							mysql_exec->drop_table("$dbName.$varTableNum");
						}
						mysql_exec->do("INSERT INTO $dbName.outvar SELECT * FROM $dbName.outvarcopy",1);
						mysql_exec->do("DROP TABLE $dbName.outvarcopy",1);
						mysql_exec->do("RENAME TABLE $dbName.${varTableNum}copy TO $dbName.$varTableNum",1);
					} else {
						mysql_exec->drop_table("$dbName.outvarcopy");
						mysql_exec->drop_table("$dbName.${varTableNum}copy");
					}
				}
				unlink $sql_file if -f $sql_file;
				unlink $csv_file if -f $csv_file;
				unlink $file_option if -f $file_option;
			},
			-state => 'disable',
		);
	}
}

1;