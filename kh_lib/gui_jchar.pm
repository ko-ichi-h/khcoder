package gui_jchar;
#use strict;
use Tk;

#------------#
#   Text用   #
#------------#

sub check_key{
	unless ($::config_obj->os eq 'win32'){
		return 1;
	}

	my $sjis = q{
		  [\x00-\x7F]
		| [\x81-\x9F][\x40-\x7E]
		| [\x81-\x9F][\x80-\xFC]
		| [\xE0-\xEF][\x40-\x7E]
		| [\xE0-\xEF][\x80-\xFC]
	};

	my $t = ${$_[2]};

	# print "$_[1]\n";

	if($_[1] eq BackSpace){
	#	$temp = $t->get("insert linestart","insert");
	#	print "$temp\n";	
		unless ($t->get("insert linestart","insert") =~ /^(?: $sjis)*$/x){
			$t->delete("insert -1 chars");
			
		}
	}elsif($_[1] eq Delete){
		unless ($Flag ==1){
			if ($t->get("insert linestart","insert lineend")=~ /^(?: $sjis)*$/x){
				@target = $t->get("insert","insert lineend") =~ /\G(?:$sjis)/gox;
				for ($i = $#base,$j = $#target;$j >= 0; $i--,$j--){
					$b = $base[$i];
					$s = $target[$j];
					unless($b eq $s){
						$t->delete("insert","insert +1 chars");
					}
				}
			}else{
				$t->delete("insert","insert +1 chars");
			}
		}
	}elsif($_[1] eq 'Left'){
		unless ($t->get("insert linestart","insert") =~ /^(?: $sjis)*$/x){
			$newvalue = $t->index("insert -1 chars");
			$t->markSet("insert",$newvalue);
		}
	}elsif(($_[1] eq 'Right') || ($_[1] eq Up) || ($_[1] eq Down)){
		unless ($t->get("insert linestart","insert") =~ /^(?: $sjis)*$/x){
			$newvalue = $t->index("insert +1 chars");
			$t->markSet("insert",$newvalue);
		}
	}


	if($t->compare("insert", ">=", "insert lineend")){
		$Flag = 1;
	}else{
		$Flag = 0;
	}
	@base = $t->get("insert linestart", "insert lineend") =~ /$sjis/gox;
}

# マウスクリック用

sub check_mouse{
	unless ($::config_obj->os eq 'win32'){
		return 1;
	}
	my $sjis = q{
		[\x00-\x7F]
		| [\x81-\x9F][\x40-\x7E]
		| [\x81-\x9F][\x80-\xFC]
		| [\xE0-\xEF][\x40-\x7E]
		| [\xE0-\xEF][\x80-\xFC]
	};

	my $t = ${$_[1]};

	if($t->compare("insert", ">=", "insert lineend")){
		$Flag = 1;
	}else{
		$Flag = 0;
	}
	@base = $t->get("insert linestart", "insert lineend") =~ /$sjis/gox;
	unless ($t->get("insert linestart","insert") =~
		/^(?: $sjis)*$/x){
		$newvalue = $t->index("insert +1 chars");
		$t->markSet("insert",$newvalue);
	}
}

#-------------#
#   Entry用   #
#-------------#

sub check_key_e_d{
	unless ($::config_obj->os eq 'win32'){
		return 1;
	}
	my $sjis = q{
		  [\x00-\x7F]
		| [\x81-\x9F][\x40-\x7E]
		| [\x81-\x9F][\x80-\xFC]
		| [\xE0-\xEF][\x40-\x7E]
		| [\xE0-\xEF][\x80-\xFC]
	};
	my $t = shift;
	my $l = $t->index('insert') + 1;            # カーソルを1つ右に
	$t->icursor($l);
	
	my $x = $t->get();                          # ちょん切れてたらもう1つ右
	$x = substr($x,0,$l);
	unless ($x =~ /^(?: $sjis)*$/x){
		++$l;
		$t->icursor($l);
#		print "a ";
	}
	
	my $y = $t->index('insert')-1;              # 一度バックスペース
	$t->delete($y) if ($y >= 0);
	
	$x = $t->get();                             # ちょん切れてたらもう一回
	$l = $t->index('insert');
	$x = substr($x,0,$l);
	unless ($x =~ /^(?: $sjis)*$/x){
		$y = $t->index('insert')-1;
		$t->delete($y) if ($y >= 0);
#		print "b ";
	}
}

# バックスペース、左右カーソルキーのバインド

sub check_key_e{
	unless ($::config_obj->os eq 'win32'){
		return 1;
	}
	my $sjis = q{
		  [\x00-\x7F]
		| [\x81-\x9F][\x40-\x7E]
		| [\x81-\x9F][\x80-\xFC]
		| [\xE0-\xEF][\x40-\x7E]
		| [\xE0-\xEF][\x80-\xFC]
	};
	my $t = ${$_[2]};

	if($_[1] eq 'BackSpace'){
		my $x = $t->get();
		my $l = $t->index('insert');
		$x = substr($x,0,$l);
		unless ($x =~ /^(?: $sjis)*$/x){
			my $y = $t->index('insert')-1;
			$t->delete($y) if ($y >= 0);
		}
	}
	elsif($_[1] eq 'Left'){
		my $x = $t->get();
		my $l = $t->index('insert');
		$x = substr($x,0,$l);
		unless ($x =~ /^(?: $sjis)*$/x){
			--$l;
			$t->icursor($l);
		}
	}
	elsif($_[1] eq 'Right'){
		my $x = $t->get();
		my $l = $t->index('insert');
		$x = substr($x,0,$l);
		unless ($x =~ /^(?: $sjis)*$/x){
			++$l;
			$t->icursor($l);
		}
	}
}
1;
