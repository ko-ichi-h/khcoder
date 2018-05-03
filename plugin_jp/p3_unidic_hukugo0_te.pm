package p3_unidic_hukugo0_te;  # ←この行はファイル名にあわせて変更
use strict;
use utf8;

#--------------------------#
#   このプラグインの設定   #

sub plugin_config{
	return {
		                                             # メニューに表示される名前
		name     => 'TermExtractを利用',
		menu_cnf => 2,                               # メニューの設定(1)
			# 0: いつでも実行可能
			# 1: プロジェクトが開かれてさえいれば実行可能
			# 2: プロジェクトの前処理が終わっていれば実行可能
		menu_grp => '複合語の検出（UniDic）',        # メニューの設定(2)
			# メニューをグループ化したい場合にこの設定を行う。
			# 必要ない場合は「'',」または「undef,」としておけば良い。
	};
}

#----------------------------------------#
#   メニュー選択時に実行されるルーチン   #

sub exec{
	my $self = shift;
	my $mw = $::main_gui->{win_obj};

	gui_window::use_te::unidic->open;

	return 1;
}

#-------------------------------#
#   GUI操作のためのルーチン群   #

package gui_window::use_te::unidic;
use base qw(gui_window::use_te);
use strict;
use Tk;


sub start{
	my $self = shift;
	
	$self->{text}->insert('1.0',$self->gui_jchar(
		"名詞-一般 => 名詞-普通名詞-一般\n\n"
	));
	$self->{text}->insert('1.0',$self->gui_jchar(
		"名詞-サ変接続 => 名詞-普通名詞-サ変可能\n"
	));
	$self->{text}->insert('1.0',$self->gui_jchar(
		"名詞-接尾-一般 => 接尾辞-名詞的-一般\n"
	));
	$self->{text}->insert('1.0',$self->gui_jchar(
		"名詞-接尾-サ変接続 => 接尾辞-名詞的-サ変可能\n"
	));
	$self->{text}->insert('1.0',$self->gui_jchar(
		"記号-アルファベット => 記号-文字\n"
	));
	$self->{text}->insert('1.0',$self->gui_jchar(
		"名詞-形容動詞語幹 => 名詞-普通名詞-形状詞可能・名詞-普通名詞-サ変形状詞可能\n"
	));
	$self->{text}->insert('1.0',$self->gui_jchar(
		"名詞-接尾-形容動詞語幹 => 接尾辞-名詞的-形状詞可能\n"
	));
	$self->{text}->insert('1.0',$self->gui_jchar(
		"名詞-ナイ形容詞語幹 => （該当なし）\n"
	));

	$self->{text}->insert('1.0',$self->gui_jchar("※本コマンドでは、「TermExtract」をUniDicに対応させるために改変したバージョンを使用します。以下のように品詞名を読み替える改変を行っています。\n"),'red');

}

sub _exec{
	my $self = shift;
	# 処理実行
	my $if_exec = 1;
	if (
		   ( -e $::project_obj->file_HukugoListTE)
		&& ( mysql_exec->table_exists('hukugo_te') )
	){
		my $t0 = (stat $::project_obj->file_target)[9];
		my $t1 = (stat $::project_obj->file_HukugoListTE)[9];
		#print "$t0\n$t1\n";
		if ($t0 < $t1){
			$if_exec = 0; # この場合だけ解析しない
		}
	}
	
	if ($if_exec){
		my $ans = $::main_gui->mw->messageBox(
			-message => gui_window->gui_jchar
				(
				   "時間のかかる処理を実行しようとしています。"
				   ."（前処理よりは短時間で終了します）\n".
				   "続行してよろしいですか？"
				),
			-icon    => 'question',
			-type    => 'OKCancel',
			-title   => 'KH Coder'
		);
		unless ($ans =~ /ok/i){ return 0; }
		
		use mysql_hukugo_te;
		
		my $temp = \&TermExtract::Chasen::get_noun_frq;
		*TermExtract::Chasen::get_noun_frq = \&get_noun_frq_unidic;
		
		my $w = gui_wait->start;
		mysql_hukugo_te->run_from_morpho;
		$w->end;
		
		*TermExtract::Chasen::get_noun_frq = $temp;
	}
	$self->close;
	gui_window::use_te_g->open;
}

sub get_noun_frq_unidic {
    my $self = shift;
    my $data = shift;           # 入力データ
    my $mode = shift || 0;      # 入力データがファイルか、変数かの識別用フラグ
    my %cmp_noun_list = ();     # 複合語と頻度情報を入れたハッシュ（関数の戻り値）
    my @input = ();             # 形態素解析結果の配列
    my $must  = 0;              # 次の語が名詞でなければならない場合は真
    my @terms = ();             # 複合語リスト作成用の作業用配列
    my @unknown = ();           # 「未知語」整形用作業変数
    my @alphabet = ();          # アルファベット整形用作業変数

    $self->IsAgglutinativeLang; # 膠着言語指定（単語間１字空けなし）

    # 専門用語リストへ、整形して追加するサブルーチン
    my $add = sub {
        my $terms         = shift;
        my $cmp_noun_list = shift;

        # 語頭の不要な語の削除
        if (defined $terms->[0]) {
            shift @$terms if $terms->[0] eq '本';
        }
        # 語尾の余分な語の削除
        if (defined $terms->[0]) {
            my $end = $terms->[$#$terms];
            if ( $end eq 'など'  || $end eq 'ら'   || $end eq '上'       || 
                 $end eq '内'    || $end eq '型'   || $end eq '間'       ||
                 $end eq '中'    || $end eq '毎'   || $end eq '等'       ||
                 $end =~ /^\s+$/ || $must) 
                { pop @$terms }
        }
        $cmp_noun_list->{ join ' ', @$terms }++ if defined $terms->[0];
        @$terms  = ();
    };

    # 入力が常にファイルと仮定し、大規模ファイルにも対応できるよう、ファイル
    # 内容を1行ずつ読み込んで処理するように変更（樋口耕一 2008 02/05）
    # print "TermExtract::Chasen Over-writed! (kh)\n";

    # 入力がファイルの場合
    #if ($mode ne 'var') {                                       # higuchi
    #    local($/) = undef;                                      # higuchi
    #    open (IN, $data) || die "Can not open input file. $!";  # higuchi
    #    $data = <IN>;                                           # higuchi
    #    close IN;                                               # higuchi
    #}                                                           # higuchi

    # 単名詞の連結処理
    # foreach my $morph ((split "\n", $data)) {                  # higuchi
	my $ocode;                                                   # higuchi
	if ($::config_obj->os eq 'win32'){                           # higuchi
		$ocode = 'cp932';                                        # higuchi
	} else {                                                     # higuchi
		if (eval 'require Encode::EUCJPMS') {                    # higuchi
			$ocode = 'eucJP-ms';                                 # higuchi
		} else {                                                 # higuchi
			$ocode = 'euc-jp';                                   # higuchi
		}                                                        # higuchi
	}                                                            # higuchi
    open (IN, "<:encoding($ocode)", $data) ||                    # higuchi
        die "Can not open input file. $!";                       # higuchi
    while (<IN>){                                                # higuchi
        my $morph = $_;                                          # higuchi
        chomp $morph;
	    my ($noun, $part_of_speach) = (split(/\t/, $morph))[0,3];
        $part_of_speach = "" unless defined $part_of_speach;  # 品詞

        # 記号・数値で区切られた「未知語」は、１つのまとまりにしてから処理
        #     アルファベット  → \x41-\x5A, \x61-\x7A
        if ($part_of_speach eq '未知語' & $noun !~ /^[\(\)\[\]\<\>|\"\'\;\,]/) {
            if (@unknown) {
                # 「未知語」が記号・数値で結びつかない
                unless ($unknown[$#unknown] =~ /[\x41-\x5A|\x61-\x7A]$/ &
                       $noun =~ /^[\x41-\x5A|\x61-\x7A]/) {
                    push @unknown, $noun;  # 「未知語」をひとまとめにする
                    next;
                }
            }
            else {
                push @unknown, $noun;
                next;
            }
        }
        # 「未知語」の最後が記号なら取り除く
        while (@unknown) {
            if ($unknown[$#unknown] =~ /^[\x21-\x2F]|[{|}:\;\<\>\[\]]$/) {
                pop @unknown;
            }
            else {
            	last;
            }
        }
        push @terms, join "", @unknown  if @unknown;
        @unknown = ();

        # 記号-アルファベットは、１つのまとまりにしてから処理
        if ($part_of_speach eq '記号-文字') {
            push @alphabet, $noun;
            next;
        }
        push @terms, join "", @alphabet  if @alphabet;
        @alphabet = ();

        if( $part_of_speach eq '名詞-普通名詞-一般'                      ||
            $part_of_speach eq '名詞-普通名詞-サ変可能'                  ||
            $part_of_speach eq '接尾辞-名詞的-一般'                          ||
            $part_of_speach eq '接尾辞-名詞的-サ変可能'                      ||
            $part_of_speach eq '記号-文字'                     ||
            $part_of_speach =~ /名詞\-固有名詞/                          ||
            $part_of_speach eq '未知語' & 
                               $noun !~ /^[\x21-\x2F]|[{|}:\;\<\>\[\]]$/
          ){
            if ($part_of_speach eq '未知語' & $noun =~ /.,$/) {
                chop $noun;
                push @terms, $noun if $noun ne "";
                &$add(\@terms, \%cmp_noun_list) unless $must;
            }
            else {
                push @terms, $noun;
            }
            $must = 0; next;
        }
        elsif(($part_of_speach eq '名詞-普通名詞-形状詞可能' | 
               $part_of_speach eq '名詞-普通名詞-サ変形状詞可能')
           ){
            push @terms, $noun;
            $must = 1; next;
        }
        elsif($part_of_speach eq '接尾辞-名詞的-形状詞可能' & @terms){
            push @terms, $noun;
            $must = 1; next;
        }
        elsif($part_of_speach =~ /^動詞/){
            @terms = ();
        }
        else {
            &$add(\@terms, \%cmp_noun_list) unless $must;
        }
        @terms = () if $must;
        $must = 0;
    }
    close IN;                                                    # higuchi

    return \%cmp_noun_list;
}


1;
