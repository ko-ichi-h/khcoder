package mysql_outvar;
use strict;
use mysql_exec;
use gui_errormsg;

use mysql_outvar::a_var;

#----------------------#
#   変数リストを返す   #

sub get_list{
	my $h = mysql_exec->select("
		SELECT tani, name, id
		FROM outvar
		ORDER BY id
	",1)->hundle->fetchall_arrayref;
	
	return $h;
}

#----------------#
#   変数を削除   #

sub delete{
	my $class = shift;
	my %args  = @_;
	
	mysql_exec->do("
		DELETE FROM outvar
		WHERE
			name = \'$args{name}\'
	",1);
}


1;
