package IMtest;
use Tk;
use strict;

my $mw = new MainWindow;
my $self;
$self->{mw} = $mw;
bless $self, "IMtest";

$self->inner;

MainLoop;


sub inner{
	my $self = shift;
	$self->mw->Label(-text => '日本語入力のテスト用プログラムです')->pack;
	$self->mw->Entry()->pack;

}

# アクセサ
sub mw{
	my $self = shift;
	return $self->{mw};
}