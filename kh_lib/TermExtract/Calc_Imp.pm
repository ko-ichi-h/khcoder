package TermExtract::Calc_Imp;

use strict;
use Fcntl;
use Exporter();
use vars qw(@ISA @EXPORT $VERSION *DB_File_Usable $DB_BTREE $MAX_CMP_SIZE);
# DB_Fileモジュールが使用可能ならモジュールを読み込み
BEGIN {
    if (eval "require DB_File") { 
        DB_File->import;
        *DB_File_Usable = \1; # DB_Fileモジュール使用可
    }
    else {
        *DB_File_Usable = \0; # DB_Fileモジュール使用不可
    }
}
$MAX_CMP_SIZE = 1024; # 半角空白区切りの単名詞リストの最大長

@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = "4,08";


# ========================================================================
# new -- constructor （オブジェクトの生成）
# 
# usage: $obj = TermExtract::Calc_Imp->new();
#
# ========================================================================
sub new {
    my $class = shift;
    my $self ={};
    bless $self, $class;
    $self->init();
    $self;
}


# ========================================================================
# init -- to initialize variables (オブジェクトのデフォルト値をセット)
#
# usage: $obj->init();
#
# ========================================================================
sub init {
    my $self = shift;
    $self->{'stat_db'}            = "stat.db";   # 単名詞ごとの連接統計情報を蓄積するDB
    $self->{'comb_db'}            = "comb.db";   # 出現した２語の連接とその頻度を蓄積するDB
    $self->{'comb_r_db'}          = "comb_r.db"; # comb.dbの連接語順を逆にしたもの（必須ではない）
    $self->{'df_db'}              = "df.db";     # df (Document Frequency)用のDB
    $self->{'lock_dir'}           = "";          # DBのロック用ディレクトリの指定
    $self->{'db_locked'}          = 0;           # DBがロック中かを記録 0 → ロックなし、1 → ロック中
    $self->{'LR'}                 = 1;           # LRの設定　0 → LRなし 1 → 延べ数 2 → 異なり数 
    	                                         # 3 →　パープレキシティ
    $self->{'frq'}                = 1;           # 文中の用語頻度を、有効にする → 1 無効にする → 0
    	                                         # TFにする → 2
    $self->{'cmp_noun_list'}      = {};          # 文中の専門用語とその頻度
    $self->{'average_rate'}       = 1;           # 重要度計算での連接情報と文中の用語頻度のバランス
    $self->{'stat_mode'}          = 0;           # 重要度計算で学習機能を 1 → 使う 0 → 使わない
    $self->{'storage_mode'}       = 0;           # 学習用DBにデータを 1 → 蓄積 0 → 蓄積しない
    $self->{'storage_df'}         = 0;           # df 用DBにデータを  1 → 蓄積 0 → 蓄積しない
    $self->{'with_idf'}           = 0;           # 重要度計算にIDFを  1 → 使う 0 → 使わない
    $self->{'get_word_done'}      = 0;           # 形態素解析のデータを 1 → 取込済 0 → 未取込
    $self->{'reset_get_word'}     = 0;           # 形態素解析のパラメータなしでも 1  →　強制取込
    $self->{'sdbm'}               = 0;           # SDBM_Fileを 真 → 使う、偽 → 使わない
    $self->{'ignore_words'}       = ();          # 重要度計算対象外にする語のリスト（配列）
    $self->{'agglutinative_lang'} = 0;           # 処理対象言語が 真 → 膠着言語、偽 → 非膠着言語
    $self;
}


#================================================================
#
# Calicurate LR of word. （専門用語の重要度の計算）
#
# usage: $obj->get_imp_word(Parameter_1, Parameter_2, ... Parameter_N);
#
#================================================================
sub get_imp_word {
    my $self = shift;
    my @param = @_;
    my $db = [];

    # LR でも頻度でも重要度計算しないときは強制終了
    if (($self->{'LR'} == 0) & ($self->{'frq'} == 0)) {
        die "Set Frequency or LR mode";
    }
    # get_imp_word のパラメータは全て get_noun_frq に渡す
    # パラメータ指定がない場合は、キャッシュしているデータを使う
    if ((@param != 0)||($self->{'reset_get_word'})) {
        $self->{'cmp_noun_list'} = $self->get_noun_frq (@param);
        if (($self->{'storage_mode'}|$self->{'storage_df'})  & ($DB_File_Usable|$self->{'sdbm'})) {
            # ロックディレクトリ方式でのロック（オプション）
            $self->lock_db or die "Now Busy!! Wait a minute" if $self->{'lock_dir'};
            # 学習用DBにデータを蓄積
            if ($self->{'storage_df'}) {
            	eval { $self->storage_df() }; 
            }
            elsif ($self->{'LR'} != 0) {
                eval { $self->storage_stat() }; 
            }
            if ($@) { 
                $self->unlock_db if $self->{'lock_dir'};
                die $@;
            }
            else {
                $self->unlock_db if $self->{'lock_dir'};
            }
        }
        $self->{'reset_get_word'} = 0;
    }
    else {
        unless ($self->{'get_word_done'}) {
            die "Can't calculate  of word!! Set right parameter at once";
        }
    }
    $self->{'get_word_done'} = 1;

    # DFモードのときは、重要度計算を行わない
    return @$db if ($self->{'storage_df'});

    # LR以外の重要度計算
    if ($self->{'LR'} == 0) {
        # 頻度を使っての重要度計算（学習機能を自動的にOFFにする)
        if ($self->{'frq'} == 1) {
            return @{ $self->calc_imp_by_HASH_Freq };
        }
        # TFを使っての重要度計算（学習機能を自動的にOFFにする)
        elsif ($self->{'frq'} == 2) {
            return @{ $self->calc_imp_by_HASH_TF };
        }
    }
    # パープレキシティを使ってのLR重要度計算（学習機能を自動的にOFFにする)
    elsif ($self->{'LR'} == 3) {
        return @{ $self->calc_imp_by_HASH_PP };
    }
    # 学習機能（連接統計DB）を使ってのLR重要度計算
    elsif ($self->{'stat_mode'} & ($DB_File_Usable|$self->{'sdbm'})) { 
        $self->lock_db or die "Now Busy!! Wait a minute";  # DBの競合を避ける
        eval { $db = $self->calc_imp_by_DB };
        if ($@) {
            $self->unlock_db if $self->{'lock_dir'};
            die $@;
        }
        else {
            $self->unlock_db if $self->{'lock_dir'};
        }
        return @$db;
    }
    # 学習機能（連接統計DB）を使わないLR重要度計算
    else {
        return @{ $self->calc_imp_by_HASH };
    }
}


#================================================================
#
# Get noun frequency [for overwrite]   
# （専門用語とその頻度を得る -- 子クラスでオーバーライトして使用)
#
# Parameters is setted by "get_noun_imp()"
#
# usage: $self->get_noun_frq(@AnyParameters);
#
#================================================================
sub get_noun_frq {}   # 派生クラスでオーバーライドするために定義


# ========================================================================
# storage_stat -- storage compound noun to Data Base File
# （連接統計DB[２種]に連接情報を蓄積）
# 
# usage: $self->storage_stat("Input_FileName");
#
# ========================================================================
sub storage_stat {
    my $self       = shift;
    my %stat_db = ();          # 単名詞単位の連接語統計DBにtieするハッシュ
    my %comb_db = ();          # ２語の連接の出現頻度DBにtieするハッシュ
    my $first_comb = 0;        # ２語の組み合わせが初出かどうかの判定フラグ

    # DBファイルを開く（２種）
    $self->dbopen($self->{'stat_db'}, \%stat_db, O_RDWR|O_CREAT);
    $self->dbopen($self->{'comb_db'}, \%comb_db, O_RDWR|O_CREAT);

    # 文中の専門用語ごとにループ
    while ( my($cmp_noun, $frq) = each %{$self->{'cmp_noun_list'}} ) {
        next if $cmp_noun eq "";                        # データがない場合読み飛ばし
        next if length($cmp_noun) > $MAX_CMP_SIZE;      # 最大長に達した場合読み飛ばし
        my @org_noun_list  = split(/\s+/, $cmp_noun);   # 単名詞リストの生成
        my @noun = ();
        my ($uniq_pre, $total_pre, $uniq_post, $total_post);

        # メソッド IgnoreWords で指定した語と数値を無視する
        LOOP:
        foreach my $word (@org_noun_list) {
            if ($self->{'ignore_words'}){
                foreach my $ignore (@{ $self->{'ignore_words'} }) {
                    next LOOP if $word eq $ignore;
                }
            }
            next if $word =~ /^[\d\.\,]+$/;
            push @noun, $word;
        }

        if (scalar @noun > 1) {   # 複合語の場合
            foreach my $i (0 .. $#noun-1) {
                my $comb_key = $noun[$i] . ' ' . $noun[$i+1];   # 2つの単名詞の組を生成
                # 複合語が既出の場合
                my $first_comb = 1 unless defined $comb_db{"$comb_key"};

                #
                #  単名詞ごとの連接統計情報[Pre(N), Post(N)]を累積
                #
                # post word (後ろにとりうる単名詞）
                $uniq_pre = $total_pre = $uniq_post = $total_post = 0;
                ($uniq_pre, $total_pre, $uniq_post, $total_post)
                    = split "\t", $stat_db{"$noun[$i]"} if defined $stat_db{"$noun[$i]"};
                $uniq_post   += 1 if $first_comb;
                $total_post  += $frq;
                $stat_db{"$noun[$i]"}
                    = sprintf "%d\t%d\t%d\t%d", $uniq_pre, $total_pre, $uniq_post, $total_post;

                # pre word　（前にとりうる単名詞）
                $uniq_pre = $total_pre = $uniq_post = $total_post = 0;
                ($uniq_pre, $total_pre, $uniq_post, $total_post)
                    = split "\t", $stat_db{"$noun[$i+1]"} if defined $stat_db{"$noun[$i+1]"};
                $uniq_pre    += 1 if $first_comb;
                $total_pre   += $frq;
                $stat_db{"$noun[$i+1]"}
                     = sprintf "%d\t%d\t%d\t%d", $uniq_pre, $total_pre, $uniq_post, $total_post;

                # 連接語とその頻度情報を累積
                if  (defined $comb_db{"$comb_key"}) {
                     $comb_db{"$comb_key"} += $frq;
                }
                else {
                    $comb_db{"$comb_key"} = $frq;
                }
            }
        }
    }
}


# ========================================================================
# storage_df -- storage compound noun to Data Base File
# (DF [Document Frequency]DBの情報を蓄積）
# 
# usage: $self->storage_df(;
#
# ========================================================================
sub storage_df {
    my $self       = shift;
    my %df_db = ();          # DFの統計用DBにtieするハッシュ
    # DBファイルを開く
    $self->dbopen($self->{'df_db'}, \%df_db, O_RDWR|O_CREAT);

    # 文中の専門用語ごとにループ
    foreach my $cmp_noun ( keys %{$self->{'cmp_noun_list'}} ) {
        next if $cmp_noun eq "";                        # データがない場合読み飛ばし
        next if length($cmp_noun) > $MAX_CMP_SIZE;      # 最大長に達した場合読み飛ばし
        $df_db{$cmp_noun}++;
    }
    # 文書数は半角スペースのハッシュで集計
    $df_db{' '}++;
}


#================================================================
#
# Calicurate importance of word by DB. （連接語統計DBから重要度を計算）
# And return sorted list by importance.
#
# usage: @array = $self->calc_imp_by_DB
#
#================================================================
sub calc_imp_by_DB {
    my $self = shift;
    my %stat_db;      # 単名詞ごとの連接語統計DBにtieするハッシュ
    my ($uniq_pre, $total_pre, $uniq_post, $total_post); # DBの値を入れる変数
    my $imp = 1;      # 専門用語全体の重要度
    my %n_imp;        # 「専門用語」をキーに、値を「重要度」にしたハッシュ
    my $count = 0;    # ループカウンター（専門用語中の単名詞数をカウント）
    my $n_cont;       # 「専門用語」をキーに、値を頻度(FrequnecyかTF)にしたハッシュ


    # 不正な average_rate のチェック
    if ($self->{'average_rate'} == 0) {
        warn "average_rate is invalid value \n";
        exit(0);
    }

    # 連接語統計DBを開く
    $self->dbopen($self->{'stat_db'}, \%stat_db, O_RDONLY);

    # 頻度をFrequency か TF のいずれでとるかを選択
    if (($self->{'frq'} == 0) | ($self->{'frq'} == 1)) {
    	$n_cont = $self->{'cmp_noun_list'};
    }
    else {
    	$n_cont = $self->calc_imp_by_HASH_TF();
    }

    # 専門用語ごとにループ
    while ( my($cmp_noun, $frq) = each %{$n_cont} ) {
        next if $cmp_noun eq "";
        next if length($cmp_noun) > $MAX_CMP_SIZE;
        LOOP:
        foreach my $noun (split /\s+/, $cmp_noun) {
            # メソッド IgnoreWords で指定した語と数値は無視する
            if ($self->{'ignore_words'}) {
                foreach my $ignore (@{ $self->{'ignore_words'} }) {
                    next LOOP if $noun eq $ignore;
                }
            }
            next if $noun =~ /^[\d\.\,]+$/;
            $uniq_pre = $total_pre = $uniq_post = $total_post = 0;
            ($uniq_pre, $total_pre, $uniq_post, $total_post)
                = split "\t", $stat_db{"$noun"} if defined $stat_db{"$noun"};
            # 連接語の延べ数をとる場合
            if ($self->{'LR'} == 1) {
                $imp *= ($total_pre + 1) * ($total_post + 1);
            }
            # 連接語の異なり数をとる場合
            elsif ($self->{'LR'} == 2)  {
                $imp *= ($uniq_pre + 1) * ($uniq_post + 1);
            }
            else {}
            $count++;
        }
        $count = 1 if $count == 0;
        # 相乗平均で重要度を出す
        if ($self->{'frq'} != 0) {
            $imp = $imp ** (1 / (2 * $self->{'average_rate'} * $count));   
            $imp = $imp * $frq;
        }
        else {
            $imp = $imp ** (1 / (2 * $self->{'average_rate'} * $count));
        }
        $n_imp{"$cmp_noun"} = $imp;
        $count = 0; $imp = 1;
    }
    return $self->modify_noun_list(\%n_imp);
}

#=================================================================
#
# Calicurate importance of word by temporary HASH.
# And return sorted list by importance.
# （文中の語のみから重要度を計算し、重要度でソートした専門用語リスト
#   を返す）
#
# usage: @array = $self->calc_imp_by_HASH
#
#================================================================
sub calc_imp_by_HASH {
    my $self = shift;
    my $imp = 1;       # 専門用語全体の重要度
    my %comb;          # 連接語とその出現頻度
    my %stat;          # 単名詞ごとの連接情報
    my %n_imp;         # 「専門用語」をキーに、値を「重要度」にしたハッシュ
    my $count = 0;     # ループカウンター（専門用語中の単名詞数をカウント）
    my $n_cont;        # 「専門用語」をキーに、値を頻度(FrequnecyかTF)にしたハッシュ

    # 専門用語ごとにループ
    foreach my $cmp_noun (keys %{$self->{'cmp_noun_list'}}) {
        next if $cmp_noun eq "";                   # データがない場合は読み飛ばし
        next if length($cmp_noun) > $MAX_CMP_SIZE; # 最大長に達した場合は読み飛ばし
        my @org_noun_list = split(/\s+/, $cmp_noun);
        my @noun = ();

        # # メソッド IgnoreWords で指定した語と数値を無視する
        LOOP:
        foreach my $word (@org_noun_list) {
            if ($self->{'ignore_words'}){
                foreach my $ignore (@{ $self->{'ignore_words'} }) {
                    next LOOP if $word eq $ignore;
                }
            }
            next if $word =~ /^[\d\.\,]+$/;
            push @noun, $word;
        }

        # 複合語の場合、連接語の情報をハッシュに入れる
        if (scalar @noun > 1) {
            foreach my $i (0 .. $#noun-1) {
                my $comb_key = "$noun[$i] $noun[$i+1]";
                my $first_comb = 1 unless defined $comb{"$comb_key"};
                # 連接語の”延べ数”をとる場合
                if ($self->{'LR'} == 1) {
                    $stat{$noun[$i]}[0]   += $self->{'cmp_noun_list'}{"$cmp_noun"};
                    $stat{$noun[$i+1]}[1] += $self->{'cmp_noun_list'}{"$cmp_noun"};
                }
                # 連接語の異なり数をとる場合
                elsif ($self->{'LR'} == 2 && defined $first_comb) {
                    $stat{$noun[$i]}[0]++;
                    $stat{$noun[$i+1]}[1]++;
                }
                else {}
            }
        }
    }

    # 頻度をFrequency か TF のいずれでとるかを選択
    if (($self->{'frq'} == 0) | ($self->{'frq'} == 1)) {
    	$n_cont = $self->{'cmp_noun_list'};
    }
    else {
    	$n_cont = $self->calc_imp_by_HASH_TF();
    }

    # 専門用語ごとにループ
    foreach my $cmp_noun (keys %{$n_cont}) {
        next if $cmp_noun =~ /^\s*$/;
        next if length($cmp_noun) > $MAX_CMP_SIZE;
        LOOP:
        foreach my $noun (split(/\s+/, $cmp_noun)){
            # メソッド IgnoreWords で指定した語と数値を無視する
            if ($self->{'ignore_words'}) {
                foreach my $ignore (@{ $self->{'ignore_words'} }) {
                    next LOOP if $noun eq $ignore;
                }
            }
            next if $noun =~ /^[\d\.\,]+$/;
            my $pre  = $stat{"$noun"}[0] || 0;
            my $post = $stat{"$noun"}[1] || 0;
            $imp *= ($pre + 1) * ($post + 1);
            $count++;
        }
        $count = 1 if $count == 0;
        # 相乗平均で重要度を出す
        if ($self->{'frq'} != 0) {
            $imp = $imp ** (1 / (2 * $self->{'average_rate'} * $count));
            $imp = $imp * $n_cont->{"$cmp_noun"};
         }
        else {
            $imp = $imp ** (1 / (2 * $self->{'average_rate'} * $count));
        }
        $n_imp{"$cmp_noun"} = $imp;
        $count = 0; $imp = 1;
    }
    return $self->modify_noun_list(\%n_imp);
}


#=================================================================
#
# Calicurate importance of word by temporary HASH.(Perplexity)
# And return sorted list by importance.
# （文中の語のみから重要度を計算し、パープレキシティによる重要度で
#  ソートした専門用語リストを返す）
#
# usage: @array = $self->calc_imp_by_HASH_PP
#
#================================================================
sub calc_imp_by_HASH_PP {
    my $self = shift;
    my $imp = 0;       # 専門用語全体の重要度
    my %comb;          # 連接語とその出現頻度
    my %stat;          # 単名詞ごとの連接情報
    my %n_imp;         # 「専門用語」をキーに、値を「重要度」にしたハッシュ
    my $count = 0;     # ループカウンター（専門用語中の単名詞数をカウント）
    my %post;          # ２語の形態素組み合わせの頻度(post)
    my %pre;           # ２語の形態素組み合わせの頻度(pre)
    my %stat_PP;       # パープレキシティ用の形態素別統計情報
    my $n_cont;        # 「専門用語」をキーに、値を頻度(FrequnecyかTF)にしたハッシュ

    # 頻度をFrequency か TF のいずれでとるかを選択
    if (($self->{'frq'} == 0) | ($self->{'frq'} == 1)) {
    	$n_cont = $self->{'cmp_noun_list'};
    }
    else {
    	$n_cont = $self->calc_imp_by_HASH_TF();
    }

    # 専門用語ごとにループ
    foreach my $cmp_noun (keys %{$n_cont}) {
        next if $cmp_noun eq "";                   # データがない場合は読み飛ばし
        next if length($cmp_noun) > $MAX_CMP_SIZE; # 最大長に達した場合は読み飛ばし
        my @org_noun_list = split(/\s+/, $cmp_noun);
        my @noun = ();

        # # メソッド IgnoreWords で指定した語と数値を無視する
        LOOP:
        foreach my $word (@org_noun_list) {
            if ($self->{'ignore_words'}){
                foreach my $ignore (@{ $self->{'ignore_words'} }) {
                    next LOOP if $word eq $ignore;
                }
            }
            next if $word =~ /^[\d\.\,]+$/;
            push @noun, $word;
        }

        # 複合語の場合、連接語の情報をハッシュに入れる
        if (scalar @noun > 1) {
            foreach my $i (0 .. $#noun-1) {
                $stat{$noun[$i]}[0]   += $self->{'cmp_noun_list'}{"$cmp_noun"};
                $stat{$noun[$i+1]}[1] += $self->{'cmp_noun_list'}{"$cmp_noun"};
                $pre{$noun[$i+1]}{$noun[$i]}++;
                $post{$noun[$i]}{$noun[$i+1]}++;
                # 全ての単名詞について処理
                foreach my $noun1 (keys %stat) {
                    my $h = 0;
                    my $work;
                    # 単名詞のエントロピーを求める（後に連接するケース）
            	    if (defined $stat{$noun1}[0]) {
            	        foreach my $noun2 (%{ $post{$noun1} }) {
            	        	if (defined $post{$noun1}{$noun2}) {
            	                $work = $post{$noun1}{$noun2} / ($stat{$noun1}[0] + 1);
            	                $h -= $work * log($work);
            	            }
            	        }
            	    }
            	    # 単名詞のエントロピーを求める（前に連接するケース）
             	    if (defined $stat{$noun1}[1]) {
            	        foreach my $noun2 (%{ $pre{$noun1} }) {
            	        	if (defined $pre{$noun1}{$noun2}) {
            	                $work = $pre{$noun1}{$noun2} / ($stat{$noun1}[1] + 1);
            	                $h -= $work  * log($work);
            	            }
            	        }
            	    }
            	    $stat_PP{$noun1} = $h;
            	}
            }
        }
    }

    # 専門用語ごとにループ
    foreach my $cmp_noun (keys %{$self->{'cmp_noun_list'}}) {
        next if $cmp_noun =~ /^\s*$/;
        next if length($cmp_noun) > $MAX_CMP_SIZE;
        LOOP:
        foreach my $noun (split(/\s+/, $cmp_noun)){
            # メソッド IgnoreWords で指定した語と数値を無視する
            if ($self->{'ignore_words'}) {
                foreach my $ignore (@{ $self->{'ignore_words'} }) {
                    next LOOP if $noun eq $ignore;
                }
            }
            next if $noun =~ /^[\d\.\,]+$/;
            $imp += $stat_PP{$noun} if $stat_PP{$noun};
            $count++;
        }
        $count = 1 if $count == 0;
        $imp = $imp / (2 * $self->{'average_rate'} * $count);
        $imp += log($n_cont->{"$cmp_noun"}+1) if $self->{'frq'} != 0;
        $imp = $imp / log(2);
        $n_imp{"$cmp_noun"} = $imp;
        $count = 0; $imp = 0;
    }
    return $self->modify_noun_list(\%n_imp);
}


#=================================================================
#
# Calicurate importance of word by temporary HASH on  Frequency
# And return sorted list by importance.
# （文中の頻度を重要度とし、重要度でソートした専門用語リスト
#   を返す）
#
# usage: @array = $self->calc_imp_by_HASH_Freq
#
#================================================================
sub calc_imp_by_HASH_Freq {
    my $self = shift;
    my $imp = 1;       # 専門用語全体の重要度
    my %n_imp;         # 「専門用語」をキーに、値を「重要度」にしたハッシュ

    # 専門用語ごとにループ
    foreach my $cmp_noun (keys %{$self->{'cmp_noun_list'}}) {
        next if $cmp_noun =~ /^\s*$/;
        next if length($cmp_noun) > $MAX_CMP_SIZE;
        $n_imp{"$cmp_noun"} = $self->{'cmp_noun_list'}{"$cmp_noun"};
    }
    return $self->modify_noun_list(\%n_imp);
}


#=================================================================
#
# Calicurate importance of word by temporary HASH on Term Frequency
# And return sorted list by importance.
# （TFを重要度とし、重要度でソートした専門用語リストを返す）
#
# usage: @array = $self->calc_imp_by_HASH_TF
#
#================================================================
sub calc_imp_by_HASH_TF {
    my $self = shift;
    my $imp = 1;        # 専門用語全体の重要度
    my %n_imp;          # 「専門用語」をキーに、値を「重要度」にしたハッシュ
    my @TF_data = [];   # TF重要度計算用の作業用配列
    my $length_of_word; # 用語の長さ（単名詞数)

    # 専門用語ごとにループ
    foreach my $cmp_noun (keys %{$self->{'cmp_noun_list'}}) {
        next if $cmp_noun =~ /^\s*$/;
        next if length($cmp_noun) > $MAX_CMP_SIZE;
        my @words = (split /\s+/, $cmp_noun);
        $length_of_word = $#words+1;
        push @{ $TF_data[$length_of_word] }, $cmp_noun;
        $n_imp{$cmp_noun} = $self->{'cmp_noun_list'}{"$cmp_noun"}
    }
    # 短い語からループ
 
    foreach my $num1 (2 .. $#TF_data) {
        my @noun1_array;
    	foreach my $noun1 (@{ $TF_data[$num1-1] }) {
    		if ($num1 == 2) { $noun1_array[0] = $noun1; }
    	    else { @noun1_array = (split /\s+/, $noun1); }
    		# 長い語

    		foreach my $num2 ($num1 .. $#TF_data) {
    			foreach my $noun2 (@{ $TF_data[$num2] }) {
                    my @noun2_array = (split /\s+/, $noun2);
                    LOOP:
                    foreach my $i (0 .. $#noun2_array) {
                    	if ($noun2_array[$i] eq $noun1_array[0]) {

                    		if ($num1 == 2) { $n_imp{"$noun1"} += $n_imp{"$noun2"} }
                    		else {
                    		    foreach my $j (1 .. $#noun1_array) {
                    		        next LOOP if $i+$j > $#noun2_array;
                    		        next LOOP if $j    > $#noun1_array;
                    		        next LOOP unless $noun2_array[$i+$j] eq $noun1_array[$j];
                    		    }
                                $n_imp{"$noun1"} += $n_imp{"$noun2"};
                            }
                        }
                    }
                }
            }
        }
    }
    # LRとの組み合わせの場合
    if ($self->{'LR'} != 0) {
       return \%n_imp;
    }
    # TF単独の場合
    else {
       return $self->modify_noun_list(\%n_imp);
    }
}


#=================================================================
#
#  Modfy extract word and inportance.
# （用語抽出結果の調整処理を行う）
#
# usage: $self->modify_noun_list(\@noun_list);
#
#================================================================

sub modify_noun_list {
	my $self       = shift;
	my $n_imp      = shift; # 「専門用語」をキーに、値を「重要度」にしたハッシュリファレンス
    my @noun_list;          # 重要度順の専門用語リスト（専門用語とその重要度）
    my $data;               # 専門用語
    my $data_disp;          # 専門用語を表示用（単名詞区切なし）に加工
    my %df_db;              # df用の統計DBにTieするハッシュ
    if ($self->{'with_idf'}) {
    	 # DF用統計DBを開く
         $self->dbopen($self->{'df_db'}, \%df_db, O_RDONLY);
         my $doc_count = $df_db{' '}; # 半角スペースは文書数
         last if $doc_count < 1;
         # 専門用語ごとにループ
         foreach $data (keys %{ $n_imp }) {
         	 my $idf = $doc_count / $df_db{$data};
             $n_imp->{$data} *= ( (log $idf / log(2)) +1 );
         }
    }
    # 専門用語を重要度順にソート
    if ($self->{'agglutinative_lang'}) {
        foreach $data ( sort { $n_imp->{$b} <=> $n_imp->{$a} } keys %{$n_imp} ) {
             $data_disp = modify_agglutinative_lang($data);
             push @noun_list,  [ $data_disp, $n_imp->{"$data"} ];
         }
     }
     else {
        foreach $data ( sort { $n_imp->{$b} <=> $n_imp->{$a} } keys %{$n_imp} ) {
             push @noun_list,  [ $data, $n_imp->{"$data"} ];
        }
    }
    return \@noun_list;
}


#================================================================
#
# Filtering extract word list by list
# （専門用語リストを、他の専門用語リストでフィルタリング）
#
# usage: $obj->result_filter(\@list_a, \@list_b, $limit_a, $limit_b);
#
#================================================================
sub result_filter {
    my $self    = shift;
    my $imp_a   = shift;           # 専門用語リスト(A)
    my $imp_b   = shift;           # 専門用語リスト(B)
    my $limit_a = shift || 100000; # 専門用語リスト(A)のフィルタリングの上限数
    my $limit_b = shift || 100000; # 専門用語リスト(B)のフィルタリングの上限数
    my %db_exsist;                 # 専門用語が既出かどうか判定するためのハッシュ
    my @result;                    # フィルタリング結果の専門用語リスト
    my $counter = 1;               # フィルタリング上限数判定用

    # 専門用語リスト(A)を作業用のハッシュに移し変え
    foreach (@$imp_a) {
        $db_exsist{$_->[0]}++;
        last if $counter >= $limit_a;
        $counter++;
    }

    # 専門用語リスト(B)と作業用のハッシュの比較
    $counter = 1;
    foreach (@$imp_b) {
        if (defined $db_exsist{$_->[0]}) {
            push @result, $_;
        }
        last if $counter >= $limit_b;
        $counter++;
    }

    return @result;
}


#================================================================
#
# Modify extract word list to readable
# （日本語などの膠着言語[単語区切りなし]の複合語を、表示用に加工）
#
# usage: modify_agglutinative_lang("some word");
#
#================================================================
sub modify_agglutinative_lang {
    my $data = shift;
    my $data_disp = "";
    my $eng  = 0;
    my $eng_pre = 0;
    foreach my $noun (split /\s+/, $data) {
        if ($noun =~ /^[\x21-\x7E]+$/) { $eng = 1; }  # \x21-\x7EはASCIIコード
        else                           { $eng = 0; }
        if ($eng & $eng_pre) { $data_disp .= ' ' . $noun; } # 前後ともASCIIなら半角空白空け
        else                 { $data_disp .=       $noun; } # 上記以外なら区切りなしで連結
        $eng_pre = $eng;
    }
    return $data_disp;
}


#================================================================
#
# Set Average rate
# （ドキュメント中の頻度を掛ける重要度計算の際の、
#   "連接語"と"ドキュメント中の頻度"のバランスをセット)
#
# usage: $obj->average_rate($Any_numerical_value);
#
#================================================================
sub average_rate {
    my $self = shift;
    my $rate = shift;
    if (defined $rate) {
        if ($rate =~ /^\d+/ && $rate != 0) {
            $self->{'average_rate'} = $rate;
        }
    }
    else {
        return $self->{'average_rate'};
    }
}


#================================================================
#
# Dump stat data from DB
# （単名詞ごとの連接後統計DBの内容を出力する)
#
# usage: $obj->dump_stat_db($Any_key_word);
#
#================================================================
sub dump_stat_db {
    my $self = shift;
    my $key  = shift;      # 検索用キー
    my $mode = shift;      # 真であれば完全一致モード
    my %db_hash;
    local (*DB);
    my $db  = $self->dbopen($self->{'stat_db'}, \%db_hash, O_RDONLY);

    if ($key) {
        # SDBM の場合は完全一致モード
        if ($mode|$self->{'sdbm'}) {
            print $key, "\t";
            $db_hash{$key} ? print $db_hash{$key} : print join "\t", (0,0,0,0);
            print "\n";
        }
        # Berkeley DB の場合は前方一致モード
        else {
            lmatch($$db, $key);
        }
    }
    else {
        foreach  (keys %db_hash) {
            print $_, "\t", $db_hash{$_}, "\n";
        }
    }
}


#================================================================
#
# Dump combinated word data from DB
# （２語の単名詞の組の出現頻度情報を出力する)
#
# usage: $obj->dump_comb_db([$Any_key_word] [,$bool]);
#
#================================================================
sub dump_comb_db {
    my $self = shift;
    my $key  = shift; # 検索用キー
    my $mode = shift; # 真であれば完全一致モード
    my %db_hash;

    my $db  = $self->dbopen($self->{'comb_db'}, \%db_hash, O_RDONLY);
    if ($key) {
        # SDBM の場合は完全一致モード
        if ($mode|$self->{'sdbm'}) {
            print $key, "\t";
            print $db_hash{$key} if $db_hash{$key};
            print "\n";
        }
        # Berkeley DB の場合は前方一致モード
        else {
            lmatch($$db, $key);
        }
    }
    else {
        foreach  (keys %db_hash) {
            print $_, "\t", $db_hash{$_}, "\n";
        }
    }
}


#================================================================
#
# Dump combinated word from DB (reversed)
# （２語の単名詞の組の出現頻度情報 --語を逆順にしたのもの-- を出力する)
#
# usage: $obj->dump_comb_r_db([$Any_key_word] [,$bool]);
#
#================================================================
sub dump_comb_r_db {
    my $self = shift;
    my $key  = shift; # 検索用キー
    my $mode = shift; # 真であれば完全一致モード
    my %db_hash;

    my $db  = $self->dbopen($self->{'comb_r_db'}, \%db_hash, O_RDONLY);
    if ($key) {
        # SDBM の場合は完全一致モード
        if ($mode|$self->{'sdbm'}) {
            print $key, "\t";
            print $db_hash{$key} if $db_hash{$key};
            print "\n";
        }
        # Berkeley DB の場合は前方一致モード
        else {
            lmatch($$db, $key);
        }
    }
    else {
        foreach  (keys %db_hash) {
            print $_, "\t", $db_hash{$_}, "\n";
        }
    }
}


#================================================================
#
# Dump stat data from DF DB
# （DF用統計DBの内容を出力する)
#
# usage: $obj->dump_df_db($Any_key_word);
#
#================================================================
sub dump_df_db {
    my $self = shift;
    my $key  = shift;      # 検索用キー
    my $mode = shift;      # 真であれば完全一致モード
    my %db_hash;
    local (*DB);
    my $db  = $self->dbopen($self->{'df_db'}, \%db_hash, O_RDONLY);

    if ($key) {
        # SDBM の場合は完全一致モード
        if ($mode|$self->{'sdbm'}) {
            print $key, "\t";
            $db_hash{$key} ? print $db_hash{$key} : print join "\t", (0,0,0,0);
            print "\n";
        }
        # Berkeley DB の場合は前方一致モード
        else {
            lmatch($$db, $key);
        }
    }
    else {
        foreach  (keys %db_hash) {
            print $_, "\t", $db_hash{$_}, "\n";
        }
    }
}


#================================================================
#
# Make combinated word from DB (reversed)
# （連接語の出現頻度情報の語を逆順にしたDBを作成する)
#
# usage: $obj->make_comb_r_db();
#
#================================================================
sub make_comb_rev {
    my $self = shift;
    my %comb_db;          # 連接語の頻度情報ＤＢ（正順）
    my %comb_r_db;        # 連接語の頻度情報ＤＢ（逆順）
    my $words     = "";   # ２語からなる連接語
    my $words_r   = "";   # $word を逆順にしたもの
    my $word_pre  = "";   # ２語からなる連接語の前の語
    my $word_post = "";   # ２語からなる連接語の後ろの語

    # 連接語の頻度統計DBとその逆順用のDBを開く
    $self->dbopen($self->{'comb_db'},   \%comb_db,   O_RDONLY);
    $self->dbopen($self->{'comb_r_db'}, \%comb_r_db, O_RDWR|O_CREAT);

    # 連接語の頻度統計DBの逆順を作成
    undef %comb_r_db;
    foreach  $words (keys %comb_db) {
        ($word_pre, $word_post) = split /\s+/, $words;
        $words_r = "$word_post $word_pre";
        $comb_r_db{$words_r} = $comb_db{$words};
    }
}


#================================================================
#
# Set file name of "stat_db"
# (単名詞ごとの、連接語統計DBのファイル名をセット）
#
# usage: $obj->stat_db("AnyFileName");
#
#================================================================
sub stat_db {
    my $self = shift;
    if (defined $_[0] && $_[0] =~ /^[\.]*[\/]*$/) 
           { die "Iregurar name for DB File Name $_[0]\n"; }
    defined $_[0]
        ? $self->{'stat_db'} = $_[0]
        : return $self->{'stat_db'};
}


#================================================================
#
# Set file name of "comb_db"
# (連接語の頻度統計DBのファイル名をセット）
#
# usage: $obj->comb_db("AnyFileName");
#
#================================================================
sub comb_db {
    my $self = shift;
    if (defined $_[0] && $_[0] =~ /^[\.]*[\/]*$/) 
           { die "Iregurar name for DB File $_[0]\n"; }
    defined $_[0]
        ? $self->{'comb_db'} = $_[0]
        : return $self->{'comb_db'};
}


#================================================================
#
# Set file name of "comb_r_db"
# ("逆順"の連接語の頻度統計DBのファイル名をセット）
#
# usage: $obj->comb_r_db("AnyFileName");
#
#================================================================
sub comb_r_db {
    my $self = shift;
    if (defined $_[0] && $_[0] =~ /^[\.]*[\/]*$/) 
           { die "Iregurar name for DB File $_[0]\n"; }
    defined $_[0]
        ? $self->{'comb_r_db'} = $_[0]
        : return $self->{'comb_r_db'};
}


#================================================================
#
# Clear data from DB
# (学習用ＤＢのデータをクリアする)
#
# usage: $obj->clear_db;
#
#================================================================
sub clear_db {
    my $self = shift;
    my %stat_db = ();          # 単名詞単位の連接語統計DBにtieするハッシュ
    my %comb_db = ();          # ２語の連接の出現頻度DBにtieするハッシュ
    $self->dbopen($self->{'stat_db'}, \%stat_db, O_RDWR|O_CREAT);
    $self->dbopen($self->{'comb_db'}, \%comb_db, O_RDWR|O_CREAT);
    %stat_db = ();
    %comb_db = ();
}


#================================================================
#
# Clear data from DF DB
# (DF用ＤＢのデータをクリアする)
#
# usage: $obj->clear_df_db;
#
#================================================================
sub clear_df_db {
    my $self = shift;
    my %df_db = ();          # DF用統計DBにtieするハッシュ
    $self->dbopen($self->{'df_db'}, \%df_db, O_RDWR|O_CREAT);
    %df_db = ();
}


#================================================================
#
# Open DBM
# (DBMのオープン)
#
# usage: $obj->dbopen($db_filename, \%hash_for_tie, $mode);
#
#================================================================
sub dbopen {
    my $self  = shift;
    my $file  = shift;       # DBのファイル名
    my $hash  = shift;       # DBとtieするためのハッシュリファレンス
    my $mode  = shift;       # Fnctlのファイルオープンのモード

    # Berkeley DB の場合
    unless ($self->{'sdbm'}) {
        my $db = tie (%$hash, 'DB_File', $file, $mode, 0644, $DB_BTREE)
            || die "Can not open DB_File $file\n";
        return \$db;
    }
    # SDBM の場合
    else {
       tie (%$hash, 'SDBM_File', $file, $mode, 0644)
            || die "Can not open SDBM_File $file\n";
       return 1;
    }
}


#================================================================
#
# Use SDBM insted of Berkeley DB
# (学習用DBにSDBMを使う）
#
# usage: $obj->use_SDBM;
#
#================================================================
sub use_SDBM {
    my $self = shift;
    use SDBM_File;
    $self->{'sdbm'} = 1;
    $self;
}


#================================================================
#
# Set directory name of "lock_dir"
# （連接語統計DBのロック時にフラグの役割を果たすディレクトリ名をセット）
#
# usage: $obj->lock_dir("AnyDirName");
#
#================================================================
sub lock_dir {
    my $self = shift;
    if (defined $_[0] && $_[0] =~ /^[\.]*[\/]*$/) 
           { die "Iregurar name for lock directory $_[0]\n"; }
    defined $_[0]
        ? $self->{'lock_dir'} = $_[0]
        : return $self->{'lock_dir'};
}


#================================================================
#
# Set calcutate mode to "no_LR"
# （重要度計算で、用語の連接情報Lを使わないモードにセット）
#
# usage: $obj->use_uniq;
#
#================================================================
sub no_LR {
    my $self = shift;
    $self->{'LR'} = 0;
    $self;
}


#================================================================
#
# Set calcurate mode to "use_total"
# （重要度計算で、連接語の頻度をとるモードにセット）
#
# usage: $obj->use_total;
#
#================================================================
sub use_total {
    my $self = shift;
    $self->{'LR'} = 1;
    $self;
}


#================================================================
#
# Set calcutate mode to "use_uniq"
# （重要度計算で、連接語の延べ数をとるモードにセット）
#
# usage: $obj->use_uniq;
#
#================================================================
sub use_uniq {
    my $self = shift;
    $self->{'LR'} = 2;
    $self;
}


#================================================================
#
# Set calcutate mode to "use_Perplexity"
# （重要度計算で、パープレキシティをとるモードにセット）
# usage: $obj->use_Perplexity;
#
#================================================================
sub use_Perplexity {
    my $self = shift;
    $self->{'LR'} = 3;
    $self;
}


#================================================================
#
# Set calcurate mode to "no_frq"
# （重要度計算で、ドキュメント上の専門用語の頻度をとらないモードにセット）
#
# usage: $obj->no_frq;
#
#================================================================
sub no_frq {
    my $self = shift;
    $self->{'frq'} = 0;
    $self;
}

#================================================================
#
# Set calcuttate mode to "use_frq"
# (重要度計算で、ドキュメント上の専門用語の頻度をとるモードにセット
# デフォルト値）
#
# usage: $obj->use_frq;
#
#================================================================
sub use_frq {
    my $self = shift;
    $self->{'frq'} = 1;
    $self;
}


#================================================================
#
# Set calcutate mode to "use_TF"
# （重要度計算をTFでをとるモードにセット、用語が他の用語の一部と
#   して現れた場合も頻度をカウント）
# usage: $obj->use_TF
#
#================================================================
sub use_TF {
    my $self = shift;
    $self->{'frq'} = 2;
    $self;
}


#================================================================
#
# Set calcurate mode to "use_stat_DB"
# （重要度計算で、連接語統計DBを使用するモードにセット）
#
# usage: $obj->use_stat;
#
#================================================================
sub use_stat {
    my $self = shift;
    $self->{'stat_mode'} = 1;
    $self;
}


#================================================================
#
# Set calcurate mode to "no_stat"
# （重要度計算で、連接語統計DBを使用しないモードにセット）
#
# usage: $obj->no_stat
#
#================================================================
sub no_stat {
    my $self = shift;
    $self->{'stat_mode'} = 0;
    $self;
}


#================================================================
#
# Set storage mode ON
# (連接語統計DBにデータを蓄積するモードにセット）
#
# usage: $obj->use_storage;
#
#================================================================
sub use_storage {
    my $self = shift;
    $self->{'storage_mode'} = 1;
}


#================================================================
#
# Set storage mode OFF
# (連接語統計DBにデータを蓄積しないモードにセット）
#
# usage: $obj->no_storage;
#
#================================================================
sub no_storage {
    my $self = shift;
    $self->{'storage_mode'} = 0;
}


#================================================================
#
# Calculate importance of term with IDF
# (重要度計算にIDFを使用するモードにセット）
#
# usage: $obj->wiht_idf;
#
#================================================================
sub with_idf {
    my $self = shift;
    $self->{'with_idf'} = 1;
}


#================================================================
#
# NOt calculate importance of term with IDF
# (重要度計算にIDFを使用しないモードにセット）
#
# usage: $obj->no_idf;
#
#================================================================
sub no_idf {
    my $self = shift;
    $self->{'with_idf'} = 0;
}


#================================================================
#
# Set DFstorage mode ON
# (DF用統計DBにデータを蓄積するモードにセット）
#
# usage: $obj->use_storage_df;
#
#================================================================
sub use_storage_df {
    my $self = shift;
    $self->{'storage_df'} = 1;
}


#================================================================
#
# Set DF storage mode OFF
# (統計DBにデータを蓄積しないモードにセット）
#
# usage: $obj->no_storage_df;
#
#================================================================
sub no_storage_df {
    my $self = shift;
    $self->{'storage_df'} = 0;
}


#================================================================
#
# set Ignore words
# （重要度計算対象外にする語を指定）
#
# usage: $obj->Ignore words($Any_words_list);
#
#================================================================
sub IgnoreWords {
    my $self  = shift;
    my @words = @_;
    if (@words) {
        $self->{'ignore_words'} = \@words;
    }
    else {
        return @{ $self->{'ignore_words'} };
    }
}


#================================================================
#
# Set language type to agglutinative language
# (処理対象言語を膠着言語[日本語]、と孤立語[中国語など]の単語区切
#  のない言語にセット）
#
# usage: $obj->IsAgglutinativeLang;
#
#================================================================
sub IsAgglutinativeLang {
    my $self = shift;
    $self->{'agglutinative_lang'} = 1;
}


#================================================================
#
# Set language type to not agglutinative language
# (処理対象言語をアルファベットなど単語区切のある語にセット）
#
# usage: $obj->NotAgglutinativeLang;
#
#================================================================
sub NotAgglutinativeLang {
    my $self = shift;
    $self->{'agglutinative_lang'} = 0;
}


#================================================================
#
# Reset "get_noun_imp()" result
# (関数 get_noun_imp のデータを再度取り込む場合に使用、
#  get_noun_imp がパラメータを何もとらない設計の場合のみ）
#
# usage: $obj->reset_get_word;
#
#================================================================
sub reset_get_word {
    my $self = shift;
    $self->{'reset_get_word'} = 1;
    $self;
}


#================================================================
#
# Lock DB File
# (DBの競合を避けるためのロックをロックディレクトリ方式で行う)
#
#  usage: $obj->lock_db;
#
#================================================================
sub lock_db {
    my $self = shift;
    my $lockdir = $self->{'lock_dir'}; # ロックディレクトリ
    if ($lockdir) {
        my $retry = 5; # ロックのリトライ回数
        while (!mkdir($lockdir, 0755)) {
            if (--$retry <= 0) { return 0; }
            sleep(1);
        }
    }
    $self->{'db_locked'} = 1;
    return 1;
}


#================================================================
#
# Un-Lock DB File
# (DBの競合を避けるためのロックディレクトリ方式のロックをはずす)
#
#  usage: $obj->unlock_db;
#
#================================================================
sub unlock_db {
    my $self = shift;
    my $lockdir = $self->{'lock_dir'}; # ロックディレクトリ
    if ($self->{'db_locked'}) {
        # ロックディレクトリを単に削除
        rmdir($lockdir) if -e $lockdir;
    }
    $self->{'db_locked'} = 0;
}


#================================================================
#
# Return DB is locked
# (DBがロック中かどうかを返す)
#
#  usage: $obj->db_locked;
#
#================================================================
sub db_locked {
    my $self = shift;
    # 0 → ロックなし、1 → ロック中
    return $self->{'db_locked'};
}


#================================================================
#
# Get key & value from Berkeley DB
# (Berkeley DBからキーの前方一致で値を取り出す）
#
# usage: lmatch(\%db, "Any_Key_word");
#
#================================================================
sub lmatch {
    my $db    = shift;                # tie( %hash, "DB_File ) の返り値
    my $key   = shift;                # 前方一致マッチングしたいキー
    my $okey  = $key;
    my $value = "";
    my $opt   = DB_File::R_CURSOR(); # 前方一致指定オプション
    my $hash  = {};
    while ( 1 ) {
        # １回目のみ＝前方一致で $key, $value を取り出す
        # ２回目以降＝Ｂ木の次の $key, $value を取り出す
        # 返り値が真の場合、ＤＢの末尾なので終了
        $db->seq( $key, $value, $opt ) and last;

        # 本当にキー前方一致しているか確認する
        last unless ( $key =~ /^\Q$okey\E(.*)$/s );

        print $key, "\t", $value, "\n";

        $opt = DB_File::R_NEXT();   # 次のキーを取り出すオプション
    }
}


1;

__END__

=head1 NAME

    TermExtract::Calc_Imp -- 専門用語重要語計算モジュール


=head1 SYNOPSIS

    use TermExtract::Calc_Imp;


=head1 DESCRIPTION

    TermExtract はテキストデータから、専門用語を取り出すためのPerlモジュ
  ールである。
    「茶筅」、「和布蕪」などの形態素解析ソフトや"Brill's Tagger"などの英
  文の品詞タグ付けソフトの処理結果、もしくは文章そのものを入力とし、複合
  語（もしくは単語）の生成と、その重要度の計算と重要度順の並び替えを行う。
    「茶筅」などからの複合語の生成は、このCalc_Impの子クラスで定義される
  メソッド get_imp_word で処理し、Calc_Imp本体は用語の重要度の計算と重要
  度順のリストの生成のみを行う。これにより、子クラスを新規に用意すること
  で、多種の形態素解析ソフト等への対応を可能にしている。また、このこのモ
　ジュールは入力となる文字コードによらず動作する。

    重要度計算は、次のとおり行う。

    このモジュールでの専門用語は、単語そのものか、複数の単語を組み合わせ
  て作られる。この複合語を構成する最小単位の名詞を特に「単名詞」と呼ぶ。
  この単名詞が他の単名詞と連結して複合語をなすことが多いほど、重要な概念
  を表すと考える。
　  簡単な例で、「情報科学技術」を考えてみる。この語は、次のとおり３つの
  単名詞に分割できる。この際、それぞれの単名詞が他の単名詞とどれだけ結び
  つくか統計的にわかっているとする。

   単名詞　　前の語に連結した回数　　後の語に連結した回数
   --------------------------------------------------------
  「情報」　　　　　１　　　　　　　　　　　　　　　２
  「科学」　　　　　２　　　　　　　　　　　　　　　３
  「技術」　　　　　１　　　　　　　　　　　　　　　１

    複合語全体の重要度はこれらの６つ（単名詞数ｘ２）の数値の平均から求め
  る。このモジュールでは平均を相乗平均でとるようにした。
  （正確には相乗平均をとる際、０回の単名詞を扱う関係から１を加算した値の
    相乗平均を用いる）

    前述のとおり、Calc_Impは子クラスでメソッド get_noun_frq をオーバーラ
  イドすることで動作する。
    そのメソッド get_noun_frq の入出力仕様は次のとおり。

    引数
        第１引数 ----  オブジェクト
        第２引数以下は任意に定義可能

    戻り値
        次のキーと値からなるハッシュリファレンスを返すこと

        キー  ----  単名詞を半角スペースで区切り表示した複合語
                  （例　"航空 工業 デザイン"）

        値    ----  文中のキー（複合語）の出現回数

      なお、キーの上限サイズは１Ｋバイトとし、それ以上の場合は異常とみ
    なし、無視するようにした。

      また、日本語や中国語のように単名詞が１字空けで表記されない言語
    （膠着言語や孤立語）の場合には、get_noun_frq内で次のメソッドを実行
    すること。これにより、アルファベット以外の単名詞は１字空けなしで結
    果出力される。
    (Calc_Imp.pm ver.2.00 から膠着言語の明示的な設定が必要になった）

         $obj->IsAgglutinativeLang;                    ($objはオブジェクト)

      また、次のメソッドを使い重要度計算を行わない語（"of"のように他の語と
    多数の組み合わせができてしまう語）を登録することもできる。
         $obj->IgnoreWords('単語Ａ', '単語Ｂ' ...);  ($objはオブジェクト)

      (Calc_Imp.pm の ver.1.xx では配列 @TermExtract::Calc_Imp::IgnoreWords
       で指定していたが、ver.2.00 から上記の方式に変更）

      １バイトの数値は重要度計算の対象から外した（単位を示す語の重要度が高
    くなりすぎることを防ぐため）。
      １バイト数値と、$obj->IgnoreWords の語が単語で現れた場合は、連接統計
    情報を常に１とするが、用語の抽出は行う。


=head1 INSTALL

    このモジュールを「学習機能」とDF(Document Frequency)を用いた重要度
  計算をサポートしている。その学習用には学習用のDBファイルが必要である。
    DBファイルは、Perlの DB_File モジュール（バークレーDB）の使用を推奨
  している。もし、DB_Fileが使えない場合は、SDBM_File を使うよう設定
  ($obj->use_SDBM) できるが、単名詞の連接統計DB（学習機能用DB）の文字コ
  ード順表示、前方一致検索の機能は使えない。
    バージョン 5 のPerl（JPerlを含む)で動作する。


=head1 METHODS

    以下のメソッドが使用可能である


=head2 new

    コンストラクタ・メソッド。
    新たに ExTerm::Calc_Imp （か、その派生クラス）のオブジェクトを作成し
  、そのオブジェクトを返す。

    usage : 

        $obj = TermExtract::AnyClass->new;

            ※ TermExtract::AnyClassは派生クラス


=head2 get_imp_word

    専門用語の重要度を計算し、専門用語と重要度（数値）の２要素からなる
  配列を重要度の高い順に返す。
  （パラメータ省略時は、前回の入力を使う、重要度の計算モードはそのつど
  セット可能）

    usage :

        @result = $obj->get_imp_word(Parameter_1, Parameter_2, ... Parameter_N);
        foreach (@result) {
            print $_->[0], "\t";    # 専門用語
            print $_->[1], "\n":    # 専門用語の重要度
        }


=head2 use_total

    重要度計算において、連接語の重みを、連接した単語の延べ数で計算する。
　  例えば、統計データで、「情報」という語が「科学」の前に２回、「技術」
  の前に３回連接したとすると。連接語の重みは次のとおり計算される。

    ５回　 （「科学」２回　＋　「技術」３回）

      ＊正確には相乗平均をとる際、０回の単名詞を扱う関係から１を加算した
        値を用いる

    usage :

        $obj->use_total;


=head2 use_uniq

    重要度計算において、複合語の重みを、単語の種類数でとるモードにする。
　  例えば、統計データで、「情報」という語が「科学」の前に２回、「技術」
  の前に３回連接したとすると。複合語の重みは次のとおり計算される。

    ２回　 （「科学」　＋　「技術」の２種）

      ＊正確には相乗平均をとる際、０回の単名詞を扱う関係から１を加算した
        値を用いる

    usage :

        $obj->use_uniq;


=head2 use_Perplexity

    重要度計算において、複合語の重みを、パープレキシティでとるモードにする。
    なお、現在の仕様では、「学習機能」と組み合わせて使うことはできない。現在
  パープレキシティによる重要度計算は、「学習機能」をサポートしていない。その
  ため、自動的に「学習機能」を使わない重要度計算が行われる。
  　パープレキシティは情報理論で使われる指標で、このシステムの場合は各単名詞
  に「情報理論的に見ていくつの単名詞が連接可能か」を示している。これは、以下
  のようにして求まる単名詞のエントロピーを元に、２のべき乗することで求められ
  る。
    連接する語のそれぞれの出現確率をP1～Pnとおくと、エントロピーの計算は次の
　ように示せる。なお対数の底は２である。
　		
    (-1 * P1 * log(P1)) + (-1 * P2 * log(P2)) ....... + (-1 * Pn * log(Pn))

    例えば、統計データで、「情報」という語が「科学」の前に２回、「技術」の
  前に３回連接（あわせると計５回連接）したとすると。単名詞のエントロピーは
  次のとおりになる。出現確率は「科学」が 2/5, 「技術」が 3/5 である。

     (-2/5 * log(2/5)) + (-3/5 * log(3/5))

    パープレキシティそのもの計算は計算機に負荷がかかるため、重要度の比較に支
  障がないレベルで計算を抑える。これは、パープレキシティの値ではなく、２を底
  にしたパープレキシティの対数を出すことで実現できる（対数でも重要度の順序に
  は影響しない）。
    重要度を２を底にした対数で出すことにより、「相乗平均」と「出現頻度の掛け
  合わせ」は次の計算になる。
    複合語内の相乗平均 ---  各単名詞のエントロピーの合計 / (単名詞数 x 2）
    出現頻度　------------  出現頻度の対数（底は2)を加算

    なお、対数の計算では 0log(0) → 0 とした。この際に log(1) → 0 と差が出なく
  なるため、log(n) の計算を log(n+1) とすることでスムージングを行った。

    usage :

        $obj->use_Perplexity;


=head2 no_LR

    重要度計算において、複合語の重みを使わないモードにする。頻度の情報
  (Frequency, TF)やIDF(Inverted Ducoment Frequency) のみ有効になる。

    usage :

        $obj->no_LR;


=head2 use_freq

    重要度を用語の出現頻度でとるモードにする。Frequency による重要度計算モード。


=head2 use_TF

    重要度を用語の出現頻度でとるモードにする。ただし、用語が他の用語の一部と
  して現れた場合もカウントする。Term Frequency (TF)による重要度計算モード。

    usage :

        $obj->use_TF;


=head2 with_idf

    他の重要度計算結果に対し、IDF (Inverted Document Frequency) にて補正する。
  事前に $obj->use_storage_df; にて、対象ドキュメントのDF(Document Frequency)
  の統計をとっておく必要がある。
  	IDFの計算は、log (総文献数　/ 該当の用語を含む文献数)+1　にて行う。

    usage :

        $obj->with_idf;


=head2 use_frq

    重要度計算において、ドキュメント中の専門用語の出現頻度を掛けるモード
  にする。
    デフォルトはこのモード。

    usage :

        $obj->use_frq;


=head2 no_frq

    重要度計算において、複合語の連接情報のみで計算する（ドキュメント中の
  専門用度の出現頻度を考慮しない）モードにする。

    usage :

        $obj->no_frq;


=head2 use_stat

    重要度計算において、学習機能（単名詞ごとの連接統計DBの情報）を使うモ
  ードにする。
    重要度計算において、単名詞の連接情報は、元となるデータが多いほど正確
  な統計データが得られると推測される。この学習機能は、いままでに処理対象
  としたテキストから単名詞の連接情報を蓄積し、重要度計算で用いるものであ
  る。
     ただし、PerlのDBMが使えない環境では、自動的に学習機能がOFFになる。
    $obj->use_storage （新規ドキュメントの単名詞の連接情報DBへの追加）と
  合わせて使用する。

    usage :

        $obj->use_stat;
        
    sample :

        $obj->use_stat;
        $bbj->use_storage;
        $obj->get_imp_word();

=head2 no_stat

    重要度計算において、ドキュメント中の情報のみ使用（学習機能を使わない
  ）モードにする。use_stat メソッドの項を参照。学習機能用データベースの
  蓄積をとめる場合は、$obj->no_storage; を使用する。
    デフォルトはこのモード(ver 4.02 より)。

    usage :

        $obj->no_stat;

    sample :

        $obj->no_stat;
        $bbj->no_storage;
        $obj->get_imp_word();


=head2 agverage_rate

    重要度計算で、「ドキュメント中の用語の頻度」と「単名詞の連接回数の相
  乗平均」のバランスを調整するためのメソッド。
    重要度計算でドキュメントの中の頻度を使用するモード（デフォルト）にし
  たときのみ、動作する。
    デフォルトの値は１。数値以外と 0 は受け付けない。

    値を大きくとる　→　ドキュメント中の用語の頻度の比重が高まる
    値を小さくとる  →　単名詞の連接回数の重要度の比重が高まる

    usage :

        $obj->average_rate($Any_numeric_value);


=head2 reset_get_word

    "get_imp_word"メッソッドは、引数なしの場合、データの再読み込みを行わ
  ない。
    このメソッドはそれを強制的に再読み込みをさせるための機能である。派生
  クラスでメソッド get_noun_word  が引数をとらずとも動くよう設計されてい
  る場合のみ意味を持つ。

    usage :

        $obj->reset_get_word;

    sample :

        @result1 = $obj->get_imp_word();

        # 再度、get_imp_word の実装にそって、データを取り込む
        $obj->reset_get_word;
        @result2 = $obj->get_imp_word();


=head2 result_filter

    "get_imp_word"の戻り値（配列）同士の掛け合わせを行う。
    戻り値は get_imp_word の戻り値と同じ形式の配列になる。
    メッソッドのパラメータ指定法は次のとおり。

      第１引数   -----   専門用語リストＡ
      第２引数   -----   専門用語リストＢ
      第３引数   -----   専門用語リストＡ の上位何件まで使用するか指定
      第４引数   -----   専門用語リストＢ の上位何件まで使用するか指定

        ※　第３引数と第４引数は省略可。省略した場合は、それぞれ
          "100000"（実質無制限）がセットされる。

    usage :

        @list = $obj->result_filter(\@list_a, \@list_b, $limit_a, $limit_b);

    sample :

        $obj->use_total;
        @result1 = $obj->get_imp_word();

        $obj->no_LR;
        @result2 = $obj->get_imp_word();

        @result3 = $self->result_filter(\@result1, \@result2, 30, 30);


=head2 stat_db

    単名詞ごとの連接情報を蓄積するDBファイル名を指定する。
    デフォルトは stat.db
    引数なしで呼び出した場合は、現在設定されているDBファイル名を返す。

    usage :

        $obj->stat_db("AnyFileName");


=head2 comb_db

    ２語の単名詞の組とその出現頻度（延べ数と異なり数）を蓄積するDBファイ
  ル名を指定する。
    デフォルトは comb.db
    引数なしで呼び出した場合は、現在設定されているDBファイル名を返す。

    usage :

        $obj->comb_db("AnyFileName");


=head2 comb_r_db

    ２語の単名詞の組とその頻度を蓄積したDBファイルから、２語の単名詞の組
  の前後を逆にしたDBを作成する際の、ファイル名を指定する。
    単名詞の統計情報を解析するためだけに使用するので、必須の設定ではない
  。このDBはメソッド make_comb_rev を使うことで初めて作成される。
    デフォルトは comb_r.db
    引数なしで呼び出した場合は、現在設定されているDBファイル名を返す。

    usege :

        $obj->comb_r_db("AnyFileName");


=head2 df_db

    DF(Document Frequency)用のDBファイル名を指定する。
    デフォルトはdf.db
    引数なしで呼び出した場合は、現在設定されているDBファイル名を返す。

    usage :

        $obj->df_db("AnyFileName");


=head2 use_storage

    単名詞の連接情報DBへデータ蓄積を行うモードにする。

    usage :

        $obj->use_storage;

    sample :

        $obj->use_stat;
        $bbj->use_storage;
        $obj->get_imp_word();


=head2 no_storage

    単名詞の連接統計DBへのデータ蓄積を行わないモードにする。デフォルト
  はこのモード。
    重要度計算で、学習機能を使うときは、このモードにしないほうが無難。
    処理対象にDBに登録されていない語が含まれていると正しく動作しない。

    usage :

        $obj->no_storage;

    sample :

        $obj->no_stat;
        $bbj->no_storage;
        $obj->get_imp_word();


=head2 use_storage_df

    DF(Document Frequency)用のDBへデータ蓄積を行うモードにする。この
  モードの間は、データの蓄積のみで重要度計算は行わない。

    usage :

        $obj->use_df_storage_df;


=head2 no_storage_df

    単名詞の連接統計DBへのデータ蓄積を行わないモードにする。デフォルト
  はこのモード。
    usage :

        $obj->no_df_storage_df;


=head2 use_SDBM

    単名詞の連接統計DBのデフォルトはBerkeley DBだが、これをSDBMに変更
  する。
    (Berkeley DBは環境によっては使えないが、SDBM は常に使用可能)

    usage :

        $obj->use_SDBM;


=head2 lock_dir

    このモジュールでは、統計DBの整合性を保つためのロック用ディレクトリを
  使用している。
    このメソッドは、そのロック用ディレクトリのディレクトリ名を設定する。
    空文字列（Null値）をセットした場合は、ロックしない。
    デフォルトでは、空文字列をセット。よってロックは行われない。
    引数なしで呼び出した場合は、設定されているディレクトリ名を返す。
    プログラムの異常終了時にはロックを開放するようになっているが、プロセ
  スの強制停止の際には、最悪ロック用ディレクトリが残ってしまう可能性があ
  る。ユーザプログラム側で次のようなコーディングをすることで、プロセスの
  強制終了（端末からの 'ctrl'キー + 'C'キー等）にある程度対応できる。


      =====================================================

      # プロセスの異常終了時処理
      $SIG{INT} = $SIG{QUIT} = $SIG{TERM} = 'sigexit';

           Any Code ................

      # プロセスの異常終了時にDBのロックを解除
      sub sigexit {
         $obj->unlock_db;
      }

     =======================================================


    これでもロックが残る可能性がある。その際は、OSからロックディレクトリ
  を削除すること。

    usage :

        $obj->lock_dir("AnyDirName");


=head2 lock_db

    統計DBをロックする（ロック用ディレクトリを作成）。
    既にDBがロックされている場合は、1システム秒おきに5回までロックを試み
  る。それでも、ロックされたままの場合は、戻り値として 0 を返す。
　　ロックに成功した場合は、戻り値として 1 を返す。
    なお、このメソッドはメソッド lock_dir で値がセットされた場合のみ動作
  する。

    usage :

        $obj->lock_db;


=head2 unlock_db

    統計DBのロックを解除する（ロック用ディレクトリの削除）。

    usage :

        $obj->unlock_db;


=head2 db_locked

    統計DBをロックしたかどうかを返す。
    ロックしているなら真(1)を返す

    usage :

        $obj->db_locked;


=head2 dump_stat_db

    単名詞の連接統計DBの内容を標準出力に出す。
      １）引数なしの場合、全件出力する
      ２）第１引数ありの場合、その引数の前方一致データを出力する
      ３）第２引数が真の場合、第１引数の完全一致データを出力する
    なお、出力フォーマットは次のとおり。

        単名詞[タブ]数値１[空白]数値２[空白]数値３[空白]数値４

          数値１ -- 単名詞の前にいくつの語をとるか（異なり数）
          数値２ -- 　　　　　　〃　　　　　　　　（延べ数）
          数値３ -- 単名詞の後にいくつの語をとるか（異なり数）
          数値４ -- 　　　　　　〃　　　　　　　　（延べ数）

    usage :

        $obj->dump_stat_db($Any_key_word);


=head2 dump_comb_db

    既出の連接語とその頻度をおさめるDBの内容を表示する。
      １）引数なしの場合、全件出力する
      ２）第１引数ありの場合、その引数の前方一致データを出力する
      ３）第２引数が真の場合、第１引数の完全一致データを出力する
    なお、出力フォーマットは次のとおり。

        単名詞１[空白]単名詞２[タブ]単名詞の組み合わせの延べ数

    usage :

        $obj->dump_comb_db($Any_key_word);


=head2 dump_comb_r_db

    既出の２語の単名詞の組とその出現頻度をおさめるDB（逆順）の内容
  を表示する。
      １）引数なしの場合、全件出力する
      ２）第１引数ありの場合、その引数の前方一致データを出力する
      ３）第２引数が真の場合、第１引数の完全一致データを出力する
    なお、出力フォーマットは次のとおり。

        単名詞１[空白]単名詞２[タブ]単名詞の組み合わせの延べ数

    usage :

        $obj->dump_comb_r_db($Any_key_word);


=head2 make_comb_rev

    既出の２語の単名詞の組とその出現頻度をおさめるDB（逆順）を作成（もし
  くは更新）する。
    重要度計算では使用しないが、ある単名詞の前にどの単名詞が結びつきうる
  かの統計情報を得ることができる。

    usage :

        $obj->make_comb_rev;


=head2 dump_df_db

    DF(Document Frequency)用の統計データの内容を表示する。

        単名詞１[空白]単名詞２[空白] ....[タブ]用語を含むドキュメント数

        [空白]の場合は、いままで読み込んだ総ドキュメント数

    usage :

        $obj->dump_df_db($Any_key_word);


=head2 clear_db

    単名詞の連接統計DBと、既出の２語の単名詞の組とその出現頻度をおさめる
  DBの内容をクリアする。

    usage :

        $obj->clear_db;


=head2 clear_df_db

    DF(Document Frequency)用統計DBの内容をクリアする。

    usage :

        $obj->clear_df_db;


=head2 IgnoreWords

      重要度が低いにもかかわらず、単語の連接で頻出する語（例えば、英語の
   ofなど）を重要度の計算対象外にする。
     ユーザプログラムではなく、派生クラスでの使用のために用意した。
     (BrillsTagger.pm, EnglishPlainText.pm などで使用している）

    usage :

        $obj->IgnoreWords('単語A', '単語B', ...);

      引数を与えないと、現在の設定値（配列）を返す。


=head2 IsAgglutinativeLang

    言語を膠着言語や孤立語（日本語や中国語などの文字空けで単語区切されない
  言語）に設定する。ユーザプログラムではなく、派生クラスでの使用のために用
  意した。
    Calc_Imp.pm の ver 2.00 以降では、処理対象言語が膠着言語か孤立語の場合、
  このメソッドの使用が必要。(Chasen.pm, ICTCLAS.pm などで使用している）
    このメソッドを使用しないと、入力を屈折語（デフォルト）として扱い
  、単名詞を半角スペースで区切った形での出力になる。

    usage :

        $obj->IsAgglutinativeLang;


=head2 NotAgglutinativeLang

    言語を屈折語（英語など文字空けで単語が区切られている言語）に設定
  する。ユーザプログラムではなく、派生クラスでの使用のために用意した。
    デフォルトは非膠着言語のため、通常は使用する必要はない。

    usage :

        $obj->NotAgglutinativeLang;


=head1 SEE ALSO

    TermExtract::Chasen
    TermExtract::MeCab
    TermExtract::BrillsTagger
    TermExtract::EnglishPlainText
    TermExtract::ChainesPlainTextUC
    TermExtract::ChainesPlainTextGB
    TermExtract::ICTCLAS
    TermExtract::JapanesePlainTextEUC
    TermExtract::JapanesePlainTextSJIS


=head1 COPYRIGHT

      このプログラムは、東京大学・中川裕志教授、横浜国立大学・森辰則助教
    授が作成した「専門用語自動抽出システム」のExtract.pm  を参考に、中川
    教授の教示を受け、１からコーディングし直したものである。
      この作業は、東京大学・前田朗(maeda@lib.u-tokyo.ac.jp)が行った。
      その際のコンセプトは次のとおり。

      １．形態素解析データの取り込みも含めてモジュール化し、他のプログラ
        ムへの組み込みができること

      ２．学習機能（連接語統計情報のDBへの蓄積とその活用）を持つこと

      ３．重要度計算方法の切り替えができること

      ４．日本語パッチを当てたPerl (Jperl) だけではなく、オリジナルの
        Perlで動作すること

      ５．信頼性の確保のためPerlのstrictモジュール及びperlの-wオプション
        に対応すること

      ６．「窓関数」による、不要語の削除ルーチンをとりはずすこと

      ７．単名詞の連接回数の相乗平均を正しくとること。Extract.pmは連接回
        数の２乗を重要度としていた。
          なお、この設定はパタメータにより調整できる。Extract.pmと同じに
        するには、$obj->average_rate(0.5) とする

      ８．数値と任意の語を重要度計算の対象からはずせるようにすること

      ９．多言語に対応するため、Unicode(UTF-8)で動作すること

      １０．パープレキシティを元に重要度計算を行えるようにすること。

      １１．Frequency, TF, TF*IDFなどの重要度計算機能を持つこと

      Extract.pm の作者は次のとおり。

        Keisuke Uchima 
        Hirokazu Ohata
        Hiroaki  Yumoto (Email:hir@forest.dnj.ynu.ac.jp)

        なお、本プログラムの使用において生じたいかなる結果に関しても当方
      では一切責任を負わない。

=cut
