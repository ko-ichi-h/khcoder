package mysql_outvar::read;
use strict;
use utf8;

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
	
	# detect character code
	my $icode = $self->{icode};
	unless ( $icode ) {
		if ( $::project_obj->morpho_analyzer_lang eq 'jp') {
			$icode = kh_jchar->check_code2($self->{file});
		} else {
			$icode = kh_jchar->check_code_en($self->{file});
		}
	}
	
	# open the file (1)
	my @data;
	use File::BOM;
	File::BOM::open_bom (my $fh, $self->{file}, ":encoding($icode)" );
	use Text::CSV_XS;
	my $csv = $self->parser;
	
	# read the first line to check names of variables
	my $row = $csv->getline($fh);
	$row = $self->check_names($row);
	return 0 unless $row;
	
	# count rows and check if it matches with case number
	unless ( $self->{skip_checks} ){
		my $nrow = 0;
		while ( my $tmp = $csv->getline($fh) ){
			++$nrow;
		}
		my $cases = mysql_exec->select("SELECT COUNT(*) from $self->{tani}",1)
			->hundle->fetch->[0];
		unless ($cases == $nrow){
			gui_errormsg->open(
				type => 'msg',
				msg  => kh_msg->get('records_error')."\n$cases, $nrow", # "ケース数が一致しません。\n読み込み処理を中断します。",
			);
			return 0;
		}
	}
	close $fh;
	undef $fh;
	
	# prepare DB
	my ($cols2, $table) = $self->prepare_db($row);
	
	# prepare ID numbers
	my @ids;
	if ( (mysql_exec->table_exists($self->{tani})) &! ($self->{skip_checks}) ){
		my $h_id = mysql_exec->select("
			select id from $self->{tani} order by id
		",1)->hundle;
		while (my $i = $h_id->fetch) {
			push @ids, $i->[0];
		}
	}
	
	File::BOM::open_bom ($fh, $self->{file}, ":encoding($icode)" );
	$csv->getline($fh);
	
	# Insert variable data
	my $n = 0;
	my $sql = "INSERT INTO $table ($cols2, id) VALUES ";
	while ( my $line = $csv->getline($fh) ){
		my $v = "";
		foreach my $i (@{$line}){
			if ($self->{var_type} eq 'INT' || $self->{var_type} eq 'DOUBLE'){
				if ($i eq '') {
					$i = "NULL";
				}
				$v .= "$i,";
			} else {
				if ($i eq '') {
					$i = '.';
				}
				$i =~ tr/　/ /;
				$v .= mysql_exec->quote($i).',';
			}
		}
		if (@ids) {
			$v .= "$ids[$n]";
		} else {
			my $idc = $n + 1;
			$v .= "$idc";
		}
		$sql .= "($v),";
		++$n;
		
		if ($n % 100 == 0) {
			chop $sql;
			$sql = Encode::encode('UCS-2LE', $sql, Encode::FB_DEFAULT);
			$sql = Encode::decode('UCS-2LE', $sql);
			$sql =~ s/\x{fffd}/_/g;
			mysql_exec->do($sql, 1);
			$sql = "INSERT INTO $table ($cols2, id) VALUES ";
		}
	}
	
	unless ($n % 100 == 0){
		chop $sql;
		$sql = Encode::encode('UCS-2LE', $sql, Encode::FB_DEFAULT);
		$sql = Encode::decode('UCS-2LE', $sql);
		$sql =~ s/\x{fffd}/_/g;
		mysql_exec->do($sql, 1);
	}
	
	mysql_exec->flush;
	return 1;
}

sub prepare_db{
	my $self = shift;
	my $names = shift;
	
	# Define a table name for variable data
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
	
	# Inseat variable names
	my $cn = 0;
	my $cols = '';
	my $cols2 = '';
	
	unless ( $self->{var_type} ){
		$self->{var_type} = "TEXT";
	}
	
	foreach my $i (@{$names}){
		my $col = 'col'."$cn"; ++$cn;
		mysql_exec->do("
			INSERT INTO outvar (name, tab, col, tani)
			VALUES (".mysql_exec->quote($i).", \'$table\', \'$col\', \'$self->{tani}\')
		",1);
		$cols .= "\t\t\t$col $self->{var_type},\n";
		$cols2 .= "$col,";
	}
	chop $cols2;
	
	# Create a table for variable data
	mysql_exec->do("create table $table
		(
			$cols
			id int primary key not null
		)
	",1);

	return ($cols2, $table);
}





sub check_names{
	my $self = shift;
	my $names = shift;
	
	# 不正な変数名が無いかチェック
	my %namechk = ();
	foreach my $i (@{$names}){
		# 「見出し1」等
		if ($i =~ /^見出し[1-5]$|^Heading[1-5]$/){
			$i .= '_m';
		}
		# 長すぎる場合
		if (length($i) > 250){
			$i = substr($i, 0, 250);
		}
		# スペース
		$i =~ tr/ /_/;
		# 重複
		if ($namechk{$i}){
			my $n = 1;
			while ( $namechk{$i.'_'.$n} ){
				++$n;
			}
			$i = $i.'_'.$n;
		}
		# BMP
		$i = Encode::encode('UCS-2LE', $i, Encode::FB_DEFAULT);
		$i = Encode::decode('UCS-2LE', $i);
		$i =~ s/\x{fffd}/_/g;
		
		$namechk{$i}++;
	}
	
	# 同じ変数名が無いかチェック（本当はこの部分はUI側へ回した方が良い…）
	my @exts = ();
	unless ( $self->{skip_checks} ){
		my %name_check;
		my $h = mysql_exec->select("
			SELECT name
			FROM outvar
			ORDER BY id
		",1)->hundle;
		while (my $i = $h->fetch){
				$name_check{$i->[0]} = 1;
		}
		
		foreach my $i (@{$names}){
			if ($name_check{$i}){
				push @exts, $i;
			}
		}
	}

	# 同じ変数名があった場合
	if (@exts){
		# 既存の変数を上書きして良いかどうか問い合わせ
		my $msg = '';
		foreach my $i (@exts){
			$msg .= ", " if length($msg);
			$msg .= gui_window->gui_jchar($i);
		}
		$msg  = kh_msg->get('overwrite_vars').$msg;

		my $ans = $::main_gui->mw->messageBox(
			-message => gui_window->gui_jchar($msg),
			-icon    => 'question',
			-type    => 'OKCancel',
			-title   => 'KH Coder'
		);
		unless ($ans =~ /ok/i){ return 0; }

		# 上書きする場合は既存の変数を削除
		foreach my $i (@exts){
			mysql_outvar->delete(
				name => $i,
			);
		}
	}
	
	return $names;
}

# This routine is a part of older codes used with "read_old" routine below.
# Still called from: kh_nbayes, a_var (gui_window::doc_cls_res_sav.pm)

sub save{
	my %args = @_;
	my @data = @{$args{data}};

	my @exts = ();
	unless ( $args{skip_checks} ){

		# ケース数のチェック
		my $cases_in_file = @data; --$cases_in_file;
		my $cases = mysql_exec->select("SELECT COUNT(*) from $args{tani}",1)
			->hundle->fetch->[0];
		unless ($cases == $cases_in_file){
			gui_errormsg->open(
				type => 'msg',
				msg  => kh_msg->get('records_error')."\n$cases, $cases_in_file", # "ケース数が一致しません。\n読み込み処理を中断します。",
			);
			return 0;
		}

		# 同じ変数名が無いかチェック（本当はこの部分はUI側へ回した方が良い…）
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
				push @exts, $i;
			}
		}
	}

	# 不正な変数名が無いかチェック
	my %namechk = ();
	foreach my $i (@{$data[0]}){
		# 「見出し1」等
		if ($i =~ /^見出し[1-5]$|^Heading[1-5]$/){
			$i .= '_m';
		}
		# 長すぎる場合
		if (length($i) > 250){
			$i = substr($i, 0, 250);
			if ($i =~ /\x8F$/ or $i =~ tr/\x8E\xA1-\xFE// % 2) {
				chop $i;
			}
			if ($i =~ /\x8F$/ or $i =~ tr/\x8E\xA1-\xFE// % 2) {
				chop $i;
			}
			if ($i =~ /\x8F$/ or $i =~ tr/\x8E\xA1-\xFE// % 2) {
				chop $i;
			}
		}
		# スペース
		$i =~ tr/ /_/;
		# 重複
		if ($namechk{$i}){
			my $n = 1;
			while ( $namechk{$i.'_'.$n} ){
				++$n;
			}
			$i = $i.'_'.$n;
		}
		$namechk{$i}++;
	}
	
	# 同じ変数名があった場合
	if (@exts){
		# 既存の変数を上書きして良いかどうか問い合わせ
		my $msg = '';
		foreach my $i (@exts){
			$msg .= ", " if length($msg);
			$msg .= gui_window->gui_jchar($i);
		}
		$msg  = kh_msg->get('overwrite_vars').$msg;

		my $ans = $::main_gui->mw->messageBox(
			-message => gui_window->gui_jchar($msg),
			-icon    => 'question',
			-type    => 'OKCancel',
			-title   => 'KH Coder'
		);
		unless ($ans =~ /ok/i){ return 0; }

		# 上書きする場合は既存の変数を削除
		foreach my $i (@exts){
			mysql_outvar->delete(
				name => $i,
			);
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
			$cols .= "\t\t\t$col TEXT,\n";
		}
		$cols2 .= "$col,";
	}
	chop $cols2;
	
	# ID番号の取得
	my @ids;
	if ( mysql_exec->table_exists($args{tani}) ){
		my $h_id = mysql_exec->select("
			select id from $args{tani} order by id
		",1)->hundle;
		while (my $i = $h_id->fetch) {
			push @ids, $i->[0];
		}
	}
	
	# DBにデータを格納
	mysql_exec->do("create table $table
		(
			$cols
			id int primary key not null
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
		if (@ids) {
			$v .= "$ids[$n]";
		} else {
			$v .= "$n";
		}
		mysql_exec->do("
			INSERT INTO $table ($cols2, id)
			VALUES ($v)
		",1);
		++$n;
	}
	
	mysql_exec->flush;
	return 1;
}

1;

__END__


sub read_old{
	my $self = shift;
	
	# 文字コードをチェック
	my $icode;
	if ( $::project_obj->morpho_analyzer_lang eq 'jp') {
		$icode = kh_jchar->check_code2($self->{file});
	} else {
		$icode = kh_jchar->check_code_en($self->{file});
	}
	
	# ファイルをメモリ上に読み込み
	my @data;
	use File::BOM;
	File::BOM::open_bom ('CSVD',$self->{file},":encoding($icode)");

	while (<CSVD>){
		chomp;
		$_ =~ tr/　/ /;
		my $line = $self->parse($_);
		push @data, $line;
	}
	close (CSVD);

	gui_errormsg->open(
		type    => 'file',
		thefile => $self->{file},
	) unless @data;

	&save(
		data        => \@data,
		tani        => $self->{tani},
		var_type    => $self->{var_type},
		skip_checks => $self->{skip_checks},
	);
}