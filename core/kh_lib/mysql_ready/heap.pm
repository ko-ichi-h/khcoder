package mysql_ready::heap;
use mysql_ready;
use strict;

sub rowdata{
	return 0 unless $::config_obj->use_heap;
	my $class = shift;
	my $self = shift;
	mysql_exec->drop_table("rowdata_isam");
	mysql_exec->do("ALTER TABLE rowdata RENAME rowdata_isam",1);
	mysql_exec->do("create table rowdata
		(
			hyoso  varchar(".$self->length('hyoso').") not null,
			genkei varchar(".$self->length('genkei').") not null,
			hinshi varchar(".$self->length('hinshi').") not null,
			katuyo varchar(".$self->length('katuyo').") not null,
			id int primary key not null
		) TYPE=HEAP
	",1);
	mysql_exec->do("
		INSERT INTO rowdata (id, hyoso, genkei, hinshi, katuyo)
		SELECT id,hyoso,genkei,hinshi,katuyo
		FROM   rowdata_isam
	",1);
}

sub hyosobun{
	return 0 unless $::config_obj->use_heap;
	
	# rowdataテーブルを戻す
	mysql_exec->drop_table("rowdata");
	mysql_exec->do("ALTER TABLE rowdata_isam RENAME rowdata",1);

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
			add index index1 (h1_id, h2_id, h3_id, h4_id, h5_id),
			add index index2 (dan_id, bun_id, bun_idt),
			add index index3 (hyoso_id),
			add index index4 (bun_idt)
	",1);
}

sub clear_heap{
	return 0 unless $::config_obj->use_heap;

	mysql_exec->drop_table("hghi");
	mysql_exec->drop_table("hyosobun");
	mysql_exec->do("ALTER TABLE hyosobun_isam RENAME hyosobun",1);
}

1;