use Tk;
my $mw = new MainWindow;
$mw->Label(-text => '入力テスト')->pack;
$mw->Entry()->pack;
MainLoop;
