package kh_r_plot;
use strict;

sub new{
	my $class = shift;
	my %args = @_;
	my $self = \%args;
	bless $self, $class;
	
	return undef unless $::config_obj->R;
	
	# フォルダ名
	my $icode = Jcode::getcode($::project_obj->dir_CoderData);
	my $dir   = Jcode->new($::project_obj->dir_CoderData, $icode)->euc;
	$dir =~ tr/\\/\//;
	$dir = Jcode->new($dir,'euc')->$icode unless $icode eq 'ascii';
	$self->{path} = $dir.$self->{name};
	
	# コマンド
	$self->{command_f} = Jcode->new($self->{command_f})->sjis
		if $::config_obj->os eq 'win32';
	
	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	$self->{path} = $::config_obj->R_device($self->{path});
	$::config_obj->R->send($self->{command_f});
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	return $self;
}

sub path{
	my $self = shift;
	return $self->{path};
}

sub save{
	my $self = shift;
	my $path = shift;
	
	my $icode = Jcode::getcode($path);
	$path = Jcode->new($path, $icode)->euc;
	$path =~ tr/\\/\//;
	$path = Jcode->new($path,'euc')->$icode unless $icode eq 'ascii';
	
	if ($path =~ /\.r$/i){
		$self->_save_r($path);
	}
	elsif ($path =~ /\.png$/i){
		$self->_save_png($path);
	}
	elsif ($path =~ /\.eps$/i){
		$self->_save_eps($path);
	}
	elsif ($path =~ /\.pdf$/i){
		$self->_save_pdf($path);
	}
	elsif ($path =~ /\.emf$/i){
		$self->_save_emf($path);
	}
	else {
		warn "The file type is not supported yet:\n$path\n";
	}
}

sub _save_emf{
	my $self = shift;
	my $path = shift;
	
	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	$::config_obj->R->send(
		 "win.metafile(filename=\"$path\", width = 7, height = 7 )"
	);
	$::config_obj->R->send($self->{command_f});
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	return 1;
}

sub _save_pdf{
	my $self = shift;
	my $path = shift;
	
	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	$::config_obj->R->send(
		 "pdf(file=\"$path\", height = 7, width = 7,"
		."family=\"Japan1GothicBBB\")"
	);
	$::config_obj->R->send($self->{command_f});
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	return 1;
}


sub _save_eps{
	my $self = shift;
	my $path = shift;
	
	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	$::config_obj->R->send(
		 "postscript(\"$path\", horizontal = FALSE, onefile = FALSE,"
		."paper = \"special\", height = 7, width = 7,"
		."family=\"Japan1GothicBBB\" )"
	);
	$::config_obj->R->send($self->{command_f});
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	return 1;
}

sub _save_png{
	my $self = shift;
	my $path = shift;
	
	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	$::config_obj->R->send("png(\"$path\")");
	$::config_obj->R->send($self->{command_f});
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	return 1;
}

sub _save_r{
	my $self = shift;
	my $path = shift;
	
	open (OUTF,">$path") or 
		gui_errormsg->open(
			type    => 'file',
			thefile => $path,
		);
	print OUTF $self->{command_f},"\n";
	close (OUTF);
	
	return 1;
}

sub _pdf_font {
	my $cmd = '
postscriptFonts(Japan1 = CIDFont("HeiseiKakuGo-W5", "90ms-RKSJ-H", "cp932"),
                Japan1HeiMin = CIDFont("HeiseiMin-W3", "90ms-RKSJ-H", "cp932"),
                Japan1GothicBBB =
                CIDFont("GothicBBB-Medium", "90ms-RKSJ-H", "cp932"),
                Japan1Ryumin = CIDFont("Ryumin-Light", "90ms-RKSJ-H", "cp932"))

pdfFonts(Japan1 = CIDFont("KozMinPro-Regular-Acro", "90ms-RKSJ-H", "cp932",
           paste("/FontDescriptor",
                 "<<",
                 "  /Type /FontDescriptor",
                 "  /CapHeight 740 /Ascent 1075 /Descent -272 /StemV 72",
                 "  /FontBBox [-195 -272 1110 1075]",
                 "  /ItalicAngle 0 /Flags 6 /XHeight 502",
                 "  /Style << /Panose <000001000500000000000000> >>",
                 ">>",
                 "/CIDSystemInfo << /Registry(Adobe) /Ordering(Japan1) /Supplement  2 >>",
                 "/DW 1000",
                 "/W [",
                 "   1 632 500 ",
                 "   8718 [500 500] ",
                 "]\n",
                 sep="\n      ")),
         Japan1HeiMin = CIDFont("HeiseiMin-W3-Acro", "90ms-RKSJ-H", "cp932",
           paste("/FontDescriptor",
                 "<<",
                 "  /Type /FontDescriptor",
                 "  /CapHeight 709 /Ascent 723 /Descent -241 /StemV 69",
                 "  /FontBBox [-123 -257 1001 910]",
                 "  /ItalicAngle 0 /Flags 6 /XHeight 450",
                 "  /Style << /Panose <000002020500000000000000> >>",
                 ">>",
                 "/CIDSystemInfo << /Registry(Adobe) /Ordering(Japan1) /Supplement  2 >>",
                 "/DW 1000",
                 "/W [",
                 "   1 632 500 ",
                 "   8718 [500 500] ",
                 "]\n",
                 sep="\n      ")),
         Japan1GothicBBB = CIDFont("GothicBBB-Medium", "90ms-RKSJ-H", "cp932",
           paste("/FontDescriptor",
                 "<<",
                 "  /Type /FontDescriptor",
                 "  /CapHeight 737 /Ascent 752 /Descent -271 /StemV 99",
                 "  /FontBBox [-22 -252 1000 892]",
                 "  /ItalicAngle 0 /Flags 4",
                 "  /Style << /Panose <0801020b0500000000000000> >>",
                 ">>",
                 "/CIDSystemInfo << /Registry(Adobe) /Ordering(Japan1) /Supplement  2 >>",
                 "/DW 1000",
                 "/W [",
                 "   1 632 500",
                 "   8718 [500 500]",
                 "]\n",
                 sep="\n      ")),
         Japan1Ryumin = CIDFont("Ryumin-Light", "90ms-RKSJ-H", "cp932",
           paste("/FontDescriptor",
                 "<<",
                 "  /Type /FontDescriptor",
                 "  /CapHeight 709 /Ascent 723 /Descent -241 /StemV 69",
                 "  /FontBBox [-54 -305 1000 903]",
                 "  /ItalicAngle 0 /Flags 6",
                 "  /Style << /Panose <010502020300000000000000> >>",
                 ">>",
                 "/CIDSystemInfo << /Registry(Adobe) /Ordering(Japan1) /Supplement  2 >>",
                 "/DW 1000",
                 "/W [",
                 "   1 632 500",
                 "   8718 [500 500]",
                 "]\n",
                 sep="\n      ")))
}
	';
	$::config_obj->R->send($cmd);

}

1;