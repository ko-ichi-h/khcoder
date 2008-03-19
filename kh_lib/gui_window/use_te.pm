package gui_window::use_te;
use base qw(gui_window);
use strict;
use Tk;
use gui_jchar;

# Windowを開く
sub _new{
	my $self = shift;
	$self->{win_obj}->title($self->gui_jchar('TermExtractの著作権について','euc'));;

	$self->{win_obj}->Label(
		-text => $self->gui_jchar('専門用語（キーワード）自動抽出用Perlモジュール「TermExtract」を利用します。','euc'),
		-font => "TKFN",
	)->pack(-anchor => 'w',-pady=>'2',-padx=>'2');

	my $f1 = $self->{win_obj}->Frame()->pack(-anchor => 'w');
	$f1->Label(
		-text => $self->gui_jchar('TermExtractのWebページ：','euc'),
		-font => "TKFN",
	)->pack(-anchor => 'w',-pady=>'2',-padx=>'2', -side => 'left');

	$f1->Button(
		-text => 'http://gensen.dl.itc.u-tokyo.ac.jp/',
		-font => "TKFN",
		-foreground => 'blue',
		-activeforeground => 'red',
		-borderwidth => '0',
		-relief => 'flat',
		-cursor => 'hand2',
		-command => sub{
			$self->{win_obj}->after(
				10,
				sub {
					gui_OtherWin->open('http://gensen.dl.itc.u-tokyo.ac.jp/');
				}
			);
		}
	)->pack(-side => 'left', -anchor => 'w');

	$self->{win_obj}->Label(
		-text => $self->gui_jchar('TermExtractの著作権：','euc'),
		-font => "TKFN",
	)->pack(-anchor => 'w',-pady=>'2',-padx=>'2');

	my $txt = $self->{win_obj}->Scrolled(
		"ROText",
		spacing1 => 3,
		spacing2 => 2,
		spacing3 => 3,
		-scrollbars=> 'osoe',
		-height => 12,
		-width => 64,
		-wrap => 'word',
		-font => "TKFN",
		-background => 'white',
		-foreground => 'black'
	)->pack(-fill => 'both', -expand => 'yes', -pady=>'2',-padx=>'2');
	$txt->bind("<Key>",[\&gui_jchar::check_key,Ev('K'),\$txt]);
	$txt->bind("<Button-1>",[\&gui_jchar::check_mouse,\$txt]);
	$self->{text} = $txt;

	
	$self->{win_obj}->Button(
		-text => $self->gui_jchar('キャンセル'),
		-font => 'TKFN',
		-width => 8,
		-command => sub{
			$self->{win_obj}->after(10,sub{$self->close;})
		}
	)->pack(-anchor=>'e',-side => 'right',-padx => 2, -pady => 2);

	my $ok_btn = $self->{win_obj}->Button(
		-text  => 'OK',
		-font  => 'TKFN',
		-width => 8,
		-command => sub{ $self->{win_obj}->after
			(
				10,
				sub {
					$self->close;
					# 処理実行
					my $if_exec = 1;
					if (-e $::project_obj->file_HukugoListTE){
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
						
						my $w = gui_wait->start;
						use mysql_hukugo_te;
						mysql_hukugo_te->run_from_morpho;
						$w->end;
						
					}
					gui_window::use_te_g->open;
				}
			);
		}
	)->pack(-anchor => 'e',-side => 'right',  -pady => 2);
	
	$self->put_info;
	$ok_btn->focus;
	return $self;
}

# 著作権情報を流し込む
sub put_info{
	my $self = shift;
	$self->{text}->tagConfigure('red',
		-foreground => 'red',
		-background => 'white',
		-underline  => 0
	);
	
	$self->{text}->insert('end',$self->gui_jchar("「TermExtract」は、東京大学情報基盤センター図書館電子化部門・中川研究室にて公開されています。詳細は以下の通りです。\n") );
	
	$self->{text}->insert('end',"TermExtract::Calc_Imp.pm:\n",'red');
	my $Calc_Imp_cr = '　このプログラムは、東京大学・中川裕志教授、横浜国立大学・森辰則助教授が作成した「専門用語自動抽出システム」のExtract.pmを参考に、中川教授の教示を受け、１からコーディングし直したものである。
　この作業は、東京大学・前田朗(maeda@lib.u-tokyo.ac.jp)が行った。
　その際のコンセプトは次のとおり。
１．形態素解析データの取り込みも含めてモジュール化し、他のプログラムへの組み込みができること
２．学習機能（連接語統計情報のDBへの蓄積とその活用）を持つこと
３．重要度計算方法の切り替えができること
４．日本語パッチを当てたPerl (Jperl) だけではなく、オリジナルのPerlで動作すること
５．信頼性の確保のためPerlのstrictモジュール及びperlの-wオプションに対応すること
６．「窓関数」による、不要語の削除ルーチンをとりはずすこと
７．単名詞の連接回数の相乗平均を正しくとること。Extract.pmは連接回数の２乗を重要度としていた。なお、この設定はパタメータにより調整できる。Extract.pmと同じにするには、$obj->average_rate(0.5) とする
８．数値と任意の語を重要度計算の対象からはずせるようにすること
９．多言語に対応するため、Unicode(UTF-8)で動作すること
１０．パープレキシティを元に重要度計算を行えるようにすること。
１１．Frequency, TF, TF*IDFなどの重要度計算機能を持つこと

Extract.pm の作者は次のとおり。
　Keisuke Uchima 
　Hirokazu Ohata
　Hiroaki  Yumoto (Email:hir@forest.dnj.ynu.ac.jp)

なお、本プログラムの使用において生じたいかなる結果に関しても当方では一切責任を負わない。';
	$self->{text}->insert('end',$self->gui_jchar($Calc_Imp_cr) );

	$self->{text}->insert('end',"\n\nTermExtract::Chasen.pm:\n",'red');
	my $Chasen = '　このプログラムは、東京大学・中川裕志教授、横浜国立大学・森辰則助教授が作成した「専門用語自動抽出システム」のtermex.pl を参考にコードを全面的に書き直したものである。
　この作業は、東京大学・前田朗 (maeda@lib.u-tokyo.ac.jp)が行った。
　相違点は次のとおり。
１．独立したスクリプトからモジュールへ書き換え、他のプログラムからの組み込みを可能とした。
２．形態素解析済みのテキストファイルだけではなく、変数からも入力可能にした。これによりUNIX環境での Text::Chasen モジュール等にも対応が可能になった。
３．オリジナルPerl対応にした。Shift-JISとEUCによる日本語入力を日本語対応パッチを当てたPerl(Jperl)を使わずとも処理可能になった。
４．常に固有名詞を候補語とし、１文字語も候補語とするようパラメータを固定した
５．次の１文字の「未知語」は語の区切りとして認識するようにした。また、「未知語」が , で終わるときにも語の区切りとした。!"#$%&\'()*+,-./{|}:;<>[]
６．複数の「未知語」から単名詞を生成するロジックを組み込んだ。（「茶筅」ver 2.3.3等の新しいバージョンへの対応）
７．複数の「記号-アルファベット」から英単語を生成するロジックを組み込んだ。（「茶筅」ver 2.3.3等の新しいバージョンへの対応）
８．信頼性の確保のため、Perlの"strict"モジュール及びperlの-wオプションへの対応を行った。

なお、本プログラムの使用において生じたいかなる結果に関しても当方では一切責任を負わない。';
	$self->{text}->insert('end',$self->gui_jchar($Chasen) );

	return $self;
}

sub win_name{
	return 'w_use_te';
}

1;
