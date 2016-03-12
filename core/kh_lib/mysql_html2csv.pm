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
	
	# 存在する見出しのチェック
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

	# 書き出し用ファイルをオープン
	use File::BOM;
	open (CSVO,'>:encoding(utf8):via(File::BOM)', $args{file}) or 
		gui_errormsg->open(
			type => 'file',
			thefile => $args{file}
		);

	my $hundle = mysql_exec->select ("
		select *
		from bun_r, bun_bak, bun_length_nouse
		where
			bun_r.id = bun_bak.id
			AND bun_length_nouse.id = bun_bak.id
		order by bun_bak.id
	",1)->hundle;

	# morpho_analyzer
	my $spacer = $::project_obj->spacer;

	my $current;
	my %head;
	my $last = 0;
	my $last_bunidt;
	my $the_tani;
	if ($args{tani} eq 'bun'){
		$the_tani = 'id';
	} else {
		$the_tani = "$args{tani}"."_id";
	}
	use kh_csv;
	while (my $i = $hundle->fetchrow_hashref){
		if ($i->{"$args{tani}"."_id"}){           # 本文の場合
			# print "$i->{$the_tani},";
			if ($i->{$the_tani} == $last){             # 継ぎ足し
				$current .= $spacer if length($current);
				$current .= $i->{rowtxt};
			} else {                                   # 書き出し（連続）
				unless (length($current)){
					$last = $i->{$the_tani};
					$current = $i->{rowtxt};
					next;
				}
				
				foreach my $g (@h){
					print CSVO kh_csv->value_conv($head{$g}).',';
				}
				if ($current =~ /<h[1-5]>(.+?)<\/h[1-5]>(.+)/i) {
					print CSVO kh_csv->value_conv($1).',';
					$current = $2;
				}
				print CSVO kh_csv->value_conv($current)."\n";
				
				$last = $i->{$the_tani};
				$current = $i->{rowtxt};
			}
		} else {                                  # 上位見出しの場合
			if ( length($current) ){                   # 書き出し（見出し変化）
				foreach my $g (@h){
					print CSVO kh_csv->value_conv($head{$g}).',';
				}
				if ($current =~ /<h[1-5]>(.+?)<\/h[1-5]>(.+)/i) {
					print CSVO kh_csv->value_conv($1).',';
					$current = $2;
				}
				print CSVO kh_csv->value_conv($current)."\n";
				$current = '';
			}
			
			$last = 0;
			
			my $midashi_tani = '';
			foreach my $g (reverse @h){                # 見出しの変更
				if ( $i->{"$g"."_id"} ){
					$head{$g} = $i->{rowtxt};
					$head{$g} =~ s#<h[1-5]>(.*)</h[1-5]>#$1#i;
					$midashi_tani = $g;
					last;
				}
			}
			my $flag = 0;
			foreach my $g (@h){
				if ($g eq $midashi_tani) {
					$flag = 1;
					next;
				}
				if ($flag) {
					$head{$g} = '';
				}
			}
			
			if ($args{tani} eq 'bun' && $i->{len} > 0) { # 文単位の場合だけ書き出し
				foreach my $g (@h){
					print CSVO kh_csv->value_conv($head{$g}).',';
				}
				my $t = $i->{rowtxt};
				$t =~ s#<h[1-5]>(.*)</h[1-5]>#$1#i;
				print CSVO kh_csv->value_conv($t)."\n";
			}
		}
	}
	
	# 最後のデータを書き出し
	if (length($current)) {
		foreach my $g (@h){
			print CSVO "$head{$g},";
		}
		if ($current =~ /<h[1-5]>(.+?)<\/h[1-5]>(.+)/i) {
			print CSVO kh_csv->value_conv($1).',';
			$current = $2;
		}
		print CSVO "$current\n";
	}

	close (CSVO);
}

1;