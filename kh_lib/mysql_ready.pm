package mysql_ready;
use strict;
use utf8;
use Jcode;
use Benchmark;

use kh_project;
use kh_jchar;
use kh_dictio;
use kh_mailif;
use mysql_exec;
use mysql_ready::check;
use mysql_ready::doclength;
use mysql_ready::heap;
use mysql_ready::df;
use mysql_ready::dump;
use mysql_ready::fc;

my $rows_per_once = 30000;    # MySQLからPerlに一度に読み込む行数
my $data_per_1ins = 200;      # 一度にINSERTする値の数

sub first{
	my $class = shift;
	my $reload = shift;
	my $self;
	$self->{temp} = 'temp';
	bless $self, $class;

	$::config_obj->in_preprocessing(1);

	# Reload Excel/CSV
	if ($reload) {
		&reload_source;
		
		my $source = $::project_obj->status_source_file;
		
		if ( $::project_obj->status_from_table ){
			&reload_from_spreadsheet;
		} elsif (
			   $source =~ /(.+)\.docx$/i
			|| $source =~ /(.+)\.doc$/i
			|| $source =~ /(.+)\.rtf$/i
			|| $source =~ /(.+)\.odt$/i
		) {
			&reload_from_docx;
		}
	}
	
	if ($::config_obj->use_heap) {
		# $self->{type_heap} = ' TYPE=HEAP ';
		$self->{type_heap} = '';        # 安全第一 / heapではなくmyisamで
	} else {
		$self->{type_heap} = '';
	}

	my $ta0 = new Benchmark;
	$::project_obj->read_hinshi_setting;
	kh_dictio->readin->mark;
	kh_morpho->run or return 0;
		my $ta1 = new Benchmark;
		print "Morpho1\t",timestr(timediff($ta1,$ta0)),"\n";
		my $t0 = new Benchmark;
	$self->readin;                 # rowdata
		my $t1 = new Benchmark;
		print "Read\t",timestr(timediff($t1,$t0)),"\n";
	$self->reform;                 # hinshi, genkei, katuyo, hyoso, khhinshi
		my $t15 = new Benchmark;
		print "Format\t",timestr(timediff($t15,$t1)),"\n";
	kh_dictio->readin->save;
	$self->hyosobun;
	$self->tag_fix;                # hyoso, genkei
	kh_dictio->readin->save;
		my $t2 = new Benchmark;
		print "Strat1\t",timestr(timediff($t2,$t15)),"\n";
	$self->tanis;
		my $t4 = new Benchmark;
		print "Strat2\t",timestr(timediff($t4,$t2)),"\n";
	$self->rowtxt;
		my $t3 = new Benchmark;
		print "RawTXT\t",timestr(timediff($t3,$t4)),"\n";
	mysql_ready::df->calc($self);
		my $t5 = new Benchmark;
		print "df\t",timestr(timediff($t5,$t3)),"\n";
	mysql_ready::fc->calc_by_db;
		my $t6 = new Benchmark;
		print "fc\t",timestr(timediff($t6,$t5)),"\n";
	mysql_ready::check->do;
		my $t7 = new Benchmark;
		print "Check\t",timestr(timediff($t7,$t6)),"\n";

	$self->fix_katuyo;
		my $t8 = new Benchmark;
		print "fix_morpho\t",timestr(timediff($t8,$t7)),"\n";

	$self->fix_michigo;
		my $t9 = new Benchmark;
		print "fix_unknown\t",timestr(timediff($t9,$t8)),"\n";

	&zero_length_headings;
		my $t10 = new Benchmark;
		print "fix_headings\t",timestr(timediff($t10,$t9)),"\n";

	&make_cache;
		my $t11 = new Benchmark;
		print "make_cache\t",timestr(timediff($t11,$t10)),"\n";

	my $t12;
	if ( $::config_obj->unify_words_with_same_lemma ){
	&unify_words;
		$t12 = new Benchmark;
		print "unify_words\t",timestr(timediff($t12,$t11)),"\n";
	} else {
		$t12 = new Benchmark;
	}

	# データベース内の一時テーブルをクリア
	mysql_exec->clear_tmp_tables;
	mysql_ready::heap->clear_heap;
	mysql_exec->drop_table("hyosobun_t");
	#mysql_exec->drop_table("hghi");
		my $t13 = new Benchmark;
		print "clear_tmp\t",timestr(timediff($t13,$t12)),"\n";

	mysql_exec->flush;
	
	print "Morpho File: ".$::config_obj->uni_path( $::project_obj->file_MorphoOut )."\n";
	kh_mailif->success;
	$::config_obj->in_preprocessing(0);
	
	return 1;
}

sub unify_words{
	# Words with the same basic form are regarded as identical even if POS is different
	
	# list up existing units
	my @avail = ();
	foreach my $tani ('bun','dan','h1','h2','h3','h4','h5'){
		if ( mysql_exec->table_exists($tani) ){
			push @avail, $tani;
		}
	}
	
	my $h = mysql_exec->select("
		select genkei.name, sum(num)
		from genkei, hselection
		where
			genkei.khhinshi_id = hselection.khhinshi_id
			AND genkei.nouse = 0
			AND hselection.ifuse = 1
		group by genkei.name having count(genkei.name) > 1
		order by sum(num) DESC
	",1)->hundle;
	
	my $config;
	while (my $i = $h->fetch) {
		$config->{$i->[0]} = [$i->[0]];
	}
	
	# get required info
	my ($hyoso, $genkei);
	foreach my $i (keys %{$config}){

		# parent
		my $quoted = mysql_exec->quote($i);
		my $hdl7 = mysql_exec->select("
			SELECT genkei.id, genkei.num
			FROM   genkei
			WHERE  genkei.name = $quoted
			ORDER BY num DESC
			LIMIT 1
		",1)->hundle->fetch;

		next unless $hdl7;

		$genkei->{$i}{id}  = $hdl7->[0];
		$genkei->{$i}{num} = $hdl7->[1];

		# hyoso of children
		my $sql = "
			SELECT hyoso.id
			FROM   hyoso, genkei, hselection
			WHERE
				hyoso.genkei_id = genkei.id
				AND genkei.khhinshi_id = hselection.khhinshi_id
				AND genkei.nouse = 0
				AND hselection.ifuse = 1
				AND 
		";
		my $sql_w;
		my $n = 0;
		foreach my $h (@{$config->{$i}}){
			$sql_w .= " OR " if $n;
			my $quoted1 = mysql_exec->quote($h);
			$sql_w .= "genkei.name = $quoted1";
			++$n;
		}
		$sql = $sql .= "( $sql_w )";
		$sql .= " AND NOT genkei_id = $genkei->{$i}{id}";
		
		my $hdl8 = mysql_exec->select($sql,1)->hundle;
		while (my $h = $hdl8->fetch){
			push @{$hyoso->{$i}}, $h->[0];
		}

		# freq of children
		my $hdl9 = mysql_exec->select("
			SELECT sum(genkei.num)
			FROM   genkei, hselection
			WHERE
				genkei.khhinshi_id = hselection.khhinshi_id
				AND hselection.ifuse = 1
				AND ( $sql_w )
				AND NOT genkei.id = $genkei->{$i}{id}
		",1)->hundle->fetch;
		if ($hdl9){
			$genkei->{$i}{add} = $hdl9->[0];
		} else {
			$genkei->{$i}{add} = 0;
		}
	}

	# exec
	foreach my $i (keys %{$config}){
	
		# hyoso
		my $sql = '';
		$sql .= "
			UPDATE hyoso
			SET    genkei_id = $genkei->{$i}{id}
			WHERE 
		";
		my $n = 0;
		foreach my $h (@{$hyoso->{$i}}){
			$sql .= " OR " if $n;
			$sql .= "id = $h";
			++$n;
		}
		next unless $n;
		mysql_exec->do($sql,1);

		# genkei 1
		$sql = '';
		$sql .= "DELETE FROM genkei\nWHERE ";
		my $nn = 0;
		foreach my $h (@{$config->{$i}}){
			my $quoted2 = mysql_exec->quote($h);
			$sql .= " OR " if $nn;
			$sql .= "( name = $quoted2 AND NOT id = $genkei->{$i}{id} )";
			++$nn;
		}
		mysql_exec->do($sql,1);

		# genkei 2
		my $new_num = $genkei->{$i}{num} + $genkei->{$i}{add};
		$sql = '';
		$sql .= "
			UPDATE genkei
			SET    num = $new_num
			WHERE  id = $genkei->{$i}{id}
		";
		mysql_exec->do($sql,1);

		# df
		foreach my $u (@avail){
			my $df = 0;
			if ($u eq 'bun'){
				$df = mysql_exec->select("
					SELECT COUNT(DISTINCT bun_idt)
					FROM hyosobun, hyoso
					WHERE
						hyosobun.bun_idt
						AND hyosobun.hyoso_id = hyoso.id
						AND hyoso.genkei_id = $genkei->{$i}{id}
				",1)->hundle->fetch;
				$df = $df->[0] if $df;
			} else {
				$df = mysql_exec->select("
					SELECT COUNT(DISTINCT tid)
					FROM hyosobun, $u"."_hb, hyoso
					WHERE
						hyosobun.id = $u"."_hb.hyosobun_id
						AND hyosobun.hyoso_id = hyoso.id
						AND hyoso.genkei_id = $genkei->{$i}{id}
				",1)->hundle->fetch;
				$df = $df->[0] if $df;
			}
			
			mysql_exec->do("
				UPDATE df_$u
				SET f = $df
				WHERE genkei_id = $genkei->{$i}{id}
			",1);
		}
	}
	return 1;
}

sub reload_source{
	my $copied = $::config_obj->os_path( $::project_obj->status_copied_file );
	my $source = $::config_obj->os_path( $::project_obj->status_source_file );
	
	if (-e $copied) {
		unlink($copied)
			or gui_errormsg->open(
				type => 'file',
				thefile =>$copied,
			)
		;
	}
	
	unless ( length($copied) ){
		my $suf;
		if ($source =~ /(\.[a-zA-Z]+?)$/) {
			$suf = $1;
		}
		$copied   = $::project_obj->file_datadir.'_tgt'.$suf;
		$::project_obj->status_copied_file( $::config_obj->uni_path($copied) );
	}
	
	use File::Copy;
	copy($source, $copied)
		or gui_errormsg->open(
			type => 'file',
			thefile =>$copied,
		)
	;
	print "Specified target file is copied to: $copied\n";
	
	return 1;
}

sub reload_from_docx{
	my $copied = $::config_obj->os_path( $::project_obj->status_copied_file );
	my $target = $::config_obj->os_path( $::project_obj->file_target );
	my $temp   = $::project_obj->file_TempTXT;
	
	use kh_docx;
	my $c = kh_docx->new( $copied );
	$c->{converted} = $temp;
	$c->conv;
	
	unless (-e $temp){
		warn("Failed to reload data from ".$::project_obj->status_copied_file."\n");
		return 0;
	}
	
	unlink $target;
	rename($temp, $target) or die;
	print "Converted to: $target\n";
	
	unless ( $::project_obj->status_converted_file ){
		$::project_obj->status_converted_file($target);
	}
	
	return 1;
}

sub reload_from_spreadsheet{
	# Identify the target column
	my $col_name = $::project_obj->status_selected_coln;
	my $copied   = $::config_obj->os_path( $::project_obj->status_copied_file );
	my $columns = kh_spreadsheet->new($copied)->columns();
	my $col = 0;
	my $hit = 0;
	foreach my $i (@{$columns}){
		if ($i eq $col_name){
			$hit = 1;
			last;
		}
		++$col;
	}
	unless ($hit){
		die(
			"Cannot reload data from the Excel/CSV file: cannot identify the target column.\n"
			."Please create a new project with the Excel/CSV file"
		);
	}
	
	# Create text files from Excel/CSV
	my $target   = $::config_obj->os_path( $::project_obj->file_target );
	my $var      = $::config_obj->os_path( $::project_obj->status_var_file );

	my $temp_t = $::project_obj->file_TempTXT;
	my $temp_v = $::project_obj->file_TempTXT;
	unlink($temp_t);
	unlink($temp_v);

	my $sheet_obj = kh_spreadsheet->new($copied);
	$sheet_obj->save_files(
		filet    => $temp_t,
		filev    => $temp_v,
		selected => $col,
		lang     => $::project_obj->morpho_analyzer_lang,
	);
	unless ( -e $temp_t ) {
		return 0;
	}
	
	unlink($target);
	unlink($var);
	rename($temp_t, $target) or die;
	rename($temp_v, $var) if -e $temp_v;
	print "Converted to: $target\n";
	
	unless ( $::project_obj->status_converted_file ){
		$::project_obj->status_converted_file($target);
	}

	# Drop duplicated variable
	use File::BOM;
	File::BOM::open_bom (my $fh, $var, ":encoding(utf-8)" );
	use Text::CSV_XS;
	my $tsv = Text::CSV_XS->new({
		binary     => 1,
		auto_diag  => 2,
		sep_char   => "\t",
		allow_loose_quotes => 1
	});
	my $names = $tsv->getline($fh);
	close $fh;
	foreach my $i (@{$names}){
		mysql_outvar->delete(
			name => $i,
		);
	}
	
	# Load variables
	mysql_outvar::read::tab->new(
		file        => $var,
		tani        => 'h5',
		skip_checks => 1,
	)->read if -e $var;

	return 1;
}

sub make_cache{
	
	# Light weight version of "hyosobun" for mysql_crossout.pm
	mysql_exec->do("
		DROP TABLE IF EXISTS hyosobun2
	",1);
	
	mysql_exec->do("
		CREATE TABLE hyosobun2(
			id INT primary key,
			hyoso_id INT
		)
	",1);
	
	mysql_exec->do("
		INSERT INTO hyosobun2 (id, hyoso_id)
		SELECT id, hyoso_id
		FROM hyosobun
	",1);
	
	mysql_exec->do("
		ALTER TABLE hyosobun2 ADD INDEX index1 (id, hyoso_id);
	",1);
	
	# Light weight version of "bun" for mysql_crossout.pm
	
	mysql_exec->do("
		DROP TABLE IF EXISTS bun_hb
	",1);
	
	mysql_exec->do("
		CREATE TABLE bun_hb(
			hyosobun_id INT primary key,
			tid         INT
		)
	",1);
	
	mysql_exec->do("
		INSERT INTO bun_hb (hyosobun_id, tid)
		SELECT hyosobun.id, bun.id
		FROM hyosobun, bun
		WHERE
			hyosobun.bun_id = bun.bun_id
			AND hyosobun.dan_id = bun.dan_id
			AND hyosobun.h5_id = bun.h5_id
			AND hyosobun.h4_id = bun.h4_id
			AND hyosobun.h3_id = bun.h3_id
			AND hyosobun.h2_id = bun.h2_id
			AND hyosobun.h1_id = bun.h1_id
		ORDER BY hyosobun.id
	",1);
	
}

# We will NOT count zero length headings as sentences
sub zero_length_headings{
	
	# make a backup
	mysql_exec->do("drop table if exists bun_bak",1);
	mysql_exec->do("CREATE TABLE bun_bak LIKE bun",1);
	mysql_exec->do("INSERT INTO bun_bak SELECT * FROM bun",1);
	
	# check length (is it necessary?)
	mysql_exec->do("drop table if exists bun_length_nouse;",1);
	mysql_exec->do("
		CREATE TABLE bun_length_nouse(
		  id int primary key not null,
		  len int
		)
	",1);
	mysql_exec->do("
		INSERT INTO bun_length_nouse (id, len)
		SELECT
			hyosobun.bun_idt,
			SUM( IF(nouse=0 and not khhinshi_id=99999, 1, 0) ) as len
		FROM hyosobun, hyoso, genkei
		WHERE   hyosobun.hyoso_id = hyoso.id
			AND hyoso.genkei_id = genkei.id
		GROUP BY hyosobun.bun_idt
		ORDER BY hyosobun.bun_idt
	",1);
	
	# delete from "bun" table
	mysql_exec->do("
		DELETE
		FROM bun
		USING bun, bun_length_nouse
		WHERE bun.id = bun_length_nouse.id
			AND bun_length_nouse.len = 0;
	",1);

	# Counts of document length will be broken here and there,
	# so I disabled this feature (count all heading sentences as 0)
	#if ($::project_obj->status_hb) {
	#	mysql_exec->do("
	#		DELETE
	#		FROM bun
	#		WHERE bun_id = 0 AND dan_id = 0
	#	",1);
	#}

	# add sequential number
	mysql_exec->do("drop table if exists bun_tmp;",1);
	mysql_exec->do("
		CREATE TABLE bun_tmp(
		  id int primary key not null,
		  bun_id int not null,
		  dan_id int not null,
		  h5_id  int not null,
		  h4_id  int not null,
		  h3_id  int not null,
		  h2_id  int not null,
		  h1_id  int not null,
		  seq int auto_increment not null UNIQUE
		)
	",1);
	mysql_exec->do("
		INSERT INTO bun_tmp (id, bun_id, dan_id, h5_id, h4_id, h3_id, h2_id, h1_id)
		SELECT id, bun_id, dan_id, h5_id, h4_id, h3_id, h2_id, h1_id
		FROM bun
		ORDER BY id
	",1);
	mysql_exec->do("alter table bun_tmp CHANGE COLUMN seq seq int not null",1);
	mysql_exec->do("drop table if exists bun",1);
	mysql_exec->do("RENAME TABLE bun_tmp TO bun",1);

	mysql_exec->do("ALTER TABLE bun ADD INDEX index1 (bun_id)",1);
	mysql_exec->do("ALTER TABLE bun ADD INDEX index2 (dan_id)",1);
	mysql_exec->do("ALTER TABLE bun ADD INDEX index3 (h5_id)",1);
	mysql_exec->do("ALTER TABLE bun ADD INDEX index4 (h4_id)",1);
	mysql_exec->do("ALTER TABLE bun ADD INDEX index5 (h3_id)",1);
	mysql_exec->do("ALTER TABLE bun ADD INDEX index6 (h2_id)",1);
	mysql_exec->do("ALTER TABLE bun ADD INDEX index7 (h1_id)",1);
	mysql_exec->do("
		ALTER TABLE bun ADD INDEX index8 (
			bun_id,dan_id,h5_id,h4_id,h3_id,h2_id,h1_id
		)
	",1);
	mysql_exec->do("ALTER TABLE bun ADD INDEX index9 (id,seq)",1);
	
}

sub fix_michigo{
	my $self = shift;
	
	# Japanese
	if ( $::project_obj->morpho_analyzer_lang eq 'jp' ){
		my $h = mysql_exec->select("
			SELECT genkei.id, genkei.name
			FROM   genkei, khhinshi
			WHERE
					genkei.khhinshi_id = khhinshi.id
				AND khhinshi.name = \"未知語\"
		",1)->hundle;
		
		my @gomi = ();
		
		while (my $i = $h->fetch){
			#print Jcode->new("$i->[1]: ")->sjis;
			if ( $i->[1] =~ /[a-z]/io ){
				#print "alpha\n";
				next;
			}
			if ( $i->[1] =~ /\p{Han}|\p{Hiragana}|\p{Katakana}/o){
				#print "zenkaku\n";
				next;
			}
			if ( $i->[1] =~ /[ａ-ｚ|Ａ-Ｚ]/o){
				#print "zenkaku-alpha\n";
				next;
			}
			#print "gomi\n";
			push @gomi, $i->[0];
		}
		
		my $sql = '';
		$sql .= "UPDATE genkei SET khhinshi_id = 9999 WHERE\n";
		
		my $n = 0;
		foreach my $i (@gomi){
			$sql .= "OR " if $n;
			$sql .= "( id = $i )\n";
			++$n;
		}
		
		#print "$sql\n\n";
		
		mysql_exec->do($sql, 1) if $n;
	}
	
	# Korean
	if ( $::project_obj->morpho_analyzer_lang eq 'kr' ){
		my $h = mysql_exec->select("
			SELECT genkei.id, genkei.name
			FROM   genkei, khhinshi
			WHERE
					genkei.khhinshi_id = khhinshi.id
				AND khhinshi.name = \"Unknown\"
		",1)->hundle;
		
		my @gomi = ();
		
		while (my $i = $h->fetch){
			# numbers
			if ( $i->[1] =~ /^\p{PosixDigit}+$/o ){
				push @gomi, $i->[0];
			}

			# symbols
			if ( $i->[1] =~ /^\p{PosixPunct}+$/o ){
				push @gomi, $i->[0];
			}
		}
		
		my $sql = '';
		$sql .= "UPDATE genkei SET khhinshi_id = 99999 WHERE\n";
		
		my $n = 0;
		foreach my $i (@gomi){
			$sql .= "OR " if $n;
			$sql .= "( id = $i )\n";
			++$n;
		}
		
		#print "$sql\n\n";
		
		mysql_exec->do($sql, 1) if $n;
	}
}


sub fix_katuyo{
	my $self = shift;
	mysql_exec->drop_table("katuyo_old");
	mysql_exec->do("ALTER TABLE katuyo RENAME katuyo_old",1);
	mysql_exec->do ("
		create table katuyo (
			id int auto_increment primary key not null,
			name varchar(".$self->length('katuyo').")
		)
	",1);
	my $sql = 'INSERT INTO katuyo (name) VALUES ';
	my $h = mysql_exec->select("select name from katuyo_old",1)->hundle;
	while (my $i = $h->fetch){
		chomp $i->[0];
		if ($i->[0] =~ /^(.*)\r$/){
			$i->[0] = $1;
		}
		my $t = mysql_exec->quote($i->[0]);
		$sql .= "($t),";
	}
	chop $sql;
	mysql_exec->do("$sql",1);
	mysql_exec->do("alter table katuyo add index index1 (id, name)",1);
}

#----------------------#
#   データの読み込み   #

sub readin{
	my $self = shift;
	my $file = $::config_obj->os_path( $::project_obj->file_MorphoOut );
	my $icode = 'utf8mb4';

	# 入力データの文字コード
	if (
		   ( $::config_obj->c_or_j eq 'chasen' )
		#|| ( $::config_obj->c_or_j eq 'mecab'  )
	){
		if ($::config_obj->os eq 'win32') {
			$icode = 'cp932';
		} else {
			$icode = 'eucjpms'
		}
	}

	#SCREEN Plugin
	use screen_code::negationchecker;
	screen_code::negationchecker::check_use_plug();
	#SCREEN Plugin

	# データファイルのサイズを確認
	open (RCNT,$file) or
		gui_errormsg->open(
			type => 'file',
			file => $file
		);
	my $max_rows = 0;
	$max_rows += tr/\n/\n/ while read(RCNT, $_, 2 ** 16); # 行数カウント
	close (RCNT);
	$max_rows += 100;
	$self->{max_rows} = "MAX_ROWS = $max_rows";

	# ローデータの読み込み
	mysql_exec->drop_table("rowdata");
	mysql_exec->do("create table rowdata
		(
			hyoso varchar(128) binary not null,
			yomi varchar(128) not null,
			genkei varchar(128) not null,
			hinshi varchar(128) not null,
			katuyogata varchar(128) not null,
			katuyo varchar(128) not null,
			id int auto_increment primary key not null
		) $self->{max_rows}
	",1);

	#my $thefile = $::config_obj->uni_path($file);
	#my $icode = Jcode->new($thefile)->icode;
	#$thefile = Jcode->new($thefile,$icode)->euc;
	#$thefile =~ tr/\\/\//;
	#$thefile = Jcode->new($thefile,'euc')->$icode;
	#print "$thefile\n";
	
	my $thefile = "'$file'";
	mysql_exec->do("LOAD DATA LOCAL INFILE $thefile INTO TABLE rowdata CHARACTER SET $icode",1);

	# 新しいバージョンの茶筌に対応するためのFix
	mysql_exec->drop_table("rowdata_org");
	mysql_exec->do("ALTER TABLE rowdata RENAME rowdata_org",1);
	mysql_exec->do("create table rowdata
		(
			hyoso varchar(128) binary not null,
			yomi varchar(128) not null,
			genkei varchar(128) not null,
			hinshi varchar(128) not null,
			katuyogata varchar(128) not null,
			katuyo varchar(128) not null,
			id int primary key not null
		) $self->{max_rows}
	",1);
	mysql_exec->do("	
		INSERT INTO rowdata (hyoso, yomi, genkei, hinshi, katuyogata, katuyo, id)
		SELECT hyoso, yomi, if( ((length(genkei) = 0) and not (hyoso = 'EOS') and not (hyoso = 'EOS\r')), hyoso, genkei), hinshi, katuyogata, katuyo, id
		FROM rowdata_org
		ORDER BY id
	",1);
	mysql_exec->drop_table("rowdata_org");

	# フィールド長の取得
	my $morpho_length_error_flag = 0;

	my $t = mysql_exec->select("
		SELECT
			MAX( CHAR_LENGTH(hyoso) )  AS hyoso,
			MAX( CHAR_LENGTH(genkei) ) AS genkei,
			MAX( CHAR_LENGTH(hinshi) ) AS hinshi,
			MAX( CHAR_LENGTH(katuyo) ) AS katuyo
		FROM rowdata
	",1)->hundle;
	my $r = $t->fetchrow_hashref;
	$t->finish;
	foreach my $key (keys %{$r}){
		$self->length($key,$r->{$key});
		$morpho_length_error_flag = 1 if $r->{$key} >= 128;
	}
	mysql_ready::dump->word_length if $morpho_length_error_flag;

	mysql_ready::heap->rowdata($self);
	
	# 強調文字列保存用のテーブルを準備
	unless ( mysql_exec->table_exists('d_force') ){
		mysql_exec->do("create table d_force
			(
				id int auto_increment primary key not null,
				name varchar(128) not null,
				type int not null
			)
		",1);
	}

}

#----------------#
#   データ整形   #

sub reform{
	my $self = shift;

	my $report_time = 0;
	my $pt1 = new Benchmark;

	# キャッシュ・テーブル作成
	mysql_exec->drop_table("hgh");
	my @len = (
		$self->length('hyoso'),
		$self->length('genkei'),
		$self->length('hinshi'),
		$self->length('katuyo')
	);
	mysql_exec->do("
		create table hgh (
			id int auto_increment primary key not null,
			num int not null,
			hyoso varchar($len[0]) binary not null,
			genkei varchar($len[1]) not null,
			hinshi varchar($len[2]) not null,
			katuyo varchar($len[3]) not null
		)
	", 1);
	mysql_exec->do("
		INSERT
		INTO hgh ( num, hyoso, genkei, hinshi, katuyo)
		SELECT COUNT(*), hyoso, genkei, hinshi, katuyo
			FROM rowdata
#			WHERE LENGTH(rowdata.genkei) > 1
			GROUP BY rowdata.katuyo, rowdata.hyoso, rowdata.genkei, rowdata.hinshi
	", 1);

	my $pt2 = new Benchmark;
	print "\tcache(hgh)\t",timestr(timediff($pt2,$pt1)),"\n" if $report_time;

	# 品詞テーブル作成
	my $len = $self->length('hinshi');
	mysql_exec->drop_table("hinshi");
	mysql_exec->do("
		create table hinshi (
			id int auto_increment primary key not null,
			name varchar($len) not null
		)
	",1);
		
	mysql_exec->do('
		INSERT
		INTO hinshi (name)
		SELECT (hinshi)
			FROM hgh
			WHERE (length(genkei) > 0) and (length(hinshi) > 0)
			GROUP BY hinshi
	',1);
	mysql_exec->do("alter table hinshi add index index1 (name)",1);

	my $pt3 = new Benchmark;
	print "\thinshi\t\t",timestr(timediff($pt3,$pt2)),"\n" if $report_time;

	# 原形テーブル作成
	$len = $self->length('genkei');                         # テーブル準備
	mysql_exec->drop_table("genkei");
	mysql_exec->do("
		create table genkei (
			id int auto_increment primary key not null,
			name varchar($len) not null,
			num int not null,
			hinshi_id int not null,
			khhinshi_id int not null,
			nouse int not null default 0
		)
	",1);

	my $rule;                                               # 分類規則準備
	if (mysql_exec->table_exists('hinshi_setting')){
		$rule = mysql_exec->select(
			 "SELECT khhinshi,condition1,condition2,khhinshi_id "
			."FROM hinshi_setting",
			1
		)->hundle->fetchall_arrayref;
	} else {
		my $dbhh = DBI->connect("dbi:CSV:", undef, undef, {
			f_dir      => "./config",
			f_encoding => "UTF8",
			csv_eol    => "\n",
		}) or die; 
		my $th = $dbhh->prepare("
			SELECT kh_hinshi,condition1,condition2,hinshi_id
			FROM hinshi_chasen
		") or die;
		$th->execute or die;
		$rule = $th->fetchall_arrayref;
	}

	my %stopwords = ();
	foreach my $i (@{$::config_obj->stopwords_current}){
		$i =~ tr/A-Z/a-z/;
		$stopwords{$i} = 1;
		#print "$i, ";
	}
	#print "\n";

                                                            # データ準備
	mysql_exec->drop_table("hgh2");
	mysql_exec->do("
		create table hgh2 (
			id INT auto_increment primary key not null,
			genkei varchar($len) not null,
			sum INT,
			h_id INT,
			h_name varchar(".$self->length('hinshi').")
		)
	",1);
	mysql_exec->do("
		INSERT INTO hgh2 (genkei, sum, h_id, h_name)
		SELECT hgh.genkei, SUM(num), hinshi.id, hinshi.name
		FROM hgh, hinshi
		WHERE hgh.hinshi=hinshi.name
		GROUP BY hgh.genkei, hgh.hinshi
	",1);

	my ($num, $con) = (0,'');
	my $id = 1;
	while (1){
		my $td = mysql_exec->select(
			mysql_ready->genkei_sql($id, $id + $rows_per_once),
			1
		)->hundle;
		unless ($td->rows > 0){
			last;
		}
		$id += $rows_per_once;
		
		while (my $d = $td->fetch){                             # 振り分け
			my $kh_hinshi = '9999';
			my $chk = $d->[0];
			#SCREEN Plugin
			$chk = &screen_code::negationchecker::mod_for_detecting_pos($chk);
			#SCREEN Plugin
			foreach my $i (@{$rule}){
				$i->[2] = '' unless defined($i->[2]);
				if ( index("$d->[3]","$i->[1]") == 0 ){        # 条件1
					if ($i->[2] eq 'ひらがな'){            # 条件2:ひらがな
						if ($chk =~ /^\p{Hiragana}+$/o){
							$kh_hinshi = $i->[3];
							last;
						}
					}
					elsif ($i->[2] eq '一文字'){           # 条件2:一文字
						if (length($chk) == 1){
							$kh_hinshi = $i->[3];
							last;
						}
					}
					elsif ($i->[2] eq 'HTML'){             # 条件2:HTML
						if ( 
							   ($chk =~ /<h[1-5]>/io)
							|| ($chk =~ /<\/h[1-5]>/io) 
						){
							$kh_hinshi = $i->[3];
							last;
						}
					}
					elsif($i->[2] eq '否定'){             # 条件2:否定
						if (
							   ($chk eq 'ない')
							|| ($chk eq 'まい')
							|| ($chk eq 'ぬ')
							|| ($chk eq 'ん')
						){
							$kh_hinshi = $i->[3];
							last;
						}
					}
					else {                                 # 条件2無しの場合
						$kh_hinshi = $i->[3];
						last;
					}
				}
				elsif ( $i->[1] eq '*' ) {
					$kh_hinshi = $i->[3];
					last;
				}
			}
			
			$chk =~ tr/A-Z/a-z/;
			if ($stopwords{$chk}){
				$kh_hinshi = '9999';
			}
			
			$d->[0] =~ s/'/\\'/go;
			$con .= "('$d->[0]',$d->[1],$d->[2],$kh_hinshi),";
			++$num;
			if ($num == $data_per_1ins){               # DBに投入
				chop $con;
				mysql_exec->do("
					INSERT
					INTO genkei (name, num, hinshi_id, khhinshi_id)
					VALUES $con
				",1);
				$con = '';
				$num = 0;
			}
		}
		$td->finish;
	}
	
	if ($con){                                         # 残りをDBに投入
		chop $con;
		mysql_exec->do("
			INSERT
			INTO genkei (name, num, hinshi_id, khhinshi_id)
			VALUES $con
		",1);
	}
	mysql_exec->do('alter table genkei add index index1(name,khhinshi_id,hinshi_id)',1);
	mysql_exec->do('alter table genkei add index index2(khhinshi_id)',1);


	# 原形テーブルの仕上げ(1)
	mysql_exec->drop_table("genkei_fin");
	mysql_exec->do("
		create table genkei_fin (
			id int auto_increment primary key not null,
			name varchar($len) not null,
			num int not null,
			khhinshi_id int not null,
			nouse int not null default 0
		)
	",1);

	mysql_exec->do("
		INSERT INTO genkei_fin (name, num, khhinshi_id)
		SELECT name, sum(num), khhinshi_id
		FROM   genkei
		GROUP BY name, khhinshi_id
	",1);

	mysql_exec->do('alter table genkei_fin add index index1(name,khhinshi_id)',1);
	mysql_exec->do('alter table genkei_fin add index index2(khhinshi_id)',1);
	mysql_exec->do('alter table genkei_fin add unique index index3(khhinshi_id, nouse, num, id)',1);

	my $pt4 = new Benchmark;
	print "\tgenkei\t\t",timestr(timediff($pt4,$pt3)),"\n" if $report_time;

	# KH_品詞テーブルの作成
	mysql_exec->drop_table("khhinshi");
	mysql_exec->do("
		create table khhinshi (
			id int primary key not null,
			name varchar(20) not null
		)
	",1);

	$con = ''; my %temp;
	foreach my $i (@{$rule}){
		unless ($temp{$i->[0]}){
			$con .= "($i->[3],'$i->[0]'),";
			$temp{$i->[0]} = 1;
		}
	}
	
	# morpho_analyzer
	my $other_hinshi = 'OTHER';
	if (
		   $::config_obj->c_or_j eq 'chasen'
		|| $::config_obj->c_or_j eq 'mecab'
	){
		$other_hinshi = 'その他';
	}
	
	$con .= "(9999,'$other_hinshi')";

	mysql_exec->do("
		INSERT
		INTO khhinshi (id,name)
		VALUES $con
	",1);
	mysql_exec->do('alter table khhinshi add index index1(name,id)',1);

	my $pt5 = new Benchmark;
	print "\tkh-hinshi\t",timestr(timediff($pt5,$pt4)),"\n" if $report_time;

	# キャッシュテーブル(2)作成
	mysql_exec->drop_table("hghi");
	mysql_exec->do("
		create table hghi (
			hyoso varchar($len[0]) binary not null,
			genkei varchar($len[1]) not null,
			hinshi varchar($len[2]) not null,
			katuyo varchar($len[3]) not null,
			hyoso_id int not null primary key,
			genkei_id int not null,
			hinshi_id int not null,
			num       int not null
		) $self->{type_heap}
	",1);
	
	# MySQL 5.6のMyISAMの挙動に合わせるため変更した (2018 4/18)
	mysql_exec->drop_table("hg_tmp");
	mysql_exec->do("
		create table hg_tmp(
			genkei_name varchar($len[1]) not null,
			hinshi_name varchar($len[2]) not null,
			genkei_id int not null,
			hinshi_id int not null
		);
	", 1);
	mysql_exec->do("
		INSERT
		INTO hg_tmp (genkei_name, hinshi_name, genkei_id, hinshi_id)
		SELECT genkei.name, hinshi.name, genkei.id, hinshi.id
		FROM genkei, hinshi
		WHERE
			genkei.hinshi_id = hinshi.id;
	", 1);
	if ($len[0] + $len[1] < 250){
		mysql_exec->do(
			"alter table hg_tmp add index index1 (genkei_name, hinshi_name)",
			1
		);
	}
	mysql_exec->do("
		INSERT
		INTO hghi (hyoso, genkei, hinshi, katuyo, hyoso_id, genkei_id, hinshi_id, num)
		SELECT hgh.hyoso, hgh.genkei, hgh.hinshi, hgh.katuyo, hgh.id, hg_tmp.genkei_id, hg_tmp.hinshi_id, hgh.num
		FROM hgh, hg_tmp
		WHERE
			hgh.genkei = hg_tmp.genkei_name
			AND hgh.hinshi = hg_tmp.hinshi_name
	", 1);
	
	# MySQL 5.6でMyISAM利用の場合、以下のコードではなぜかINSERTされる行数が
	# 減ることが判明した。InnoDBでは問題ないのだが…。orz
	#mysql_exec->do('
	#	INSERT
	#	INTO hghi (hyoso, genkei, hinshi, katuyo, hyoso_id, genkei_id, hinshi_id, num)
	#	SELECT hgh.hyoso, hgh.genkei, hgh.hinshi, hgh.katuyo, hgh.id, genkei.id, hinshi.id, hgh.num
	#		FROM hgh, genkei, hinshi
	#		WHERE
	#			    hgh.genkei = genkei.name
	#			AND hgh.hinshi = hinshi.name
	#			AND genkei.hinshi_id = hinshi.id
	#',1);
	
	mysql_exec->drop_table("hgh");
	if ($len[0] + $len[1] + $len[2] <= 250){
		mysql_exec->do(
			"alter table hghi add index index1 (hyoso, genkei, hinshi)",
			1
		);
	} else {
		mysql_exec->do("alter table hghi add index index1 (hyoso)",1);
		mysql_exec->do("alter table hghi add index index2 (genkei)",1);
		mysql_exec->do("alter table hghi add index index3 (hinshi)",1);
		mysql_exec->do("alter table hghi add index index4 (katuyo)",1);
	}

	my $pt6 = new Benchmark;
	print "\tcache(hghi)\t",timestr(timediff($pt6,$pt5)),"\n" if $report_time;

	# 活用テーブル作成
	mysql_exec->drop_table("katuyo");
	mysql_exec->do ("
		create table katuyo (
			id int auto_increment primary key not null,
			name varchar($len[3])
		)
	",1);
	mysql_exec->do("
		INSERT INTO katuyo ( name )
		SELECT katuyo FROM hghi
		GROUP BY katuyo
	",1);
	mysql_exec->do("alter table katuyo add index index1 (id, name)",1);

	my $pt7 = new Benchmark;
	print "\tkatuyo\t\t",timestr(timediff($pt7,$pt6)),"\n" if $report_time;

	# 表層テーブル作成
	mysql_exec->drop_table("hyoso");
	mysql_exec->do("
		create table hyoso (
			id int not null primary key,
			name varchar($len[0]) not null,
			len int not null,
			katuyo_id int not null,
			hinshi_id int not null,
			genkei_id int not null,
			num int not null
		)
	",1);
	mysql_exec->do("
		INSERT
		INTO hyoso (id, name, len, genkei_id, num, katuyo_id, hinshi_id)
		SELECT hyoso_id, hyoso, CHAR_LENGTH(hyoso), genkei_fin.id, hghi.num, katuyo.id, genkei.hinshi_id
			FROM hghi, katuyo, genkei, genkei_fin
			WHERE
				    hghi.katuyo = katuyo.name
				AND hghi.genkei_id = genkei.id
				AND genkei.name = genkei_fin.name
				AND genkei.khhinshi_id = genkei_fin.khhinshi_id
	",1);
	mysql_exec->do("alter table hyoso add index index1 (name, genkei_id)",1);
	mysql_exec->do("alter table hyoso add index index2 (genkei_id)",1);

	my $pt8 = new Benchmark;
	print "\thyoso\t\t",timestr(timediff($pt8,$pt7)),"\n" if $report_time;

	mysql_ready::heap->rowdata_restore;
}

sub genkei_sql{
	my $self = shift;
	my $d1 = shift;
	my $d2 = shift;
	
	my $sql = "
		SELECT genkei, sum, h_id, h_name
		FROM hgh2
		WHERE
			    id >= $d1
			AND id  < $d2
	";
	return $sql;
}

#-------------------------#
#   表層-文テーブル作成   #

sub hyosobun{
	my $self = shift;
	
	# 各種準備
	my $t = mysql_exec->select("        # HTMLタグと句読点のhyoso.idを取得
		SELECT hyoso.name, hyoso.id
		FROM hyoso
		WHERE
			   (( name RLIKE '<[Hh][1-5]\>' ) AND ( len = 4 ))
			OR (( name RLIKE '</[Hh][1-5]>' ) AND ( len = 5 ))
			OR ( name = '。' )
	",1)->hundle;
	my ($IDs, $IDsR);
	while (my $d = $t->fetch){
		$IDs->{$d->[1]} = $d->[0];
		$IDsR->{$d->[0]} = $d->[1];
	}
	$t->finish;

	mysql_exec->drop_table("hyosobun");   # テーブル作成
	mysql_exec->do("
		create table hyosobun (
			id int auto_increment primary key not null,
			hyoso_id INT not null,
			h1_id INT not null,
			h2_id INT not null,
			h3_id INT not null,
			h4_id INT not null,
			h5_id INT not null,
			dan_id INT not null,
			bun_id INT not null,
			bun_idt INT not null
		) $self->{max_rows}
	",1);
	mysql_exec->drop_table("hyosobun_t");# 単位用キャッシュ・テーブル作成
	mysql_exec->do("
		create table hyosobun_t (
			h1_id INT not null,
			h2_id INT not null,
			h3_id INT not null,
			h4_id INT not null,
			h5_id INT not null,
			dan_id INT not null,
			bun_id INT not null,
			bun_idt INT not null,
			lc INT not null,
			lw INT not null
		) $self->{type_heap}
	",1);

	# 初期化
	my ($bun, $dan, $h5, $h4, $h3, $h2, $h1, $lastrow, $midashi, $bun2) = 
		(1,1,0,0,0,0,0,0,0,1);
	my ($temp, $c, $maru);
	my ($temp_tani, $last_tani, $c_t, $lw, $lc, $lt);
	my $id = 1;
	# 実行
	while (1){
		my $t = mysql_exec->select(
			$self->hyosobun_sql($id, $id + $rows_per_once),
			1
		)->hundle;
		unless ($t->rows > 0){
			last;
		}
		$id += $rows_per_once;

		while (my $d = $t->fetch){
			if ( ($d->[0] - $lastrow > 1) &! ($lastrow == 0) ){# 改行のチェック
				++$dan;
				$bun = 1;
				unless ($maru){
					++$bun2;
				}
			}
			$lastrow = $d->[0];
			if ( defined($IDs->{$d->[1]}) ){           # HTML開始タグのチェック
				if (
					   $IDs->{$d->[1]} eq '<h1>' 
					|| $IDs->{$d->[1]} eq '<H1>'
				){
					++$h1;
					($h2,$h3,$h4,$h5,$dan,$bun,$midashi)
						= (0,0,0,0,0,0,1);
				}
				elsif (
					   $IDs->{$d->[1]} eq '<h2>'
					|| $IDs->{$d->[1]} eq '<H2>'
				){
					++$h2;
					($h3,$h4,$h5,$dan,$bun,$midashi)
						= (0,0,0,0,0,1)
				}
				elsif (
					   $IDs->{$d->[1]} eq '<h3>'
					|| $IDs->{$d->[1]} eq '<H3>'
				){
					++$h3;
					($h4,$h5,$dan,$bun,$midashi)
						= (0,0,0,0,1)
				}
				elsif (
					   $IDs->{$d->[1]} eq '<h4>'
					|| $IDs->{$d->[1]} eq '<H4>'
				){
					++$h4;
					($h5,$dan,$bun,$midashi)=(0,0,0,1)
				}
				elsif (
					   $IDs->{$d->[1]} eq '<h5>'
					|| $IDs->{$d->[1]} eq '<H5>'
				){
					++$h5;
					($dan,$bun,$midashi)=(0,0,1)
				}
			} else {
				$IDs->{$d->[1]} = '';
			}

			                                          # DBに書き込み
			$temp .= "($bun2,$bun,$dan,$h5,$h4,$h3,$h2,$h1,$d->[1]),";
			unless (defined($last_tani) && $last_tani eq "$bun2,$bun,$dan,$h5,$h4,$h3,$h2,$h1"){
				if (defined($last_tani) && length($last_tani)){
					$temp_tani .= '('."$last_tani,$lc,$lw".'),';
				}
				$last_tani = "$bun2,$bun,$dan,$h5,$h4,$h3,$h2,$h1";
				$lc = 0;
				$lw = 0;
				$lt = 0;
				++$c_t;
			}
			
			++$c;
			if ($c == $data_per_1ins){
				#print "d";
				chop $temp;
				my_threads->exec("
					mysql_exec->do(\"
						INSERT INTO hyosobun
						(bun_idt, bun_id, dan_id, h5_id, h4_id, h3_id, h2_id, h1_id,hyoso_id)
						VALUES
							$temp
					\",1);
				");
				$temp = '';
				$c    = 0;
			}
			if ($c_t == $data_per_1ins){
				chop $temp_tani;
				my_threads->exec("
					mysql_exec->do(\"
						INSERT INTO hyosobun_t
						(bun_idt, bun_id, dan_id, h5_id, h4_id, h3_id, h2_id, h1_id, lc, lw)
						VALUES
							$temp_tani
					\",1);
				");
				$temp_tani = '';
				$c_t = 0;
			}

			if (
				   ($d->[2])
				and not ($IDs->{$d->[1]} =~ /<\/[Hh][1-5]>/o)
				and not ($IDs->{$d->[1]} =~ /<[Hh][1-5]>/o)
				and not ($d->[3])
			){
				$lc += $d->[2];
				++$lw;
			}
			++$lt;

			if ($IDs->{$d->[1]} eq '。'){              # 句読点のチェック
				unless ($midashi){
					++$bun; ++$bun2; $maru = 1;
				}
			} else {
				$maru = 0;
			}
			if ($IDs->{$d->[1]} =~ /<\/[Hh][1-5]>/o){  # HTML終了タグのチェック
					$midashi = 0;
			}
		}
	$t->finish;
	}

	# 残りをDBに投入
	if ($temp){
		chop $temp;
		my_threads->exec("
			mysql_exec->do(\"
				INSERT INTO hyosobun
				   (bun_idt, bun_id, dan_id, h5_id, h4_id, h3_id, h2_id, h1_id,hyoso_id)
					VALUES
						$temp
			\",1);
		");
	}
	if ( ($lc) || ($lw) || ($lt) ){
		$temp_tani .= '('."$last_tani,$lc,$lw".'),';
	}
	if ($temp_tani){
		chop $temp_tani;
		my_threads->exec("
			mysql_exec->do(\"
				INSERT INTO hyosobun_t
				(bun_idt, bun_id, dan_id, h5_id, h4_id, h3_id, h2_id, h1_id, lc, lw)
				VALUES
					$temp_tani
			\",1);
		");
	}

	my_threads->wait;

	# 不要な場合は「。」を削除 # morpho_analyzer
	unless (
		   $::project_obj->morpho_analyzer_lang eq 'jp'
		|| $::project_obj->morpho_analyzer_lang eq 'cn'
		|| (! $IDsR->{'。'} )
	){
		mysql_exec->do("
			DELETE FROM hyosobun
			WHERE hyoso_id = $IDsR->{'。'}
		",1);
		mysql_exec->do("
			DELETE FROM genkei
			WHERE name = '。'
		",1);
		mysql_exec->do("
			DELETE FROM genkei_fin
			WHERE name = '。'
		",1);
		mysql_exec->do("
			DELETE FROM hyoso
			WHERE name = '。'
		",1);
		
		mysql_exec->drop_table("hyosobun_n");
		mysql_exec->do("
			create table hyosobun_n (
				id int auto_increment primary key not null,
				hyoso_id INT not null,
				h1_id INT not null,
				h2_id INT not null,
				h3_id INT not null,
				h4_id INT not null,
				h5_id INT not null,
				dan_id INT not null,
				bun_id INT not null,
				bun_idt INT not null
			) $self->{max_rows}
		",1);
		
		mysql_exec->do("
			INSERT INTO hyosobun_n (hyoso_id, h1_id, h2_id, h3_id, h4_id, h5_id, dan_id, bun_id, bun_idt)
			SELECT hyoso_id, h1_id, h2_id, h3_id, h4_id, h5_id, dan_id, bun_id, bun_idt
			FROM hyosobun
			ORDER BY id
		",1);
		
		mysql_exec->drop_table("hyosobun");

		mysql_exec->do("
			RENAME TABLE hyosobun_n TO hyosobun
		",1);
	}

	# インデックスを貼る
	mysql_exec->do("
		alter table hyosobun
			add index index1 (h1_id, h2_id, h3_id, h4_id, h5_id, dan_id),
			add index index2 (bun_id, dan_id, bun_idt, hyoso_id),
			add index index3 (hyoso_id),
			add index index4 (bun_idt)
	",1);
	mysql_exec->do("
		alter table hyosobun_t
			add index a1     (h1_id, h2_id, h3_id, h4_id, h5_id,dan_id),
			add index a2     (h1_id, h2_id, h3_id, h4_id, h5_id),
			add index a3     (h1_id, h2_id, h3_id, h4_id),
			add index a4     (h1_id, h2_id, h3_id),
			add index a5     (h1_id, h2_id),
			add index a6     (h1_id),
			add index index2 (bun_id, dan_id, bun_idt),
			add index index4 (bun_idt)
	",1);

	# 原形テーブルの仕上げ(2)
	mysql_exec->drop_table("genkei");
	mysql_exec->do(" RENAME TABLE genkei_fin TO genkei",1);


	mysql_ready::heap->hyosobun;
}

sub hyosobun_sql{
	my $self = shift;
	my $d1   = shift;
	my $d2   = shift;

	my $sql ="
		SELECT rowdata.id, hghi.hyoso_id, hyoso.len, genkei.nouse
		FROM rowdata, hghi, genkei, hyoso
		WHERE
				    rowdata.hyoso  = hghi.hyoso
				AND rowdata.genkei = hghi.genkei
				AND rowdata.hinshi = hghi.hinshi
				AND rowdata.katuyo = hghi.katuyo
				AND hghi.hyoso_id  = hyoso.id
				AND hghi.genkei_id = genkei.id
				AND rowdata.id >= $d1
				AND rowdata.id <  $d2
		ORDER BY rowdata.id
	";

	#my $sql ="
	#	SELECT rowdata.id, hghi.hyoso_id,
	#	FROM rowdata, hghi
	#	WHERE
	#			    rowdata.hyoso  = hghi.hyoso
	#			AND rowdata.genkei = hghi.genkei
	#			AND rowdata.hinshi = hghi.hinshi
	#			AND rowdata.id >= $d1
	#			AND rowdata.id <  $d2
	#	ORDER BY rowdata.id
	#";
	return $sql;
}

#--------------------------------------#
#   タグ品詞の抽出語から<>を取り除く   #

sub tag_fix{
	my $self = shift;
	
	# 表層語テーブル
	my $h = mysql_exec->select("
		SELECT hyoso.id, hyoso.name
		FROM hyoso, genkei, hselection
		WHERE 
			    hyoso.genkei_id = genkei.id
			AND genkei.khhinshi_id = hselection.khhinshi_id
			AND (
				   hselection.name = \'タグ\'
				|| hselection.name = \'TAG\'
			)
	",1)->hundle;
	while (my $i = $h->fetch){
		my $name = $i->[1];
		chop $name; substr($name,0,1) = '';
		my $length = length($name);
		$name =~ s/'/\\'/go;
		#print "$name, $length, $i->[0] : $i->[1]\n";
		mysql_exec->do("
			UPDATE hyoso
			SET name = \'$name\', len = $length
			WHERE id = $i->[0]
		",1);
	}
	$h->finish;
	
	# 基本形テーブル(1)
	my $k = mysql_exec->select("
		SELECT genkei.id, genkei.name
		FROM genkei, hselection
		WHERE 
			    genkei.khhinshi_id = hselection.khhinshi_id
			AND (
				   hselection.name = \'タグ\'
				|| hselection.name = \'TAG\'
			)
	",1)->hundle;
	while (my $i = $k->fetch){
		my $name = $i->[1];
		chop $name; substr($name,0,1) = '';
		$name =~ s/'/\\'/go;
		mysql_exec->do("
			UPDATE genkei
			SET name = \'$name\'
			WHERE id = $i->[0]
		",1);
	}
	
	# 基本形テーブル(2)
	#$k = mysql_exec->select("
	#	SELECT genkei_fin.id, genkei_fin.name
	#	FROM genkei_fin, hselection
	#	WHERE 
	#		    genkei_fin.khhinshi_id = hselection.khhinshi_id
	#		AND (
	#			   hselection.name = \'タグ\'
	#			|| hselection.name = \'TAG\'
	#		)
	#",1)->hundle;
	#while (my $i = $k->fetch){
	#	my $name = $i->[1];
	#	chop $name; substr($name,0,1) = '';
	#	$name =~ s/'/\\'/go;
	#	mysql_exec->do("
	#		UPDATE genkei_fin
	#		SET name = \'$name\'
	#		WHERE id = $i->[0]
	#	",1);
	#}
	
	
	$k->finish;
	
	# HTMLタグを小文字に統一する
	#
	#foreach my $i ("h1","h2","h3","h4","h5"){
	#	my $uc = uc $i;
	#	mysql_exec->do("
	#		UPDATE genkei
	#		SET    name = \"<$i>\"
	#		WHERE  name = \"<$uc>\"
	#	",1);
	#	mysql_exec->do("
	#		UPDATE genkei
	#		SET    name = \"</$i>\"
	#		WHERE  name = \"</$uc>\"
	#	",1);
	#	mysql_exec->do("
	#		UPDATE hyoso
	#		SET    name = \"<$i>\"
	#		WHERE  name = \"<$uc>\"
	#	",1);
	#	mysql_exec->do("
	#		UPDATE hyoso
	#		SET    name = \"</$i>\"
	#		WHERE  name = \"</$uc>\"
	#	",1);
	#}
	
}

#----------------------------#
#   平文格納テーブルを作製   #

sub rowtxt{
	my $self = shift;
	unless (
		mysql_exec->select("select max(bun_idt) from hyosobun",1)
			->hundle->fetch->[0]
	){ return 0; }
	$::project_obj->status_bun(1);

	# morpho_analyzer
	my $spacer = $::project_obj->spacer;

	mysql_exec->drop_table("bun_r");
	mysql_exec->do("create table bun_r(id int auto_increment primary key not null, rowtxt TEXT )",1);

	my ($c,$last,$values,$sql,$temp)
		=(0,1,'','INSERT into bun_r (rowtxt) VALUES ','');

	my $id = 1; my $tc = 0;
	while (1){
		my $h = mysql_exec->select(
			mysql_ready->rowtxt_sql($id, $id + $rows_per_once),
			1,
		)->hundle;
		unless ($h->rows > 0){
			last;
		}
		$id += $rows_per_once;

		while (my $i = $h->fetch){
			++$tc;
			if ($last == $i->[0]){
				$temp .= $spacer if length($temp);
				$temp .= $i->[1];
			} else {
				# エラー・チェック
				if ( length($temp) > 65535 ){
					gui_errormsg->open(
						type => 'msg',
						msg  => kh_msg->get('too_long_sentence') # "Error: there are too long sentences. ( > 65535 )\nKH Coder will exit now."
					);
					exit;
				}
				unless ($last + 1 == $i->[0]){
					print "counters: $last, $i->[0]\n";
					print "the sentence: $temp\n";
					gui_errormsg->open(
						type => 'msg',
						msg  => kh_msg->get('error_in_mysql_bunr') # "「bun_r」テーブル作成中にデータの整合性が失われました。\nKH Coderを終了します。"
					);
					exit;
				}
				# エスケープ
				$temp =~ s/'/\\'/go;
				if ($spacer eq ' '){
					$temp =~ s/^(<h[1-5]>) /$1/i;
					$temp =~ s/ (<\/h[1-5]>)$/$1/i;
				}
				
				$values .= "(\'$temp\'),";
				$temp = $i->[1];
				$last = $i->[0];
				++$c;
			}
			
			if ($c == $data_per_1ins){
				chop $values;
				mysql_exec->do("$sql $values",1);
				$c = 0; $values = '';
			}
		}
		$h->finish;
	}
	
	if (length($values) or length($temp)){
		if (length($temp)){
			$temp =~ s/'/\\'/go;
			$values .= "(\'$temp\'),";
		}
		chop $values;
		mysql_exec->do("$sql $values",1);
	}
}

#my $debug_print_frag = 0;

sub rowtxt_sql{
	my $self = shift;
	my $d1   = shift;
	my $d2   = shift;

	my $sql ="
		SELECT hyosobun.bun_idt, hyoso.name
		FROM hyosobun, hyoso
		WHERE 
			    hyosobun.hyoso_id = hyoso.id
			AND hyosobun.id >= $d1
			AND hyosobun.id < $d2
		ORDER BY hyosobun.id
	";

	#unless ($debug_print_frag){
	#	print "$sql\n";
	#	my $h = mysql_exec->select("explain\n$sql")->hundle;
	#	while (my $i = $h->fetch){
	#		foreach my $ii (@{$i}){
	#			print "$ii: ";
	#		}
	#		print "\n";
	#	}
	#	$debug_print_frag = 1;
	#}

	return $sql;
}

#--------------------------------------------------#
#    各集計単位（H1, H2, H3,,,）のテーブルを作製   #


sub tanis{
	if (mysql_exec->select("select max(bun_idt) from hyosobun",1)->hundle->fetch->[0]){
		# 文単位2
		mysql_exec->drop_table("bun");
		mysql_exec->do("
			create table bun(
				id int auto_increment primary key not null,
				bun_id int,
				dan_id int,
				h5_id int,
				h4_id int,
				h3_id int,
				h2_id int,
				h1_id int
			)
		",1);
		mysql_exec->do("
			INSERT INTO bun (bun_id, dan_id, h5_id, h4_id, h3_id, h2_id, h1_id)
			SELECT bun_id, dan_id, h5_id, h4_id, h3_id, h2_id, h1_id
			FROM hyosobun_t
			GROUP BY bun_idt
			ORDER BY bun_idt
		",1);
		mysql_exec->do("ALTER TABLE bun ADD INDEX index1 (bun_id)",1);
		mysql_exec->do("ALTER TABLE bun ADD INDEX index2 (dan_id)",1);
		mysql_exec->do("ALTER TABLE bun ADD INDEX index3 (h5_id)",1);
		mysql_exec->do("ALTER TABLE bun ADD INDEX index4 (h4_id)",1);
		mysql_exec->do("ALTER TABLE bun ADD INDEX index5 (h3_id)",1);
		mysql_exec->do("ALTER TABLE bun ADD INDEX index6 (h2_id)",1);
		mysql_exec->do("ALTER TABLE bun ADD INDEX index7 (h1_id)",1);
		mysql_exec->do("
			ALTER TABLE bun ADD INDEX index8 (
				bun_id,dan_id,h5_id,h4_id,h3_id,h2_id,h1_id
			)
		",1);
		#mysql_exec->do("
		#	ALTER TABLE bun ADD INDEX test1 (
		#		id,bun_id,dan_id,h5_id,h4_id,h3_id,h2_id,h1_id
		#	)
		#",1);
		mysql_ready::doclength->make_each('bun');
	}
	
	
	# 段落単位
	if(mysql_exec->select("select max(dan_id) from hyosobun",1)->hundle->fetch->[0]){
		$::project_obj->status_dan(1);
		mysql_exec->drop_table("dan");
		mysql_exec->do("
			create table dan(
				id int auto_increment primary key not null,
				dan_id int,
				h5_id int,
				h4_id int,
				h3_id int,
				h2_id int,
				h1_id int
			)
		",1);
		mysql_exec->do("
			INSERT INTO dan (dan_id, h5_id, h4_id, h3_id, h2_id, h1_id)
			SELECT dan_id, h5_id, h4_id, h3_id, h2_id, h1_id
			FROM hyosobun_t
			WHERE dan_id > 0
			GROUP BY dan_id, h5_id, h4_id, h3_id, h2_id, h1_id
			ORDER BY h1_id, h2_id, h3_id, h4_id, h5_id, dan_id
		",1);
		mysql_exec->do("ALTER TABLE dan ADD INDEX index2 (dan_id)",1);
		mysql_exec->do("ALTER TABLE dan ADD INDEX index3 (h5_id)",1);
		mysql_exec->do("ALTER TABLE dan ADD INDEX index4 (h4_id)",1);
		mysql_exec->do("ALTER TABLE dan ADD INDEX index5 (h3_id)",1);
		mysql_exec->do("ALTER TABLE dan ADD INDEX index6 (h2_id)",1);
		mysql_exec->do("ALTER TABLE dan ADD INDEX index7 (h1_id)",1);
		mysql_exec->do("
			ALTER TABLE dan ADD INDEX index8 (
				dan_id,h5_id,h4_id,h3_id,h2_id,h1_id
			)
		",1);
		#mysql_exec->do("
		#	ALTER TABLE dan ADD INDEX test1 (
		#		id,dan_id,h5_id,h4_id,h3_id,h2_id,h1_id
		#	)
		#",1);
		mysql_ready::doclength->make_each('dan');
	} else {
		$::project_obj->status_dan(0);
	}
	# h5単位
	if(mysql_exec->select("select max(h5_id) from hyosobun",1)->hundle->fetch->[0]){
		$::project_obj->status_h5(1);
		mysql_exec->drop_table("h5");
		mysql_exec->do("
			create table h5(
				id int auto_increment primary key not null,
				h5_id int,
				h4_id int,
				h3_id int,
				h2_id int,
				h1_id int
			)
		",1);
		mysql_exec->do("
			INSERT INTO h5 (h5_id, h4_id, h3_id, h2_id, h1_id)
			SELECT h5_id, h4_id, h3_id, h2_id, h1_id
			FROM hyosobun_t
			WHERE h5_id > 0
			GROUP BY h5_id, h4_id, h3_id, h2_id, h1_id
			ORDER BY h1_id, h2_id, h3_id, h4_id, h5_id
		",1);
		mysql_exec->do("ALTER TABLE h5 ADD INDEX index3 (h5_id)",1);
		mysql_exec->do("ALTER TABLE h5 ADD INDEX index4 (h4_id)",1);
		mysql_exec->do("ALTER TABLE h5 ADD INDEX index5 (h3_id)",1);
		mysql_exec->do("ALTER TABLE h5 ADD INDEX index6 (h2_id)",1);
		mysql_exec->do("ALTER TABLE h5 ADD INDEX index7 (h1_id)",1);
		mysql_exec->do("
			ALTER TABLE h5 ADD INDEX index8 (
				h5_id,h4_id,h3_id,h2_id,h1_id
			)
		",1);
		#mysql_exec->do("
		#	ALTER TABLE h5 ADD INDEX test1 (
		#		id,h5_id,h4_id,h3_id,h2_id,h1_id
		#	)
		#",1);
		mysql_ready::doclength->make_each('h5');
	} else {
		$::project_obj->status_h5(0);
	}
	# h4単位
	if(mysql_exec->select("select max(h4_id) from hyosobun",1)->hundle->fetch->[0]){
		$::project_obj->status_h4(1);
		mysql_exec->drop_table("h4");
		mysql_exec->do("
			create table h4(
				id int auto_increment primary key not null,
				h4_id int,
				h3_id int,
				h2_id int,
				h1_id int
			)
		",1);
		mysql_exec->do("
			INSERT INTO h4 (h4_id, h3_id, h2_id, h1_id)
			SELECT h4_id, h3_id, h2_id, h1_id
			FROM hyosobun_t
			WHERE h4_id > 0
			GROUP BY h4_id, h3_id, h2_id, h1_id
			ORDER BY h1_id, h2_id, h3_id, h4_id
		",1);
		mysql_exec->do("ALTER TABLE h4 ADD INDEX index4 (h4_id)",1);
		mysql_exec->do("ALTER TABLE h4 ADD INDEX index5 (h3_id)",1);
		mysql_exec->do("ALTER TABLE h4 ADD INDEX index6 (h2_id)",1);
		mysql_exec->do("ALTER TABLE h4 ADD INDEX index7 (h1_id)",1);
		mysql_exec->do("
			ALTER TABLE h4 ADD INDEX index8 (
				h4_id,h3_id,h2_id,h1_id
			)
		",1);
		#mysql_exec->do("
		#	ALTER TABLE h4 ADD INDEX test1 (
		#		id,h4_id,h3_id,h2_id,h1_id
		#	)
		#",1);
		mysql_ready::doclength->make_each('h4');
	} else {
		$::project_obj->status_h4(0);
	}
	# h3単位
	if(mysql_exec->select("select max(h3_id) from hyosobun",1)->hundle->fetch->[0]){
		$::project_obj->status_h3(1);
		mysql_exec->drop_table("h3");
		mysql_exec->do("
			create table h3(
				id int auto_increment primary key not null,
				h3_id int,
				h2_id int,
				h1_id int
			)
		",1);
		mysql_exec->do("
			INSERT INTO h3 (h3_id, h2_id, h1_id)
			SELECT h3_id, h2_id, h1_id
			FROM hyosobun_t
			WHERE h3_id > 0
			GROUP BY h3_id, h2_id, h1_id
			ORDER BY h1_id, h2_id, h3_id
		",1);
		mysql_exec->do("ALTER TABLE h3 ADD INDEX index5 (h3_id)",1);
		mysql_exec->do("ALTER TABLE h3 ADD INDEX index6 (h2_id)",1);
		mysql_exec->do("ALTER TABLE h3 ADD INDEX index7 (h1_id)",1);
		mysql_exec->do("
			ALTER TABLE h3 ADD INDEX index8 (
				h3_id,h2_id,h1_id
			)
		",1);
		#mysql_exec->do("
		#	ALTER TABLE h3 ADD INDEX test1 (
		#		id,h3_id,h2_id,h1_id
		#	)
		#",1);
		mysql_ready::doclength->make_each('h3');
	} else {
		$::project_obj->status_h3(0);
	}
	# h2単位
	if(mysql_exec->select("select max(h2_id) from hyosobun",1)->hundle->fetch->[0]){
		$::project_obj->status_h2(1);
		mysql_exec->drop_table("h2");
		mysql_exec->do("
			create table h2(
				id int auto_increment primary key not null,
				h2_id int,
				h1_id int
			)
		",1);
		mysql_exec->do("
			INSERT INTO h2 (h2_id, h1_id)
			SELECT h2_id, h1_id
			FROM hyosobun_t
			WHERE h2_id > 0
			GROUP BY h2_id, h1_id
			ORDER BY h1_id, h2_id
		",1);
		mysql_exec->do("ALTER TABLE h2 ADD INDEX index6 (h2_id)",1);
		mysql_exec->do("ALTER TABLE h2 ADD INDEX index7 (h1_id)",1);
		mysql_exec->do("
			ALTER TABLE h2 ADD INDEX index8 (
				h2_id,h1_id
			)
		",1);
		#mysql_exec->do("
		#	ALTER TABLE h2 ADD INDEX test1 (
		#		id,h2_id,h1_id
		#	)
		#",1);
		mysql_ready::doclength->make_each('h2');
	} else {
		$::project_obj->status_h2(0);
	}
	# h1単位
	if(mysql_exec->select("select max(h1_id) from hyosobun",1)->hundle->fetch->[0]){
		$::project_obj->status_h1(1);
		mysql_exec->drop_table("h1");
		mysql_exec->do("
			create table h1(
				id int auto_increment primary key not null,
				h1_id int
			)
		",1);
		mysql_exec->do("
			INSERT INTO h1 (h1_id)
			SELECT h1_id
			FROM hyosobun_t
			WHERE h1_id > 0
			GROUP BY h1_id
			ORDER BY h1_id
		",1);
		mysql_exec->do("ALTER TABLE h1 ADD INDEX index7 (h1_id)",1);
		#mysql_exec->do("
		#	ALTER TABLE h1 ADD INDEX test1 (
		#		id,h1_id
		#	)
		#",1);
		mysql_ready::doclength->make_each('h1');
	} else {
		$::project_obj->status_h1(0);
	}
}

#--------------#
#   アクセサ   #
#--------------#

sub length{
	my $self   = shift;
	my $name   = shift;
	my $length = shift;
	
	if ($length){
		$self->{length}{$name} = $length;
		return $self;
	} else {
		if ($self->{length}{$name}){
			return $self->{length}{$name};
		} else {
			return 128;
		}
	}
}

1;


__END__

#if ($::config_obj->sqllog){                    # coder_data/*_fm.csv出力
#	my $f = $::project_obj->file_FormedText;    # デバッグモード時のみ
#	my $d = '';
#	my $h = mysql_exec->select("select h1_id, h2_id, h3_id, h4_id, h5_id, dan_id, bun_id, bun_idt, hyoso.name from hyosobun, hyoso where hyosobun.hyoso_id = hyoso.id",1)->hundle;
#	my $last = -1;
#	while (my $r = $h->fetch){
#		if ( $r->[7] != $last){
#			$last = $r->[7];
#			$d .= "\n";
#			$d .= "$r->[0],$r->[1],$r->[2],$r->[3],$r->[4],$r->[5],$r->[6],$r->[7],$r->[8]";
#		} else {
#			$d .= $r->[8];
#		}
#	}
#	substr($d,0,1) = '';
#	open (FT,">$f") or die;
#	print FT $d;
#	close (FT);
#	use kh_jchar;
#	kh_jchar->to_sjis($f);
#}
