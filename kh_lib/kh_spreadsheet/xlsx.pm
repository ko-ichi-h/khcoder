package kh_spreadsheet::xlsx;

use strict;
use warnings;
use base 'kh_spreadsheet';

use Spreadsheet::XLSX;

no warnings 'redefine';
*Spreadsheet::XLSX::new = \&___new;
use warnings 'redefine';

sub parser{
	my $self = shift;
	
	my $workbook = Spreadsheet::XLSX->new($self->{file});
	return $workbook;
}

sub get_value{
	use Encode qw(decode);
	if ( $_[1] ){
		my $t = $_[1]->value ;
		$t = decode('utf8', $t) unless utf8::is_utf8($t);
		return $t;
	} else {
		return '';
	}
}

sub ___new {

	my ($class, $filename, $converter) = @_;
	
	my $self = {};
	
	$self -> {zip} = Archive::Zip -> new ();

	if (ref $filename) {
	
		$self -> {zip} -> readFromFileHandle ($filename) == Archive::Zip::AZ_OK or die ("Cannot open data as Zip archive");
	
	} 
	else {
	
		$self -> {zip} -> read ($filename) == Archive::Zip::AZ_OK or die ("Cannot open $filename as Zip archive");
	
	};

	my $member_shared_strings = $self -> {zip} -> memberNamed ('xl/sharedStrings.xml');
	
	my @shared_strings = ();

	if ($member_shared_strings) {
	
		my $mstr = $member_shared_strings->contents; 
		$mstr =~ s/<t\/>/<t><\/t>/gsm;  # this handles an empty t tag in the xml <t/>
		foreach my $si ($mstr =~ /<si.*?>(.*?)<\/si/gsm) {
			$si =~ s!<rPh[^>]*>.*?</rPh>!!gsm; # modified
			my $str;
			foreach my $t ($si =~ /<t.*?>(.*?)<\/t/gsm) {
				$t = $converter -> convert ($t) if $converter;
				$str .= $t;
			}
			push @shared_strings, $str;
		}	
	}
        my $member_styles = $self -> {zip} -> memberNamed ('xl/styles.xml');

        my @styles = ();

	my %style_info = ();

        if ($member_styles) {

                foreach my $t ($member_styles -> contents =~ /xf\ numFmtId="([^"]*)"(?!.*\/cellStyleXfs)/gsm) { #"
                       # $t = $converter -> convert ($t) if $converter;
                        push @styles, $t;

                }
		my $default = $1 || '';

		foreach my $t1 (@styles){
			$member_styles -> contents =~ /numFmtId="$t1" formatCode="([^"]*)/;
			my $formatCode = $1 || '';
			if ($formatCode eq $default || not($formatCode)){
				if ($t1 == 9 || $t1==10){ $formatCode="0.00000%";}
				elsif ($t1 == 14){ $formatCode="m-d-yy";}
				else {
					$formatCode="";
				}
			}
			$style_info{$t1} = $formatCode;
			$default = $1 || '';
		}

        }

	my $member_rels = $self -> {zip} -> memberNamed ('xl/_rels/workbook.xml.rels') or die ("xl/_rels/workbook.xml.rels not found in this zip\n");
	
	my %rels = ();

	foreach ($member_rels -> contents =~ /\<Relationship (.*?)\/?\>/g) {
	
		/^Id="(.*?)".*?Target="(.*?)"/ or next;
		
		$rels {$1} = $2;
	
	}

	my $member_workbook = $self -> {zip} -> memberNamed ('xl/workbook.xml') or die ("xl/workbook.xml not found in this zip\n");
	my $oBook = Spreadsheet::ParseExcel::Workbook->new;
	$oBook->{SheetCount} = 0;
	$oBook->{FmtClass} = Spreadsheet::XLSX::Fmt2007->new;
	$oBook->{Flg1904}=0;
	if ($member_workbook->contents =~ /date1904="1"/){
		$oBook->{Flg1904}=1;
	}
	my @Worksheet = ();
	
	foreach ($member_workbook -> contents =~ /\<(.*?)\/?\>/g) {
	
		/^(\w+)\s+/;
		
		my ($tag, $other) = ($1, $');

		my @pairs = split /\" /, $other;

		$tag eq 'sheet' or next;
		
		my $sheet = {
			MaxRow => 0,
			MaxCol => 0,
			MinRow => 1000000,
			MinCol => 1000000,
		};
		
		foreach ($other =~ /(\S+=".*?")/gsm) {

			my ($k, $v) = split /=?"/; #"
	
			if ($k eq 'name') {
				$sheet -> {Name} = $v;
				$sheet -> {Name} = $converter -> convert ($sheet -> {Name}) if $converter;
			}
			elsif ($k eq 'r:id')	{
			
				$sheet -> {path} = $rels {$v};
				
			};
					
		}
		my $wsheet = Spreadsheet::ParseExcel::Worksheet->new(%$sheet);
		push @Worksheet, $wsheet;
		$oBook->{Worksheet}[$oBook->{SheetCount}] = $wsheet;
		$oBook->{SheetCount}+=1;
				
	}

	$self -> {Worksheet} = \@Worksheet;
	
	foreach my $sheet (@Worksheet) {
		
		my $member_sheet = $self -> {zip} -> memberNamed ("xl/$sheet->{path}") or next;
	
		my ($row, $col);
		
		my $flag = 0;
		my $s    = 0;
		my $s2   = 0;
		my $sty  = 0;
		foreach ($member_sheet -> contents =~ /(\<.*?\/?\>|.*?(?=\<))/g) {
			if (/^\<c r=\"([A-Z])([A-Z]?)(\d+)\"/) {
				
				$col = ord ($1) - 65;
				
				if ($2) {
                			$col++;
					$col *= 26;
					$col += (ord ($2) - 65);
				}
				
				$row = $3 - 1;
				
				$s   = m/t=\"s\"/      ?  1 : 0;
				$s2  = m/t=\"str\"/    ?  1 : 0;
				$sty = m/s="([0-9]+)"/ ? $1 : 0;

			}
			elsif (/^<v/) {
				$flag = 1;
			}
			elsif (/^<\/v/) {
				$flag = 0;
			}
			elsif (length ($_) && $flag) {
				my $v = $s ? $shared_strings [$_] : $_;
				if ($v eq "</c>"){$v="";}
				my $type = "Text";
				my $thisstyle = "";
				if (not($s) && not($s2)){
					$type="Numeric";
					$thisstyle = $style_info{$styles[$sty]};
					if ($thisstyle =~ /(?<!Re)d|m|y/){
						$type="Date";
					}
				}	
				$sheet -> {MaxRow} = $row if $sheet -> {MaxRow} < $row;
				$sheet -> {MaxCol} = $col if $sheet -> {MaxCol} < $col;
				$sheet -> {MinRow} = $row if $sheet -> {MinRow} > $row;
				$sheet -> {MinCol} = $col if $sheet -> {MinCol} > $col;
				if ($v =~ /(.*)E\-(.*)/gsm && $type eq "Numeric"){
					$v=$1/(10**$2);  # this handles scientific notation for very small numbers
				}
				my $cell =Spreadsheet::ParseExcel::Cell->new(

					Val    => $v,
					Format => $thisstyle,
					Type => $type
					
				);

				$cell->{_Value} = $oBook->{FmtClass}->ValFmt($cell, $oBook);
				if ($type eq "Date" && $v<1){  #then this is Excel time field
					$cell->{Type}="Text";
					$cell->{Val}=$cell->{_Value};
				}
				$sheet -> {Cells} [$row] [$col] = $cell;
			}
					
		}
		
		$sheet -> {MinRow} = 0 if $sheet -> {MinRow} > $sheet -> {MaxRow};
		$sheet -> {MinCol} = 0 if $sheet -> {MinCol} > $sheet -> {MaxCol};

	}
foreach my $stys (keys %style_info){
}
	bless ($self, $class);

	return $oBook;

}



1;
