# 「テキストファイルの変形」->「HTMLからCSVに変換」コマンドのためのロジック
# Usage:
# 	mysql_csvout->exec(
# 		tani => h1 | h2 | h3 ...
# 		file => '書き出しファイル'
# 	);

package mysql_html2csv;
use strict;

use mysql_exec;
use mysql_getdoc;

sub exec{
	my $class = shift;
	my %args  = @_;
	
	my @h = ();
	foreach my $i ("h1", "h2", "h3", "h4", "h5"){
		if ($args{tani} eq $i) {last;}
		if (
			mysql_exec->select(
				"select status from status where name = \'$i\'",1
			)->hundle->fetch->[0]
		){
			push @h ,$i;
		}
	}

	open (CSVO,">$args{file}") or 
		gui_errormsg->open(
			type => 'file',
			thefile => $args{file}
		);

	my $h = mysql_exec->select ("
		select *
		from bun_r, bun
		where
			bun_r.id = bun.id
		order by bun.id
	",1)->hundle;
	
	my $current; my %h;
	my $last = 0;
	while (my $i = $h->fetchrow_hashref){
		if ($i->{"$args{tani}"."_id"}){           # 本文の場合
			if ($i->{"$args{tani}_id"} == $last){      # 継ぎ足し
				$current .= $i->{rowtxt};
			} else {                                   # 書き出し
				unless ($current){
					$last = $i->{"$args{tani}_id"};
					$current = $i->{rowtxt};
					next;
				}
				
				foreach my $g (@h){
					print CSVO "$h{$g},";
				}
				print CSVO "$current\n";
				
				$last = $i->{"$args{tani}_id"};
				$current = $i->{rowtxt};
			}
		} else {                                  # 上位見出しの場合
			$last = 0;
			foreach my $g (reverse @h){
				if ( $i->{"$g"."_id"} ){
					$h{$g} = $i->{rowtxt};
					last;
				}
			}
		}
	}
	
	# 最後のデータを書き出し
	foreach my $g (@h){
		print CSVO "$h{$g},";
	}
	print CSVO "$current\n";
	close (CSVO);
	
	if ($::config_obj->os eq 'win32'){
		kh_jchar->to_sjis($args{file});
	}
}

1;