package mysql_ready::heap;
use mysql_ready;
use strict;

sub rowdata{
	return 0 unless $::config_obj->use_heap;
	my $class = shift;
	my $self = shift;

	my $sizeof_char = 4;
	my $a_row = 0;
	if (mysql_exec->version_number > 4 ){    # MySQL 4.1 以上
		# data
		$a_row =
			  $self->length('hyoso')  * 3
			+ $self->length('genkei') * 3
			+ $self->length('hinshi') * 3
			+ $self->length('katuyo') * 3
			+ 4 + 1;
		if ($a_row % $sizeof_char) {
			$a_row += $sizeof_char - ( $a_row % $sizeof_char );
		}
		# index
		$a_row += $sizeof_char * 2;
		# margin
		$a_row += 3;
		print "a_row: $a_row\n";
	} else {                                 # MySQL 3.x 以下
		# data
		$a_row =
			  $self->length('hyoso')
			+ $self->length('genkei')
			+ $self->length('hinshi')
			+ $self->length('katuyo')
			+ 4 + 1;
		if ($a_row % $sizeof_char) {
			$a_row += $sizeof_char - ( $a_row % $sizeof_char );
		}
		# index
		$a_row += 4 + $sizeof_char * 2;
		# margin
		$a_row += 3;
	}

	my $rows = mysql_exec->select("
		select count(*) from rowdata
	")->hundle->fetch->[0];
	my $memory_n = int($a_row * $rows / 1024 /1024) + 1;
	my $max = mysql_exec->select("
		SHOW VARIABLES like \"max_heap_table_size\"
	")->hundle->fetch->[1];
	$max = int($max / 1024 /1024);
	print "\tThe HEAP table will eat approx. $memory_n"."MB; We have $max"."MB max.\n";
	
	if ($memory_n > $max){
		print "\tWe are going to use MyISAM instead of HEAP...\n";
		$self->{use_heap_act} = 0;
		return $self;
	}
	$self->{use_heap_act} = 1;

	mysql_exec->drop_table("rowdata_isam");
	mysql_exec->do("ALTER TABLE rowdata RENAME rowdata_isam",1);
	mysql_exec->do("create table rowdata
		(
			id int primary key not null,
			hyoso  varchar(".$self->length('hyoso').") binary not null,
			genkei varchar(".$self->length('genkei').") not null,
			hinshi varchar(".$self->length('hinshi').") not null,
			katuyo varchar(".$self->length('katuyo').") not null
		) TYPE=HEAP
	",1);

	mysql_exec->do("
		INSERT INTO rowdata (id, hyoso, genkei, hinshi, katuyo)
		SELECT id,hyoso,genkei,hinshi,katuyo
		FROM   rowdata_isam
	",1);
	
	return $self;
}

sub rowdata_restore{
	return 0 unless $::config_obj->use_heap;
	return 0 unless mysql_exec->table_exists("rowdata_isam");
	
	mysql_exec->drop_table("rowdata");
	mysql_exec->do("ALTER TABLE rowdata_isam RENAME rowdata",1);
}

sub hyosobun{
	return 0 unless $::config_obj->use_heap;
	
	return 1; # 無効化…
	
	# hyosobunテーブルを読み込み
	mysql_exec->drop_table("hyosobun_isam");
	mysql_exec->do("ALTER TABLE hyosobun RENAME hyosobun_isam",1);
	mysql_exec->do("
		create table hyosobun (
			id int primary key not null,
			hyoso_id INT not null,
			h1_id INT not null,
			h2_id INT not null,
			h3_id INT not null,
			h4_id INT not null,
			h5_id INT not null,
			dan_id INT not null,
			bun_id INT not null,
			bun_idt INT not null
		) TYPE=HEAP
	",1);
	mysql_exec->do("
		INSERT INTO hyosobun (id,hyoso_id,h1_id,h2_id,h3_id,h4_id,h5_id,dan_id,bun_id,bun_idt)
		SELECT id,hyoso_id,h1_id,h2_id,h3_id,h4_id,h5_id,dan_id,bun_id,bun_idt
		FROM hyosobun_isam
	",1);
	mysql_exec->do("
		alter table hyosobun
			add index a1     (h1_id, h2_id, h3_id, h4_id, h5_id,dan_id),
			add index a2     (h1_id, h2_id, h3_id, h4_id, h5_id),
			add index a3     (h1_id, h2_id, h3_id, h4_id),
			add index a4     (h1_id, h2_id, h3_id),
			add index a5     (h1_id, h2_id),
			add index a6     (h1_id),
			add index index2 (dan_id, bun_id, bun_idt),
			add index index3 (hyoso_id),
			add index index4 (bun_idt)
			#add index index5 (bun_idt, bun_id, dan_id, h5_id, h4_id, h3_id, h2_id, h1_id)
	",1);
}

sub clear_heap{
	return 0 unless $::config_obj->use_heap;

	return 1; # 無効化…

	mysql_exec->drop_table("hyosobun");
	mysql_exec->do("ALTER TABLE hyosobun_isam RENAME hyosobun",1);
}

1;