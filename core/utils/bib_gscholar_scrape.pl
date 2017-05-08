# (1)「gscholar」フォルダに「1.html」「2.html」といった名前で、Google Scholarの
# 検索結果を保存しておく。
# (2) このスクリプトを実行すると、タイトルとURLをスクレイピングして「cinii_
# result.txt」に保存する。

use strict;

use utf8;
use Encode::Locale;
eval { binmode STDOUT, ":encoding(console_out)"; }; warn $@ if $@;

my @results;
for (my $n = 1; $n <= 4; ++$n){
	open my $fh, '<:utf8', "gscholar/$n.html" or die;
	my @t = <$fh>;
	close $fh;
	my $t = join ("\n", @t);

	my $r = &pickup_elements($t);
	@results = (@results, @{$r});
}

open my $fh, '>:utf8', "cinii_result.txt";
foreach my $i (@results){
	print $fh "$i->{title}\t$i->{href}\n";
}

my $num = @results;
print $num;


sub pickup_elements{
	my $t = shift;

	my $p = MyParser->new->my_init;
	$p->parse($t);
	$p->eof;
	return $p->results;

	{
		package MyParser;
		use base 'HTML::Parser';
		my ($flg_pickup, $current, @stor, $next, $last_text, $last_link);
		
		sub my_init{
			my $self = shift;
			undef $flg_pickup;
			undef $current;
			undef @stor;
			undef $next;
			undef $last_text;
			undef $last_link;
			return $self;
		}
		
		sub start {
			my($self, $tagname, $attr, $attrseq, $origtext) = @_;
			
			# 取得開始フラグを立てる
			if ( ($tagname eq "h3") && ($attr->{class} eq 'gs_rt') ){
				#print "flg_pickup 1\n";
				$flg_pickup = 1;
			}
			
			# 取得処理(1)
			if ($flg_pickup){
				# URL取得 & タイトル取得フラグを立てる
				if ( ($flg_pickup == 1) && ($tagname eq 'a') ){
					unless (
						index($attr->{href},'search?q=cache:') > -1
					){
						$current->{href} = $attr->{href};
						$flg_pickup = 2;
						#print "flg_pickup 2: $attr->{href}\n";
					}
				}
			}
		}

		sub end {
			my($self, $tagname, $origtext) = @_;

			# 完了
			if ( ($flg_pickup == 2) && ($tagname eq 'h3') ){
				$flg_pickup = 0;
				push @stor, $current;
				$current = undef;
			}
		}

		sub text {
			my($self, $origtext, $is_cdata) = @_;
			
			# 取得処理(2)
			
			# タイトル取得
			if ($flg_pickup == 2){
				$current->{title} .= $origtext;
			}
			
			$last_text = $origtext;
		}

		sub results{
			my $self = shift;
			return \@stor;
		}
	}

}
1;