package TermExtract::Chasen;
use TermExtract::Calc_Imp;
use strict;
use Exporter ();
use vars qw(@ISA $VERSION @EXPORT);

@ISA = qw(TermExtract::Calc_Imp Exporter);
@EXPORT = qw();
$VERSION = "2.17";

# ========================================================================
# get_noun_frq -- Get noun frequency.
#                 The values of the hash are frequency of the noun.
# （専門用語とその頻度を得るサブルーチン）
#
#  Over-write TermExtract::Calc_Imp::get_noun_frq
#
# ========================================================================
no warnings 'redefine';
sub get_noun_frq {
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
    open (IN, $data) || die "Can not open input file. $!";       # higuchi
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
        if ($part_of_speach eq '記号-アルファベット') {
            push @alphabet, $noun;
            next;
        }
        push @terms, join "", @alphabet  if @alphabet;
        @alphabet = ();

        if( $part_of_speach eq '名詞-一般'                               ||
            $part_of_speach eq '名詞-サ変接続'                           ||
            $part_of_speach eq '名詞-接尾-一般'                          ||
            $part_of_speach eq '名詞-接尾-サ変接続'                      ||
            $part_of_speach eq '記号-アルファベット'                     ||
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
        elsif(($part_of_speach eq '名詞-形容動詞語幹' | 
               $part_of_speach eq '名詞-ナイ形容詞語幹')
           ){
            push @terms, $noun;
            $must = 1; next;
        }
        elsif($part_of_speach eq '名詞-接尾-形容動詞語幹' & @terms){
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
use warnings 'redefine';

1;

__END__

=head1 NAME

    TermExtract::Chasen -- 専門用語抽出モジュール（「茶筅」版)

=head1 SYNOPSIS

    use TermExtract::Chasen;

=head1 DESCRIPTION

    入力テキストを、「茶筅」（奈良先端大学で作成している日本語形態素解析
  プログラム）にかけ、その結果をもとに入力テキストから専門用語を抽出する
  プログラム。
    なお、「茶筅」の出力はデフォルトのフォーマット指定（レコードの第一フ
  ィールドが「単語、第４フィールドが「品詞」）を前提としている。
    使用法については、親クラス（TermExtract::Calc_Imp)か、以下のサンプル
  スクリプトを参照のこと。

=head2 Sample Script

 #!/usr/local/bin/perl -w
 
 #
 #  ex_chasen.pl
 #
 #　ファイルから「茶筅」の形態素解析済みのデータを読み取り
 #  標準出力に専門用語とその重要度を返すプログラム
 #
 #   version 0.32
 #
 #   maeda@lib.u-tokyo.ac.jp
 
 use TermExtract::Chasen;
 #use strict;
 my $data = new TermExtract::Chasen;
 my $InputFile = "chasen_out.txt";    # 入力ファイル指定
 
 # プロセスの異常終了時処理
 # (ロックディレクトリを使用した場合のみ）
 $SIG{INT} = $SIG{QUIT} = $SIG{TERM} = 'sigexit';
 
 # 出力モードを指定
 # 1 → 専門用語＋重要度、2 → 専門用語のみ
 # 3 → カンマ区切り
 my $output_mode = 1;
 
 #
 # 重要度計算で、連接語の"延べ数"、"異なり数"、"パープレキシティ"のい
 # ずれをとるか選択。パープレキシティは「学習機能」を使えない
 # また、"連接語の情報を使わない"選択もあり、この場合は用語出現回数
 # (と設定されていればIDFの組み合わせ）で重要度計算を行う
 # （デフォルトは"延べ数"をとる $obj->use_total)
 #
 #$data->use_total;      # 延べ数をとる
 #$data->use_uniq;       # 異なり数をとる
 #$data->use_Perplexity; # パープレキシティをとる(TermExtract 3.04 以上)
 #$data->no_LR;          # 隣接情報を使わない (TermExtract 4.02 以上)
 
 #
 # 重要度計算で、連接情報に掛け合わせる用語出現頻度情報を選択する
 # $data->no_LR; との組み合わせで用語出現頻度のみの重要度も算出可能
 # （デフォルトは "Frequency" $data->use_frq)
 # TFはある用語が他の用語の一部に使われていた場合にもカウント
 # Frequency は用語が他の用語の一部に使われていた場合にカウントしない
 #
 #$data->use_TF;   # TF (Term Frequency) (TermExtract 4.02 以上)
 #$data->use_frq;  # Frequencyによる用語頻度
 #$data->no_frq;   # 頻度情報を使わない
 
 #
 # 重要度計算で、学習機能を使うかどうか選択
 # （デフォルトは、使用しない $obj->no_stat)
 #
 #$data->use_stat; # 学習機能を使う
 #$data->no_stat;  # 学習機能を使わない
 
 #
 # 重要度計算で、「ドキュメント中の用語の頻度」と「連接語の重要度」
 # のどちらに比重をおくかを設定する。
 # デフォルト値は１
 # 値が大きいほど「ドキュメント中の用語の頻度」の比重が高まる
 #
 #$data->average_rate(0.5);
 
 #
 # 学習機能用DBにデータを蓄積するかどうか選択
 # 重要度計算で、学習機能を使うときは、セットしておいたほうが
 # 無難。処理対象に学習機能用DBに登録されていない語が含まれる
 # と正しく動作しない。
 # （デフォルトは、蓄積しない $obj->no_storage）
 #
 #$data->use_storage; # 蓄積する
 #$data->no_storage;  # 蓄積しない
 
 #
 # 学習機能用DBに使用するDBMをSDBM_Fileに指定
 # （デフォルトは、DB_FileのBTREEモード）
 #
 #$data->use_SDBM;
 
 # 過去のドキュメントの累積統計を使う場合のデータベースの
 # ファイル名をセット
 # （デフォルトは "stat.db"と"comb.db"）
 #
 #$data->stat_db("stat.db");
 #$data->comb_db("comb.db");
 
 #
 # データベースの排他ロックのための一時ディレクトリを指定
 # ディレクトリ名が空文字列（デフォルト）の場合はロックしない
 #
 #$data->lock_dir("lock_dir");
 
 #
 # 形態素解析済みのテキストから、データを読み込み
 # 専門用語リストを配列に返す
 # （累積統計DB使用、ドキュメント中の頻度使用にセット）
 #
 #my @noun_list = $data->get_imp_word($str, 'var');     # 入力が変数
 my @noun_list = $data->get_imp_word($InputFile); # 入力がファイル
 
 #
 # 前回読み込んだ形態素解析済みテキストファイルを元に
 # モードを変えて、専門用語リストを配列に返す
 #$data->use_stat->no_frq;
 #my @noun_list2 = $data->get_imp_word();
 # また、その結果を別のモードによる結果と掛け合わせる
 #@noun_list = $data->result_filter (\@noun_list, \@noun_list2, 30, 1000);
 
 #
 #  専門用語リストと計算した重要度を標準出力に出す
 #
 foreach (@noun_list) {
    # 日付・時刻は表示しない
    next if $_->[0] =~ /^(昭和)*(平成)*(\d+年)*(\d+月)*(\d+日)*(午前)*(午後)*(\d+時)*(\d+分)*(\d+秒)*$/;
    # 数値のみは表示しない
    next if $_->[0] =~ /^\d+$/;
 
    # 結果表示（$output_modeに応じて、出力様式を変更
    printf "%-60s %16.2f\n", $_->[0], $_->[1] if $output_mode == 1;
    printf "%s\n",           $_->[0]          if $output_mode == 2;
    printf "%s,",            $_->[0]          if $output_mode == 3;
 }
 
 # プロセスの異常終了時にDBのロックを解除
 # (ロックディレクトリを使用した場合のみ）
 sub sigexit {
    $data->unlock_db;
 }

=head1 Methods

    このモジュールでは、get_imp_word のみ実装し、それ以外のメソッドは親
  モジュール TermExtract::Calc_Imp で実装されている。
    get_imp_word は形態素解析を行い抽出された単語を、個々の単語の語順と
  品詞情報を元に複合語に生成している。それ以外のメソッドについては、
  TermExtract::Calc_Imp のPODドキュメントを参照すること。

=head2 get_imp_word

    形態素解析の結果抽出された単語を次のルールにより複合語に生成する。第
  １引数は、処理対象のデータ、第２引数は第１引数の種別である。デフォルト
  では、第１引数は、形態素解析済みのテキストファイルとなる。第２引数に文
  字列 'var'がセットされたときには、第一引数を形態素解析済のテキストデー
  タが入ったスカラー変数と解釈する。

    １．次の品詞をもつ単名詞が連続で現れたときは結合する
       ・名詞    一般
       ・名詞    サ変接続
       ・名詞    接尾            一般
       ・名詞    接尾            サ変接続
       ・名詞    固有名詞
       ・未知語
       ・記号    アルファベット

        ＊「未知語」の場合、「茶筅」のバージョン2.3.3では . （ピリオド
          ）や - （ハイフン）などでも語が分割される。そこで、ASCIIの記号
         があらわれたときは、前後の語を結合して処理するようにしている。
         ただし、次の記号は除く。
            ()[]<>|"';,

        ＊「茶筅」のバージョン2.3.3では、ほとんどの英文が「未知語」では
        　なく「記号-アルファベット」として一字単位で扱われる。そのため、
        　「記号-アルファベット」は可能な限り連結して１語として扱うよう
        　にした。しかし、複数単語が区切りなしで扱われてしまうので了解い
        　ただきたい。旧バージョンの「茶筅」や「和布蕪」ではこの不具合は
        　起こらない。

    ２．次の品詞をもつ単名詞が現れたときは、次に続く語が上記１の名詞かど
      うか判定し、異なるときは複合語として扱わない

       ・名詞    形容動詞語幹
       ・名詞    ナイ形容詞語幹

    ３．次の品詞をもつ単名詞が現れたときは、次に続く語が上記１の名詞かど
      うか判定し、異なるときは複合語として扱わない。また、複合語の先頭に
      きた場合は廃棄する。

        ・名詞    接尾         形容動詞語幹

    ４．品詞が動詞の場合は、複合語を廃棄する

    ５．次の１文字の「未知語」は語の区切りとする。また、「未知語」が ,  
      で終わるときにも語の区切りとする。

          !"#$%&'()*+,-./{|}:;<>[]

    ６．複合語をなす語頭の単名詞が「本」の場合は、「本」のみ削除する。

    ７．複合語をなす単名詞のうち、末尾が次の語の場合は、その末尾のみ削除
      する。また末尾が空白の場合も削除する。

      "など", "ら", "上", "内", "型", "間", "中", "毎" ,"等"

=head1 SEE ALSO

    TermExtract::Calc_Imp
    TermExtract::MeCab
    TermExtract::BrillsTagger
    TermExtract::EnglishPlainText
    TermExtract::ChainesPlainTextUC
    TermExtract::ChainesPlainTextGB
    TermExtract::ICTCLAS
    TermExtract::JapanesePlainTextEUC
    TermExtract::JapanesePlainTextSJIS

=head1 COPYRIGHT

    このプログラムは、東京大学・中川裕志教授、横浜国立大学・森辰則助教授
  が作成した「専門用語自動抽出システム」のtermex.pl を参考にコードを全面
  的に書き直したものである。
    この作業は、東京大学・前田朗 (maeda@lib.u-tokyo.ac.jp)が行った。

    相違点は次のとおり。

    １．独立したスクリプトからモジュールへ書き換え、他のプログラムからの
      組み込みを可能とした。

    ２．形態素解析済みのテキストファイルだけではなく、変数からも入力可能
      にした。これによりUNIX環境での Text::Chasen モジュール等にも対応が
      可能になった。

    ３．オリジナルPerl対応にした。Shift-JISとEUCによる日本語入力を日本語
      対応パッチを当てたPerl(Jperl)を使わずとも処理可能になった。

    ４．常に固有名詞を候補語とし、１文字語も候補語とするようパラメータを
      固定した

    ５．次の１文字の「未知語」は語の区切りとして認識するようにした。また
       、「未知語」が , で終わるときにも語の区切りとした。

        !"#$%&'()*+,-./{|}:;<>[]

    ６．複数の「未知語」から単名詞を生成するロジックを組み込んだ。
      （「茶筅」ver 2.3.3等の新しいバージョンへの対応）

    ７．複数の「記号-アルファベット」から英単語を生成するロジックを組み込んだ。
      （「茶筅」ver 2.3.3等の新しいバージョンへの対応）

    ８．信頼性の確保のため、Perlの"strict"モジュール及びperlの-wオプショ
      ンへの対応を行った。

    なお、本プログラムの使用において生じたいかなる結果に関しても当方では
  一切責任を負わない。

=cut
