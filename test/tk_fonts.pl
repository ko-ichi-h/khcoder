package FontTest;
use strict;
use Tk;
use Tk::Font;
use Tk::FontDialog;
use Jcode;
require Encode if $] > 5.008;

my $self;
$self->{mw} = MainWindow->new;
bless $self, 'FontTest';

$self->{mw}->fontCreate('TKFN',
	-family => 'HiraginoKaku',
	-size   => 10
);
$self->{mw}->optionAdd('*font', "TKFN");

$self->{mw}->Label(
	-text => $self->gui_jchar('日本語のラベル'),
	-font => "TKFN"
)->pack();
$self->{mw}->Button(
	-text => $self->gui_jchar('Font変更'),
	-font => "TKFN",
	-command => sub {$self->font_change},
)->pack;


MainLoop;

sub font_change{
	my $self = shift;
	my $font = $self->{mw}->FontDialog(
		-nicefontsbutton  => 0,
		-fixedfontsbutton => 0,
		-sampletext       => $self->gui_jchar('KH Coderは計量テキスト分析を支援します。'),
		-initfont         => ,"TKFN"
	)->Show;
	$self->{mw}->fontDelete('TKFN');
	$self->{mw}->fontCreate('TKFN',
		-family => $font->configure(-family),
		-size   => $font->configure(-size),
	);
	$self->{mw}->optionAdd('*font', "TKFN");
}

sub gui_jchar{
	my $self = shift;
	my $str = shift;
	if ($] > 5.008){
		return Encode::decode('eucjp',$str);
	} else {
		return Jcode->new($str)->sjis;
	}
}
