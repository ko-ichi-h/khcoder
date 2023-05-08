package screen_code::word_cloud;
use strict;
use utf8;
use mysql_exec;

use screen_code::plugin_path;

my $kh_homepage_url = "https://khcoder.net/scr_monkin.html";

use gui_window::main::menu;
use File::Path;
use Encode qw/encode decode/;

my $hselection_file = &screen_code::plugin_path::assistant_option_folder."WC_hselection.txt";
my $folder_path = $::config_obj->cwd."/screen/MonkinPresentation/python-3.8.10-embed/";
my $network_word_group_file = $::config_obj->cwd."/screen/temp/word_data.csv";
my $network_word_group_file_r = $::config_obj->cwd."/screen/temp/word_data_r.csv";
my $network_word_group_file_b = $::config_obj->cwd."/screen/temp/word_data_b.csv";
my $network_word_group_file_m = $::config_obj->cwd."/screen/temp/word_data_m.csv";
my $network_line_data_file = $::config_obj->cwd."/screen/temp/line_data.csv";

my $grouping_checkState;


sub do_grouping_word_ass{
	my $self = shift;
	my $start = $self->{start};
	
	my @s = $self->{clist}->info('selection');
	my $use_single_word = 0;
	my $main_word = "";
	
	if ( @s && $s[0] eq '0' ){
		my $raw = $self->{direct_w_e}->get;
		if ($raw =~ /<>.*-->/) {
			$main_word = $raw;
			$main_word =~ s/<>.*-->//g;
			$main_word .= "  -";
		} else {
			my $mode = $self->gui_jg( $self->{opt_direct});
			my @words;
			my @words_plus;
			my %words_num_hash;
			my %words_hinshi_hash;
			
			if ($mode ne 'and') {
				$mode = 'or';
			}
			my $sql =  'SELECT genkei.name, genkei.num, hselection.name 
			FROM
				genkei, hselection
			WHERE
				genkei.khhinshi_id = hselection.khhinshi_id
				AND hselection.ifuse = 1
				AND genkei.nouse = 0 AND (';
			my $n = 0;
			foreach my $i (@{$self->{code_obj}->{query_words}}){
				if ($n){ $sql .= "OR "; }
				$sql .= "genkei.id = $i\n";
				++$n;
			}
			$sql .= ")";
			my $h;
			if ($n){
				$h = mysql_exec->select("$sql",1)->hundle;
				@words = ();
				@words_plus = ();
				while (my $i = $h->fetch){
					push @words, $i->[0];
					push @words_plus, "「".$i->[0]."」";
					$words_num_hash{$i->[0]} = $i->[1];
					$words_hinshi_hash{$i->[0]} = $i->[2];
				}
			}
			
			$use_single_word = 1 if $n == 1;
			if ($use_single_word) {
				$main_word = join(",", @words);
				$main_word .= " ".$words_hinshi_hash{$main_word}." -";
			} else {
				if ($mode ne 'and') {
					$main_word = join("か", @words_plus);
				} else {
					$main_word = join("と", @words_plus);
				}
				$main_word .= "  -";
			}
		}
	} else {
		foreach my $i (@s){
			$main_word =  $self->{clist}->itemCget(  $i, 0, 'text' );
			$main_word .= "  -";
		}
	}
	
	if ($self->{result}){
	
		my $detail_file = $folder_path."wordRelationList.txt";
		unlink $detail_file if -f $detail_file;
		my $DETAIL;
		open ($DETAIL, '>:encoding(utf8)', $detail_file) or return;
	
		print $DETAIL "$main_word\n";
		my $row = 0;
		foreach my $i (@{$self->{result}}){
			
			my $str = $i->[0];
			$str =~ s/\(否定\)/_否定/;
			print $DETAIL "$str $i->[1] $i->[6]\n";
			++$row;
		}
		close ($DETAIL);
		
		return 1;
	} else {
		return 0;
	}
}

sub do_word_cloud{
	my $self = shift;
	my $start = $self->{start};
	
	my $filter_exists = 0;
	my $filter = undef;
	$filter->{limit}   = 100;                  # LIMIT number
	my $h = mysql_exec->select("
		SELECT name, khhinshi_id
		FROM   hselection
		WHERE  ifuse = 1
	",1)->hundle;
	while (my $i = $h->fetch){                 # Filter by POS
		if (
			   $i->[0] =~ /B$/
			|| $i->[0] eq '否定助動詞'
			|| $i->[0] eq '形容詞（非自立）'
		){
			$filter->{hinshi}{$i->[1]} = 0;
		} else {
			$filter->{hinshi}{$i->[1]} = 1;
		}
		$filter_exists = 1;
	}
	
	my $sql;
	$sql = '
		SELECT
			genkei.name, hselection.name, genkei.num, genkei.id
		FROM
			genkei, hselection
		WHERE
			    genkei.khhinshi_id = hselection.khhinshi_id
			#AND genkei.hinshi_id = hinshi.id
			AND hselection.ifuse = 1
			AND genkei.nouse = 0'."\n";
	
	if ($filter_exists){
		my $n = 0;
		$sql .= "\tAND (\n";
		foreach my $i (keys %{$filter->{hinshi}}){
			if ($filter->{hinshi}{$i}){
				$sql .= "\t\t";
				$sql .= "|| " if $n;
				$sql .= "genkei.khhinshi_id = $i\n";
				++$n;
			}
		}
		$sql .= "\t)\n";
	}
	$sql .= 'ORDER BY genkei.num DESC';
	
	#my $t = mysql_exec->select("
	#	select genkei_name,hselection_name,genkei_num,genkei_id,id
	#	from word_search_temp
	#	order by id
	#",1)->hundle;
	
	my $t = mysql_exec->select($sql,1)->hundle;
	
	my $detail_file = $folder_path."wordDetailList_all.txt";
	print "$detail_file datailfile\n";
	unlink $detail_file if -f $detail_file;
	my $DETAIL;
	open ($DETAIL, '>:encoding(utf8)', $detail_file) or return;
	while (my $i = $t->fetch){
		my $str = $i->[0];
		$str =~ s/\(否定\)/_否定/;
		print $DETAIL "$str $i->[1] $i->[2]\n";
	}
	
	close ($DETAIL);
	return 1;
}

sub add_word_cloud_menu{
	my $self = shift;
	my $f = shift;
	my $menu1_ref = shift;
	
	push @{$menu1_ref}, 't_wordcloud_plugin';
	if (-e &screen_code::plugin_path::WC_path) {
		$self->{t_wordcloud_plugin} = $f->command(
			-label => kh_msg->get('screen_code::assistant->wordcloud_button'),
			-font => "TKFN",
			-command => sub{
				&do_word_cloud($self);
				my $system_err = 0;
				$! = undef;
				my $plugin_rtn = system(&screen_code::plugin_path::WC_path, "1");
				$system_err = 1 if ($!) ;
				$::main_gui->{win_obj}->deiconify;
				if ($plugin_rtn == 0 || $system_err != 0) {
					
				} elsif ($plugin_rtn == 256) {
					
				}
			}
		);
	} else {
		$self->{t_wordcloud_plugin} = $f->command(
			-label => kh_msg->get('screen_code::assistant->wordcloud_button2'),
			-font => "TKFN",
			-command => sub{
				gui_OtherWin->open($kh_homepage_url);
			}
		);
	}
}

sub add_button_wordcloud{
	my $self = shift;
	my $wmw = shift;
	
	if (-e &screen_code::plugin_path::WC_path) {
		$self->{wc_btn} = $wmw->Button(
			-text =>kh_msg->get('screen_code::assistant->wordcloud_button'),
			-font => "TKFN",
			-borderwidth => '1',
			-command => sub{
				&do_word_cloud($self);
				my $system_err = 0;
				$! = undef;
				my $plugin_rtn = system(&screen_code::plugin_path::WC_path, "1");
				$system_err = 1 if ($!) ;
				$::main_gui->{win_obj}->deiconify;
				if ($plugin_rtn == 0 || $system_err != 0) {
					
				} elsif ($plugin_rtn == 256) {
					
				}
			}
		)->pack(-side => 'left');
	} else {
		if ($::config_obj->os eq 'win32' && $::config_obj->msg_lang eq 'jp' ){
			$self->{wc_btn} = $wmw->Button(
				-text =>kh_msg->get('screen_code::assistant->wordcloud_button2'),
				-font => "TKFN",
				-borderwidth => '1',
				-command => sub{
					gui_OtherWin->open($kh_homepage_url);
				}
			)->pack(-side => 'left');
		}
	}
	
}

sub add_button_grouping{
	my $self = shift;
	my $rf = shift;
	my $f5 = shift;
	$grouping_checkState = 0;
	
	if (-e &screen_code::plugin_path::WC_path) {
		$rf->Button(
			-text => kh_msg->get('screen_code::assistant->presentation_button'),
			-font => "TKFN",
			-borderwidth => '1',
			-command => sub {
				if (do_grouping_word_ass($self)) {
					
					my $order_name = {
						'fr'  => 2, # 共起
						'sa'  => 3, # 確率差
						'hi'  => 4, # 確率比
						'jac' => 1,
						'ochi'=> 5,
						'dice'=> 6,
						'simp'=> 7,
						'll'  => 8,
					};
					
					my $orderNum = $$order_name{$self->{opt_order}};
					
					my $system_err = 0;
					$! = undef;
					my $plugin_rtn = system(&screen_code::plugin_path::WC_path, "2", $orderNum);
					$system_err = 1 if ($!) ;
					$::main_gui->{win_obj}->deiconify;
					if ($plugin_rtn == 0 || $system_err != 0) {
						
					} elsif ($plugin_rtn == 256) {
						
					}
				}
			}
		)->pack(-side => 'left', -padx => 15);
	} else {
		if ($::config_obj->os eq 'win32' && $::config_obj->msg_lang eq 'jp' ){
			$rf->Button(
				-text => kh_msg->get('screen_code::assistant->presentation_button2'),
				-font => "TKFN",
				-borderwidth => '1',
				-command => sub {
					gui_OtherWin->open($kh_homepage_url);
				}
			)->pack(-side => 'left', -padx => 15);
		}
	}
}

sub add_code_to_network{
    my($r_command_ref) = @_;

	unless (-d $::config_obj->cwd."/screen/temp"){
		mkdir($::config_obj->cwd."/screen/temp")
			or die("could not create dir: ".$::config_obj->cwd."/screen/temp")
		;
	}

	$$r_command_ref .= "output_word_data <- \"".$network_word_group_file."\"\n";
	unlink $network_word_group_file if -f $network_word_group_file;
	$$r_command_ref .= "output_line_data <- \"".$network_line_data_file."\"\n";
	unlink $network_line_data_file if -f $network_line_data_file;
	$$r_command_ref .= "output_word_data_r <- \"".$network_word_group_file_r."\"\n";
	unlink $network_word_group_file_r if -f $network_word_group_file_r;
	$$r_command_ref .= "output_word_data_b <- \"".$network_word_group_file_b."\"\n";
	unlink $network_word_group_file_b if -f $network_word_group_file_b;
	$$r_command_ref .= "output_word_data_m <- \"".$network_word_group_file_m."\"\n";
	unlink $network_word_group_file_m if -f $network_word_group_file_m;
}


sub word_link_check{
	
	my $wordPairDic = shift;
	my $checkedWord = shift;
	my $linkedWords = shift;
	my $targetWord = shift;
	$$checkedWord{$targetWord} = 1;
	foreach my $word (@{$$wordPairDic{$targetWord}}) {
		unless (exists($$checkedWord{$word})) {
			&word_link_check($wordPairDic, $checkedWord, $linkedWords, $word);
		}
		$$linkedWords{$word} = 1;
	}
}

sub grouping_network_menu{
	my $w = shift;
	my $parent_win_obj = shift;
	my $select_word = shift;
	my $result_window_self = shift;
	
	
	my $title = $parent_win_obj->title;
	$title = Encode::decode("utf-8",$title);
	#print "grouping_network_menu title=$title select_word=$select_word\n";
	if ($title eq "抽出語・共起ネットワーク") {
	
		#print "grouping_network_menu called ax=$result_window_self->{ax} \n";
		my $ax_num = 0;
		my $selected_picture = "";
		my $selected_picture_type = "";
		my $use_word_file;
		foreach my $i (@{$result_window_self->option1_options}){
			#print "$i \n";
			if ($ax_num == $result_window_self->{ax}) {
				#print "selected picture = $i \n";
				$selected_picture = $i;
			}
			$ax_num++;
		}
		
		if ($selected_picture eq kh_msg->get('gui_window::r_plot::word_netgraph->com_m')) {
			$selected_picture_type = "com";
			$use_word_file = $network_word_group_file_m;
		} elsif ($selected_picture eq kh_msg->get('gui_window::r_plot::word_netgraph->com_b')) {
			$selected_picture_type = "com";
			$use_word_file = $network_word_group_file_b;
		} elsif ($selected_picture eq kh_msg->get('gui_window::r_plot::word_netgraph->com_r')) {
			$selected_picture_type = "com";
			$use_word_file = $network_word_group_file_r;
		} else {
			$selected_picture_type = "cnt";
			$use_word_file = $network_word_group_file;
		}
	
		my $x = $w->pointerx;
		my $y = $w->pointery;
		my $m = $parent_win_obj->Menu(
			-type => 'normal',
			-tearoff=>'no'
		);
		if (-f &screen_code::plugin_path::WC_path) {
			#my $cascade_upper = $m->cascade(
			#	-label => kh_msg->get('screen_code::assistant->presentation_button'),
			#	-font => "TKFN",
			#	-tearoff=>'no'
			#);
			my $cascade = $m->cascade(
				-label => kh_msg->get('screen_code::assistant->grouping_menu_p'),
				-font => "TKFN",
				-tearoff=>'no'
			);
			$cascade->command(-label => kh_msg->get('screen_code::assistant->grouping_menu_1'), -command => sub {
				if ($selected_picture_type eq "cnt") {
					if (-f $network_line_data_file) {
						my %wordNumDic = ();
						open(my $IN, "<:encoding(cp932)", $use_word_file);
						while (my $line = <$IN>) {
							chomp($line);
							$line =~ s/\t//go;
							my @splited = split(/,/, $line);
							my $word = $splited[0];
							my $wordnum = $splited[4];
							$wordNumDic{$word} = $wordnum;
						}
						close($IN);
						
						open($IN, "<:encoding(cp932)", $network_line_data_file);
						my $wordPairDic = {};
						while (my $line = <$IN>) {
							chomp($line);
							my @splited = split(/,/, $line);
							my $word1 = $splited[3];
							my $word2 = $splited[12];
							my $weiget = $splited[11];
							unless (exists($$wordPairDic{$word1})) {
								$$wordPairDic{$word1} = [];
							}
							unless (exists($$wordPairDic{$word2})) {
								$$wordPairDic{$word2} = [];
							}
							push(@{$$wordPairDic{$word1}}, $word2);
							push(@{$$wordPairDic{$word2}}, $word1);
						}
						close($IN);
						
						my $checkedWord = {};
						my $linkedWords = {};
						&word_link_check($wordPairDic, $checkedWord, $linkedWords, $select_word);
						
						my @linkedWordsAry = keys %{$linkedWords};
						
						my $first = 1;
						my $relation_file = $folder_path."wordRelationList.txt";
						unlink $relation_file if -f $relation_file;
						my $REALTION;
						open ($REALTION, '>:encoding(utf8)', $relation_file) or return;
						
						my $genkei = shift;
						my $sql = '
							SELECT
								genkei.name, hselection.name, genkei.num 
							FROM
								genkei, hselection
							WHERE
								genkei.khhinshi_id = hselection.khhinshi_id
								AND hselection.ifuse = 1
								AND genkei.nouse = 0
								AND (genkei.name = \''.$select_word.'\'';
								
						foreach my $genkei (@linkedWordsAry) {
							$sql .= ' OR genkei.name = \''.$genkei.'\'';
						}
						$sql .= ') ORDER BY genkei.num DESC';
						
						my $t = mysql_exec->select($sql,1)->hundle;
						my @relationStrArray;
						while (my $i = $t->fetch){
							if ($wordNumDic{$i->[0]} == $i->[2]) {
								if ($i->[0] eq $select_word) {
									unshift(@relationStrArray, $i->[0]." ".$i->[1]." ".$i->[2]);
								} else {
									push(@relationStrArray, $i->[0]." ".$i->[1]." ".$i->[2]);
								}
							}
						}
						
						print $REALTION join("\n", @relationStrArray)."\n";
						close ($REALTION);
						
						
						my $system_err = 0;
						$! = undef;
						my $plugin_rtn = system(&screen_code::plugin_path::WC_path, "2","0");
						$system_err = 1 if ($!) ;
						$::main_gui->{win_obj}->deiconify;
						if ($plugin_rtn == 0 || $system_err != 0) {
							
						} elsif ($plugin_rtn == 256) {
							
						}
					} else {
						return;
					}
				} elsif ($selected_picture_type eq "com") {
					if (-f $use_word_file) {
						my %wordToGroupDic = ();
						my %groupTowordsDic = ();
						my %wordNumDic = ();
						open(my $IN, "<:encoding(cp932)", $use_word_file);
						while (my $line = <$IN>) {
							chomp($line);
							$line =~ s/\t//go;
							my @splited = split(/,/, $line);
							my $word = $splited[0];
							my $group = $splited[1];
							my $wordnum = $splited[4];
							$wordToGroupDic{$word} = $group;
							if (exists($groupTowordsDic{$group})) {
							} else{
								$groupTowordsDic{$group} = [];
							}
							push(@{$groupTowordsDic{$group}}, $word);
							$wordNumDic{$word} = $wordnum;
						}
						close($IN);
						
						open($IN, "<:encoding(cp932)", $network_line_data_file);
						my %wordPairDic = ();
						while (my $line = <$IN>) {
							chomp($line);
							my @splited = split(/,/, $line);
							my $word1 = $splited[3];
							my $word2 = $splited[12];
							my $weiget = $splited[11];
							unless (exists($wordPairDic{$word1})) {
								$wordPairDic{$word1} = {};
								$wordPairDic{$word1}{1} = $word1;
							}
							unless (exists($wordPairDic{$word2})) {
								$wordPairDic{$word2} = {};
								$wordPairDic{$word2}{1} = $word2;
							}
							$wordPairDic{$word1}{$weiget} = $word2;
							$wordPairDic{$word2}{$weiget} = $word1;
						}
						close($IN);
						my @keys = sort { $b cmp $a } keys %{$wordPairDic{$select_word}};
						
						my $groupStr = $wordToGroupDic{$select_word};
						if ($groupStr ne "NA") {
							my $relation_file = $folder_path."wordRelationList.txt";
							unlink $relation_file if -f $relation_file;
							my $REALTION;
							open ($REALTION, '>:encoding(utf8)', $relation_file) or return;
							my $genkei = shift;
							my $sql = '
								SELECT
									genkei.name, hselection.name, genkei.num 
								FROM
									genkei, hselection
								WHERE
									genkei.khhinshi_id = hselection.khhinshi_id
									AND hselection.ifuse = 1
									AND genkei.nouse = 0
									AND (genkei.name = \''.$select_word.'\'';
									
							foreach my $genkei (@{$groupTowordsDic{$groupStr}}) {
								$sql .= ' OR genkei.name = \''.$genkei.'\'';
							}
							$sql .= ') ORDER BY genkei.num DESC';
							
							my $t = mysql_exec->select($sql,1)->hundle;
							my @relationStrArray;
							while (my $i = $t->fetch){
								if ($wordNumDic{$i->[0]} == $i->[2]) {
									if ($i->[0] eq $select_word) {
										unshift(@relationStrArray, $i->[0]." ".$i->[1]." ".$i->[2]);
									} else {
										push(@relationStrArray, $i->[0]." ".$i->[1]." ".$i->[2]);
									}
								}
							}
							
							print $REALTION join("\n", @relationStrArray)."\n";
							close ($REALTION);
							
							my $system_err = 0;
							$! = undef;
							my $plugin_rtn = system(&screen_code::plugin_path::WC_path, "2","0");
							$system_err = 1 if ($!) ;
							$::main_gui->{win_obj}->deiconify;
							if ($plugin_rtn == 0 || $system_err != 0) {
								
							} elsif ($plugin_rtn == 256) {
								
							}
							
						}
					} else {
						return;
					}
				}
			});
			
			$cascade->command(-label => kh_msg->get('screen_code::assistant->grouping_menu_2'),  -command => sub {
				if (-f $network_line_data_file) {
					my %wordNumDic = ();
					open(my $IN, "<:encoding(cp932)", $use_word_file);
					while (my $line = <$IN>) {
						chomp($line);
						$line =~ s/\t//go;
						my @splited = split(/,/, $line);
						my $word = $splited[0];
						my $wordnum = $splited[4];
						$wordNumDic{$word} = $wordnum;
					}
					close($IN);
					
					open($IN, "<:encoding(cp932)", $network_line_data_file);
					my $wordPairDic = {};
					while (my $line = <$IN>) {
						chomp($line);
						my @splited = split(/,/, $line);
						my $word1 = $splited[3];
						my $word2 = $splited[12];
						my $weiget = $splited[11];
						unless (exists($$wordPairDic{$word1})) {
							$$wordPairDic{$word1} = [];
						}
						unless (exists($$wordPairDic{$word2})) {
							$$wordPairDic{$word2} = [];
						}
						push(@{$$wordPairDic{$word1}}, $word2);
						push(@{$$wordPairDic{$word2}}, $word1);
					}
					close($IN);
					
					my $checkedWord = {};
					my $linkedWords = {};
					&word_link_check($wordPairDic, $checkedWord, $linkedWords, $select_word);
					
					my @linkedWordsAry = keys %{$linkedWords};
					
					my $first = 1;
					my $relation_file = $folder_path."wordRelationList.txt";
					unlink $relation_file if -f $relation_file;
					my $REALTION;
					open ($REALTION, '>:encoding(utf8)', $relation_file) or return;
					
					my $genkei = shift;
					my $sql = '
						SELECT
							genkei.name, hselection.name, genkei.num 
						FROM
							genkei, hselection
						WHERE
							genkei.khhinshi_id = hselection.khhinshi_id
							AND hselection.ifuse = 1
							AND genkei.nouse = 0
							AND (genkei.name = \''.$select_word.'\'';
							
					foreach my $genkei (@linkedWordsAry) {
						$sql .= ' OR genkei.name = \''.$genkei.'\'';
					}
					$sql .= ') ORDER BY genkei.num DESC';
					
					my $t = mysql_exec->select($sql,1)->hundle;
					my @relationStrArray;
					while (my $i = $t->fetch){
						if ($wordNumDic{$i->[0]} == $i->[2]) {
							if ($i->[0] eq $select_word) {
								unshift(@relationStrArray, $i->[0]." ".$i->[1]." ".$i->[2]);
							} else {
								push(@relationStrArray, $i->[0]." ".$i->[1]." ".$i->[2]);
							}
						}
					}
					
					print $REALTION join("\n", @relationStrArray)."\n";
					close ($REALTION);
					
					
					my $system_err = 0;
					$! = undef;
					my $plugin_rtn = system(&screen_code::plugin_path::WC_path, "2","0");
					$system_err = 1 if ($!) ;
					$::main_gui->{win_obj}->deiconify;
					if ($plugin_rtn == 0 || $system_err != 0) {
						
					} elsif ($plugin_rtn == 256) {
						
					}
				} else {
					return;
				}
			});
			
			$cascade->command(-label => kh_msg->get('screen_code::assistant->grouping_menu_3'), -command => sub {
				my $code_asso_obj = kh_cod::asso->new;
				
				$code_asso_obj->add_direct(
					mode => "and",
					raw  => $select_word,
				);
				
				my @selected = (0);
				
				my $query_ok = $code_asso_obj->asso(
					selected => \@selected,
					tani     => "h5",
					method   => "and",
				);
				
				if ($query_ok){
					$code_asso_obj = $query_ok;
					
					my $filter = {};
					$filter->{limit}     = 75;
					$filter->{min_doc}   = 1;
					$filter->{show_lowc} = 0;
					my $h = mysql_exec->select("
						SELECT name, khhinshi_id
						FROM   hselection
						WHERE  ifuse = 1
					",1)->hundle;
					while (my $i = $h->fetch){
						if (
							   $i->[0] =~ /B$/
							|| $i->[0] eq '否定助動詞'
							|| $i->[0] eq '形容詞（非自立）'
						){
							$filter->{hinshi}{$i->[1]} = 0;
						} else {
							$filter->{hinshi}{$i->[1]} = 1;
						}
					}
					
					my $result = $code_asso_obj->fetch_results(
						order  => "jac",
						filter => $filter,
					);
					
					my $first = 1;
					my $relation_file = $folder_path."wordRelationList.txt";
					unlink $relation_file if -f $relation_file;
					my $REALTION;
					open ($REALTION, '>:encoding(utf8)', $relation_file) or return;
					my $hinshi = genkeiToHinshi($select_word);
					print $REALTION $select_word." ".$hinshi." -\n";
					
					foreach my $i (@{$result}){
						print $REALTION "$i->[0] $i->[1] $i->[6]\n";
						$first = 0;
					}
					close ($REALTION);
					
					my $system_err = 0;
					$! = undef;
					my $plugin_rtn = system(&screen_code::plugin_path::WC_path, "2","1");
					$system_err = 1 if ($!) ;
					$::main_gui->{win_obj}->deiconify;
					if ($plugin_rtn == 0 || $system_err != 0) {
						
					} elsif ($plugin_rtn == 256) {
						
					}
				}
			});
			
		} else  {
			$m->command(-label => kh_msg->get('screen_code::assistant->presentation_button2'), -under => 0, -command => sub {
				gui_OtherWin->open($kh_homepage_url);
			});
		}
		$m->post($x, $y);
	}
}

sub genkeiToHinshi{
	my $genkei = shift;
	my $sql = '
		SELECT
			genkei.name, hselection.name 
		FROM
			genkei, hselection
		WHERE
			genkei.khhinshi_id = hselection.khhinshi_id
			AND hselection.ifuse = 1
			AND genkei.nouse = 0
			AND genkei.name = \''.$genkei.'\'';
	
	my $hinshi;
	my $t = mysql_exec->select($sql,1)->hundle;
	while (my $i = $t->fetch){
		$hinshi = $i->[1];
	}
	
	return $hinshi;
}

1;