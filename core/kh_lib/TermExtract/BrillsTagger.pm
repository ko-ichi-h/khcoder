package TermExtract::BrillsTagger;
use TermExtract::Calc_Imp;

use strict;
use Exporter ();
use vars qw(@ISA $VERSION @EXPORT);
use locale;

@ISA = qw(TermExtract::Calc_Imp Exporter);
@EXPORT = qw();
$VERSION = "2.15";

# ========================================================================
# get_noun_frq -- Get noun frequency.
#                 The values of the hash are frequency of the noun.
# （専門用語とその頻度を得るサブルーチン）
#
#  Over-write TermExtract::Calc_Imp::get_noun_frq
#
# ========================================================================

sub get_noun_frq {
    my $self = shift;
    my $data = shift;           # 入力データ
    my $mode = shift || 0;      # 入力データがファイルか、変数かの識別用フラグ
    my %cmp_noun_list = ();     # 複合語と頻度情報を入れたハッシュ（関数の戻り値）

    $self->IgnoreWords('of', 'Of', 'OF');  # of は重要度計算外とする

    # 入力が常にファイルと仮定し、大規模ファイルにも対応できるよう、ファイル
    # 内容を1行ずつ読み込んで処理するように変更（樋口耕一 2012 08/01）

    # 入力がファイルの場合
    #if ($mode ne 'var') {                                       # higuchi
    #    local($/) = undef;                                      # higuchi
    #    open (IN, $data) || die "Can not open input file. $!";  # higuchi
    #    $data = <IN>;                                           # higuchi
    #    close IN;                                               # higuchi
    #}                                                           # higuchi

    #foreach my $morph ((split /\n/, $data)) {                   # higuchi
    open (IN, $data) || die "Can not open input file. $!";       # higuchi
    while (<IN>){                                                # higuchi
        my $morph = $_;                                          # higuchi
        chomp $morph;
        next if $morph =~ /^\s*$/;

        # $status = 1   前が名詞(NN, NNS, NNP)
        #           2   前が形容詞(JJ)
        #           3   前が所有格語尾(POS)
        #           4   前がof
        #           5   前が基数(CD)
        #           6   前が過去分詞の動詞(VBN)
        #           7   前が外来語(FW)
        my $status = 0;

        my $rest   = 0;  # 名詞以外の語が何語連続したかカウント
        my @seg    = (); # 複合語のリスト（配列）

        foreach my $term (split(/ /, $morph)) {
            # 数値や区切り記号の場合
            if($term =~ /^[\s\+\-\%\&\$\*\#\^\|\/]/ || $term =~ /^[\d]+\//){
                _increase_frq(\%cmp_noun_list, \@seg, \$rest);
                next;
            }
            next if $term =~ /suusiki/;  # 数式は除外

            # 名詞の場合
            if($term =~ /NN[PS]?$/ || $term =~ /NNPS$/){
                # 複数形を単数形に置き換える。
                $term = &_stemming($term) if $term =~ /NNS$/;
                # 固有名詞以外は先頭の大文字を小文字に。
                $term = lcfirst($term) if ($term =~ /NNS?$/ && $term =~ /^[A-Z][a-z]/);
                $status = 1;
                push(@seg, $term); $rest = 0;
            }
            # 形容詞(JJ)の場合
            elsif($term =~ /JJ$/){
                #　前の語が"なし","形容詞","所有格語尾","基数"の場合は連結する
                if($status == 0 || $status == 2 || $status == 3 || $status == 5){
                    push(@seg, $term); $rest++;
                }
                else{
                    _increase_frq(\%cmp_noun_list, \@seg, \$rest);
                    @seg = ($term); $rest++;
                }
                $status = 2;
           }
            # 所有格語尾(POS)の場合
            elsif($term =~ /POS$/){
               # 前の語が名詞の場合は連結する
               if($status == 1){
                    $status = 3;
                    push(@seg, $term); $rest++;
                }
                else{
                    _increase_frq(\%cmp_noun_list, \@seg, \$rest);
                }
            }
            # of の場合
            elsif($term =~ /^of\/IN$/){
                # 前の語が名詞の場合は連結する
                if($status == 1){
                    $status = 4;
                    push(@seg, $term); $rest++;
                }
                else{
                    _increase_frq(\%cmp_noun_list, \@seg, \$rest);
                    $status = 0;
		}
            }
            # 基数(CD)の場合は、語の先頭のみ許可
            elsif($term =~ /CD$/){
                _increase_frq(\%cmp_noun_list, \@seg, \$rest);
                @seg = ($term);
                $status = 5;
            }
            # 過去分詞の動詞は語の先頭のみ許可
            elsif($term =~ /VBN$/){
                _increase_frq(\%cmp_noun_list, \@seg, \$rest);
                $status = 6;
                @seg = ($term); $rest++;
            }
            # 外来語(FW)の場合は単語として処理
            elsif($term =~ /FW$/){
                _increase_frq(\%cmp_noun_list, \@seg, \$rest);
                $status = 7;
                @seg = ($term);
                _increase_frq(\%cmp_noun_list, \@seg, \$rest);
            }
            # 指定した品詞以外の場合は、そこで複合語の区切りとする
            else{
                _increase_frq(\%cmp_noun_list, \@seg, \$rest);
                $status = 0;
            }
        }
        # 改行があった場合はそこで複合語の区切りとする
        _increase_frq(\%cmp_noun_list, \@seg, \$rest);
        $status = 0;
    }
    close IN;                                                    # higuchi
    return \%cmp_noun_list;
}

# ---------------------------------------------------------------------------
#   _stemming  --  複数形を単数形に変えるだけのstemmer
# 
#   usage : _stemming(word);
# ---------------------------------------------------------------------------

sub _stemming {
    my $noun = shift;
	return $noun;                                                # higuchi

    if($noun =~ /ies\// && $noun !~ /[ae]ies\//){
	$noun =~ s/ies\//y\//;
    }
    elsif($noun =~ /es\// && $noun !~ /[aeo]es\//){
	$noun =~ s/es\//e\//;
    }
    elsif($noun =~ /s\// && $noun !~ /[us]s\//){
	$noun =~ s/s\//\//;
    }
    $noun;
}

# ---------------------------------------------------------------------------
#   _increase_frq  --  頻度増やす
# 
#   usage : _increase_frq(frequency_of_compnoun, segment, rest_after_noun);
# ---------------------------------------------------------------------------

sub _increase_frq {
    my $frq_ref  = shift;
    my $seg      = shift;
    my $rest     = shift;
    my $allwords = "";

    # 複合語の末尾は名詞とし、それ以外は切り捨てる
    $#$seg -= $$rest if @$seg;
    $$rest = 0;

    if ($#$seg >= 0) {
        foreach my $word (@$seg) {
            $word =~ s/^\s+//;        # 邪魔なスペースを取り除く
            $word =~ s/\s+$//;
	    $word =~ s/\/[A-Z\$]+$//; # タグを取り除く
            if ($allwords eq "") { 
                $allwords = $word;
            }
            else {
                $allwords .= ' ' . $word;
            }
        }
        # ' で区切られた語は接続する
        $allwords =~ s/(\S+)\s(\'s\s)/$1$2/g;
        # 末尾の . と , は削除する
        $allwords =~ s/\,$//;
        $allwords =~ s/\.$//;
        $$frq_ref{"$allwords"}++;
    }
    @$seg = ();
}

1;

__END__

=head1 NAME

    TermExtract::BrillsTagger 
                -- 専門用語抽出モジュール（"Brill's Tagger"版)

=head1 SYNOPSIS

    use TermExtract::BrillsTagger;

=head1 DESCRIPTION

    入力テキストを、"Brill's Tagger"（英文の品詞タグ付与プログラム）にか
  け、その結果をもとに入力テキストから専門用語を抽出するプログラム。
    Brill's Taggerを元にして作られた Monty Tagger にも対応している。

    なお、Brill's Tagger でタグ付けを行う場合は、事前にBrill's Tagger付
  属のPerlスクリプト Tokenizer.pl をかけておくことを推奨している。

    当モジュールの使用法については、親クラス（TermExtract::Calc_Imp)か、
  以下のサンプルスクリプトを参照のこと。

=head2 Sample Script

 #!/usr/local/bin/perl -w
 
 #
 #  ex_BT.pl
 #
 #　ファイルからBrill's Tagger の処理結果を読み取り
 #  標準出力に専門用語とその重要度を返すプログラム
 #
 #   version 0.14
 #
 #
 
 use TermExtract::BrillsTagger;
 #use strict;
 my $data = new TermExtract::BrillsTagger;
 my $InputFile = "BT_out.txt";    # 入力ファイル指定
 
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
 
 #
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
 # 品詞タグ付け済みのテキストから、データを読み込み
 # 専門用語リストを配列に返す
 # （累積統計DB使用、ドキュメント中の頻度使用にセット）
 #
 #my @noun_list = $data->get_imp_word($str, 'var');     # 入力が変数
 my @noun_list = $data->get_imp_word($InputFile); # 入力がファイル
 
 #
 # 前回読み込んだ品詞タグ付け済みテキストファイルを元に
 # モードを変えて、専門用語リストを配列に返す
 #$data->use_stat->no_frq;
 #my @noun_list2 = $data->get_imp_word();
 # また、その結果を別のモードによる結果と掛け合わせる
 #@noun_list = $data->result_filter (\@noun_list, \@noun_list2, 30, 1000);
 
 #
 #  専門用語リストと計算した重要度を標準出力に出す
 #
 foreach (@noun_list) {
    # 数値のみは表示しない
    next if $_->[0] =~ /^\d+$/;
 
   # 結果表示
   printf "%-60s %16.2f\n", $_->[0], $_->[1] if $output_mode == 1;
   printf "%s\n",           $_->[0]          if $output_mode == 2;
   printf "%s,",            $_->[0]          if $output_mode == 3;
 }

=head1 Methods

    このモジュールでは、get_imp_word のみ実装し、それ以外のメソッドは親
  モジュール TermExtract::Calc_Imp で実装されている。
    get_imp_word は品詞タグ付与を行い抽出された単語を、個々の単語の語順
  と品詞情報を元に複合語に生成している。それ以外のメソッドについては、
  TermExtract::Calc_Imp のPODドキュメントを参照すること。

=head2 get_imp_word

    英文の品詞タグ付与結果を次のルールにより複合語に生成する。第１引数は、
  処理対象のデータ、第２引数は第１引数の種別である。デフォルトでは、第１
  引数は、品詞タグ付け済みのテキストファイルとなる。第２引数に文字列
  'var'がセットされたときには、第一引数を品詞タグ付け済のテキストデータ
  が入ったスカラー変数と解釈する。

    １．各品詞は次のとおり結合する
       （１）名詞(NN)      　　　→　名詞、形容詞、基数、過去分詞の動詞に
                                   結合する。複合語の先頭になる。
       （２）外来語(FW)    　　　→　単語として処理
       （３）基数(CD)      　　　→　複合語の先頭のみ許可する
       （４）形容詞(JJ)    　　　→　形容詞,所有格語尾,基数に結合する。
                                   複合語の先頭になる
        (５）所有格語尾(POS)　 　→　名詞に結合する
       （６）of　　　　　　　　　→　名詞に結合する
       （７）過去分詞の動詞(VBN) →　複合語の先頭のみ許可する

    ２．改行があった場合は、そこで複合語の区切りとする

    ３．次の記号や数値で始まる語の場合は、そこで複合語の区切りとする

        +-%\&\$*#^|

    ４．複合語は名詞か外来語で終わるものとし、以後は切り捨てる

    ５．固有名詞以外の名詞は、先頭が大文字の場合に小文字に変換する

    ６．複合語の名詞(NNS)を単数形に変える

    ７．' （シングルクォーテーション)で区切られた語は単語とする

    ８．複合語末尾の , . は除去する

    ９．重要度計算において次の語は無視する
      of Of OF

=head1 SEE ALSO

    TermExtract::Calc_Imp
    TermExtract::Chasen
    TermExtract::MeCab
    TermExtract::EnglishPlainText
    TermExtract::ChainesPlainTextUC
    TermExtract::ChainesPlainTextGB
    TermExtract::ICTCLAS
    TermExtract::JapanesePlainTextEUC
    TermExtract::JapanesePlainTextSJIS

=head1 COPYRIGHT

    このプログラムは、東京大学・中川裕志教授、横浜国立大学・森辰則助教授が
  作成した「専門用語自動抽出システム」のtermex_e.pl を元にモジュール
  TermExtract用に書き換えたものである。
    この作業は、東京大学・前田朗 (maeda@lib.u-tokyo.ac.jp)が行った。

    なお、本プログラムの使用において生じたいかなる結果に関しても当方では
  一切責任を負わない。

=cut


1;
