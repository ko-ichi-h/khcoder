package screen_code::r_plot_multiselect;
use strict;
use utf8;

use gui_window::r_plot;
use screen_code::plugin_path;

use File::Path;
use Encode qw/encode decode/;

use Time::Local;
use Time::HiRes 'usleep';

my $kh_homepage_url = "http://khcoder.net/scr_3wnew_monkin.html";

my $default_undecorate;
my $wordlist_file_name = "multi_wordlist.txt";
my $and_file_name = "multi_AND.txt";
my $or_file_name = "multi_result.txt";
my $target_id_file_name = "multi_target_id.txt";
my $detail_file_name = "multi_detail.txt";
my $footer_file_name = "multi_footer.txt";
my $relation_file_name = "multi_relation.txt";
my $inittani_file_name = "multi_inittani.txt";
my $recieved_file_name = "multi_recieved.txt";
my $font_file_name = "multi_font.txt";


my $part_target = "h5";
my @tani_ary;
my $tani_col_str;
my $dan_disuse_flg;
my $dan_in_tag_flg;
my $dan_replace_tani_str;
my $outbar_tani;
my $outvar_tani_index;


my $cancel_flag;
my $waitDialog;
my $previousTime;

my $result_window_checkState = 0;
my $checkState = 0;

my $parent_win_obj;
my $result_window_parent_win_obj;
my $result_window_self;

#中止可能なダイアログの開始
sub start_waitDialog {
	if (defined($waitDialog)) {
		$waitDialog->destroy;
		undef $waitDialog;
	}
	
	my $is_result_window = shift;
	my $mw;
	if ($is_result_window) {
		$mw = $result_window_parent_win_obj;
	} else {
		$mw = $parent_win_obj;
	}
	my $message = "Monkin is processing data...";
	$cancel_flag = 0;
	$waitDialog = $mw->Toplevel();
	$waitDialog->transient($mw);
	$waitDialog->overrideredirect(1);
	$waitDialog->Popup( -popanchor => 'c' );
	my $frame = $waitDialog->Frame( -border => 5, -relief => 'groove' )->pack;
	$frame->Label( -text => $message, )->pack( -padx => 5 );
	$previousTime = timelocal(localtime);
	$waitDialog->update;
}

#中止ボタンが押されたか
sub check_cancel {
	return 0;
}

sub end_waitDialog {
	if (defined($waitDialog)) {
		$waitDialog->destroy;
		undef $waitDialog;
    }
}

#hyosobunテーブル中の区切りID列名
sub part_target_id{
	$part_target = shift;
	if ($part_target eq "bun") {
		return "bun_idt";
	} elsif ($dan_disuse_flg && $part_target eq "dan") {
		return $dan_replace_tani_str."_id";
	} else {
		return $part_target."_id";
	}
}

sub make_tani_id_col{
	my $t = mysql_exec->select("SELECT name, status FROM status WHERE status = TRUE AND name IN ('h1','h2','h3','h4','h5','dan','bun') ORDER BY name",1)->hundle;
	@tani_ary = ();
	my $dan_exist = 0;
	my $h_min_tani= "";
	while (my $i = $t->fetch){
		push @tani_ary, $i->[0];
		$dan_exist = 1 if $i->[0] eq "bun";
		$h_min_tani = $i->[0] if $i->[0] =~ /h/;
	}
	
	$dan_disuse_flg = 0;
	if ($dan_exist && $h_min_tani ne "") {
		$t = mysql_exec->select("SELECT COUNT(*) FROM dan",1)->hundle;
		my $dan_row = $t->fetch->[0];
		$t = mysql_exec->select("SELECT COUNT(*) FROM $h_min_tani",1)->hundle;
		my $h_min_row = $t->fetch->[0];
		$dan_disuse_flg = 0 if $dan_row == $h_min_row;
		$dan_replace_tani_str = $h_min_tani;
	}
	
	my $count;
	my @tani_order = ("h1","h2","h3","h4","h5","dan","bun");
	$outvar_tani_index = 8;
	$tani_col_str = "CONCAT(";
	foreach my $tani_str (@tani_ary) {
		if($count) {
			$tani_col_str .= ", ";
		}
		if ($tani_str eq "bun") {
			$tani_col_str .= "'".$tani_str.":', hyosobun.bun_idt, '\@'";
		} elsif ($dan_disuse_flg && $tani_str eq "dan") {
			$tani_col_str .= "'".$tani_str.":', hyosobun.".$h_min_tani."_id, '\@'";
		} else {
			$tani_col_str .= "'".$tani_str.":', hyosobun.".$tani_str."_id, '\@'";
		}
		$count++;
		my ($index) = grep { $tani_order[$_] eq 'h5' } 0 .. $#tani_order;
		$outvar_tani_index = $index if $outvar_tani_index > $index
	}
	$tani_col_str .= ")";
	$outbar_tani = $tani_order[$outvar_tani_index];
}


sub bind_multiselect{
	my $self = shift;
	return 0 unless $self->{coordin};
	$result_window_parent_win_obj = $self->{win_obj};
	$result_window_checkState = 0;
	$result_window_self = $self;
	#print "bind_multiselect called\n";
	
	foreach my $i (keys %{$self->{coordin}}) {
		
		next unless $i =~ /^[0-9]+$/;
		$self->{canvas}->bind(
			$i,
			"<Button-3>",
			[sub {
				my($w) = @_;
				my $select_word = $self->{coordin}{$i}{name};
				
				use screen_code::word_cloud;
				&screen_code::word_cloud::grouping_network_menu($w, $result_window_parent_win_obj, $select_word, $result_window_self);
				return;
			}]
		);
	}
	if (-e &screen_code::plugin_path::KWIC_main_path &! $self->{kwic_button_w}) {
		$self->{kwic_button_w} = $self->{bottom_frame}->Button(
			-text => kh_msg->get('screen_code::assistant->KWIC_button'),
			-font => "TKFN",
			-borderwidth => '1',
			-command => sub {
				my @selected_words;
				foreach my $i (keys %{$self->{coordin}}) {
					if ($i ne 'decorated' && $self->{coordin}{$i}{selected}) {
						push @selected_words, $self->{coordin}{$i}{name};
					}
				}
				do_multi_KWIC(\@selected_words);
			}
		)->pack(-side => 'right');
		$self->{bottom_frame}->Checkbutton(
			-variable => \$result_window_checkState,
		)->pack(-side => 'right');
	} else {
		if ( $::config_obj->os eq 'win32' && $::config_obj->msg_lang eq 'jp' &! $self->{kwic_button_w}){
			$self->{kwic_button_w} = $self->{bottom_frame}->Button(
				-text => kh_msg->get('screen_code::assistant->KWIC_button2'),
				-font => "TKFN",
				-borderwidth => '1',
				-command => sub {
					gui_OtherWin->open($kh_homepage_url);
				}
			)->pack(-side => 'right');
			$self->{bottom_frame}->Checkbutton(
				-variable => \$result_window_checkState,
				-state => 'disable',
			)->pack(-side => 'right');
		}
		return;
	}
	foreach my $i (keys %{$self->{coordin}}) {
		
		next unless $i =~ /^[0-9]+$/;
		
		$self->{canvas}->bind(
			$i,
			"<Control-Button-1>",
			sub {
				select_word($self,$i);
			}
		);
		$self->{canvas}->bind(
			$i,
			"<Button-1>",
			sub {
				$self->undecorate(1);
				if ($result_window_checkState) {
					my @selected_words;
					push @selected_words, $self->{coordin}{$i}{name};
					do_multi_KWIC(\@selected_words);
				} else {
					$self->show_kwic($i);
				}
			}
		);
	}
	
	unless ($default_undecorate) {
		$default_undecorate = \&gui_window::r_plot::undecorate;
		*gui_window::r_plot::undecorate = \&undecorate_multiselect;
	}
	
	$self->{canvas}->bind(
		1,
		"<Button-1>",
		sub { $self->undecorate; }
	);
	$self->{bottom_frame}->Label(
		-text => "  ",
		-font => "TKFN",
	)->pack(-side => 'right');
	
}

sub add_button_ass{
	my $self = shift;
	my $rf = shift;
	my $f5 = shift;
	$checkState = 0;
	
	if (-e &screen_code::plugin_path::KWIC_main_path) {
		$parent_win_obj = $self->{win_obj};
		 $rf->Checkbutton(
			-variable => \$checkState,
			-width => 0,
		)->pack(-side => 'left');
		$rf->Button(
			-text => kh_msg->get('screen_code::assistant->KWIC_button'),
			-font => "TKFN",
			-borderwidth => '1',
			-command => sub {
				#if ($checkState) {
					my @selected = $self->{rlist}->infoSelection;
					return unless @selected;
					my @s = $self->{clist}->info('selection');
					if ( @s && $s[0] eq '0' ) {
						my $mode =  $self->gui_jg( $self->{opt_direct});
						screen_code::r_plot_multiselect::do_multi_KWIC_relation($self->{result}->[$selected[0]][0], $self->{code_obj}->{query_words}, $mode);
					}
				#}
			}
		)->pack(-side => 'left');
	} else {
		if ($::config_obj->os eq 'win32' && $::config_obj->msg_lang eq 'jp' ){
			$rf->Checkbutton(
				-variable => \$checkState,
				-width => 0,
				-state => 'disable',
			)->pack(-side => 'left');
			$rf->Button(
				-text => kh_msg->get('screen_code::assistant->KWIC_button2'),
				-font => "TKFN",
				-borderwidth => '1',
				-command => sub {
					gui_OtherWin->open($kh_homepage_url);
				}
			)->pack(-side => 'left');
		}
	}
	
}

sub checkbutton_KWIC{
	my $self = shift;
	if ($checkState) {
		my @selected = $self->{rlist}->infoSelection;
		return unless @selected;
		my @s = $self->{clist}->info('selection');
		if ( @s && $s[0] eq '0' ) {
			my $mode =  $self->gui_jg( $self->{opt_direct});
			screen_code::r_plot_multiselect::do_multi_KWIC_relation($self->{result}->[$selected[0]][0], $self->{code_obj}->{query_words}, $mode);
		}
		return 1;
	}
	return 0;
}

#プロットからの呼び出し
sub do_multi_KWIC{
	my $selected_words_ref = shift;
	
	mkpath('screen/temp');
	output_inittani();
	
	my $relation_file_path = &screen_code::plugin_path::assistant_option_folder.$relation_file_name;
	unlink $relation_file_path if -f $relation_file_path;
	
	start_waitDialog(1);
	my $rtn = output_KWIC_files($selected_words_ref);
	end_waitDialog();
	return 0 if !$rtn;
	
	require Win32::Process::List;
	my %list =Win32::Process::List->new()->GetProcesses();
	unlink &screen_code::plugin_path::assistant_option_folder.$recieved_file_name if -f &screen_code::plugin_path::assistant_option_folder.$recieved_file_name;
	while (my ($key,$value) = each(%list)){
		if ($value =~ /MonkinKWIC/) {
			while (!(-f &screen_code::plugin_path::assistant_option_folder.$recieved_file_name)) {
				system(&screen_code::plugin_path::KWIC_sub_path." reload");
				usleep(500);
			}
			return 0;
		}
	}
	
	output_font_file();
	system(&screen_code::plugin_path::KWIC_pl_path." ".&screen_code::plugin_path::KWIC_main_path);
	return 0;
	
}

sub output_font_file{
	my $file_path = &screen_code::plugin_path::assistant_option_folder.$font_file_name;
	unlink $file_path if -f $file_path;
	
	open(my $OUT, ">:encoding(utf8)", $file_path);
	my $font_str = gui_window->gui_jchar($::config_obj->font_main);
	$font_str =~ s/,.*//;
	print $OUT $font_str;
	
	close($OUT);
}

sub close_KWIC{
	unless (-e &screen_code::plugin_path::KWIC_main_path) {
		return 0;
	}
	require Win32::Process::List;
	my %list =Win32::Process::List->new()->GetProcesses();
	unlink &screen_code::plugin_path::assistant_option_folder.$recieved_file_name if -f &screen_code::plugin_path::assistant_option_folder.$recieved_file_name;
	while (my ($key,$value) = each(%list)){
		if ($value =~ /MonkinKWIC/) {
			while (!(-f &screen_code::plugin_path::assistant_option_folder.$recieved_file_name)) {
				system(&screen_code::plugin_path::KWIC_sub_path." close");
				usleep(500);
			}
			return 0;
		}
	}
}

#同義語検索からの呼び出し
sub do_multi_KWIC_relation{
	my $selected_word_ref = shift;
	my $code_words_genkeiid_ref = shift;
	my $mode = shift;
	my @words;
	
	mkpath('screen/temp');
	output_inittani();
	
	if ($mode ne 'and') {
		$mode = 'or';
	}
	my $sql =  "SELECT genkei.name\n";
	$sql .= "FROM genkei WHERE (\n";
	my $n = 0;
	foreach my $i (@{$code_words_genkeiid_ref}){
		if ($n){ $sql .= "OR "; }
		$sql .= "genkei.id = $i\n";
		++$n;
	}
	$sql .= "\t)";
	my $h;
	if ($n){
		$h = mysql_exec->select("$sql",1)->hundle;
		@words = ();
		while (my $i = $h->fetch){
			push @words, $i->[0];
		}
	}
	push @words, $selected_word_ref;
	
	my $relation_file_path = &screen_code::plugin_path::assistant_option_folder.$relation_file_name;
	unlink $relation_file_path if -f $relation_file_path;
	
	open(my $OUT, ">:encoding(utf8)", $relation_file_path);
	print $OUT "$selected_word_ref $mode";
	close($OUT);
	
	start_waitDialog(0);
	my $rtn = output_KWIC_files(\@words);
	end_waitDialog();
	return 0 unless $rtn;
	
	require Win32::Process::List;
	my %list =Win32::Process::List->new()->GetProcesses();
	unlink &screen_code::plugin_path::assistant_option_folder.$recieved_file_name if -f &screen_code::plugin_path::assistant_option_folder.$recieved_file_name;
	while (my ($key,$value) = each(%list)){
		if ($value =~ /MonkinKWIC/) {
			while (!(-f &screen_code::plugin_path::assistant_option_folder.$recieved_file_name)) {
				system(&screen_code::plugin_path::KWIC_sub_path." reload");
				usleep(500);
			}
			return 0;
		}
	}
	
	output_font_file();
	system(&screen_code::plugin_path::KWIC_pl_path." ".&screen_code::plugin_path::KWIC_main_path);
	
	return 0;
	
	
}

#プラグイン開始時の初期taniを出力する
sub output_inittani{
	my $tani = $::project_obj->last_tani;
	my $inittani_file_path = &screen_code::plugin_path::assistant_option_folder.$inittani_file_name;
	unlink $inittani_file_path if -f $inittani_file_path;
	
	open(my $OUT, ">:encoding(utf8)", $inittani_file_path);
	print $OUT $tani;
	
	close($OUT);
}

#前準備を行った後、AND検索とOR検索の関数を呼び出す
sub output_KWIC_files{
	my $selected_words_ref = shift;
	
	my @genkei_id_list;
	my $sql = "
		SELECT genkei.id
		FROM genkei
		WHERE (";
	
	my $count = 0;
	foreach my $word (@{$selected_words_ref}) {
		$sql .= " OR " if $count > 0;
		$sql .= "genkei.name = \'$word\'";
		$count++;
	}
	$sql .= ")";
	
	if ($count == 0) {
		print "no selected \n";
		return 0;
	}
	
	my $t = mysql_exec->select($sql,1)->hundle;
	while (my $i = $t->fetch){
		push @genkei_id_list, $i->[0];
	}
	
	make_tani_id_col();
	
	if (mysql_exec->table_exists("temp_conc_multi")) {
		mysql_exec->do("DROP TABLE temp_conc_multi",1);
	}
	unless (mysql_exec->table_exists("temp_conc_multi")) {
		mysql_exec->do("
			create table temp_conc_multi (
				genkei_id int not null,
				hyoso_id int,
				hyosobun_id int,
				part_id int,
				tani_id_string varchar(30)
			) TYPE = HEAP
		",1);
		mysql_exec->do("ALTER TABLE temp_conc_multi ADD INDEX index1 (genkei_id)",1);
		mysql_exec->do("ALTER TABLE temp_conc_multi ADD INDEX index2 (hyosobun_id)",1);
	}
	unless (mysql_exec->table_exists("temp_part")) {
		mysql_exec->do("
			create table temp_part (
				id int primary key
			) TYPE = HEAP
		",1);
	}
	if (mysql_exec->table_exists("temp_conc_multi_sort")) {
		mysql_exec->do("DROP TABLE temp_conc_multi_sort",1);
	}
	unless (mysql_exec->table_exists("temp_conc_multi_sort")) {
		mysql_exec->do("
			create table temp_conc_multi_sort (
				row_num int not null,
				center_id int,
				l1_id int,
				l2_id int,
				l3_id int,
				l4_id int,
				l5_id int,
				r1_id int,
				r2_id int,
				r3_id int,
				r4_id int,
				r5_id int,
				center_count int,
				l1_count int,
				l2_count int,
				l3_count int,
				l4_count int,
				l5_count int,
				r1_count int,
				r2_count int,
				r3_count int,
				r4_count int,
				r5_count int,
				genkei_id int
			) TYPE = HEAP
		",1);
	}
	
	
	mysql_exec->do("DELETE FROM temp_conc_multi",1);
	mysql_exec->do("DELETE FROM temp_conc_multi_sort",1);
	$sql = "INSERT INTO temp_conc_multi (genkei_id, hyoso_id, hyosobun_id, part_id, tani_id_string) \n";
	$sql .= "SELECT genkei.id, hyoso.id, hyosobun.id, hyosobun.h5_id, $tani_col_str ";
	$sql .= " FROM hyosobun, hyoso, genkei\n";
	$sql .= "WHERE genkei.id = hyoso.genkei_id AND hyosobun.hyoso_id = hyoso.id";
	
	$sql .= " AND (\n";
	$count = 0;
	foreach my $id (@genkei_id_list){
		$sql .= " OR " if $count > 0;
		$sql .= "genkei.id = $id \n";
		$count++;
	}
	$sql .= ")";
	
	mysql_exec->do($sql,1);
	
	return 0 if check_cancel();
	
	return 0 unless output_wordlist(\@genkei_id_list);
	return 0 unless output_or_result(\@genkei_id_list);
	return 1;
}

#検索対象の単語を「原型表記 原型ID:表層ID 表層表記」という形式でリスト出力する
sub output_wordlist{
	my $genkei_id_list = shift;
	
	my $file_path = &screen_code::plugin_path::assistant_option_folder.$wordlist_file_name;
	unlink $file_path if -f $file_path;
	
	my $sql = "
		SELECT genkei.name, genkei.id, hyoso.id, hyoso.name
		FROM genkei, hyoso
		WHERE genkei.id = hyoso.genkei_id AND (";
	my $count = 0;
	foreach my $id (@{$genkei_id_list}){
		$sql .= " OR " if $count > 0;
		$sql .= "genkei.id = $id \n";
		$count++;
	}
	$sql .= ") ORDER BY genkei.id";
	
	open(my $OUT, ">:encoding(utf8)", $file_path);
	my $t = mysql_exec->select($sql,1)->hundle;
	while (my $i = $t->fetch){
		print $OUT "$i->[0] $i->[1]:$i->[2],$i->[3]\n";
	}
	close($OUT);
	return 1;
}



#OR検索を行い結果を出力する
sub output_or_result{
	my $genkei_id_list = shift;
	
	my $file_path = &screen_code::plugin_path::assistant_option_folder.$or_file_name;
	my $target_id_path = &screen_code::plugin_path::assistant_option_folder.$target_id_file_name;
	my $detail_path = &screen_code::plugin_path::assistant_option_folder.$detail_file_name;
	my $footer_path = &screen_code::plugin_path::assistant_option_folder.$footer_file_name;
	unlink $file_path if -f $file_path;
	unlink $target_id_path if -f $target_id_path;
	unlink $detail_path if -f $detail_path;
	unlink $footer_path if -f $footer_path;
	
	my @hyosobun_id_list;
	my @target_id_list;
	my @tani_id_list;
	my @tani_id_list_header;
	
	my $sql = "SELECT DISTINCT hyosobun_id, h5_id, h1_id, h2_id, h3_id, h4_id, h5_id, dan_id, bun_idt FROM temp_conc_multi INNER JOIN hyosobun ON temp_conc_multi.hyosobun_id = hyosobun.id ORDER BY hyosobun.id";
	
	my $t = mysql_exec->select($sql,1)->hundle;
	my $prev_id = "";
	my $footer_id_str;
	my @tani_order = ('h1','h2','h3','h4','h5','dan','bun');
	my $dan_in_tag; #hタグを考慮した段落番号
	$dan_in_tag_flg = 0;
	while (my $i = $t->fetch){
		push @hyosobun_id_list, $i->[0];
		push @target_id_list, $i->[1];
		
		#hタグ内の段落に対応する
		$dan_in_tag = $i->[7];
		if ($i->[6] > 0) {
			$dan_in_tag = $i->[6] * 100 + $i->[7];
			$dan_in_tag_flg = 1;
			#print "h5=$i->[6] dan=$i->[7] dan_in_tag=$dan_in_tag \n";
		}
		
		$footer_id_str = "";
		foreach my $tani_str (@tani_ary) {
			my $temp_tani_str;
			if ($dan_disuse_flg && $tani_str eq "dan") {
				$temp_tani_str = $dan_replace_tani_str;
			
			#hタグ内の段落はテーブルの値そのままではないため特別な対応が必要
			} elsif ($tani_str eq "dan") {
				$footer_id_str .= $tani_str.":".$dan_in_tag."@";
				next;
			} else {
				$temp_tani_str = $tani_str;
			}
			my ($index) = grep { $tani_order[$_] eq $temp_tani_str } 0 .. $#tani_order;
			$footer_id_str .= $tani_str.":".$i->[$index + 2]."@";
		}
		
		push @tani_id_list, $footer_id_str."h1 = $i->[2], h2 = $i->[3], h3 = $i->[4], h4 = $i->[5], h5 = $i->[6], dan = $dan_in_tag, bun = $i->[8]";
		push @tani_id_list_header, $i->[$outvar_tani_index+2];
		$prev_id = $i->[1];
	}
	
	return 0 if check_cancel();
	
	my @result;
	return 0 unless get_result_by_hyosobun_id(\@hyosobun_id_list, \@result);
	output_sort_table($genkei_id_list);
	my @detail;
	return 0 unless get_detail_by_part_target_id(\@detail);
	my %outvar;
	return 0 unless get_outvar_by_part_target_id(\@target_id_list, \%outvar);
	
	my $OUT;
	open($OUT, ">:encoding(utf8)", $file_path);
	foreach (@result) {
	    print $OUT $_;
	}
	close($OUT);
	
	open($OUT, ">:encoding(utf8)", $target_id_path);
	foreach (@target_id_list) {
	    print $OUT $_."\n";
	}
	close($OUT);
	
	open($OUT, ">:encoding(utf8)", $detail_path);
	foreach (@detail) {
	    print $OUT $_;
	}
	close($OUT);
	
	open($OUT, ">:encoding(utf8)", $footer_path);
	my $count;
	for ($count = 0; $count < int(@tani_id_list); $count++) {
		my $temp = $tani_id_list[$count];
		$temp .= "<br><br>".$outvar{$tani_id_list_header[$count]} if exists $outvar{$tani_id_list_header[$count]};
		$temp .= "\n";
	    print $OUT $temp;
	}
	close($OUT);
	
	return 1;
	
}

#表層文IDリストから結果の文章を求める
sub get_result_by_hyosobun_id{
	my $hyosobun_id_list = shift;
	my $result = shift;
	my $sql;
	
	my $csv_file_path = &screen_code::plugin_path::assistant_option_folder."hyosobun_id.csv";
	unlink $csv_file_path if -f $csv_file_path;
	my $OUT;
	open($OUT, ">:encoding(utf8)", $csv_file_path);
	foreach my $id (@{$hyosobun_id_list}){
		for (my $i = $id - 24; $i < ($id + 24); $i++){
	    	print $OUT "$i\n";
		}
	}
	close($OUT);
	
	mysql_exec->do("DELETE FROM temp_part",1);
	mysql_exec->do("LOAD DATA LOCAL INFILE '$csv_file_path' INTO TABLE temp_part",1);
	
	$sql = "SELECT hyosobun.id, hyoso.name, temp_conc_multi.hyosobun_id, hyoso.genkei_id, hyosobun.hyoso_id, hyosobun.bun_id, temp_conc_multi.tani_id_string, hyosobun.dan_id, hyosobun.h5_id\n";
	$sql .= "FROM (hyosobun INNER JOIN temp_part ON  hyosobun.id = temp_part.id) INNER JOIN hyoso ON hyosobun.hyoso_id = hyoso.id LEFT JOIN temp_conc_multi ON hyosobun.id = temp_conc_multi.hyosobun_id\n";
	
	my $t = mysql_exec->select($sql,1)->hundle;
	
	my $row_str = "";
	my $is_bun_header = 0;
	my $res;
	while (my $i = $t->fetch){
		$res->{$i->[0]}[0] = $i->[1]; #name
		$res->{$i->[0]}[1] = $i->[2]; #hsb_id
		$res->{$i->[0]}[2] = $i->[3]; #genkei_id
		$res->{$i->[0]}[3] = $i->[4]; #hyoso_id
		$res->{$i->[0]}[4] = $i->[5]; #bun_id
		$res->{$i->[0]}[5] = $i->[6]; #tani_id
		
		$res->{$i->[0]}[6] = $i->[7]; #dan_id
		$res->{$i->[0]}[7] = $i->[8]; #h5_id
	}
	
	return 0 if check_cancel();
	
	my $count = 0;
	my $row_num = 0;
	my @sort_id_ary;
	my $sort_genkei_id;
	my $dan_str_temp;
	my $dan_in_tag_str;
	
	foreach my $id (@{$hyosobun_id_list}){
		my $row_str = "";
		my $is_bun_header = 0;
		$count = $id - 24;
		$count = 0 if $count < 0;
		@sort_id_ary = (-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1);
		while ($count <= $id + 24){
			if ($res->{$count}[4] == 0) {
				$is_bun_header = 1;
			} else {
				if ($is_bun_header) {
					$is_bun_header = 0;
					$row_str .= "◇";
				}
				if ($res->{$count}[1]) {
					$row_str .= "@" if $count == $id;
					if ($count == $id) {
						if ($dan_in_tag_flg) {
							$dan_in_tag_str = 'dan:'.($res->{$count}[7] * 100 + $res->{$count}[6]);
							$dan_str_temp = $res->{$count}[5];
							#print "dan_str_temp=$dan_str_temp ";
							$dan_str_temp =~ s/dan:[1-9]+/$dan_in_tag_str/;
							#print "$dan_str_temp \n";
							$row_str = $dan_str_temp.$row_str;
						} else {
							$row_str = $res->{$count}[5].$row_str;
						}
					}
					$row_str .= "$res->{$count}[2]:$res->{$count}[3]";
				} else {
					$row_str .= "$res->{$count}[0]";
				}
				
				if ($count == $id) {
					$sort_id_ary[5] = $res->{$count}[3];
					$sort_genkei_id = $res->{$count}[2];
				} elsif ($count >= $id - 5 && $count <= $id + 5) {
					$sort_id_ary[(5 - $id + $count)] = $res->{$count}[2];
				}
			}
			$count++;
		}
		$row_str .= "\n";
		push @{$result}, $row_str;
		my $sort_sql = "INSERT INTO temp_conc_multi_sort (row_num, l5_id, l4_id, l3_id, l2_id, l1_id, center_id, r1_id, r2_id, r3_id, r4_id, r5_id, genkei_id) VALUES(";
		$sort_sql .= "$row_num, $sort_id_ary[0], $sort_id_ary[1], $sort_id_ary[2], $sort_id_ary[3], $sort_id_ary[4], $sort_id_ary[5],";
		$sort_sql .= " $sort_id_ary[6], $sort_id_ary[7], $sort_id_ary[8], $sort_id_ary[9], $sort_id_ary[10], $sort_genkei_id)";
		mysql_exec->do($sort_sql,1);
		$row_num++;
		
		return 0 if check_cancel();
	}
	return 1;
}

#ソート情報を出力する
sub output_sort_table{
	my $genkei_id_list = shift;
	my $sql;
	my @col_word_order = ("l1","l2","l3","l4","l5","r1","r2","r3","r4","r5","center");
	
	my $is_first = 1;
	my @ary;
	my $count;
	my $total_count = 0;
	$sql = "SELECT row_num";
	foreach my $col_word (@col_word_order) {
		$sql .= ", ".$col_word."_id";
	}
	$sql .= " FROM temp_conc_multi_sort";
	
	my $sort_file_path = &screen_code::plugin_path::assistant_option_folder."multi_sort.txt";
	unlink $sort_file_path if -f $sort_file_path;
	my $OUT;
	open($OUT, ">:encoding(utf8)", $sort_file_path);
	my $t = mysql_exec->select($sql,1)->hundle;
	while (my $i = $t->fetch){
		for (my $j = 0; $j < 12; $j++) {
			print $OUT "\t" if $j;
			print $OUT $i->[$j];
		}
		print $OUT "\n";
	}
	close($OUT);
}


#区切りIDリストから文章の詳細(ダブルクリックで表示するデータ)を求める
sub get_detail_by_part_target_id{
	#my $part_target_id_list = shift;
	my $result = shift;
	my $sql;
	
	foreach my $tani (@tani_ary) {
		my $part_target_id = part_target_id($tani);
		
		if ($tani eq 'dan' && $dan_in_tag_flg) {
		
			mysql_exec->do("DELETE FROM temp_part",1);
			$sql = "INSERT IGNORE INTO temp_part (id) SELECT (h5_id * 100) + dan_id FROM temp_conc_multi INNER JOIN hyosobun ON temp_conc_multi.hyosobun_id = hyosobun.id";
			
			mysql_exec->do($sql,1);
			
			$sql = "SELECT hyoso.name, temp_part.id, hyosobun.id, temp_conc_multi.genkei_id, temp_conc_multi.hyoso_id \n";
			$sql .= "FROM (hyosobun INNER JOIN temp_part ON ((temp_part.id MOD 100) = hyosobun.dan_id AND (temp_part.id DIV 100) = hyosobun.h5_id) ) ";
			$sql .= "INNER JOIN hyoso ON hyosobun.hyoso_id = hyoso.id ";
			$sql .= " LEFT JOIN temp_conc_multi ON hyosobun.id = temp_conc_multi.hyosobun_id ORDER BY hyosobun.id";
			my $t = mysql_exec->select($sql,1)->hundle;
			
			my $row_str = "";
			my $prev_part_id;
			my $prev_hsb_id;
			my $count = 0;
			while (my $i = $t->fetch){
				if ($count && $prev_part_id != $i->[1]) {
					$row_str = "$tani:$prev_part_id@".$row_str."//\n";
					push @{$result}, $row_str;
					$row_str = "";
				} elsif ($count && $i->[2] == $prev_hsb_id) {
					next;
				}
				if ($i->[3]) {
					$row_str .= "$i->[3]:$i->[4]";
				} else {
					$row_str .= "$i->[0]";
				}
				$prev_part_id = $i->[1];
				$prev_hsb_id = $i->[2];
				$count++;
				return 0 if check_cancel();
			}
			$row_str = "$tani:$prev_part_id@".$row_str."//\n";
			push @{$result}, $row_str;
			
		} else {
		
			mysql_exec->do("DELETE FROM temp_part",1);
			$sql = "INSERT IGNORE INTO temp_part (id) SELECT $part_target_id FROM temp_conc_multi INNER JOIN hyosobun ON temp_conc_multi.hyosobun_id = hyosobun.id";
			mysql_exec->do($sql,1);
			
			$sql = "SELECT hyoso.name, hyosobun.$part_target_id, hyosobun.id, temp_conc_multi.genkei_id, temp_conc_multi.hyoso_id \n";
			$sql .= "FROM (hyosobun INNER JOIN temp_part ON temp_part.id = hyosobun.$part_target_id)";
			$sql .= "INNER JOIN hyoso ON hyosobun.hyoso_id = hyoso.id ";
			$sql .= " LEFT JOIN temp_conc_multi ON hyosobun.id = temp_conc_multi.hyosobun_id ORDER BY hyosobun.id";
			my $t = mysql_exec->select($sql,1)->hundle;
			
			my $row_str = "";
			my $prev_part_id;
			my $prev_hsb_id;
			my $count = 0;
			while (my $i = $t->fetch){
				if ($count && $prev_part_id != $i->[1]) {
					$row_str = "$tani:$prev_part_id@".$row_str."//\n";
					push @{$result}, $row_str;
					$row_str = "";
				} elsif ($count && $i->[2] == $prev_hsb_id) {
					next;
				}
				if ($i->[3]) {
					$row_str .= "$i->[3]:$i->[4]";
				} else {
					$row_str .= "$i->[0]";
				}
				$prev_part_id = $i->[1];
				$prev_hsb_id = $i->[2];
				$count++;
				return 0 if check_cancel();
			}
			$row_str = "$tani:$prev_part_id@".$row_str."//\n";
			push @{$result}, $row_str;
			
		}
	}
	return 1;
}

#外部変数を取得 もっとも外側のtaniを指定するように変更し、ハッシュを返す
sub get_outvar_by_part_target_id{
	my $part_target_id_list = shift;
	my $result = shift;
	my $sql;
	
	$sql = "SELECT tani, tab, name, col FROM outvar WHERE tani = '$outbar_tani' ORDER BY CHAR_LENGTH(col), col";
	my $t = mysql_exec->select($sql,1)->hundle;
	my $id_where = "WHERE (";
	my $count = 0;
	foreach my $id (@{$part_target_id_list}){
		$id_where .= " OR " if $count > 0;
		$id_where .= "id = $id";
		$count++;
	}
	$id_where .= ")";
	my $select_str;
	my $table_str;
	$count = 0;
	my @col_names;
	while (my $i = $t->fetch){
		$select_str .= ", " if $count > 0;
		$select_str .= "$i->[1].$i->[3]";
		push @col_names, $i->[2];
		$table_str = "$i->[1]";
		$count++;
		return 0 if check_cancel();
	}
	return 1 unless $count;
	$sql = "SELECT $select_str, id FROM $table_str $id_where ORDER BY id";
	
	$t = mysql_exec->select($sql,1)->hundle;
	while (my $i = $t->fetch){
		my $row_str = "";
		my $col_num = 0;
		while ($col_num < $count){
			$row_str .= ", " if $col_num > 0;
			$row_str .= "$col_names[$col_num] = $i->[$col_num]";
			$col_num ++;
		}
		${$result}{$i->[$count]} = $row_str;
		return 0 if check_cancel();
	}
	return 1;
}


#主に単語でない場所をクリックした際の処理
sub undecorate_multiselect{
	my $self = shift;
	my $without_default = shift;
	
	$default_undecorate->($self) unless $without_default;
	
	foreach my $i (keys %{$self->{coordin}}) {
		if ($i ne 'decorated' && $self->{coordin}{$i}{selected}) {
			$self->{canvas}->delete( $self->{coordin}{$i}{selected_color} );
			$self->{coordin}{$i}{selected_color} = undef;
			$self->{coordin}{$i}{selected} = 0;
		}
	}
	
	return;
}

#選択した単語を枠で囲う処理
sub select_word{
	my $self = shift;
	my $id = shift;
	
	$self->{coordin}{$id}{selected} = !$self->{coordin}{$id}{selected};
	
	
	if ($self->{coordin}{$id}{selected}) {
		# show
		$self->{coordin}{$id}{selected_color} = $self->{canvas}->createRectangle(
			$self->{coordin}{$id}{x1} -2,
			$self->{coordin}{$id}{y1},
			$self->{coordin}{$id}{x2} +3,
			$self->{coordin}{$id}{y2} +1,
			-outline => 'blue',
			-width   => 2,
		);
	} else {
		if ( $self->{coordin}{$id}{selected_color} ){
			$self->{canvas}->delete( $self->{coordin}{$id}{selected_color} );
			$self->{coordin}{$id}{selected_color} = undef;
		}
	}
}

1;