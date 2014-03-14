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
		my $t = Jcode->new($_)->h2z->tr('　',' ')->euc;
		my $line = $self->parse($t);
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
			type => 'msg',
			msg  => kh_msg->get('records_error'), # "ケース数が一致しません。\n読み込み処理を中断します。",
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
	my @exts = ();
	foreach my $i (@{$data[0]}){
		if ($name_check{$i}){
			push @exts, $i;
		}
	}

	# 不正な変数名が無いかチェック

	foreach my $i (@{$data[0]}){
		if ($i =~ /^見出し[1-5]$|^Heading[1-5]$/){
			gui_errormsg->open(
				icon => 'info',
				msg  => kh_msg->get('midashi_error'), # "「見出し1」〜「見出し5」までは、変数名として利用できません。\n外部変数の読み込みを中断します。",
				type => 'msg',
			);
			return 0;
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