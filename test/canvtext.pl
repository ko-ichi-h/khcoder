#! perl -w
# Title: キャンバステキスト日本語入力サンプルプログラム
# Author: 廣島 勉 (Tsutomu Hiroshima tsutomu@nucba.ac.jp)
# Date: 2000年12月14日
#
# Canvas Widget の Text オブジェクトの文字＿のみ＿を編集するデモプログラムです．
# Canvas Widget はデフォルトで編集のためのバインディングは一切行われていませんので，
# このプログラムで定義しているようなバインディングを用意する必要があります．
#
# 新しい Text オブジェクトを作ったり，
# 今ある Text オブジェクトを削除したり，
# 移動したり，色を変えたりする機能はありません．
#
# 矢印キーで編集位置を移動させることもできませんが，
# BackSpace と Delete で 前後の文字を消去したり，
# カット，コピー，ペーストは出来ます．

use Tk;

### Canvas Widget で インプットメソッドを使うと宣言．
### デフォルトの入力スタイルは
### ['PreeditArea', 'StatusArea'] か ['PreeditNothing', 'StatusNothing']．
Tk::Kanji::UseIM('Tk::Canvas');

$mw = MainWindow->new;

### この場所で次を呼ぶのは
### Tk::Kanji::UseIM('Tk::Canvas');
### と，同じ効果をもつ．

#$mw->OpenIM('Tk::Canvas');

$cn = $mw->Canvas(-takefocus => 1, # 編集するためにはフォーカスが必要．
		  -width => 300,
		  -height => 300,
		  -background => 'white')->pack;

### インスタンス $cn だけで日本語入力を使いたい場合は
### 次のどちらかを呼ぶ．

# $cn->OpenIM;
# $mw->OpenIM($cn);

$mw->title('キャンバステキストへの日本語入力');

### メニューの作成．
$mn = $mw->Menu;
$mw->configure(-menu => $mn);

$mn->add('cascade', -label => 'ファイル(F)', -underline => 5);
$mn->add('cascade', -label => '編集(E)', -underline => 3);

$it1 = $mn->Menu;
$mn->entryconfigure('ファイル(F)', -menu => $it1);
$it1->add('command',
	  -label => '印刷(P)',
	  -underline => 3,
	  -command => \&PrintPS);
$it1->add('separator');
$it1->add('command',
	  -label => '終了(Q)',
	  -underline => 3,
	  -command => sub {exit});

$it2 = $mn->Menu;
$mn->entryconfigure('編集(E)', -menu => $it2);

$it2->add('command', -label => 'カット(X)',
	  -underline => 4,
	  -command => [\&ClipCut, $cn]);
$it2->add('command', -label => 'コピー(C)',
	  -underline => 4,
	  -command => [\&ClipCopy, $cn]);
$it2->add('command', -label => 'ペースト(V)',
	  -underline => 5,
	  -command => [\&ClipPaste, $cn]);
### メニューの作成の終り．

### Text オブジェクトの作成．
### 須栗歩人さんの「入門 Perl/Tk」の
### サンプルスクリプトを参考にしました．
$cn->createText( 0, 30, -text => 'アンカーの位置', -anchor => 'w');
@ap = (['e', 'magenta'], ['w', 'green'], ['s', 'blue'], ['n', 'red']);

foreach $p (@ap) {
  $cn->createText(150, 70, -text => "アンカー-$p->[0]", -anchor => $p->[0], 
		  -fill => $p->[1]);
}

$msg = 'ようこそ！ Perl/Tk の世界へ！！！';

$cn->createText( 0, 120, -text => 'ジャスティファイ', -anchor => 'w');

@jf = ([150, 'left'], [200, 'center'], [250, 'right']);
foreach $p (@jf) {
  $cn->createText(150, $p->[0], -text => $msg, -width => 180, 
		  -justify => $p->[1]);	  
}
### Text オブジェクトの作成の終り．

### 編集のためのバインディング．
### 日本語入力のために特別なことは一切していない．
### Canvas Widget では，'Tk::' の接頭辞が必須．
$cn->Tk::bind('<Button-1>', [\&FocusText, Ev('x'), Ev('y')]);
$cn->Tk::bind('<ButtonRelease-1>', [\&EndDrag, Ev('x'), Ev('y')]);
$cn->Tk::bind('<Key>', [\&InsertChar, Ev('A')]);
$cn->Tk::bind('<Key-BackSpace>', [\&DeleteChar, -1]);
$cn->Tk::bind('<Key-Delete>', [\&DeleteChar, 0]);


MainLoop;

### ファイルメニュー -> 印刷コマンドの関数．
sub PrintPS {
  my $fname = $mw->getSaveFile(-initialfile => 'Untitled',
			       -defaultextension => '.ps');
  $cn->postscript(-file => $fname);
}

### ボタン１を押したイベントで呼ばれる．
sub FocusText {
  my ($w, $x, $y) = @_;

  ### Canvas にフォーカスを自動的には移動してくれないので，
  ### 自前で設定．
  ### $w->focus は Canvas 内の Text オブジェクト間の
  ### フォーカスの移動に使うので
  ### 'Tk::' の接頭辞は必須．
  $w->Tk::focus;

  ### ポイントに近い Text オブジェクトを選択，
  ### 重なりあってる場合を考えて，手前に移動，
  ### そのオブジェクトにフォーカスを置いて，
  ### カーソルをポイントに設定．
  my $tagOrId = $w->find('closest', $x, $y);
  $w->raise($tagOrId);
  $w->focus($tagOrId);
  $w->icursor($tagOrId, '@'."$x,$y");

  ### 既に選択されたテキストがあれば，非選択に，
  ### 現在位置を選択開始位置として，
  ### ポインタの移動イベントにテキスト選択の関数をバインド
  $w->selectClear;
  $w->selectFrom($tagOrId, '@'."$x,$y");
  $w->Tk::bind('<Motion>', [\&SelectText, Ev('x'), Ev('y')]);
}

### ポインタの移動のイベントで呼ばれる．
### ただしそのバインドはボタンを押している間だけ有効．
### ポインタが移動した位置のテキストまでを選択する．
sub SelectText {
  my ($w, $x, $y) = @_;
  my $focused = $w->focus;
  if ($focused) {
    $w->selectTo($focused,  '@'."$x,$y");
  }
}

### ボタン１を離したイベントで呼ばれる．
### ポインタの移動にバインドしていた関数をアンバインドする．
sub EndDrag {
  my $w = shift;
  $w->Tk::bind('<Motion>', '');
}

### 文字の挿入と削除の関数．
sub InsertChar {
  my ($w, $c) = @_;
  return unless $c;
  my $focused = $w->focus;
  if ($focused) {
    eval { $w->dchars($focused, 'sel.first', 'sel.last') };
    my $index = $w->index($focused, 'insert');
    $w->insert($focused, $index, $c);
  }
}

sub DeleteChar {
  my ($w, $c) = @_;
  my $focused = $w->focus;
  if ($focused) {
    eval { $w->dchars($focused, 'sel.first', 'sel.last') };
    if ($@) {
      my $index = $w->index($focused, 'insert');
      $w->dchars($focused, $index + $c);
    }
  }
}

### 編集メニュー -> カット，コピー，ペーストコマンドの関数．
### 須栗歩人さんの「入門 Perl/Tk」の
### サンプルスクリプトを参考にしました．
sub ClipCut {
  my $w = shift;
  ClipCopy($w);
  my $focused = $w->focus;
  if ($focused) {
    eval { $w->dchars($focused, 'sel.first', 'sel.last') };
  }
}

sub ClipCopy {
  my $w = shift;
  my $owner = $w->SelectionOwner;
  if ($owner && $owner eq $w) {
    my $selected = eval {$w->SelectionGet};
    if ($selected) {
      $w->clipboardClear;
      $w->clipboardAppend($selected);
    }
  }
}

sub ClipPaste {
  my $w = shift;
  my $owner = $w->SelectionOwner;
  my $focused = $w->focus;
  if ($focused) {
    my $index = $w->index($focused, 'insert');
    if ($owner && $owner eq $w) {
      eval { $w->dchars($focused, 'sel.first', 'sel.last') };
    }
    $w->insert($focused, $index,
	       $w->SelectionGet(-selection => 'CLIPBOARD'));
  }
}
