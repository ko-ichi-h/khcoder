package screen_code::rde_menu;
use strict;

use screen_code::plugin_path;

#use encoding "cp932";
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
				my $latestTableNum;
				unlink $sql_file if -f $sql_file;
				if (-f $sql_file) {
					return 0;
				}
				
				my $outvarhundle = mysql_exec->select("SELECT tab, col FROM $dbName.outvar ORDER BY CHAR_LENGTH(col), col",1)->hundle;
				if ($outvarhundle->rows > 0) {
					#$latestTableNum = $outvarhundle->fetch->[0];
					#my $SQL = "SELECT * FROM $dbName.$latestTableNum ORDER BY id INTO OUTFILE '$sql_file' FIELDS TERMINATED BY ',' ENCLOSED BY '\"' ESCAPED BY '\"' LINES TERMINATED BY '\r\n'";
					#mysql_exec->do($SQL,1);
					
					my ($select_col, $first_table, $join_str, $on_str , @table_num_list);
					while (my $i = $outvarhundle->fetch){
						$select_col = "$select_col, $i->[0].$i->[1]";
						unless (scalar(@table_num_list)) {
							$first_table = $i->[0];
							push(@table_num_list, $i->[0]);
							$latestTableNum = $i->[0];
						} else {
							unless (grep{$_ eq $i->[0]} @table_num_list) {
								$join_str = "$join_str INNER JOIN $i->[0]";
								my $connect;
								if (scalar(@table_num_list) > 1) {
									$connect = "AND ";
								} else {
									$connect = "ON ";
								}
								$on_str = "$on_str $connect$first_table.id = $i->[0].id";
								push(@table_num_list, $i->[0]);
								if(length($i->[0]) > length($latestTableNum)) {
									$latestTableNum = $i->[0];
								} elsif ($i->[0] gt $latestTableNum) {
									$latestTableNum = $i->[0];
								}
							}
						}
					}
					$select_col = substr($select_col, 1);
					#print "$select_col \n";
					#print "$join_str \n";
					#print "$on_str \n";
					my $SQL = "SELECT $select_col FROM $first_table $join_str $on_str INTO OUTFILE '$sql_file' FIELDS TERMINATED BY ',' ENCLOSED BY '\"' ESCAPED BY '\"' LINES TERMINATED BY '\r\n'";
					#print "$SQL \n";
					mysql_exec->do($SQL,1);
				} else {
					$latestTableNum = 0;
				}
				
				print $t_file."\n";
				if (!$t_file){
					gui_errormsg->open(
						type   => 'msg',
						msg    => kh_msg->get('err_not_exist'),
					);
					return 0;
				}
				if ($latestTableNum && !(-f $sql_file)) {
					gui_errormsg->open(
						type   => 'msg',
						msg    => kh_msg->get('err_output_from_db'),
					);
					return 0;
				}
				
				print $latestTableNum."\n";
				my $csv_file = "";
				my $DATAFILE;
				if ($latestTableNum) {
					$csv_file = $::config_obj->cwd."/screen/temp/vardata.csv";
					unlink $csv_file if -f $csv_file;
					open($DATAFILE, "+>>", $csv_file);
					my $h = mysql_exec->select("SELECT name FROM $dbName.outvar ORDER BY CHAR_LENGTH(col), col",1)->hundle;
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
				$plugin_rtn = system(&screen_code::plugin_path::rde_path, "$file_option");
				$system_err = 1 if ($!) ;
				$::main_gui->{win_obj}->deiconify;
				print "$plugin_rtn $system_err $latestTableNum\n";
				if (length($latestTableNum) == 0 || $system_err != 0) {
					#エラーのため適用せず終了
				} elsif ($plugin_rtn == 256) {
					if (mysql_exec->table_exists("$dbName.outvarcopy")) {
						mysql_exec->drop_table("$dbName.outvarcopy");
					}
					mysql_exec->do("CREATE TABLE $dbName.outvarcopy LIKE $dbName.outvar",1);
					mysql_exec->do("INSERT INTO $dbName.outvarcopy SELECT * FROM $dbName.outvar",1);
					mysql_exec->do("DELETE FROM $dbName.outvar",1);
					if (mysql_exec->table_exists("$dbName.${latestTableNum}copy")) {
						mysql_exec->drop_table("$dbName.${latestTableNum}copy");
					}
					mysql_exec->do("RENAME TABLE $dbName.$latestTableNum TO $dbName.${latestTableNum}copy",1);
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
						if (mysql_exec->table_exists("$dbName.$latestTableNum")) {
							mysql_exec->drop_table("$dbName.$latestTableNum");
						}
						mysql_exec->do("INSERT INTO $dbName.outvar SELECT * FROM $dbName.outvarcopy",1);
						mysql_exec->do("DROP TABLE $dbName.outvarcopy",1);
						mysql_exec->do("RENAME TABLE $dbName.${latestTableNum}copy TO $dbName.$latestTableNum",1);
					} else {
						mysql_exec->drop_table("$dbName.outvarcopy");
						mysql_exec->drop_table("$dbName.${latestTableNum}copy");
						
						#プロジェクトを閉じて開く(前処理も必要か)
						my $cu_project;
						$cu_project = $::project_obj;
						undef $::project_obj;
						$cu_project->open;
					}
				} elsif ($plugin_rtn == 512) {
					open($DATAFILE, "<:encoding(shiftjis)", $file_option) if -f $file_option;
					my $line = <$DATAFILE>;
					if ( defined($line) ) {
						my $new_file = $line;
						#use screen_code::copy_project;
						#screen_code::copy_project::copy_project($new_file);
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