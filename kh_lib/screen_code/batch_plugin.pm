package screen_code::batch_plugin;
use strict;
use utf8;

use screen_code::plugin_path;
use gui_widget::hinshi;

#use encoding "cp932";
use gui_window::main::menu;
use File::Path;
use Encode qw/encode decode/;
use Excel::Writer::XLSX;
use File::Basename;
use Time::Piece;
use Time::Local;
use POSIX 'strftime';

my %obj;
my $default_hinshi_method;
my $default_plot_method;
my $default_warning_method;
my $default_message_method;
my $default_wait_start_method;
my $default_wait_end_method;
my $r_command_method;
my $r_code_method;
my @hinshi_list;
my @hinshi_list_original;


my $waitDialog;
my $parent_win_obj;

my $win;
my $started_timestamp;

my $plot_new_method;
my $ratio_set_method;

sub start_waitDialog{
	my $d = [localtime];
	
	if ($win){
		$win->configure(-txt1 => "Start: ".strftime('%Y %m/%d %H:%M:%S',@{$d}));
		#print "gui_wait: re-using...\n";
	} else {
		#print "gui_wait: making new...\n";
		$win = $::main_gui->mw->WaitBox_kh(
			-title      => kh_msg->get('screen_code::assistant->batch_wait'),
			-txt1       => "Start: ".strftime('%Y %m/%d %H:%M:%S',@{$d}),
			-background => 'white',
			-takefocus  => 0
		);
	}

	if (
		   ($::config_obj->os eq 'win32')
		&& (eval 'require Tk::Icon' )
	) {
		$win->Show;
		require Tk::Icon;
		$win->setIcon(-file => Tk->findINC('1.ico') );
	} else {
		eval'$win->Icon(-image => \'window_icon\')';
		$win->Show;
	}
	
	$started_timestamp = timelocal(@{$d});
}

sub end_waitDialog{
	my $e = timelocal(localtime) - $started_timestamp;
	
	my ($h, $m, $s);
	if ($e >= 3600){
		$h = int($e / 3600);
		$e %= 3600;
		if ($h < 10){
			$h = "0"."$h";
		}
	} else {
		$h = "00";
	}
	
	if ($e >= 60){
		$m = int($e / 60);
		$e %= 60;
		if ($m < 10){
			$m = "0"."$m";
		}
	} else {
		$m = "00";
	}
	
	if ($e < 10){
		$s = "0"."$e";
	} else {
		$s = $e;
	}
	
	print "done:  $h:$m:$s\n";
	
	$win->unShow unless $::config_obj->os eq 'win32';
	$win->{bitmap}->destroy;
	$win->destroy;
	undef $win;
	
	return 1;
}


#ダイアログの開始
sub start_waitDialog_old {
	if (defined($waitDialog)) {
		$waitDialog->destroy;
		undef $waitDialog;
	}
	
	my $mw = $parent_win_obj;
	my $message = kh_msg->get('screen_code::assistant->batch_wait');
	$waitDialog = $mw->Toplevel();
	$waitDialog->transient($mw);
	$waitDialog->overrideredirect(1);
	$waitDialog->Popup( -popanchor => 'c' );
	my $frame = $waitDialog->Frame( -border => 5, -relief => 'groove' )->pack;
	$frame->Label( -text => kh_msg->get('screen_code::assistant->batch_wait'), )->pack( -padx => 5 );
	#$previousTime = timelocal(localtime);
	$waitDialog->update;
	$waitDialog->raise; #最前面に表示
}

sub end_waitDialog_old {
	if (defined($waitDialog)) {
		$waitDialog->destroy;
		undef $waitDialog;
    }
}

#テスト用にプラグイン実行部分を省いたもの
sub add_button_batch_test{
}
sub batch_calc_test{
}






sub add_button_batch{
	if (
		   ($::config_obj->os       eq 'win32')
		&& ($::config_obj->msg_lang eq 'jp'   )
	) {
		my $self = shift;
		my $rf = shift;
		if (-f &screen_code::plugin_path::batch_path) {
			$parent_win_obj = $self->{win_obj};
			
			mkpath('screen/temp');
			
			$rf->Label(
				-text => ' ',
				-font => "TKFN",
			)->pack(-side => 'right', -pady => 2,  -padx => 10, -anchor => 'se');
			$rf->Button(
				-text => kh_msg->get('screen_code::assistant->batch_plugin'),
				-width => 12,
				-font => "TKFN",
				-command => sub{&batch_calc($self);}
			)->pack(-side => 'right', -pady => 2,  -padx => 2, -anchor => 'se');
		} else {
			$rf->Label(
				-text => ' ',
				-font => "TKFN",
			)->pack(-side => 'right', -pady => 2,  -padx => 10, -anchor => 'se');
			$rf->Button(
				-text => kh_msg->get('screen_code::assistant->batch_plugin2'),
				-width => 14,
				-font => "TKFN",
				-command => sub{gui_OtherWin->open('http://khcoder.net/scr_monkin.html');}
			)->pack(-side => 'right', -pady => 2,  -padx => 2, -anchor => 'se');
		}
	}
}

#各分析ごとに異なる、実行に必要な初期データをオブジェクトに格納
sub set_process_settings{
	my $self = shift;
	#以下は分析毎の設定を用意し、そこから取得する
	my $process_name = ref $self;
	substr($process_name, 0, rindex($process_name, ":") + 1, '');
	print "process_name = $process_name\n";
	$obj{'process_name'} = $process_name;
	
	
	my $r_command_package;
	my $r_command_method_str;
	
    no strict 'refs';
    eval 'use screen_code::batch_plugin::'.$process_name.';';
	eval '$obj{\'need_pict_num\'} = screen_code::batch_plugin::'.$process_name.'::need_pict_num();';
	eval '$obj{\'setting_table\'} = screen_code::batch_plugin::'.$process_name.'::setting_table();';
	eval '$obj{\'worksheet_col_hash\'} = screen_code::batch_plugin::'.$process_name.'::worksheet_col_hash();';
	eval '$obj{\'display_colname_hash\'} = screen_code::batch_plugin::'.$process_name.'::display_colname_hash();';
	eval '$obj{\'worksheet_col\'} = screen_code::batch_plugin::'.$process_name.'::worksheet_col();';
	eval '$r_command_package = screen_code::batch_plugin::'.$process_name.'::r_command_package();';
	eval '$r_command_method_str = screen_code::batch_plugin::'.$process_name.'::r_command_method_str();';
	eval '$obj{\'match_str\'} = screen_code::batch_plugin::'.$process_name.'::match_str();';
	eval '$obj{\'replace_str\'} = screen_code::batch_plugin::'.$process_name.'::replace_str();';
	eval '$obj{\'r_command_method_type\'} = screen_code::batch_plugin::'.$process_name.'::r_command_method_type();';
	eval '$obj{\'discript_plot_ratio\'} = screen_code::batch_plugin::'.$process_name.'::discript_plot_ratio();';
	eval '$obj{\'other_expand_plot_num\'} = screen_code::batch_plugin::'.$process_name.'::other_expand_plot_num();';
	#先に一度なんらかのサブルーチンのアドレスを格納する必要がある
	$ratio_set_method = \&r_command_method_replace;
	eval '$ratio_set_method = \&screen_code::batch_plugin::'.$process_name.'::ratio_set_method;';
	
	#プロット画面の開始を置き換え
    use gui_window;
    $default_plot_method = \&gui_window::open;
    *gui_window::open = \&dummy_method;

    #エラーメッセージ表示を置き換え
    use gui_errormsg;
    $default_warning_method = \&gui_errormsg::open;
    *gui_errormsg::open = \&dummy_warning;
    
    #待機メッセージダイアログを置き換え
    use gui_wait;
	$default_wait_start_method = \&gui_wait::start;
    *gui_wait::start = \&dummy_wait_start;
	$default_wait_end_method = \&gui_wait::end;
    *gui_wait::end = \&dummy_wait_end;
    
    #
	use Tk;
	$default_message_method = \&Tk::messageBox;
	*Tk::messageBox = \&dummy_message;
	
	
	#eval '$sub_temp = \&'.$window_package_name.'::dummy_method;'; #クラスのメソッドを取得し、別の変数からそのメソッドを参照する
	#eval '*'.$window_package_name.'::dummy_method = $sub_temp'; #クラスのメソッドを別のサブルーチンと入れ替え
	
	#print "r_command_package=$r_command_package r_command_method_str=$r_command_method_str\n";
	
	
	unless ($r_command_method) {
		#先に一度なんらかのサブルーチンのアドレスを格納する必要がある
		$r_command_method = \&r_command_method_replace;
		
		eval 'use '.$r_command_package.';';
		eval '$r_command_method = \&'.$r_command_package.'::'.$r_command_method_str.';';
		eval '*'.$r_command_package.'::'.$r_command_method_str.' = \&r_command_method_replace;';
		$obj{'r_command_package'} = $r_command_package;
		$obj{'r_command_method_str'} = $r_command_method_str;
	}
	
	
	unless ($r_code_method) {
	    use kh_r_plot;
	    $r_code_method = \&kh_r_plot::R_device;
	    *kh_r_plot::R_device = \&r_code_replace;
	    $plot_new_method = \&kh_r_plot::new;
	    *kh_r_plot::new = \&r_new_replace;
	}
}

#Rの処理の一部分を画像ファイル表示用処理に置き換えるメソッド
sub r_command_method_replace{
    no strict 'refs';
	my %args = @_;
	#print "called r_command_method_replace \n";
	my $origin_str;
	if ($obj{'r_command_method_type'}) {
		$origin_str = $r_command_method->(%args);
	} else {
		$origin_str = $r_command_method->();
	}
	#print "get origin_str\n";
	
	if (exists($obj{'match_str'}) && exists($obj{'replace_str'}) && $obj{'display_option'} && !$obj{'do_other_expand'}) {
		$origin_str =~ s/$obj{'match_str'}/$obj{'replace_str'}/;
		my $setting_string;
		my @setting_str_split;
		my $count;
		my @setting_col_sorted = ();
		
		#順番の固定化にExcelでの列番号を利用するが、先頭の1個が空白になるためshiftで削除する必要がある
		for my $col_name (keys $obj{'worksheet_col_hash'}) {
			$setting_col_sorted[$obj{'worksheet_col_hash'}->{$col_name}] = $col_name;
		}
		shift @setting_col_sorted;
		
		my $display_colname;
		$setting_string = '';
		for my $col_name (@setting_col_sorted) {
			unless ($setting_string) {
				$setting_string = 'settings <- c(';
			} else {
				$setting_string = $setting_string.', ';
			}
			if (exists($obj{'display_colname_hash'}{$col_name})) {
				$display_colname = $obj{'display_colname_hash'}{$col_name};
			} else {
				$display_colname = $col_name;
			}
			
			$setting_string = $setting_string.'"'.$display_colname.'", "';
			@setting_str_split = split(/,/, $obj{'setting_description_hash'}->{$col_name});
			
			unless (exists($obj{'whole_setting_exclusion_hash'}{$col_name})) {
				$count = 0;
				foreach my $s (@setting_str_split) {
					$setting_string = $setting_string.',' if $count;
					$setting_string = $setting_string.$s;
					
					$count += length($s);
					if ($count > 30) {
						$setting_string = $setting_string.'\n';
						$count = 0;
					}
				}
			}
			$setting_string = $setting_string.'"';
		}
		$setting_string = $setting_string.')';
		
		#print "\n r_command_method_replace \n $setting_string \n\n";
		
		$origin_str =~ s/replace_target/$setting_string/;
		#print "\n".$origin_str."\n";
	}
	return $origin_str;
}

#プロットサイズ決定処理を置き換えるメソッド
sub r_code_replace{
    no strict 'refs';
	my $self  = shift;
	my $path  = shift;
	my $width = shift;
	my $height = shift;
	my $return;
	
	#print "r_code_replace start\n";
	if (exists($obj{'match_str'}) && exists($obj{'replace_str'}) && $obj{'display_option'} && !$obj{'do_other_expand'}) {
		$height = $self->{height};
		$return = $r_code_method->($self, $path, $width, $height);
		#$self->{height} = $height;
		#$self->{width} = $width;
		if ($self->{name} =~ /$obj{'other_expand_plot_num'}/) {
		#if ($self->{name} =~ /_1$/) {
			#print "r_code_replace 1 self = $self\n";
			$obj{'save_target_plot'} = $self;
			#print "r_code_replace 1 save_target_plot = $obj{'save_target_plot'}\n\n";
		}
	} else {
		$return = $r_code_method->($self, $path, $width, $height);
		#$self->{height} = $height;
		#$self->{width} = $width;
		if ($self->{name} =~ /$obj{'other_expand_plot_num'}/) {
		#if ($self->{name} =~ /_1$/) {
			#print "r_code_replace 2 self = $self\n";
			$obj{'save_target_plot'} = $self;
			#print "r_code_replace 2 save_target_plot = $obj{'save_target_plot'}\n\n";
		}
	}
	return $return;
}

sub r_new_replace{
	my $class = shift;
	my %args = @_;
	print "r_new_replace start\n";
	
	my $use_option_table = 0;
	if (exists($obj{'match_str'}) && exists($obj{'replace_str'}) && $obj{'display_option'} && !$obj{'do_other_expand'}) {
		print "match_str=".$obj{'match_str'}." replace_str=".$obj{'replace_str'}." display_option=".$obj{'display_option'}." \n\n";
		$use_option_table = 1;
	}
	print "use_option_table $use_option_table\n";
	$args{width}  = $::config_obj->plot_size_codes unless defined($args{width});
	$args{height} = $::config_obj->plot_size_codes unless defined($args{height});
	#print $args{height}." height \n";
	
	%args = %{$ratio_set_method->($use_option_table,%args)};
	#print $args{height}." height after\n";
	
	my $return = $plot_new_method->($class, %args);
	return $return;
}

#置き換えたメソッドを元に戻す
sub restore_subroutine{
	#print "restore \n";
	if ($default_hinshi_method) {
		*gui_widget::hinshi::selected = $default_hinshi_method;
		undef $default_hinshi_method;
	}
	
	if ($default_plot_method) {
		*gui_window::open = $default_plot_method;
		undef $default_plot_method;
	}
	
	if ($default_warning_method) {
    	*gui_errormsg::open = $default_warning_method;
		undef $default_warning_method;
	}
	
	if ($default_message_method) {
    	*Tk::messageBox = $default_message_method;
		undef $default_message_method;
	}
	
	if ($default_wait_start_method) {
    	*gui_wait::start = $default_wait_start_method;
		undef $default_wait_start_method;
	}
	
	if ($default_wait_end_method) {
    	*gui_wait::end = $default_wait_end_method;
		undef $default_wait_end_method;
	}
	
	if ($default_wait_end_method) {
    	*gui_wait::end = $default_wait_end_method;
		undef $default_wait_end_method;
	}
	
	if ($r_code_method) {
	    *kh_r_plot::R_device = $r_code_method;
	    undef $r_code_method;
	    *kh_r_plot::new = $plot_new_method;
	    undef $plot_new_method;
	}
	
	if ($r_command_method) {
		my $r_command_package = $obj{'r_command_package'};
		my $r_command_method_str = $obj{'r_command_method_str'};
		
		eval '*'.$r_command_package.'::'.$r_command_method_str.' = $r_command_method;';
		undef $r_command_method;
	}
}

sub dummy_method{
	#print "batch dummy_method\n";
}

sub dummy_warning{
	#print "batch dummy_warning\n";
	my $class = shift;
	my %args = @_;
	my $self = \%args;
	bless $self, "$class"."::"."$args{type}";
	
	$self->{msg} = $self->get_msg;
	unless ($self->{type} eq 'msg') {
		#print "hoge!!!!\n";
		($self->{caller_pac}, $self->{caller_file}, $self->{caller_line}) = caller;
		$self->{msg} .= "\n\n";
		$self->{msg} .= "$self->{caller_file} line $self->{caller_line}";
	}
	die "message gui_errormsg: $self->{msg}\n";
}

sub dummy_message{
	#print "batch dummy_message\n";
	return "ok";
}

sub dummy_wait_start{
	#print "batch dummy_wait_start\n";
	my $class = shift;
	my $self = {};
	bless $self, $class;

	return $self;
}
sub dummy_wait_end{
	#print "batch dummy_wait_end\n";
	return 1;
}


#その他の設定(出力するファイルのパス、画像中オプション表示可否、拡張子違いのファイル出力可否)を、オプションファイルから取得
sub get_path_from_option{
	my $self = shift;
	
	my $file_option = shift;
	my $result_path = "";
	if (-f $file_option) {
		my $IN;
		open($IN, "<:encoding(utf8)", $file_option);
		
		#ファイルパス
		my $line = <$IN>;
		chomp($line);
		
		my $now = localtime;
		#そのフォルダ内に画像保管、ファイル名称は分析名と実行時のタイムスタンプ
		$result_path = $line;
		$obj{'pict_folder'} = $result_path;
		$result_path .= '/'.$obj{'analysis_name'}.$now->ymd.'_'.$now->hms(".").".xlsx";
		$obj{'sub_folder_name'} = $now->ymd.'_'.$now->hms(".");
		$obj{'HTML_file_path'} = $obj{'pict_folder'}.'/'.$obj{'analysis_name'}.$now->ymd.'_'.$now->hms('.').'.html';
		#print "result_path=$result_path\n";
		mkpath(encode("cp932", $obj{'pict_folder'}));
		
		#オプション表示
		$line = <$IN>;
		chomp($line);
		$obj{'display_option'} = $line;
		if ($obj{'display_option'}) {
			#print "display_option ON \n";
		} else {
			#print "display_option OFF \n";
		}
		
		#EMF
		$line = <$IN>;
		chomp($line);
		$obj{'need_EMF'} = $line;
		if ($obj{'need_EMF'}) {
			#print "need_EMF ON \n";
		} else {
			#print "need_EMF OFF \n";
		}
		
		
		#PDF
		$line = <$IN>;
		chomp($line);
		$obj{'need_PDF'} = $line;
		if ($obj{'need_PDF'}) {
			#print "need_PDF ON \n";
		} else {
			#print "need_PDF OFF \n";
		}
	}
	
	return $result_path;
}

#オプションファイルを作成する
sub save_option_file{
	my $self = shift;
	my $file_option = &screen_code::plugin_path::assistant_option_folder."batch_option.txt"; #実行設定ファイル、プロジェクト毎に記録する可能性もある
	unlink $file_option if -f $file_option;
	
	my $process_name = ref $self;
	substr($process_name, 0, rindex($process_name, ":") + 1, '');
    no strict 'refs';
    eval 'use screen_code::batch_plugin::'.$process_name.';';
	eval '$obj{\'analysis_name\'} = screen_code::batch_plugin::'.$process_name.'::get_analysis_name();';
	
	my $OUT;
	open($OUT, ">:encoding(utf8)", $file_option);
	
		
	my $font_str = gui_window->gui_jchar($::config_obj->font_main);
	print $OUT "フォント=$font_str\n";
	print $OUT "分析名=".$obj{'analysis_name'}."\n";
	print $OUT "品詞=".join(",",@{$obj{'checked_hinshi_word'}})."\n";
	print $OUT "外部変数=";
	my $row = 0;
	#if ($self->{opt_body_var}) {
	#	foreach my $i (@{$self->{vars}}){
	#		print $OUT "," if $row;
	#		print $OUT "$i->[0]";
	#		$row++;
	#	}
	#}
	
	my $h = mysql_outvar->get_list;
	
	foreach my $i (@{$h}){
		if ($i->[1] =~ /^_topic_[0-9]+$|^_topic_docid$/ && $self->{no_topics}) {
			next;
		}
		
		print $OUT "," if $row;
		print $OUT "$i->[1]";
		$obj{'outvar_list'}{$row} = "$i->[1]";
		$obj{'outvar_list'}{"$i->[1]"} = $row;
		$row++;
	}
	print $OUT "\n";
	#my @tani_list = @{get_tani_list()};
	
	my @list0 = ("bun","dan","h5","h4","h3","h2","h1");

	my $len = 0;

	my @list1;
	foreach my $i (@list0){
		if (
			mysql_exec->select(
				"select status from status where name = \'$i\'",1
			)->hundle->fetch->[0]
		){
			push @list1, $i;
		}
	}
	
	my @tani_list;
	my %name = (
		"bun" => "文",
		"dan" => "段落",
		"h5"  => "H5",
		"h4"  => "H4",
		"h3"  => "H3",
		"h2"  => "H2",
		"h1"  => "H1",
	);
	
	my $dan_exist = 0;
	my $h_min_tani= "";
	my $h_min_tani_str = "";
	my $dan_in_cell = 0;
	#現在のプロジェクトに存在する単位を取得し、そのリストを作成する
	#加えて、セル内段落があるケースについても調べる
	foreach my $i (@list1){
		if (exists($name{$i})) {
			push @tani_list, $name{$i};
			$dan_exist = 1 if $i eq "dan";
			if ($i =~ /h/) {
				$h_min_tani = $i;
				$h_min_tani_str = $name{$i};
			}
		}
	}
	
	if ($dan_exist && $h_min_tani ne "") {
		my $t = mysql_exec->select("SELECT COUNT(*) FROM dan",1)->hundle;
		my $dan_row = $t->fetch->[0];
		$t = mysql_exec->select("SELECT COUNT(*) FROM $h_min_tani",1)->hundle;
		my $h_min_row = $t->fetch->[0];
		#print "dan_row=$dan_row h_min_row=$h_min_row\n";
		$dan_in_cell = 1 if $dan_row != $h_min_row;
	}
	
	if ($dan_in_cell == 1) {
 		print $OUT "集計単位自動=段落\t".$h_min_tani_str."\n";
	} elsif ($h_min_tani ne "") {
 		print $OUT "集計単位自動=文\t".$h_min_tani_str."\n";
	} elsif ($dan_exist) {
 		print $OUT "集計単位自動=文\t段落\n";
	} elsif ($dan_exist) {
 		print $OUT "集計単位自動=文\n";
	}
	
	print $OUT "単位=".join(",",@tani_list)."\n";
	$obj{'has_more_words'} = {};
	if ($dan_exist && ($dan_in_cell == 1 || $h_min_tani eq "")) {
		my $sql = "SELECT hyosobun.dan_id, hyosobun.hyoso_id, hyoso.name, CHAR_LENGTH(hyoso.name) \n";
		$sql .= "FROM hyosobun INNER JOIN hyoso ON hyosobun.hyoso_id = hyoso.id ORDER BY hyosobun.id";
		my $t = mysql_exec->select($sql,1)->hundle;
		my $tag_id_temp = 1;
		my $counts = 0;
		$obj{'has_more_words'}{$h_min_tani_str} = 0;
		while (my $i = $t->fetch){
			if ($i->[0] < 10) {
				#print $i->[0].":".$i->[3]." ".$i->[2]."\n";
				if ($tag_id_temp != $i->[0]) {
					#print "count $counts \n";
					if ($counts > 1000) {
						print "1000over dan\n";
						$obj{'has_more_words'}{'段落'} = 1;
						last;
					}
					$tag_id_temp = $i->[0];
					$counts = $i->[3];
				} else {
					$counts += $i->[3];
				}
			}
		}
		if ($counts > 1000) {
			$obj{'has_more_words'}{'段落'} = 1;
		}
	}
	
	if ($h_min_tani ne "") {
		my $sql = "SELECT hyosobun.".$h_min_tani."_id, hyosobun.hyoso_id, hyoso.name, CHAR_LENGTH(hyoso.name) \n";
		$sql .= "FROM hyosobun INNER JOIN hyoso ON hyosobun.hyoso_id = hyoso.id ORDER BY hyosobun.id";
		my $t = mysql_exec->select($sql,1)->hundle;
		my $tag_id_temp = 1;
		my $counts = 0;
		$obj{'has_more_words'}{$h_min_tani_str} = 0;
		while (my $i = $t->fetch){
			if ($i->[0] < 10) {
				#print $i->[0].":".$i->[3]." ".$i->[2]."\n";
				if ($tag_id_temp != $i->[0]) {
					#print "count $counts \n";
					if ($counts > 1000) {
						print "1000over htag\n";
						$obj{'has_more_words'}{$h_min_tani_str} = 1;
						last;
					}
					$tag_id_temp = $i->[0];
					$counts = $i->[3];
				} else {
					$counts += $i->[3];
				}
			}
		}
		if ($counts > 1000) {
			$obj{'has_more_words'}{$h_min_tani_str} = 1;
		}
	}
 	#print $OUT "自動設定=".$auto_str."\n";
	close($OUT);
}

#現在のプロジェクトに存在する単位を取得し、そのリストを作成する
sub get_tani_list{
	my @list0 = ("bun","dan","h5","h4","h3","h2","h1");

	my $len = 0;

	my @list1;
	foreach my $i (@list0){
		if (
			mysql_exec->select(
				"select status from status where name = \'$i\'",1
			)->hundle->fetch->[0]
		){
			push @list1, $i;
		}
	}
	
	my @tani_list;
	my %name = (
		"bun" => "文",
		"dan" => "段落",
		"h5"  => "H5",
		"h4"  => "H4",
		"h3"  => "H3",
		"h2"  => "H2",
		"h1"  => "H1",
	);
	
	my $dan_exist = 0;
	my $h_min_tani= "";
	foreach my $i (@list1){
		if (exists($name{$i})) {
			push @tani_list, $name{$i};
			$dan_exist = 1 if $i eq "dan";
			$h_min_tani = $i if $i =~ /h/;
		}
	}
	
	return \@tani_list;
}

sub cluster_R_test{
	my $self = shift;
	my $check_num_flag = shift;
	
	unless ( eval(@{$self->hinshi}) ){
		return 0;
	}
	
	my $check_num = mysql_crossout::r_com->new(
		tani     => $self->tani,
		tani2    => $self->tani,
		hinshi   => $self->hinshi,
		max      => $self->max,
		min      => $self->min,
		max_df   => $self->max_df,
		min_df   => $self->min_df,
	)->wnum;
	
	if ($check_num < 3){
		return 0;
	}
	
	my $default_cls = int( sqrt( $check_num ) + 0.5);
	$obj{'default_cls'} = $default_cls;
	if ($check_num_flag) {
		return 0;
	}
	
	my $r_command = mysql_crossout::r_com->new(
		tani   => $self->tani,
		tani2  => $self->tani,
		hinshi => $self->hinshi,
		max    => $self->max,
		min    => $self->min,
		max_df => $self->max_df,
		min_df => $self->min_df,
		rownames => 0,
		sampling => $self->{words_obj}->sampling_value,
	)->run;

	# クラスター分析を実行するためのコマンド
	$r_command .= "d <- t(d)\n";
	$r_command .= "# END: DATA\n";
	
	#print "r_command = ".$r_command."\n";
	
    no strict 'refs';
	my %args = (
		$self->{cls_obj}->params,
		font_size      => $self->{font_obj}->font_size,
		font_bold      => $self->{font_obj}->check_bold_text,
		plot_size      => $self->{font_obj}->plot_size,
		r_command      => $r_command,
		plotwin_name   => 'word_cls',
		data_number      => $check_num,
	);
	
	#print "args data=".$args{font_size}."\n";
	#print "args data=".$args{method_dist}."\n";
	
	my $fontsize = $args{font_size};
	#my $fontsize = 1;
	my $cluster_number = $args{cluster_number};

	my $old_simple_style = 0;
	if ( $args{cluster_color} == 0 ){
		$old_simple_style = 1;
	}

	my $bonus = 0;
	$bonus = 8 if $old_simple_style;

	if ($cluster_number =~ /auto/i){
		$cluster_number = $default_cls;
	}

	my $par = 
		"par(
			mai=c(0,0,0,0),
			mar=c(1,2,1,0),
			omi=c(0,0,0,0),
			oma=c(0,0,0,0) 
		)\n"
	;

	$r_command .= "font_size <- $fontsize\n";
	
	$r_command .= "labels <- rownames(d)\n";
	$r_command .= "rownames(d) <- NULL\n";

	$r_command .= "freq <- NULL\n";
	$r_command .= "for (i in 1:nrow(d)) {\n";
	$r_command .= "	freq[i] = sum( d[i,] )\n";
	$r_command .= "}\n";

	$r_command .= "

if (exists(\"doc_length_mtr\")){
	leng <- as.numeric(doc_length_mtr[,2])
	leng[leng ==0] <- 1
	d <- t(d)
	d <- d / leng
	d <- d * 1000
	d <- t(d)
}

" unless $args{method_dist} eq 'binary';

	if ($args{method_dist} eq 'euclid'){
		$r_command .= "d <- t( scale( t(d) ) )\n";
	}
	# euclidの場合は抽出語ごとに標準化
		# euclid係数を使う主旨からすると、標準化は不要とも考えられるが、
		# 標準化を行わないと連鎖の程度が激しくなり、クラスター分析として
		# の用をなさなくなる場合がまま見られる。

	$r_command .= "method_dist <- \"$args{method_dist}\"\n";
	$r_command .= "method_clst <- \"$args{method_mthd}\"\n";

	$r_command .= '
library(amap)
dj <- Dist(d,method=method_dist)

if (
	   ( as.numeric( R.Version()$major ) >= 3 )
	&& ( as.numeric( R.Version()$minor ) >= 1.0)
){                                                      # >= R 3.1.0
	if (method_clst == "ward"){
		method_clst  <-  "ward.D2"
	}
	hcl <- hclust(dj,method=method_clst)
} else {                                                # <= R 3.0
	if (method_clst == "ward"){
		dj <- dj^2
		hcl <- hclust(dj,method=method_clst)
		hcl$height <- sqrt( hcl$height )
	} else {
		hcl <- hclust(dj,method=method_clst)
	}
}'
	;
	$r_command .= "\n$par";
	
	$r_command .= '
ary <- cbind(length(hcl$height):1, hcl$height)
colnames(ary) <- c("num", "height")
ary <- ary[order(ary[,1]),]
item_num <- nrow(ary)
if (method_clst != "ward") {
    item_num <- item_num / 2
}
average <- NULL
if (item_num <= 3) {
    average <- 0
} else {
    average <- (ary[1,2] - ary[item_num,2]) / (item_num - 1)
}
cls_num_ary <- NULL
merge_ary <- NULL
if (average != 0) {
    for (i in 3:item_num) {
        before <- ary[(i-2),2] - ary[(i-1),2]
        merge_ary <- c(merge_ary,before)
        after <- ary[(i-1),2] - ary[i,2]
        if (before / max(after, average) >= 2) {
            cls_num_ary <- c(cls_num_ary, (i-1))
            if (length(cls_num_ary) >= 3){
                break
            }
        }
    }
}
if (!is.null(cls_num_ary)) {
    print(cls_num_ary)
} else {
    print("null")
}
'
	;
	
	#print "\n".$r_command."\n";
	
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	$::config_obj->R->send("the_warning <<- \"\"\n");
	#print "cluster_R_test lock ok.\n";
	$::config_obj->R->send("Sys.setlocale(category=\"LC_ALL\",locale=\"Japanese\")");
	$::config_obj->R->send($r_command);
	#print "cluster_R_test send ok.\n";
	$self->{r_msg} = $::config_obj->R->read;
	#print "cluster_R_test read ok.\n";
	$::config_obj->R->send('dev.off()');
	#print "cluster_R_test dev.off ok.\n";
	$::config_obj->R->unlock;
	#print "cluster_R_test unlock ok.\n";
	$::config_obj->R->output_chk(1);
	
	print "msg:".$self->{r_msg}."\n";
	
	if ($self->{r_msg} =~ /null/i || $self->{r_msg} =~ /Error/i){
		return 0;
	} else {
		$self->{r_msg} =~ s/\[1\]//;
		$self->{r_msg} =~ s/^\s*//;
		my @split = split(/ +/, $self->{r_msg});
		$obj{'recalc_array'} = \@split;
		$obj{'recalc_need'} = int(@split);
	}
	
	return 1;
}

sub batch_calc{
	%obj = (); #無名ハッシュ生成は{}を使う
	$obj{'original_setting'} = {}; #設定画面で決定されていた設定を保存するハッシュを初期化
	
	my $self = shift;
	
	#品詞の初期設定
	@hinshi_list_original = @{$self->hinshi()};
	$obj{'checked_hinshi_word'} = checked_hinshi_word($self);
	$obj{'outvar_list'} = (); #外部変数リスト
	
	&save_option_file($self);
	my $file_config = &screen_code::plugin_path::assistant_option_folder."batch_config.ini"; #実行設定ファイル、プロジェクト毎に記録する可能性もある
	unlink $file_config if -f $file_config;
	my $plugin_file_config = &screen_code::plugin_path::assistant_option_folder."batch_config2.ini"; #プラグイン内の名称を使った設定リストファイル
	unlink $plugin_file_config if -f $plugin_file_config;
	my $inBatch_file_config = &screen_code::plugin_path::assistant_option_folder."batch_config3.ini"; #見出し用インデックスファイル
	unlink $inBatch_file_config if -f $inBatch_file_config;
	my $file_option = &screen_code::plugin_path::assistant_option_folder."batch_name.txt";
	unlink $file_option if -f $file_option;
	
	
	my $system_err = 0;
	$! = undef;
	my $plugin_rtn = system(&screen_code::plugin_path::batch_path);
	print $plugin_rtn." rtn \n";
	$system_err = 1 if ($!);
	#エラー発生
	if ($plugin_rtn == 0 || $system_err != 0) {
		return;
	#正常終了
	} elsif ($plugin_rtn == 256) {
		return unless -f $file_config;
	}
	
	my $path = &get_path_from_option($self, $file_option);
	my $check_rm_open = $self->{check_rm_open};
	
	if (-f $file_config && $path) {
		start_waitDialog();
		&set_process_settings($self);
		$self->{check_rm_open} = 1;
	
		my $IN;
		open($IN, "<:encoding(utf8)", $file_config);
		my $IN_plugin;
		open($IN_plugin, "<:encoding(utf8)", $plugin_file_config);
		
		#print $path."\n";
		my $folder_name =dirname($path);
		#$obj{'workbook'} = Excel::Writer::XLSX->new($::config_obj->os_path($path));
		#$obj{'worksheet'} = $obj{'workbook'}->add_worksheet('実行内容',1);;
		#$obj{'worksheet_row'} = 2;
		#$obj{'worksheet_format'} = $obj{'workbook'}->add_format( color => 'black');
		#$obj{'worksheet_format'}->set_border(1);
		#全体設定出力用のハッシュ
		$obj{'whole_setting_hash'} = {};
		#Disableになっており全体設定から取り除くものをまとめる
		$obj{'whole_setting_exclusion_hash'} = {};
		#フィルター対象設定をまとめるハッシュ
		$obj{'filterTypes'} = {};
		#設定を纏める配列
		$obj{'file_path_for_HTML'} = [];
		$obj{'title_path_for_HTML'} = [];
		$obj{'setting_description_for_HTML'} = [];
		$obj{'batch_setting_description_for_HTML'} = [];
		$obj{'plugin_setting_description_for_HTML'} = [];
		#見出し出力用のハッシュ
		$obj{'index_hash'} = {};
		$obj{'count'} = 0; #実行した回数
		$obj{'do_other_expand'} = 0;

		#&set_header();
		
		$obj{'last_timestamp'} = localtime;
		
		#実行設定ファイルには、１行ごとに1実行分の設定が入っている
		while (my $line = <$IN>) {
			my $line_plugin = <$IN_plugin>;
			chomp($line_plugin);
			$obj{'plugin_setting_description_for_HTML'}[$obj{'count'}] = $line_plugin;
			
			
			$obj{'entry_num'} = 0;
			$obj{'ignore_num'} = 0;
			$obj{'need_calculation'} = 0; #布置される語数の計算が必要かどうか
			$obj{'setting_description_hash'} = {};
			$obj{'batch_setting_description_for_HTML'}[$obj{'count'}] = '';
			
			#品詞の設定を擬似的に元に戻す
			@hinshi_list = @hinshi_list_original;
			#KHCoderの元の設定を取得する
			for my $col_name (keys $obj{'worksheet_col_hash'}) {
				my $hash_str = $obj{'setting_table'}->{$col_name}{'hash'};
    			eval '&get_from_window_'.$obj{'setting_table'}->{$col_name}{'type'}.'($self, $col_name, $hash_str);';
		
				if ($obj{'count'} == 0 && exists($obj{'setting_table'}->{$col_name}{'widget_hash_name'})) {
					my $widgetHash = $obj{'setting_table'}->{$col_name}{'widget_hash_name'};
					#print "$col_name widgetHash=$widgetHash\n";
					my $widgetHashRef = get_target_ref($self, $widgetHash);
					my $state = $widgetHashRef->cget('-state');
					#print "  state=$state\n\n";
					if ($state eq 'disabled') {
						$obj{'whole_setting_exclusion_hash'}{$col_name} = 1;
					} elsif ($state eq '') {
						my $bg = $widgetHashRef->cget('-background');
						#print "  background=$bg\n\n";
						if ($bg eq 'gray') {
							$obj{'whole_setting_exclusion_hash'}{$col_name} = 1;
						}
					}
				}
			}
			
			chomp($line);
			#数による語の取捨選択の設定がひとつでも存在した場合、KHCoderが持つ数の設定はすべて無視する必要がある
			if ($line =~ /最小出現数/) {
				#print "exists num_settings \n";
				
				set_entry($self, '最大出現数', '', 'words_obj->ent_max', 1);
				set_entry($self, '最大文章数', '', 'words_obj->ent_max_df', 1);
			}
			
			
			my @splited = split(/,/, $line);
			foreach my $item (@splited) {
				my @splited_item = split(/=/, $item);
				#検索対象設定名はここで取得するのが一番正確
				unless (exists($obj{'filterTypes'}{$splited_item[0]})){
					$obj{'filterTypes'}{$splited_item[0]} = {};
				}
				if ($obj{'batch_setting_description_for_HTML'}[$obj{'count'}] ne '') {
					$obj{'batch_setting_description_for_HTML'}[$obj{'count'}] .= ',';
				}
				$obj{'batch_setting_description_for_HTML'}[$obj{'count'}] .= $splited_item[0].':\''.$splited_item[1].'\'';
				set_config($self, $splited_item[0], $splited_item[1]);
			}
			calculate_word_min($self) if $obj{'need_calculation'} == 1;
			
			$obj{'recalc_need'} = 0;
			$obj{'recalc_count'} = 0;
			if ($obj{'analysis_name'} eq 'クラスター分析') {
				my $cls_num = $obj{'setting_description_hash'}->{'クラスター数'};
				if ($cls_num eq '文錦推奨値') {
					if (cluster_R_test($self, 0)) {
						$obj{'batch_setting_description_temp'} = $obj{'batch_setting_description_for_HTML'}[$obj{'count'}];
						$obj{'plugin_setting_description_temp'} = $obj{'plugin_setting_description_for_HTML'}[$obj{'count'}];
						RECALC:
						#print "recalc_need=".$obj{'recalc_need'}."\n";
						print "recalc_cls_num=".$obj{'recalc_array'}[$obj{'recalc_count'}]."\n";
						
						my $temps = $obj{'batch_setting_description_temp'};
						$temps =~ s/文錦推奨値/$obj{'recalc_array'}[$obj{'recalc_count'}]/;
						$obj{'batch_setting_description_for_HTML'}[$obj{'count'}] = $temps;
						$temps = $obj{'plugin_setting_description_temp'};
						$temps =~ s/文錦推奨値/$obj{'recalc_array'}[$obj{'recalc_count'}]/;
						$obj{'plugin_setting_description_for_HTML'}[$obj{'count'}] = $temps;
						set_entry($self, 'クラスター数', $obj{'recalc_array'}[$obj{'recalc_count'}], 'cls_obj->entry_cluster_number');
					} else {
						set_entry($self, 'クラスター数', 'Auto', 'cls_obj->entry_cluster_number');
					}
				} elsif ($cls_num eq 'Auto') {
					&cluster_R_test($self, 1);
					print "cls_num=Auto defalut=".$obj{'default_cls'}."\n";
					set_entry($self, 'クラスター数', $obj{'default_cls'}, 'cls_obj->entry_cluster_number');
						my $temps = $obj{'batch_setting_description_for_HTML'}[$obj{'count'}];
						$temps =~ s/Auto/$obj{'default_cls'}/;
						$obj{'batch_setting_description_for_HTML'}[$obj{'count'}] = $temps;
						print "$temps\n";
						$temps = $obj{'plugin_setting_description_for_HTML'}[$obj{'count'}];
						$temps =~ s/Auto/$obj{'default_cls'}/;
						$obj{'plugin_setting_description_for_HTML'}[$obj{'count'}] = $temps;
						print "$temps\n";
					#$obj{'setting_description_hash'}->{'クラスター数'} = $obj{'default_cls'};
				}
			}
			
			#print "現在の設定の布置される語数を計算=".calculate_words_count($self)."\n";
			
			
			#見出し用ハッシュに追加
			my $index_parent;
			my $index_key = '';
			if (exists($obj{'setting_description_hash'}{'文章と見なす単位'})) {
				$index_parent = 'なし';
			} else {
				$index_parent = $obj{'setting_description_hash'}{'集計単位'};
			}
			my @index_keys_array = ('布置される語数','無視語数','最小出現数','最大出現数','最小文章数','最大文章数');
			#for my $key_name (@index_keys_array) {
			#	#print "make index $key_name $index_key\n";
			#	if (exists($obj{'setting_description_hash'}{$key_name})) {
			#		if ($obj{'setting_description_hash'}{$key_name} ne '') {
			#			$index_key .= ',' if $index_key ne '';
			#			$index_key .= $key_name.'='.$obj{'setting_description_hash'}{$key_name};
			#		}
			#	}
			#}
			#見出しは布置される語数のみとする
			$index_key = "布置される語数=".calculate_words_count($self);
			unless (exists($obj{'index_hash'}{$index_parent})){
				$obj{'index_hash'}{$index_parent} = {};
				$obj{'index_hash'}{$index_parent}{'label'} = $index_parent;
				$obj{'index_hash'}{$index_parent}{'subItems'} = {};
			}
			unless ($obj{'index_hash'}{$index_parent}{'subItems'}{$index_key}) {
				$obj{'index_hash'}{$index_parent}{'subItems'}{$index_key} = {};
				$obj{'index_hash'}{$index_parent}{'subItems'}{$index_key}{'pngTitles'} = [];
				if (exists($obj{'setting_description_hash'}{'文章と見なす単位'})) {
					$obj{'index_hash'}{$index_parent}{'subItems'}{$index_key}{'label'} = $index_key;
					$obj{'index_hash'}{$index_parent}{'subItems'}{$index_key}{'link_id'} = $index_key;
				} else {
					$obj{'index_hash'}{$index_parent}{'subItems'}{$index_key}{'label'} = $index_parent."\t".$index_key;
					$obj{'index_hash'}{$index_parent}{'subItems'}{$index_key}{'link_id'} = $index_parent."_".$index_key;
				}
				$obj{'index_hash'}{$index_parent}{'subItems'}{$index_key}{'id'} = $index_key;
			}
			
			my @description_str = ();
			my @description_str_for_HTML = ();
			#設定を説明する文字列を作成する 順番の固定化にExcelでの列番号を利用するが、先頭の1個が空白になるためあとで削除する必要がある
			for my $col_name (keys $obj{'worksheet_col_hash'}) {
				my $display_colname;
				if (exists($obj{'display_colname_hash'}{$col_name})) {
					$display_colname = $obj{'display_colname_hash'}{$col_name};
				} else {
					$display_colname = $col_name;
				}
				
				$description_str[$obj{'worksheet_col_hash'}->{$col_name}] = $obj{'setting_description_hash'}->{$col_name};
				#空白の場合はnullにし、数値はシングルクォーテーションで囲まないようにする必要がある
				if ($obj{'setting_description_hash'}->{$col_name}) {
					if ($obj{'setting_description_hash'}->{$col_name} =~ /^[0-9]+$/) {
						$description_str_for_HTML[$obj{'worksheet_col_hash'}->{$col_name}] = '{key:\''.$display_colname.'\',val:'.$obj{'setting_description_hash'}->{$col_name}.'}';
					} else {
						$description_str_for_HTML[$obj{'worksheet_col_hash'}->{$col_name}] = '{key:\''.$display_colname.'\',val:\''.$obj{'setting_description_hash'}->{$col_name}.'\'}';
					}
				} else {
					$description_str_for_HTML[$obj{'worksheet_col_hash'}->{$col_name}] = '{key:\''.$display_colname.'\',val:\'\'}';
				}
			}
			shift @description_str;
			shift @description_str_for_HTML;
			$obj{'setting_description'} = '';
			$obj{'setting_description_for_HTML'}[$obj{'count'}] = join(',', @description_str_for_HTML);
			my $desc_temp = '';
			for my $desc (@description_str) {
				#品詞のコンマを句点に置き換える
				$desc =~ s/,/、/g;
				if (length($desc_temp.",".$desc) > 60) {
					$obj{'setting_description'} .= $desc_temp."\n";
					$desc_temp = '';
				}
				$desc_temp .= "," unless $desc_temp eq '';
				$desc_temp .= $desc;
				
			}
			$obj{'setting_description'} .= $desc_temp;
			
			#実行
			eval{
				if ($self->can("calc")) {
					$self->calc;
				} else {
					$self->_calc;
				}
			};
			
			# 例外が発生した場合の処理
			if ($@) {
				print "Exception occur: $@";
				
				#$obj{'worksheet_row'}->write_string(
				#	$obj{'worksheet_row'},
				#	$obj{'worksheet_col'},
				#	$@,
				#	$obj{'worksheet_format'},
				#);
				
				move_target_file(&screen_code::plugin_path::batch_dummy_path, 0);
			} else {
				
				&move_results();
				
				
				#異なる拡張子
				if ($obj{'need_EMF'} || $obj{'need_PDF'}) {
					$obj{'do_other_expand'} = 1;
					eval{
						if ($self->can("calc")) {
							$self->calc;
						} else {
							$self->_calc;
						}
					};
					
					if ($obj{'need_EMF'}) {
						my $other_path = $obj{'other_expand_base'}.'.emf';
						my $save_target_plot = $obj{'save_target_plot'};
						&kh_r_plot::_save_emf($save_target_plot, $other_path);
					}
					if ($obj{'need_PDF'}) {
						my $other_path = $obj{'other_expand_base'}.'.pdf';
						my $save_target_plot = $obj{'save_target_plot'};
						&kh_r_plot::_save_pdf($save_target_plot, $other_path);
					}
					$obj{'do_other_expand'} = 0;
				}
			}
			
			push $obj{'index_hash'}{$index_parent}{'subItems'}{$index_key}{'pngTitles'}, 'No.'.$obj{'pict_file_main'};
	
			my $i = 1;
			my $ini_path = $obj{'pict_folder'}.'/'.$obj{'sub_folder_name'}.'/'.$obj{'pict_file_main'}.'.ini';
			#print "inipath=$ini_path\n";
			my $setting_string = $obj{'setting_description'};
			$setting_string =~ s/\n/,/g;
			
			my $OUT;
			open($OUT, ">:encoding(utf8)", encode("cp932", $ini_path));
			
			print $OUT $setting_string;
			close($OUT);
			#$obj{'worksheet'}->write_url(
			#	$obj{'worksheet_row'},
			#	$obj{'worksheet_col'},
			#	#"external:".$save_path,
			#	"external:".'./'.$obj{'sub_folder_name'}.'/'.$obj{'pict_file_main'}.'.ini',
			#	$obj{'worksheet_format'},
			#);
			
			
			$obj{'count'}++;
			#$obj{'worksheet_row'}++;
			
			
			$obj{'recalc_count'}++;
			if ($obj{'recalc_need'} != 0 && $obj{'recalc_need'} > $obj{'recalc_count'}) {
				print "do recalc\n";
				goto RECALC;
			}
			
			#元の値に戻す
			#print "start return to original_setting\n";
			foreach my $key (keys $obj{'original_setting'}) {
				#print " original_setting $key\n";
				set_config($self, $key, $obj{'original_setting'}{$key});
			}
		}
		
		close($IN);
		close($IN_plugin);
		
		#$obj{'workbook'}->close();
		
		end_waitDialog();
	} else {
		
		return;
	}
	
	
	$self->{check_rm_open} = $check_rm_open;
	#品詞選択メソッドを元に戻す
	&restore_subroutine();
	
	#JavaScript実行用のファイルをフォルダごとコピー
	use File::Copy::Recursive q(dircopy);\
	mkpath(encode("cp932", $obj{'pict_folder'}.'/js'));
	dircopy(&screen_code::plugin_path::batch_js_path, encode("cp932", $obj{'pict_folder'}.'/js'));
	
	#HTMLファイルの作成 テンプレートをコピーしリネーム
	copy(&screen_code::plugin_path::batch_HTML_path.'/'.$obj{'process_name'}.'_temp.html', encode("cp932", $obj{'HTML_file_path'}));
	
	my $HTML;
	my $HTML_string = '';
	open($HTML, "<:encoding(utf8)", encode("cp932", $obj{'HTML_file_path'}));
	while (my $line = <$HTML>) {
		$HTML_string .= $line;
	}
	close($HTML);
	
	my $IN_inBatch;
	open($IN_inBatch, "<:encoding(utf8)", $inBatch_file_config);
	my $line_inBatch = <$IN_inBatch>;
	chomp($line_inBatch);
	close($IN_inBatch);
	my @tempArray = split(/,/, $line_inBatch);
	#my %inBatchSettingHash = ();
	$obj{'whole_setting_hash'}{$_} = '可変' for @tempArray;
		
	my @whole_settings_for_HTML = ();
	#設定を説明する文字列を作成する 順番の固定化にExcelでの列番号を利用するが、先頭の1個が空白になるためあとで削除する必要がある
	for my $col_name (keys $obj{'whole_setting_hash'}) {
		#if (exists($inBatchSettingHash{$col_name})) {
		#	$whole_settings_for_HTML[$obj{'worksheet_col_hash'}->{$col_name}] = "\n".$col_name.':\'可変\'';
		#} els
		
		if (exists($obj{'whole_setting_exclusion_hash'}{$col_name})) {
			$whole_settings_for_HTML[$obj{'worksheet_col_hash'}->{$col_name}] = "\n".$col_name.':\'\'';
		} elsif ($obj{'whole_setting_hash'}->{$col_name} eq 'null') {
			$whole_settings_for_HTML[$obj{'worksheet_col_hash'}->{$col_name}] = "\n".$col_name.':'.$obj{'whole_setting_hash'}->{$col_name};
		} else {
			$whole_settings_for_HTML[$obj{'worksheet_col_hash'}->{$col_name}] = "\n".$col_name.':\''.$obj{'whole_setting_hash'}->{$col_name}.'\'';
		}
	}
	shift @whole_settings_for_HTML;
	#print "\n".join(',', @whole_settings_for_HTML)."\n";
	my $whole_setting_string = join(',', @whole_settings_for_HTML);
	$HTML_string =~ s/wholeSettingReplace/$whole_setting_string/;
	
	#検索対象の文字列
	my $filter_types_string = '';
	for my $col_name (keys $obj{'filterTypes'}) {
	
		my $display_colname;
		if (exists($obj{'display_colname_hash'}{$col_name})) {
			$display_colname = $obj{'display_colname_hash'}{$col_name};
		} else {
			$display_colname = $col_name;
		}
		if ($obj{'setting_table'}->{$col_name}{'category'} eq 'numeric') {
			$filter_types_string .= '{label:\''.$display_colname.'\',category:\'number\',comboItems:null},'."\n";
		} else {
			my $itemStr = join("','", keys $obj{'filterTypes'}->{$col_name});
			$filter_types_string .= '{label:\''.$display_colname.'\',category:\'combo\',comboItems:[\''.$itemStr.'\']},'."\n";
		
		}
	}
	$HTML_string =~ s/filterTypesReplace/$filter_types_string/;
	
	my $pngs_string = '';
	for (my $count = 0; $count < $obj{'count'};$count++) {
		$pngs_string .= '{path: \''.$obj{'file_path_for_HTML'}[$count].'\',title: \''.$obj{'title_path_for_HTML'}[$count].'\','."\n";
		$pngs_string .= 'settings:['.$obj{'setting_description_for_HTML'}[$count].'],'."\n";
		$pngs_string .= 'batichSettings:{'.$obj{'batch_setting_description_for_HTML'}[$count].'},'."\n";
		$pngs_string .= 'pluginSettings:{'.$obj{'plugin_setting_description_for_HTML'}[$count].'},'."\n";
		$pngs_string .= "},\n";
      
	}
	#print "\n".$pngs_string."\n\n";
	$HTML_string =~ s/pngsReplace/$pngs_string/;
	
	my $top_index_string;
	my $png_index_string;
	for my $index_name (keys $obj{'index_hash'}) {
		#print "index_name=$index_name \n";
		$top_index_string .= '{label:\''.$obj{'index_hash'}{$index_name}{'label'}.'\',subItems:[';
		for my $sub_item_name (keys $obj{'index_hash'}{$index_name}{'subItems'}) {
		#print "sub_item_name=$sub_item_name \n";
			$top_index_string .= '\''.$obj{'index_hash'}{$index_name}{'subItems'}{$sub_item_name}{'id'}.'\',';
			$png_index_string .= '{label:\''.$obj{'index_hash'}{$index_name}{'subItems'}{$sub_item_name}{'label'}.'\',';
			$png_index_string .= 'link_id:\''.$obj{'index_hash'}{$index_name}{'subItems'}{$sub_item_name}{'link_id'}.'\',';
			$png_index_string .= 'id:\''.$obj{'index_hash'}{$index_name}{'subItems'}{$sub_item_name}{'id'}.'\',';
			$png_index_string .= 'pngTitles:[\''.join("','", @{$obj{'index_hash'}{$index_name}{'subItems'}{$sub_item_name}{'pngTitles'}}).'\']';
			$png_index_string .= "},\n";
		}
		$top_index_string .= "]},\n";
	}
	$HTML_string =~ s/indexTopReplace/$top_index_string/;
	$HTML_string =~ s/pngIndexReplace/$png_index_string/;
	
	$HTML_string =~ s/calculateDateReplace/$obj{'sub_folder_name'}/;
	
	open($HTML, ">:encoding(utf8)", encode("cp932", $obj{'HTML_file_path'}));
	
	print $HTML $HTML_string;
	close($HTML);
	
	system(encode("cp932",$obj{'HTML_file_path'}));
	
	
	#オブジェクトをリセット
	%obj = ();
}


#出力された画像ファイルをリネームして移動し、結果Excelシートにその画像へのリンクを作成する
sub move_results{
	my $output_num = 0;
	my $current_timestamp = 0;
	my @temp = @{$obj{'need_pict_num'}};
	for my $pict_num (@temp) {
		unless ($output_num) {
			my $file_path = $::config_obj->cwd.'/config/R-bridge/'.$::project_obj->dbname.'_'.$obj{'process_name'}.'_'.$pict_num.'.png';
			print "file search $file_path\n";
			if (-f $file_path) {
				
				print "file exist $file_path\n";
				my @filestat = stat $file_path;
				next if $obj{'last_timestamp'} >= localtime($filestat[9]);
				$current_timestamp = localtime($filestat[9]);
				#print "new result file \n";
				move_target_file($file_path, $output_num);
				$output_num++;
			}
		}
	}
	
	
	if ($output_num > 0) {
		$obj{'last_timestamp'} = $current_timestamp;
	}
}

sub move_target_file{
	my $file_path = shift;
	my $output_num = shift;
	
	use File::Copy qw/copy/;
	my $i = 1;
	mkpath((encode("cp932", $obj{'pict_folder'}.'/'.$obj{'sub_folder_name'})));
	my $save_path = $obj{'pict_folder'}.'/'.$obj{'sub_folder_name'}.'/'.$i.'.png';
	my $other_expand_base = $obj{'pict_folder'}.'/'.$obj{'sub_folder_name'}.'/'.$i;
	#相対パスでリンクを作成する
	my $part_path;
	while (-f encode("cp932", $save_path)) {
		$i++;
		$save_path = $obj{'pict_folder'}.'/'.$obj{'sub_folder_name'}.'/'.$i.'.png';
		$other_expand_base = $obj{'pict_folder'}.'/'.$obj{'sub_folder_name'}.'/'.$i;
	}
	$part_path = './'.$obj{'sub_folder_name'}.'/'.$i.'.png';
	$obj{'file_path_for_HTML'}[$obj{'count'}] = $part_path;
	$obj{'title_path_for_HTML'}[$obj{'count'}] = 'No.'.$i;
	$obj{'other_expand_base'} = $other_expand_base;
	$obj{'pict_file_main'} = $i;
	#print "savepath $save_path\n";
	copy($file_path, encode("cp932", $save_path));
	#$obj{'worksheet'}->write_url(
	#	$obj{'worksheet_row'},
	#	$obj{'worksheet_col'} + 1 + $output_num,
	#	#"external:".$save_path,
	#	"external:".$part_path,
	#	$obj{'worksheet_format'},
	#);
	
	
}


#一度実行設定ファイルを全て読み、Excelファイルの列を決定しヘッダーを作成する
sub set_header{
	my $header_format = $obj{'workbook'}->add_format( color => 'black');
	$header_format->set_border(2);
	$header_format->set_bg_color( 'yellow' );
	$header_format->set_bold();
	for my $col_name (keys $obj{'worksheet_col_hash'}) {
		$obj{'worksheet'}->write_string(
			1,
			$obj{'worksheet_col_hash'}{$col_name},
			$col_name,
			$header_format,
		);
	}
}
#列番号と設定名のペアを作りハッシュで記憶
sub set_header_pair{
	my $key = shift;
	my $val = shift;
	unless (exists($obj{'worksheet_col_hash'}->{$key})) {
		$obj{'worksheet_col_hash'}{$key} = $obj{'worksheet_col'};
		$obj{'worksheet_col'}++;
	}
}

sub set_config{
	my $self = shift;
	my $key = shift;
	my $val = shift;
	#print " set_config $key $val \n";
	
	my $typeStr;
	my $hashStr;
	if (exists($obj{'setting_table'}->{$key})) {
		#print "$key が設定名として存在する \n";
		
		
		#$obj{'worksheet'}->write_string(
		#	$obj{'worksheet_row'},
		#	$obj{'worksheet_col_hash'}{$key},
		#	$val,
		#	$obj{'worksheet_format'},
		#);
		
		$typeStr = $obj{'setting_table'}->{$key}{'type'};
		$hashStr = $obj{'setting_table'}->{$key}{'hash'};
		#print "typeStr=$typeStr hashStr=$hashStr\n";
		#タイプ毎に異なる処理を行う
    	eval '&set_'.$typeStr.'($self, $key, $val, $hashStr);';
    	
    	#エラー時は何をすべきか
		if ($@) {
			print "error in set_config $@\n";
			
		}
		
		#設定が存在するので除外を取りやめる
		if (exists($obj{'whole_setting_exclusion_hash'}{$key})) {
			delete($obj{'whole_setting_exclusion_hash'}{$key});
		}
	}
}

#ハッシュ文字列を元に対象のコントロールへの参照を取得
sub get_target_ref{
	my $self = shift;
	my $hashStr = shift;
	my $isScalar = shift;
	
	my @hashAry;
	
	unless ($hashStr eq '') {
		#print "hashStr=$hashStr\n";
		@hashAry = split(/->/,$hashStr);
		
		my $count = 1;
		my $length = @hashAry;
		#print $length." ary count\n";
		foreach my $hash (@hashAry) {
			#print $hash." hash=$self->{$hash}\n";
			if ($count == $length && $isScalar == 1) {
				$self = \{$self->{$hash}};
			} else {
				$self = $self->{$hash};
			}
			$count++;
		}
	}
	return $self;
}

#布置される語数からの逆算
sub calculate_word_min{
	#対応分析(word_corresp)のみtaniが二つあり、それに対し布置される語数の計算 mysql_crossout::r_com ではtaniとtani2という二つ変数で対応しているが、
	#そもそも対応分析がtaniとtani2が異なったケースに対応しておらず、計算前に中断されるようになっているので、実質的にtani2を用いる必要がないと思われる
	my $self = shift;
	
	my $sql = '';
	$sql .= "SELECT genkei.num, genkei.name \n";
	$sql .= "FROM   genkei, hselection, df_".$self->{words_obj}->tani."";
	#if ($self->{words_obj}->tani and $self->{words_obj}->tani ne $self->{words_obj}->tani){
	#	$sql .= ", df_".$self->{words_obj}->tani.".\n";
	#} else {
		$sql .= "\n";
	#}
	$sql .= "WHERE\n";
	$sql .= "	    genkei.khhinshi_id = hselection.khhinshi_id\n";
	$sql .= "	AND genkei.nouse = 0\n";
	$sql .= "	AND genkei.id = df_".$self->{words_obj}->tani.".genkei_id\n";
	#前述のtani2を考慮した処理、不要と思われる
	#if ($self->{words_obj}->tani and $self->{words_obj}->tani ne $self->{words_obj}->tani){
	#	$sql .= "	AND genkei.id = df_".$self->{words_obj}->tani.".genkei_id\n";
	#	$sql .= "	AND df_".$self->{words_obj}->tani.".f >= 1\n";
	#
	#文章数は考慮しないように変更
	#$sql .= "	AND df_".$self->{words_obj}->tani.".f >= ".$self->{words_obj}->min_df."\n";
	$sql .= "	AND (\n";
	
	my $n = 0;
	foreach my $i ( @{$self->{words_obj}->hinshi} ){
		if ($n){ $sql .= ' OR '; }
		$sql .= "hselection.khhinshi_id = $i\n";
		++$n;
	}
	$sql .= ")\n";
	#文章数と最大出現数は考慮しないように変更
	#無視語数は最大出現数と競合する設定
	#if ($self->{words_obj}->max && !$obj{'ignore_num'}){
	#	$sql .= "AND genkei.num <= ".$self->{words_obj}->max."\n";
	#}
	#if ($self->{words_obj}->max_df){
	#	$sql .= "AND df_".$self->{words_obj}->tani.".f <= ".$self->{words_obj}->max_df."\n";
	#}
	$sql .= " ORDER BY genkei.num DESC\n";
	#print "$sql\n";
	
	my $hdl = mysql_exec->select($sql,1)->hundle;
	my $count = 0 - $obj{'ignore_num'};
	my $min = 0;
	my $max = 0;
	while (my $i = $hdl->fetch){
		$count++;
		#print "$i->[1]:$i->[0] $count\n";
		$min = $i->[0];
		#無視語数から最大出現数を求める
		if ($count <= 0) {
			$max = $i->[0];
		}
		#布置される語数の設定があり、その数よりも多くなった場合にカウント終了
		if (($obj{'entry_num'} && $count >= $obj{'entry_num'}) or $min <= 1) {
			#print "last ";
			last
		} elsif ($obj{'entry_num'} == 0 && $count >= $obj{'entry_num'}) {
			#print "last2 ";
			last
		}
	}
	#print "entry_num=".$obj{'entry_num'}." ignore_num=".$obj{'ignore_num'}." count=$count min=$min max=$max  \n";
	
	set_entry($self, '最小出現数', $min, 'words_obj->ent_min', 1);
	if ($obj{'ignore_num'}) {
		set_entry($self, '最大出現数', $max, 'words_obj->ent_max', 1);
	}
}

#布置される語数は別途計算する必要がある
sub set_calculation{
	my $self = shift;
	my $key = shift;
	my $val = shift;
	my $hashStr = shift;
	
	$obj{'setting_description_hash'}->{$key} = "$val";
	
	#全体設定出力用のハッシュの更新、仕様上かならず同じ文言になる
	$obj{'whole_setting_hash'}{$key} = "ユーザー設定";
	
	$obj{'need_calculation'} = 1;
	if ($key eq "布置される語数") {
		$obj{'entry_num'} = $val;
	} else {
		$obj{'ignore_num'} = $val;
	}
	
}
#布置される語数は設定ウィンドウには存在しないため、常にval = ''
sub get_from_window_calculation{
	my $self = shift;
	my $key = shift;
	my $hashStr = shift;
	
	my $val = '';
	#print "get_from_window_calculation key=$key hashStr=$hashStr val=$val\n";
	$obj{'setting_description_hash'}->{$key} = "$val";
	
	#全体設定出力用のハッシュ
	unless (exists($obj{'whole_setting_hash'}{$key})){
		$obj{'whole_setting_hash'}{$key} = "null";
	}
	
	
	#Excelに書き込む
	#$obj{'worksheet'}->write_string(
	#	$obj{'worksheet_row'},
	#	$obj{'worksheet_col_hash'}{$key},
	#	$val,
	#	$obj{'worksheet_format'},
	#);
}

#現在の設定での、布置される語数の計算
sub calculate_words_count{
	my $self = shift;
	
	#最小出現数が存在しない場合は計算できない
	if ($self->{words_obj}->min eq "") {
		return 0;
	}
	
	my $sql = '';
	$sql .= "SELECT genkei.num, genkei.name \n";
	$sql .= "FROM   genkei, hselection, df_".$self->{words_obj}->tani."";
	#if ($self->{words_obj}->tani and $self->{words_obj}->tani ne $self->{words_obj}->tani){
	#	$sql .= ", df_".$self->{words_obj}->tani.".\n";
	#} else {
		$sql .= "\n";
	#}
	$sql .= "WHERE\n";
	$sql .= "	    genkei.khhinshi_id = hselection.khhinshi_id\n";
	$sql .= "	AND genkei.num >= ".$self->{words_obj}->min."\n";
	$sql .= "	AND genkei.nouse = 0\n";
	$sql .= "	AND genkei.id = df_".$self->{words_obj}->tani.".genkei_id\n";
	#if ($self->{words_obj}->tani and $self->{words_obj}->tani ne $self->{words_obj}->tani){
	#	$sql .= "	AND genkei.id = df_".$self->{words_obj}->tani.".genkei_id\n";
	#	$sql .= "	AND df_".$self->{words_obj}->tani.".f >= 1\n";
	
	$sql .= "	AND df_".$self->{words_obj}->tani.".f >= ".$self->{words_obj}->min_df."\n";
	$sql .= "	AND (\n";
	
	my $n = 0;
	foreach my $i ( @{$self->{words_obj}->hinshi} ){
		if ($n){ $sql .= ' OR '; }
		$sql .= "hselection.khhinshi_id = $i\n";
		++$n;
	}
	$sql .= ")\n";
	if ($self->{words_obj}->max){
		$sql .= "AND genkei.num <= ".$self->{words_obj}->max."\n";
	}
	if ($self->{words_obj}->max_df){
		$sql .= "AND df_".$self->{words_obj}->tani.".f <= ".$self->{words_obj}->max_df."\n";
	}
	$sql .= " ORDER BY genkei.num DESC\n";
	
	my $hdl = mysql_exec->select($sql,1)->hundle;
	my $count = 0;
	while (my $i = $hdl->fetch){
		#print "$i->[1]:$i->[0] $count\n";
		$count++;
	}
	return $count;
}


#入力ボックスへの値設定
sub set_entry{
	my $self = shift;
	my $key = shift;
	my $val = shift;
	my $hashStr = shift;
	my $ignore_add_whole_setting = shift;
	
	my $hashRef = get_target_ref($self, $hashStr);
	
	#最初の一回は元の値を保存
	if (!exists($obj{'original_setting'}{$key})) {
		my $origin_val = $hashRef->get;
		#print "register new original_setting to $key val=".$origin_val."\n";
    	$obj{'original_setting'}{$key} = $hashRef->get;
    	
    }
    	
	#全体設定出力用のハッシュを更新する
	if (exists($obj{'whole_setting_hash'}{$key}) && $ignore_add_whole_setting == 0){
		if ($obj{'whole_setting_hash'}{$key} eq "null") {
			$obj{'whole_setting_hash'}{$key} = 'ユーザー選択(基本設定:なし)';
		} else {
			$obj{'whole_setting_hash'}{$key} = 'ユーザー選択(基本設定:'.$obj{'whole_setting_hash'}{$key}.')';
		}
		#常に「可変」とする
		$obj{'whole_setting_hash'}{$key} = '可変';
	}
	
	#print $hashRef->get." getFromEntry\n";
	$obj{'setting_description_hash'}->{$key} = "$val";
	#print "setting_description_hash - $key=".$obj{'setting_description_hash'}->{$key}."\n";
	
	$hashRef->configure(-state => 'normal'); #値を変更する前に対象のコントロールを有効化する必要がある
	$hashRef->delete(0, 'end');
	$hashRef->insert(0, $val);
	
}
#入力ボックスの既存設定取得
sub get_from_window_entry{
	my $self = shift;
	my $key = shift;
	my $hashStr = shift;
	
	my $hashRef = get_target_ref($self, $hashStr);
	my $val;
	#最初の一回の値があるならそれを使用
	if (exists($obj{'original_setting'}{$key})) {
    	$val = $obj{'original_setting'}{$key};
    } else {
    	$val = $hashRef->get;
    }
    
    #全体設定出力用のハッシュ
	unless (exists($obj{'whole_setting_hash'}{$key})){
		if ($val) {
			$obj{'whole_setting_hash'}{$key} = $val;
		} else {
			$obj{'whole_setting_hash'}{$key} = "null";
		}
	}
	
	#print "get_from_window_entry key=$key hashStr=$hashStr val=$val\n";
	$obj{'setting_description_hash'}->{$key} = "$val";
	
	#Excelに書き込む
	#$obj{'worksheet'}->write_string(
	#	$obj{'worksheet_row'},
	#	$obj{'worksheet_col_hash'}{$key},
	#	$val,
	#	$obj{'worksheet_format'},
	#);
}

sub checked_hinshi_word{
	my %hinshi_word_table = (
		7 =>  '地名' ,
		6 =>  '人名',
		5 =>  '組織名',
		4 =>  '固有名詞',
		2 =>  'サ変名詞',
		3 =>  '形容動詞',
		8 =>  'ナイ形容',
		16 => '名詞B',
		20 => '名詞C',
		21 => '否定助動詞',
		0 =>  '代名詞',
		1 =>  '名詞',
		9 =>  '副詞可能',
		10 => '未知語',
		12 => '感動詞',
		99999 => 'HTMLタグ',
		11 => 'タグ',
		17 => '動詞B',
		13 => '動詞',
		22 => '形容詞（非自立）',
		18 => '形容詞B',
		14 => '形容詞',
		19 => '副詞B',
		15 => '副詞',
	);
	
	
	my @ary = ();
	#番号から品詞名に置き換える
	foreach my $hinshi_num (@hinshi_list_original) {
		if (exists($hinshi_word_table{$hinshi_num})) {
			push @ary, $hinshi_word_table{$hinshi_num};
		}
	}
	
	return \@ary;
}

#品詞設定は複雑だが、品詞設定コントロールクラスが持つ、チェックされた品詞一覧を返すメソッドを置き換えることで対応可能か
sub set_hinshi{

	#品詞選択メソッドの一時置き換え
	unless ($default_hinshi_method) {
		$default_hinshi_method = \&gui_widget::hinshi::selected;
		*gui_widget::hinshi::selected = \&selected_replace;
	}
	
	my %hinshi_table = (
		'地名'  => 7, 
		'人名' => 6, 
		'組織名' => 5,
		'固有名詞' => 4,
		'サ変名詞' => 2,
		'形容動詞' => 3,
		'ナイ形容' => 8,
		'名詞B' => 16,
		'名詞C' => 20,
		'否定助動詞' => 21,
		'代名詞' => 0,
		'名詞' => 1,
		'副詞可能' => 9,
		'未知語' => 10,
		'感動詞' => 12,
		'HTMLタグ' => 99999,
		'タグ' => 11,
		'動詞B' => 17,
		'動詞' => 13,
		'形容詞（非自立）' => 22,
		'形容詞B' => 18,
		'形容詞' => 14,
		'副詞B' => 19,
		'副詞' => 15,
	);

	#共通形式のため以下を受け取るが一部しか使わない
	my $self = shift;
	my $key = shift;
	my $val = shift;
	my $hashStr = shift;
	
	$obj{'setting_description_hash'}->{$key} = "$val";
	my @hinshi_name_list = split(/、/, $val);
	
    #全体設定出力用のハッシュを更新する
	if (exists($obj{'whole_setting_hash'}{$key})){
		my $origin_val = join(",",@hinshi_list_original);
		if ($origin_val) {
			$obj{'whole_setting_hash'}{$key} = 'ユーザー選択(基本設定:'.$origin_val.')';
		} else {
			$obj{'whole_setting_hash'}{$key} = 'ユーザー選択(基本設定:なし)';
		}
		#常に「可変」とする
		$obj{'whole_setting_hash'}{$key} = '可変';
	}

	
	#品詞名から番号に置き換える
	foreach my $hinshi_name (@hinshi_name_list) {
		if (exists($hinshi_table{$hinshi_name})) {
			push @hinshi_list, $hinshi_table{$hinshi_name};
			if (exists($obj{'filterTypes'}{$key})) {
				$obj{'filterTypes'}{$key}{$hinshi_name} = 1;
			}
		}
	}
	
}

#一時置き換え用メソッド
sub selected_replace{
	return \@hinshi_list;
}

#品詞の既存設定取得 これは先にオプションファイル出力に必要なので、既に取得しておりハッシュから参照できる
sub get_from_window_hinshi{
	my $self = shift;
	my $key = shift;
	my $hashStr = shift;
	
	my @ary = @{$obj{'checked_hinshi_word'}};
	#print "get_from_window_hinshi key=$key hashStr=$hashStr val=".join(",",@ary)."\n";
	$obj{'setting_description_hash'}->{$key} = "".join(",",@ary);
	
    #全体設定出力用のハッシュ
	unless (exists($obj{'whole_setting_hash'}{$key})){
		if (@ary) {
			$obj{'whole_setting_hash'}{$key} = join(",",@ary);
		} else {
			$obj{'whole_setting_hash'}{$key} = "null";
		}
	}
	
	#Excelに書き込む
	#$obj{'worksheet'}->write_string(
	#	$obj{'worksheet_row'},
	#	$obj{'worksheet_col_hash'}{$key},
	#	join(",",@ary),
	#	$obj{'worksheet_format'},
	#);
}

#クラスオブジェクトが持つハッシュへの値設定(内部の値のみ変更するため、コントロールへは反映されない)
sub set_hash{
	my $self = shift;
	my $key = shift;
	my $val = shift;
	my $hashStr = shift;
	
	my $parentHashRef = get_target_ref($self, $obj{'setting_table'}->{$key}{'value_hash_parent'});
	my $valueHashName = $obj{'setting_table'}->{$key}{'value_hash_name'};
	
	#最初の一回は元の値を保存
	if (!exists($obj{'original_setting'}{$key})) {
    	$obj{'original_setting'}{$key} = $obj{'setting_table'}->{$key}{$parentHashRef->{$valueHashName}};
    	#print "set_hash $key original_val=".$parentHashRef->{$valueHashName}." ".$obj{'original_setting'}{$key}."\n";
    	
	    #全体設定出力用のハッシュを更新する
		if (exists($obj{'whole_setting_hash'}{$key})){
			if ($obj{'whole_setting_hash'}{$key} eq "null") {
				$obj{'whole_setting_hash'}{$key} = 'ユーザー選択(基本設定:なし)';
			} else {
				$obj{'whole_setting_hash'}{$key} = 'ユーザー選択(基本設定:'.$obj{'whole_setting_hash'}{$key}.')';
			}
			#常に「可変」とする
			$obj{'whole_setting_hash'}{$key} = '可変';
		}
    }
    
    if ($val eq "自動選択"){
    	if (exists($obj{'setting_description_hash'}{'集計単位'}) && exists($obj{'setting_table'}->{$key}{'more_words_setting'})) {
	    	my $tani = $obj{'setting_description_hash'}{'集計単位'};
	    	print "\n $key auto selected $tani \n";
			if ($obj{'has_more_words'}{$tani}) {
				$val = $obj{'setting_table'}->{$key}{'more_words_setting'};
	    		print "over 1000 select ".$val." \n";
			} else {
				$val = $obj{'setting_table'}->{$key}{'less_words_setting'};
	    		print "less than 1000 select ".$val." \n";
			}
		} else {
	    	print "\n $key auto selected not exists setting \n";
			$val = $obj{'setting_table'}->{$key}{'less_words_setting'};
		}
		my $plug_setting_string = $obj{'plugin_setting_description_for_HTML'}[$obj{'count'}];
		$plug_setting_string =~ s/自動選択/$val/;
		$obj{'plugin_setting_description_for_HTML'}[$obj{'count'}] = $plug_setting_string;
    }
    
    #検索対象列に追加
	if (exists($obj{'filterTypes'}{$key})) {
		if ($val) {
			$obj{'filterTypes'}{$key}{$val} = 1;
	    }
	}
    
    #print "valueHashName=$valueHashName newval=".$obj{'setting_table'}->{$key}{$val}."\n";
	$obj{'setting_description_hash'}->{$key} = "$val";
    
    #親を参照し、そこから以下のように代入することで参照先の値を変更できる
	$parentHashRef->{$valueHashName} = $obj{'setting_table'}->{$key}{$val};
}
#入力ボックスの既存設定取得
sub get_from_window_hash{
	my $self = shift;
	my $key = shift;
	my $hashStr = shift;
	
	my $val;
	#最初の一回の値があるならそれを使用
	if (exists($obj{'original_setting'}{$key})) {
    	$val = $obj{'original_setting'}{$key};
    } else {
		my $parentHashRef = get_target_ref($self, $obj{'setting_table'}->{$key}{'value_hash_parent'});
		my $valueHashName = $obj{'setting_table'}->{$key}{'value_hash_name'};
		#print "get_from_window_hash key=$key control=".$parentHashRef->{$valueHashName}."\n";
    	$val = $obj{'setting_table'}->{$key}{$parentHashRef->{$valueHashName}};
    }
    
    #全体設定出力用のハッシュ
	unless (exists($obj{'whole_setting_hash'}{$key})){
		if ($val) {
			$obj{'whole_setting_hash'}{$key} = $val;
		} else {
			$obj{'whole_setting_hash'}{$key} = "null";
		}
		#一部チェックボックスはUninitialize Value となる？他にあるかは不明 個別の対応を行うべきか
	}
	
	#print "get_from_window_hash key=$key val=$val\n";
	$obj{'setting_description_hash'}->{$key} = "$val";
	
	#Excelに書き込む
	#$obj{'worksheet'}->write_string(
	#	$obj{'worksheet_row'},
	#	$obj{'worksheet_col_hash'}{$key},
	#	$val,
	#	$obj{'worksheet_format'},
	#);
}

#固定の選択肢ではない単独選択のプルダウン(主に外部変数)への設定
sub set_pulldown{
	my $self = shift;
	my $key = shift;
	my $val = shift;
	my $hashStr = shift;
	
	my $parentHashRef = get_target_ref($self, $obj{'setting_table'}->{$key}{'value_hash_parent'});
	my $valueHashName = $obj{'setting_table'}->{$key}{'value_hash_name'}; #値のハッシュ、文字列ではなくプルダウンのidが格納される
	my $colnameArrayHashName = $obj{'setting_table'}->{$key}{'colname_array_hash_name'}; #プルダウンの列名のハッシュ
	my $testColname = $parentHashRef->{$colnameArrayHashName};
	my @colnameArray = @{$parentHashRef->{$colnameArrayHashName}};
	
	#最初の一回は元の値を保存
	if (!exists($obj{'original_setting'}{$key})) {
    	my $original_id = $parentHashRef->{$valueHashName};
		foreach my $i (@colnameArray) {
			if ($original_id eq @{$i}[1]) {
    			$obj{'original_setting'}{$key} = @{$i}[0];
				last;
			}
		}
    	#print "set_pulldown $key original_id=$original_id original_colname=".$obj{'original_setting'}{$key}."\n";
    	
	    #全体設定出力用のハッシュを更新する
		if (exists($obj{'whole_setting_hash'}{$key})){
			if ($obj{'whole_setting_hash'}{$key} eq "null") {
				$obj{'whole_setting_hash'}{$key} = 'ユーザー選択(基本設定:なし)';
			} else {
				$obj{'whole_setting_hash'}{$key} = 'ユーザー選択(基本設定:'.$obj{'whole_setting_hash'}{$key}.')';
			}
			#常に「可変」とする
			$obj{'whole_setting_hash'}{$key} = '可変';
		}
    }
    
    #検索対象列に追加
	if (exists($obj{'filterTypes'}{$key})) {
		if ($val) {
			$obj{'filterTypes'}{$key}{$val} = 1;
	    }
	}
	
	$obj{'setting_description_hash'}->{$key} = "$val";
	
	my $new_id = -1;
	foreach my $i (@colnameArray) {
		if ($val eq @{$i}[0]) {
			$new_id = @{$i}[1];
			last;
		}
	}
	
    #親を参照し、そこから以下のように代入することで参照先の値を変更できる
    if ($new_id >= 0) {
		$parentHashRef->{$valueHashName} = $new_id;
	}
}
sub get_from_window_pulldown{
	my $self = shift;
	my $key = shift;
	my $hashStr = shift;
	
	my $val;
	#最初の一回の値があるならそれを使用
	if (exists($obj{'original_setting'}{$key})) {
    	$val = $obj{'original_setting'}{$key};
    } else {
		my $parentHashRef = get_target_ref($self, $obj{'setting_table'}->{$key}{'value_hash_parent'});
		my $valueHashName = $obj{'setting_table'}->{$key}{'value_hash_name'}; #値のハッシュ、文字列ではなくプルダウンのidが格納される
		my $colnameArrayHashName = $obj{'setting_table'}->{$key}{'colname_array_hash_name'}; #プルダウンの列名のハッシュ
		my $testColname = $parentHashRef->{$colnameArrayHashName};
		my @colnameArray = @{$parentHashRef->{$colnameArrayHashName}};
    	my $original_id = $parentHashRef->{$valueHashName};
		foreach my $i (@colnameArray) {
			if ($original_id eq @{$i}[1]) {
    			$val = @{$i}[0];
				last;
			}
		}
    }
    
    #全体設定出力用のハッシュ
	unless (exists($obj{'whole_setting_hash'}{$key})){
		if ($val) {
			$obj{'whole_setting_hash'}{$key} = $val;
		} else {
			$obj{'whole_setting_hash'}{$key} = "null";
		}
		#一部チェックボックスはUninitialize Value となる？他にあるかは不明 個別の対応を行うべきか
	}
	
	#print "get_from_window_hash key=$key val=$val\n";
	$obj{'setting_description_hash'}->{$key} = "$val";
	
	#Excelに書き込む
	#$obj{'worksheet'}->write_string(
	#	$obj{'worksheet_row'},
	#	$obj{'worksheet_col_hash'}{$key},
	#	$val,
	#	$obj{'worksheet_format'},
	#);
}

#固定の選択肢ではない複数選択可のリスト(主に対応分析の外部変数)への設定
sub set_any_each_list{
	my $self = shift;
	my $key = shift;
	my $val = shift;
	my $hashStr = shift;
	
	my $hashRef = get_target_ref($self, $hashStr); #対象のリストへの参照
	my $valueHashRef = get_target_ref($self, $obj{'setting_table'}->{$key}{'value_hash'}); #リストに付随するテキスト値のデータ配列への参照
	
	my @vars = ();
	#最初の一回は元の値を保存
	if (!exists($obj{'original_setting'}{$key})) {
		foreach my $i ( $self->{opt_body_var}->selectionGet ){
			push @vars, $valueHashRef->[$i][0];
		}
    	$obj{'original_setting'}{$key} = join("、", @vars);
    	
    	#print "vars ".join("、", @vars)."\n";
    	
	    #全体設定出力用のハッシュを更新する
		if (exists($obj{'whole_setting_hash'}{$key})){
			if ($obj{'whole_setting_hash'}{$key} eq "null") {
				$obj{'whole_setting_hash'}{$key} = 'ユーザー選択(基本設定:なし)';
			} else {
				$obj{'whole_setting_hash'}{$key} = 'ユーザー選択(基本設定:'.$obj{'whole_setting_hash'}{$key}.')';
			}
			#常に「可変」とする
			$obj{'whole_setting_hash'}{$key} = '可変';
		}
    }
    
    
    $hashRef->selectionClear;
    
	$obj{'setting_description_hash'}->{$key} = "$val";
	
	my @setting_word_list = split(/、/, $val);
	my $count = 0;
	foreach my $i ( @$valueHashRef ){
		foreach my $word (@setting_word_list) {
			#print " ".$i->[0]." $word\n";
			if ($i->[0] eq $word) {
				$hashRef->selectionSet($count);
				last;
			}
			
		    #検索対象列に追加
			if (exists($obj{'filterTypes'}{$key})) {
				if ($word) {
					$obj{'filterTypes'}{$key}{$word} = 1;
			    }
			}
		}
		$count++;
	}
}
#複数選択可のリストの既存設定取得
sub get_from_window_any_each_list{
	my $self = shift;
	my $key = shift;
	my $hashStr = shift;
	
	my $hashRef = get_target_ref($self, $hashStr); #対象のリストへの参照
	my $valueHashRef = get_target_ref($self, $obj{'setting_table'}->{$key}{'value_hash'}); #リストに付随するテキスト値のデータ配列への参照
	my $val;
	my @vars = ();
	#最初の一回の値があるならそれを使用
	if (exists($obj{'original_setting'}{$key})) {
    	$val = $obj{'original_setting'}{$key};
    } else {
		foreach my $i ( $self->{opt_body_var}->selectionGet ){
			push @vars, $valueHashRef->[$i][0];
		}
    	$val = join("、", @vars);
    }
    
    #全体設定出力用のハッシュ
	unless (exists($obj{'whole_setting_hash'}{$key})){
		if ($val) {
			$obj{'whole_setting_hash'}{$key} = $val;
		} else {
			$obj{'whole_setting_hash'}{$key} = "null";
		}
	}
	
	#print "get_from_window_each_list key=$key hashStr=$hashStr val=$val\n";
	$obj{'setting_description_hash'}->{$key} = "$val";
	
	#Excelに書き込む
	#$obj{'worksheet'}->write_string(
	#	$obj{'worksheet_row'},
	#	$obj{'worksheet_col_hash'}{$key},
	#	$val,
	#	$obj{'worksheet_format'},
	#);
}



#以下の二つは不要か
#チェックボックスへの設定
sub set_check{
	my $self = shift;
	my $key = shift;
	my $val = shift;
	my $hashStr = shift;
	
	my $hashRef = get_target_ref($self, $hashStr);
	my $valueHashRef = get_target_ref($self, $obj{'setting_table'}->{$key}{'value_hash'});
	
	#最初の一回は元の値を保存
	if (!exists($obj{'original_setting'}{$key})) {
    	$obj{'original_setting'}{$key} = $obj{'setting_table'}->{$key}{$valueHashRef};
    }
    
    #TRUE = 1, FALSE = 0 なので、TRUEの場合
    if ($obj{'setting_table'}->{$key}{$val}) {
    	$hashRef->select;
    } else {
    	$hashRef->deselect;
    }
}

#バッチ処理前に行うと思われる、関数置き換え処理の検証
sub batch_calc_pre{
	#ダイアログ表示とプロット表示の関数を一時的にダミーに置き換えることで無視できると思われる
	my $self = shift;
	
	my $sub_temp; #他のサブルーチンを参照するための変数
	my $module_name;
	my $package_name;
	
    no strict 'refs';
	$package_name = "screen_code::auto_execute_type";
	$module_name = "auto_test";
	
    eval 'use '.$package_name.';';
    eval '$sub_temp = \&'.$package_name.'::'.$module_name.';';
	
	$sub_temp->();
	
	#$selfが参照しているパッケージ名を取得できる(ここから$selfのクラスが持つメソッドを参照できる)
	my $window_package_name = ref $self;
	#eval '$sub_temp = \&'.$window_package_name.'::dummy_method;'; #クラスのメソッドを取得し、別の変数からそのメソッドを参照する
	eval '*'.$window_package_name.'::dummy_method = $sub_temp'; #クラスのメソッドを別のサブルーチンと入れ替え
	
	$self->dummy_method;
}



1;