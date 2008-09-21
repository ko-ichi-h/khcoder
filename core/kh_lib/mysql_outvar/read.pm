package mysql_outvar::read;
use strict;

use mysql_outvar::read::csv;
use mysql_outvar::read::tab;

sub new{
	my $class = shift;
	my %args  = @_;
	my $self = \%args;
	
	bless $self, "$class";
	return $self;
}

sub read{
	my $self = shift;
	
	# ファイルをメモリ上に読み込み
	my @data;
	open (CSVD,$self->{file}) or 
		gui_errormsg->open(
			type    => 'file',
			thefile => $self->{file},
		);
	while (<CSVD>){
		chomp;
		my $line = $self->parse($_);
		push @data, $line;
	}
	close (CSVD);
	
	&save(
		data     => \@data,
		tani     => $self->{tani},
		var_type => $self->{var_type},
	);
}

sub save{
	my %args = @_;
	my @data = @{$args{data}};

	# ケース数のチェック
	my $cases_in_file = @data; --$cases_in_file;
	my $cases = mysql_exec->select("SELECT COUNT(*) from $args{tani}",1)
		->hundle->fetch->[0];
	unless ($cases == $cases_in_file){
		gui_errormsg->open(
			type   => 'msg',
			msg    => Jcode->new("ケース数が一致しません。\n読み込み処理を中断します。")->sjis,
		);
		return 0;
	}
	
	# 同じ変数名が無いかチェック
	my %name_check;
	my $h = mysql_exec->select("
		SELECT name
		FROM outvar
		ORDER BY id
	",1)->hundle;
	while (my $i = $h->fetch){
			$name_check{$i->[0]} = 1;
	}
	foreach my $i (@{$data[0]}){
		if ($name_check{$i}){
			gui_errormsg->open(
				type   => 'msg',
				msg    => Jcode->new("同じ名前の変数が既に読み込まれています。\n読み込み処理を中断します。")->sjis,
			);
			return 0;
		}
	}

	# 保存用テーブル名の決定
	my $n = 0;
	while (1){
		my $table = 'outvar'."$n";
		if ( mysql_exec->table_exists($table) ){
			++$n;
		} else {
			last;
		}
	}
	my $table = 'outvar'."$n";
	
	# DBにヘッダを格納
	my $cn = 0;
	my $cols = '';
	my $cols2 = '';
	foreach my $i (@{$data[0]}){
		my $col = 'col'."$cn"; ++$cn;
		mysql_exec->do("
			INSERT INTO outvar (name, tab, col, tani)
			VALUES (\'$i\', \'$table\', \'$col\', \'$args{tani}\')
		",1);
		
		if ($args{var_type} eq 'INT') {
			$cols .= "\t\t\t$col INT,\n";
		} else {
			$cols .= "\t\t\t$col varchar(255),\n";
		}
		$cols2 .= "$col,";
	}
	chop $cols2;
	
	# DBにデータを格納
	mysql_exec->do("create table $table
		(
			$cols
			id int auto_increment primary key not null
		)
	",1);
	shift @data;
	$n = 0;
	foreach my $i (@data){
		my $v = '';
		foreach my $h (@{$i}){
			if ($v =~ /^[0-9]+$/o){
				$v .= "$h,";
			} else {
				$h =~ s/\\/\\\\/g;
				$h =~ s/'/\\'/g;
				$v .= "\'$h\',";
			}
		}
		chop $v;
		mysql_exec->do("
			INSERT INTO $table ($cols2)
			VALUES ($v)
		",1);
	}
	
	return 1;
}


1;