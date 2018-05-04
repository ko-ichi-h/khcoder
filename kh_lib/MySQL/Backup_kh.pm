package MySQL::Backup_kh;

use strict;

use DBI;
our $VERSION = '0.04';

sub new{   #standart constructor
    my ($pkg, $dbname, $dbhost, $dbuser, $dbpass, $param) = @_;

    my $self           = {};
    my $dbh            = DBI->connect("DBI:mysql:$dbname:$dbhost", $dbuser, $dbpass, {RaiseError=>1});
    $self->{'DBH_OBJ'} = $dbh;
    $self->{'param'}   = {};

    foreach my $key(keys %{$param}){
      $self->{'param'}->{$key} = $param->{$key};
    }

    bless($self, $pkg);
    return $self;
}

sub new_from_DBH{   #if you have already DBI connection, you can use this
    my ($pkg, $dbh, $param) = @_;

    my $self           = {};
    $self->{'DBH_OBJ'} = $dbh;
    $self->{'param'}   = {};

    foreach my $key(keys %{$param}){
      $self->{'param'}->{$key} = $param->{$key};
    }

    bless($self, $pkg);
    return $self;
}

sub run_sql{
    my ($self, $sql) = @_;
    my $dbh = $self->{'DBH_OBJ'};
    #die $dbh->prepare($sql);
    
    my $sth = $dbh->prepare($sql) || die $self->caller();
    
    if (not $sth){
      die $DBI::errstr;
    }

    my $res = $sth->execute;
    if (not $res){
      return undef;
    }
    return $sth;
}

sub arr_hash{
    my ($self, $sql) = @_;
    my @res;
    if (my $sth = $self->run_sql($sql)){
      while (my $ref = $sth->fetchrow_hashref){
        push @res, $ref;
      }
    }
    return @res;
}

sub param{
    my ($self, $ref) = @_;
    if(ref $ref eq 'HASH'){
      foreach my $key(keys %{$ref}){
        $self->{'param'}->{$key} = $ref->{$key};
      }
    }
    elsif(ref $ref eq 'SCALAR'){
       if(defined $self->{'param'}->{$ref}){
         return $self->{'param'}->{$ref};
       }
       else{
         $self->{'error'} = 'can\'t return this param: please check if name of it is right. Also, this param can be undefined';
         return undef;
       }
    }
}

sub table_desc{ #creates a structure of the inputed table

    my ($self, $table) = @_;
    my @temp = $self->arr_hash("SHOW COLUMNS FROM $table");
    my @temp2;

    foreach my $ref(@temp){
      my $null = 'NOT NULL' if ($ref->{'Null'} !~ m/YES/i);
      my $default;
      if($ref->{'default'}){
        $default .= $null.' default '."'".$ref->{'Default'}."'";
      }
      else{
        if (($ref->{'Null'} =~ m/YES/i)and(!($ref->{'Type'} =~ m/timestamp/i))){
	  $default .= 'default '.'NULL';
        }
        else{
          $default .= $null;
	}
      }
      chomp $default;
      push @temp2, join(' ', '`'.$ref->{'Field'}.'`', $ref->{'Type'}, $default.($ref->{'Extra'}?' '.$ref->{'Extra'}:''));
    }

    my $columns = join(', ', @temp2);

    @temp = $self->arr_hash("SHOW KEYS FROM $table");
       foreach my $ref(@temp){
         if ($ref->{'Key_name'} =~ m/PRIMARY/i){
           $columns .= ", PRIMARY KEY (`".$ref->{'Column_name'}."`)";
	 }
     #    elsif ($ref->{'Non_unique'} =~ m/0/i){
     #      $columns .= ", UNIQUE INDEX (`".$ref->{'Column_name'}."`)";
	 #}
     #    elsif ($ref->{'Index_type'} =~ m/FULLTEXT/i){
     #      $columns .= ", FULLTEXT INDEX (`".$ref->{'Column_name'}."`)";
	 #}
     #    else{
     #      $columns .= ", INDEX (`".$ref->{'Column_name'}."`)";
	 #}
       }
    my $sql = "CREATE TABLE `$table` ($columns);";

    return $sql;
}

sub create_structure{ #creates a structure of the current DB
	my $self = shift;
	my $fh = shift;
	my $sql = '';

	my @arr;
	if ($self->{'param'}->{'tables'}){
		@arr = @{$self->{'param'}->{'tables'}};
	} else {
		my $sth = $self->run_sql("SHOW TABLES");
		while(my @temp = $sth->fetchrow_array()){
			push @arr, $temp[0];
		}
	}

	foreach my $temp(@arr){
		if ($fh){
			print $fh $self->table_desc($temp)."\n";
		} else {
			$sql .=   $self->table_desc($temp)."\n";
		}
	}

	if ($fh){
		return 1;
	} else {
		return $sql;
	}
}

sub table_idx_desc{ #creates a index structure of the inputed table
	my ($self, $table) = @_;

	my %keys;
	foreach my $ref( $self->arr_hash("SHOW KEYS FROM $table") ){
		if ($ref->{'Key_name'} =~ m/PRIMARY/i){
			next;
		}
		push @{$keys{ $ref->{'Key_name'} }->{member}}, $ref->{'Column_name'};
		$keys{ $ref->{'Key_name'} }->{Non_unique} = $ref->{'Non_unique'};
		$keys{ $ref->{'Key_name'} }->{Index_type} = $ref->{'Index_type'};
	}

	my $sql = '';
	foreach my $i (keys %keys){
		$sql .= 'CREATE ';
		$sql .= 'UNIQUE '   if ( $keys{$i}->{Non_unique} =~ m/0/i );
		$sql .= 'FULLTEXT ' if ( $keys{$i}->{Index_type} =~ m/FULLTEXT/i );
		$sql .= "INDEX `$i` ON `$table` (";
		foreach my $h ( @{$keys{$i}->{member}} ){
			$sql .= "`$h`,";
		}
		chop $sql;
		$sql .= ");\n";
	}

	return $sql;
}

sub create_index_structure{ #creates a index structure of the current DB
	my $self = shift;
	my $fh = shift;
	my $sql = '';

	my @arr;
	if ($self->{'param'}->{'tables'}){
		@arr = @{$self->{'param'}->{'tables'}};
	} else {
		my $sth = $self->run_sql("SHOW TABLES");
		while(my @temp = $sth->fetchrow_array()){
			push @arr, $temp[0];
		}
	}

	foreach my $temp(@arr){
		if ($fh){
			print $fh $self->table_idx_desc($temp);
		} else {
			$sql .=   $self->table_idx_desc($temp);
		}
	}

	if ($fh){
		return 1;
	} else {
		return $sql;
	}
}

sub get_table_data{
	my ($self, $table, $fh) = @_;
	my $data;

	my $key_list = '';
	foreach my $i ($self->arr_hash("SHOW COLUMNS FROM $table")){
		$key_list .= '`'.$i->{Field}.'`,';
	}
	chop $key_list;

	my $sth = $self->run_sql("SELECT $key_list FROM $table WHERE 1");
	while ( my $i = $sth->fetch() ){
		my $value_list;
		foreach my $h (@{$i}){
			$value_list .= $self->{'DBH_OBJ'}->quote($h).',';
		}
		chop $value_list;

		if($self->{'param'}->{'USE_REPLACE'}){
			$data .= "REPLACE INTO `$table` ($key_list) VALUES ($value_list);\n";
		} else{
			$data .= "INSERT INTO `$table` ($key_list) VALUES ($value_list);\n";
		}
		if ($fh){
			print $fh $data;
			$data = '';
		}
	}

	return $data;
}

sub data_backup{ #get all data from current database
	my $self = shift;
	my $fh   = shift;
	my $sql = '';

	my @arr;
	if ($self->{'param'}->{'tables'}){
		@arr = @{$self->{'param'}->{'tables'}};
	} else {
		my $sth = $self->run_sql("SHOW TABLES");
		while(my @temp = $sth->fetchrow_array()){
			push @arr, $temp[0];
		}
	}

	foreach my $temp(@arr){
		if ( ($self->{'param'}->{'SHOW_TABLE_NAMES'}) ){
			if ($fh){
				print $fh "/* $temp */\n";
			} else {
				$sql .= "/* $temp */\n";
			}
		}
		
		my $table_data = $self->get_table_data($temp,$fh);
		$sql .= $table_data if $table_data;
	}

	if ($fh){
		return 1;
	} else {
		return $sql;
	}
}

sub run_restore_script{
    my ($self, $file) = @_;
    my $sth = $self->run_sql("SHOW TABLES");
    my $dbh = $self->{'DBH_OBJ'};
    my (@tables, @tables_for_lock);
    while(my $temp = $sth->fetchrow_array()){
      push @tables, "$temp";
      push @tables_for_lock, "$temp WRITE";
    }
    foreach my $temp(@tables){
      $dbh->do("DROP TABLE IF EXISTS `$temp`");
    }

	open(FILE, $file) or die("cannot open file: $file\n");

	while (<FILE>){
		s/\x0D\x0A/\n/g;
		tr/\x0D\x0A/\n\n/;
		chomp;
		chop;
		$self->run_sql($_);
	}

	close (FILE);

    return 1;
}

sub run_upgrade_script{
       my $self =shift;
       my $file = shift;
       my $db_vers;
       my $dbh = $self->{'DBH_OBJ'};
       my $sth = $self->run_sql("SHOW TABLES");
       my (@tables, @tables_for_lock, $table_list);
       while(my $temp = $sth->fetchrow_array()){
         push @tables, "`$temp`";
         push @tables_for_lock, "`$temp` WRITE";
       }
       #run_sql("LOCK TABLES ".join(', ', @tables_for_lock));
       #$sth = run_sql("FLUSH TABLES");

       open(FILE, $file);
       my $fline = readline(*FILE); # kh
       if ($fline =~ m/\r\n/){
         $/ = ";\r\n";
       }
       elsif($fline =~ m/\n\r/){
         $/ = ";\n\r";
       }
       else{
         $/ = ";\n";
       }

       my @sql = <FILE>;
       unshift @sql, $fline;
       $/= "\n";
       close(FILE);
       
       foreach my $sql(@sql){
         chomp $sql;
         if($sql =~ /^CREATE TABLE ([`\w]+) \((.*)\)/i){
           for(my $i=0; $i<=$#tables; $i++){
	    #die "lc($tables[$i]) eq lc($1)";
             if(($tables[$i] eq $1)or(lc($tables[$i]) eq lc($1))){
                my $temp_2_1 = $2;
                my @columns_desc = split /, /, $temp_2_1;
                my $real_table = $self->table_desc($tables[$i]);
                #die $real_table
                #die $real_table."<br>".$sql if $tables[$i] eq 'perldesk_kb_ratings';
		$real_table =~ /^CREATE TABLE ([`\w]+) \((.*)\)/i;
                my $temp_2_2 = $2;
                my @real_columns_desc = split /, /, $temp_2_2;



		my (@columns, @real_columns);
                $#columns      = $#columns_desc;
                $#real_columns = $#real_columns_desc;
		for(my $j=0; $j<=$#columns_desc; $j++){
                  $columns_desc[$j] =~ s/^\s*(.*?)\s*$/$1/gi;
                  if($columns_desc[$j] =~ m/^([`\w]+) /){
                    $columns[$j] = $1;
                  }
   	        }

		for(my $j=0; $j<=$#real_columns_desc; $j++){
                  $real_columns_desc[$j] =~ s/^\s*(.*?)\s*$/$1/gi;
                  if($real_columns_desc[$j] =~ m/^([`\w]+) /){
                    $real_columns[$j] = $1;
                  }
	        }

		my $bool = 0;
                for(my $j=0; $j<=$#columns; $j++){  #checking for existing of columns
                 for(my $k=0; $k<=$#real_columns; $k++){
                   $bool = 0;
		   if ($columns_desc[$j] =~ /^PRIMARY KEY \(([`\w]+)\)/){ #checking if it's Primary key
                      my $column_name = $1;
                      #die $tables[$i];
                      $sth = $self->run_sql("SHOW KEYS FROM $tables[$i]");

                      while(my $temp = $sth->fetchrow_hashref()){
                       # die $temp->{'Column_name'}.' '.$column_name;
                        if((($temp->{'Key_name'} eq 'PRIMARY')or($temp->{'Key_name'} eq 'primary'))and(('`'.$temp->{'Column_name'}.'`' eq $column_name)or('`'.lc($temp->{'Column_name'}).'`' eq lc($column_name)))){
                         $bool= 1;
                         #die $bool;
                         last;
			}
                      }
	  	   }


		   elsif ($columns_desc[$j] =~ /^KEY(.*)\(([`\w]+)\)/){  #checking if it's key
                    #for(my $l=0; $l<$#real_columns; $l++){
                     if($columns_desc[$j] eq $real_columns_desc[$k]){

                      $bool = 1;
                      last;
		     }
                    #}
                    if($bool){last;}
	  	   }
                  # elsif ($columns_desc[$j] =~ /^INDEX/){

                  # }
                   elsif ($columns_desc[$j] =~ /^INDEX(.*)\(([`\w]+)\)/){  #checking if it's key
                    #for(my $l=0; $l<$#real_columns; $l++){
                     if($columns_desc[$j] eq $real_columns_desc[$k]){
                     #die $real_columns_desc[$k];
                      $bool = 1;
                      #die $columns_desc[$j]."  ".$real_columns_desc[$k];
                      #die $bool;
                      last;
		     }
                    #}
                    if($bool){last;}
	  	   }
                   elsif ($columns_desc[$j] =~ /^UNIQUE INDEX(.*)\(([`\w]+)\)/){  #checking if it's key UNIQUE

                    #for(my $l=0; $l<$#real_columns; $l++){
                     if($columns_desc[$j] eq $real_columns_desc[$k]){
                      $bool = 1;
                      #die $columns_desc[$j];
                      last;
		     }
                    #}
                    if($bool){last;}
	  	   }

                   elsif ($columns_desc[$j] =~ /^FULLTEXT INDEX(.*)\(([`\w]+)\)/){  #checking if it's key FULLTEXT
                   #die $columns_desc[$j];
                    #for(my $l=0; $l<$#real_columns; $l++){
                     if($columns_desc[$j] eq $real_columns_desc[$k]){
                      $bool = 1;
                      last;
		     }
                    #}
                    if($bool){last;}
	  	   }

		   elsif(lc($columns[$j]) eq lc($real_columns[$k])){ #checking for existence of column
                    if(lc($columns_desc[$j]) eq lc($real_columns_desc[$k])){
                     $bool = 1;
                     last;
                    }
                    else{
                    #die "lc($columns[$j]) eq lc($real_columns[$k])";
                    # die "$columns_desc[$j] eq $real_columns_desc[$k]";
                     $bool = 2;
                     last;
		    }
		   }
                 }
                   my $key;
		 unless($bool){ #the column or Key doesn't exist
                   #chomp $columns_desc[$j];

                   if($columns_desc[$j] =~ /^PRIMARY KEY \(([`\w]+)\)/){
                    
                     my $column_name = $1; #die $column_name;
                     $key = "PRIMARY KEY ($column_name)";
                     #killimg duplicates
                     my $sth = $self->run_sql("SELECT * FROM $tables[$i] WHERE 1");
                     while(my $temp = $sth->fetchrow_hashref()){
                      my $th = $self->run_sql("SELECT * FROM $tables[$i] WHERE $column_name = ".$dbh->quote($temp->{$column_name}));
                      my $rows = $th->rows;
                      if($rows > 1){
                          $self->run_sql("DELETE FROM $tables[$i] WHERE $column_name = ".$dbh->quote($temp->{$column_name})." LIMIT 1");
                          $table_list.="DELETE FROM $tables[$i] WHERE $column_name = ".$dbh->quote($temp->{$column_name})." LIMIT 1\n";
		      }
                     }
                   }
                   my $key_name;
		   unless ($key){
                    if($columns_desc[$j] =~ /^KEY (.*) \((.*)\)/){
                      $key = "INDEX $1 ($2)";
                      $key_name = $1;
		    }
                    elsif($columns_desc[$j] =~ /^KEY(.*)\((.*)\)/){
                      $key = "INDEX ($2)";
                      $key_name = $2;
		    }
                    elsif($columns_desc[$j] =~ /^INDEX (.*) \((.*)\)/){
                      $key = "INDEX $1 ($2)";
                      $key_name = $1;
		    }
                    elsif($columns_desc[$j] =~ /^INDEX(.*)\((.*)\)/){
                      $key = "INDEX ($2)";
                      $key_name = $2;
		    }
                    elsif($columns_desc[$j] =~ /^UNIQUE INDEX (.*) \((.*)\)/){
                      $key = "UNIQUE INDEX $1 ($2)";
                      $key_name = $1;
		    }
		    elsif($columns_desc[$j] =~ /^UNIQUE INDEX(.*)\((.*)\)/){
                      $key = "UNIQUE INDEX ($2)";
                      $key_name = $2;
		    }
                    elsif($columns_desc[$j] =~ /^FULLTEXT INDEX (.*) \((.*)\)/){
                      $key = "FULLTEXT INDEX $1 ($2)";
                      $key_name = $1;
		    }
		    elsif($columns_desc[$j] =~ /^FULLTEXT INDEX(.*)\((.*)\)/){
                      $key = "FULLTEXT INDEX ($2)";
                      $key_name = $2;
		    }
                    
		   }

                   unless($key){
                    my $add;
                    if($columns_desc[$j] =~ m/auto_increment/i){$add=' PRIMARY KEY';}
                    my $sql2 = "ALTER TABLE $tables[$i] ADD COLUMN ".$columns_desc[$j].$add;
                    eval{$dbh->do($sql2)} or die $self->errstr("Couldn't execute statement: $sql2 $DBI::errstr: stopped");
		    $table_list .= $sql2."\n";
                   }
                   else{
                    
                    my $sql2 = "SHOW KEYS FROM $tables[$i]";
                    #die $sql2;
                    my $sth = $self->run_sql($sql2);
		    $table_list .= $sql2."\n";
                    my $key_exists;
                    while(my $ref = $sth->fetchrow_hashref()){
                        die $ref->{'Key_name'}.' ? '.$key_name;
                        if('`'.$ref->{'Key_name'}.'`' eq $key_name){
                           $key_exists = 1;
                           last;
			}
		    }
                    unless($key_exists){
                        $sql2 = "ALTER TABLE $tables[$i] ADD $key";
                        die $sql2;
                        $self->run_sql($sql2);
		        $table_list .= $sql2."\n";
                    }
		   }

                   #$bool =1;
 	         }
                 elsif($bool == 2){
                    my $add;
                    #if($columns_desc[$j] =~ m/auto_increment/i){$add=' PRIMARY KEY';}
                    my $sql2 = "ALTER TABLE $tables[$i] MODIFY COLUMN ".$columns_desc[$j].$add;
                    eval{$dbh->do($sql2)} or die $self->errstr("Couldn't execute statement: $sql2 $DBI::errstr: stopped");
		    $table_list .= $sql2."\n";
		 }
                }

	        $table_list .= "Log: ".$tables[$i]." ".$2."\n";
                last;
	       }
             if($i == $#tables){ #table doesn't exist
              $dbh->do($sql);
	      $table_list .= $sql."\n";
	     }
	   }
	 }
         elsif($sql =~ /^ALTER TABLE (.*) DROP INDEX (.*);/i){
               $sth = $self->run_sql("SHOW KEYS FROM $1");
               my $bool = 0;
               while(my $temp = $sth->fetchrow_hashref()){
                   if(lc($temp->{'Key_name'}) eq lc($2)){
                      $bool= 1;
                      last;
	           }
               }
               if ($bool){
                 $table_list .= $sql."\n";
                 $dbh->do($sql);
	       }
	 }
         elsif(($sql =~ /^INSERT/i)or($sql =~ /^REPLACE/i)){
           $sql =~ s/^INSERT/REPLACE/i;
           $sql =~ m/INTO (\w+)/i;
           my $table = $1;
           if(($table eq 'perlDesk_settings')and($sql !~ /^ALTER/i)){
              if($sql =~ m/\(value, setting\) VALUES \('(.*)', 'db_version'\);$/i){
                $db_vers = $1;
                $table_list .= $sql."\n";
                $self->run_sql($sql);
              }
              else{
                $sql =~ m/\(value, setting\) VALUES \('(.*)', '(.*)'\);$/i;
                my ($value, $setting) = ($1, $2);
                my $sth = $self->run_sql("SELECT * FROM perlDesk_settings WHERE setting=".$dbh->quote($setting));
                unless($sth->rows){
                 $table_list .= $sql."\n";
                 $self->run_sql($sql);
		}
	      }
	   }
           else{
	     $table_list .= $sql."\n";
             my $rt = $dbh->prepare($sql);
             $rt->execute;
           }
	 } 
	 else{
             $table_list .= $sql."\n";
             my $rt = $dbh->prepare($sql);
             $rt->execute;
         }
       }




       $self->run_sql("UNLOCK TABLES");
       return $db_vers;
      }

1;

__END__


=head1 NAME

MySQL::Backup - Perl extension for making backups of mysql DBs.

=head1 SYNOPSIS

  use MySQL::Backup;
  my $mb = new MySQL::Backup('database','127.0.0.1','user','password',{'USE_REPLACE' => 1, 'SHOW_TABLE_NAMES' => 1});
  print $mb->create_structure();
  print $mb->data_backup();

=head1 DESCRIPTION

C<MySQL::Backup> should be useful for people, who needed in backuping mysql DBs by perl script
and doesn't want to use mysqldump or doesn't able to do this.

=head2 Main Methods

=over 4

=item *

C<$mb-E<gt>create_structure()>       - returns structure of current database

=item *

C<$mb-E<gt>data_backup()>  returns a full DATA backup of current database

=item *

C<$mb-E<gt>table_data($tablename)> - get all data from the table with $tablename

=item *

C<$mb-E<gt>table_desc($tablename)> - get a structure of inputed table

=item *

C<$mb-E<gt>new_from_DBH($dbh)>     - if you have already DBI connection, you can use this

=item *

C<$mb-E<gt>run_restore_script($filename)>       - Just DROPs all from current DB
and run all sql from the specified file (param is filepath to needed file)

=item *

C<$mb-E<gt>run_upgrade_script($filename)>       - opens file by set filepath, then analyzes differencies in proposed
and current structures and tries to fix differencies in DB.
For instance: you have 1 table in DB with 3 columns, and one string CREATE TABLE ... with same name in the file,
but CREATE TABLE describes 4 columns,.. after running this you should have 4 columns in table in DB.
Also, all INSERTs/REPLACEs from file will be executed(also, please be careful on execute stage all INSERTs will be changed to REPLACE)

=back

=head2 Params

Params could be set on creating, like shown in example, or/and set/changed as you should see below:

=over 4

=item *

C<$mb-E<gt>{'param'}-E<gt>{'USE_REPLACE'}>      - '1' means using REPLACE instead of INSERT

=item *

C<$mb-E<gt>{'param'}-E<gt>{'SHOW_TABLE_NAMES'}> - '1' means outputing a string in data_backup that marks
actions on which table should be done

=item *

C<$mb-E<gt>{'param'}-E<gt>{'tables'}>           - this param is a link to array with table names,..
can be used if you're needed to backup only few tables from DB (used by create_structure/data_backup)

=back

=head1 SEE ALSO

DBI, DBD::mysql and http://dev.mysql.com

=head1 AUTHOR

Dmitry Nikolayev <dmitry@cpan.org>, http://perl.dp.ua/resume.html

=head1 THANKS

Thanks for DotHost Hosting Provider: http://dothost.ru for their Tech. support.

Also, Thanks to Dree <dree@perl.it> for his comments and suggestions.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dmitry Nikolayev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

