# 「部分テキストの取り出し」->「特定のコードが与えられた文書だけ」コマンド
#                                                         のためのロジック

package kh_cod::pickup;
use base qw(kh_cod);
use strict;

my $records_per_once = 5000;


sub pick{
	my $self = shift;
	my %args = @_;
	
	use Benchmark;                                    # 時間計測用
	my $t0 = new Benchmark;                           # 時間計測用
	
	# 取り合えずコーディング
	
	my $the_code = $self->{codes}[$args{selected}];
	$the_code->ready($args{tani});
	$the_code->code('ct_pickup');
	unless ($the_code->res_table){
		gui_errormsg->open(
			type => 'msg',
			msg  =>
				"選択されたコードは、どの文書にも与えられませんでした。\n".
				"ファイル作製は中止されました。"
		);
		return 0;
	}

	# 書き出し

	open (F,">$args{file}") or 
		gui_errormsg->open(
			thefile => $args{file},
			type    => 'file'
		);
	my $last = 0;
	my $id = 1;
	while (1){
		my $sth = mysql_exec->select(
			$self->sql(
				tani    => $args{tani},
				pick_hi => $args{pick_hi},
				d1      => $id,
				d2      => $id + $records_per_once,
			),
			1
		)->hundle;
		unless ($sth->rows > 0){
			last;
		}
		$id += $records_per_once;

		while (my $i = $sth->fetchrow_hashref){
			if ($i->{bun_id} == 0 && $i->{dan_id} == 0){
				if ($last){
					print F "\n";
					$last = 0;
				}
				print F "$i->{rowtxt}\n";
			} else {
				if ($last == $i->{dan_id}){
					print F "$i->{rowtxt}";
				}
				elsif ($i->{dan_id} == 1){
					print F "$i->{rowtxt}";
					$last = 1;
				} else {
					print F "\n$i->{rowtxt}";
					$last = $i->{dan_id};
				}
			}
		}
		print "$id,";
	}
	close (F);

	my $t1 = new Benchmark;                           # 時間計測用
	print timestr(timediff($t1,$t0)),"\n";            # 時間計測用

}

sub sql{
	my $self = shift;
	my %args = @_;
	
	my $sql;
	if ($args{pick_hi}){
		$sql .= "SELECT bun_id, dan_id, rowtxt\n";
		$sql .= "FROM bun, bun_r\n";
		$sql .= "	LEFT JOIN $args{tani} ON\n";
		my $flag = 0;
		foreach my $i ('bun','dan','h5','h4','h3','h2','h1'){
			if ($i eq $args{tani}){ ++$flag;}
			if ($flag) {
				if ($flag > 1){
					$sql .= "\t\tAND bun.$i"."_id = $args{tani}.$i"."_id\n";
				} else {
					$sql .= "\t\t    bun.$i"."_id = $args{tani}.$i"."_id\n";
				}
				++$flag;
			}
		}
		$sql .= "\tLEFT JOIN ct_pickup ON ct_pickup.id = $args{tani}.id\n";
		$sql .= "WHERE\n";
		$sql .= "
			    bun.id = bun_r.id
			AND bun.id >= $args{d1}
			AND bun.id <  $args{d2}
			AND (
				IFNULL(ct_pickup.num,0)
				OR
				(
					    bun.bun_id = 0
					AND bun.dan_id = 0
					AND bun.$args{tani}"."_id  = 0
				)
			)
		";
	} else {
		$sql .= "SELECT bun_id, dan_id, rowtxt\n";
		$sql .= "FROM bun, bun_r, $args{tani}, ct_pickup\n";
		$sql .= "WHERE\n";
		$sql .= "	    bun.id = bun_r.id\n";
		$sql .= "	AND bun.id >= $args{d1}\n";
		$sql .= "	AND bun.id <  $args{d2}\n";
		$sql .= "	AND ct_pickup.id = $args{tani}.id\n";
		my $flag = 0;
		foreach my $i ('bun','dan','h5','h4','h3','h2','h1'){
			if ($i eq $args{tani}){$flag=1;}
			if ($flag) {
				$sql .= "\t\tAND bun.$i"."_id = $args{tani}.$i"."_id\n";
			}
		}
		
	}
	
	return $sql;
}


1;