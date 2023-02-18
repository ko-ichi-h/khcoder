package kh_r_plot;
use strict;
use utf8;

use kh_r_plot::network;
use kh_r_plot::corresp;
use kh_r_plot::mds;

use vars qw($if_font);
$kh_r_plot::if_font = 0;

my $if_lt25 = 0;
my $debug = 0;

sub new{
	my $class = shift;
	my %args = @_;
	my $self = \%args;
	bless $self, $class;
	
	$self->{command_a} = '' unless defined( $self->{command_a} );
	$self->{command_s} = '' unless defined( $self->{command_s} );
	return undef unless $::config_obj->R;
	
	# ファイル名
	if ( utf8::is_utf8($self->{name}) ) {
		$self->{name} = Encode::encode('ascii', $self->{name} );
	}
	$self->{path} = $::config_obj->cwd.'/config/R-bridge/'.$::project_obj->dbname.'_'.$self->{name};
	#print "path: $self->{path}\n";
	#print "utf8? path : ", utf8::is_utf8($self->{path}), "\n";
	#print "utf8? name : ", utf8::is_utf8($self->{name}), "\n";
	#print "utf8? db_name : ", utf8::is_utf8($::project_obj->dbname), "\n";
	#print "utf8? cwd_name : ", utf8::is_utf8($::config_obj->cwd), "\n";

	# コマンドの文字コード
	print "Checking character code...\n" if $debug;
	if ( utf8::is_utf8($self->{command_f}) ){
		# It's OK!
	} else {
		$self->{command_f} = Encode::decode('utf8', Jcode->new($self->{command_f})->utf8);
		$self->{command_a} = Encode::decode('utf8', Jcode->new($self->{command_a})->utf8);
		$self->{command_s} = Encode::decode('utf8', Jcode->new($self->{command_s})->utf8);
		warn( "Warn: R commands are not decoded!\n" );
	}

	# コマンドから日本語コメントを削除
	print "Checking Japanese comments...\n" if $debug;
	if (
		   ($::config_obj->os eq 'win32')
		&& 0
		#&! ($::project_obj->morpho_analyzer_lang eq 'jp')
	){
		$self->{command_f} =~ s/#.*?\p{Hiragana}.*?\n/\n/go;
		$self->{command_f} =~ s/#.*?\p{Katakana}.*?\n/\n/go;
		$self->{command_f} =~ s/#.*?\p{Han}.*?\n/\n/go;
		$self->{command_a} =~ s/#.*?\p{Hiragana}.*?\n/\n/go;
		$self->{command_a} =~ s/#.*?\p{Katakana}.*?\n/\n/go;
		$self->{command_a} =~ s/#.*?\p{Han}.*?\n/\n/go;
		$self->{command_s} =~ s/#.*?\p{Hiragana}.*?\n/\n/go;
		$self->{command_s} =~ s/#.*?\p{Katakana}.*?\n/\n/go;
		$self->{command_s} =~ s/#.*?\p{Han}.*?\n/\n/go;
	}

	# コマンドの改行コード
	print "Checking CR LR comments...\n" if $debug;
	$self->{command_f} =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
	$self->{command_a} =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
	$self->{command_s} =~ s/\x0D\x0A|\x0D|\x0A/\n/g;

	print "Escaping Unicode char...\n" if $debug;
	$self->{command_f} = $self->escape_unicode($self->{command_f});
	$self->{command_a} = $self->escape_unicode($self->{command_a});
	$self->{command_s} = $self->escape_unicode($self->{command_s});

	print "Here...\n" if $debug;
	if ( length($self->{command_f}) ) {
		$self->{command_f} =~ s/color_universal_design <\- [01]\n//;
		$self->{command_f} =
			 'color_universal_design <- '.$::config_obj->color_universal_design."\n"
			.$self->{command_f}
		;
	}
	if ( length($self->{command_a}) ) {
		$self->{command_a} =~ s/color_universal_design <\- [01]\n//;
		$self->{command_a} =
			 'color_universal_design <- '.$::config_obj->color_universal_design."\n"
			.$self->{command_a}
		;
	}
	if ( length($self->{command_s}) ) {
		$self->{command_s} =~ s/color_universal_design <\- [01]\n//;
		$self->{command_s} =
			 'color_universal_design <- '.$::config_obj->color_universal_design."\n"
			.$self->{command_s}
		;
	}
		# command_sはプロットの保存専用コード。
		# 現在はMDSでのみ使用。

	my $command = '';
	if (length($self->{command_a})){
		$command = $self->{command_a};
	} else {
		$command = $self->{command_f};
	}
	
	#$command = $self->escape_unicode($command);
	
	# Debug用出力 1
	if ($::config_obj->r_plot_debug){
		my $file_debug = $self->{path}.'.r';
		open (RDEBUG, '>encoding(utf8)', $file_debug) or 
			gui_errormsg->open(
				type    => 'file',
				thefile => $file_debug,
			)
		;
		print "R debug file: ", $::config_obj->uni_path($file_debug), "\n";
		print RDEBUG
			"# command_f\n",
			$self->{command_f},
			"\n\n# command_a\n",
			$self->{command_a}
		;
		close (RDEBUG)
	}
	
	# Linux用フォント設定
	if ( ($::config_obj->os ne 'win32') and ($kh_r_plot::if_font == 0) ){
		system('xset fp rehash');
		$::config_obj->R->output_chk(0);
		if ( $::config_obj->R_version < 207 ){
			# 2.7以前
			$::config_obj->R->send(
				 'options(X11fonts = c('
				.'"-*-gothic-%s-%s-normal--%d-*-*-*-*-*-*-*",'
				.'"-adobe-symbol-*-*-*-*-%d-*-*-*-*-*-*-*"))'
			);
		} else {
			# 2.7以降
			$::config_obj->R->send(
				 'X11.options(fonts = c('
				.'"-*-gothic-%s-%s-normal--%d-*-*-*-*-*-*-*",'
				.'"-adobe-symbol-*-*-*-*-%d-*-*-*-*-*-*-*"))'
			);
		}

		# Cairo
		unless ($^O =~ /darwin/i ){
			my $f = $::config_obj->font_plot_current;
			$::config_obj->R->send(
				 "try( library(Cairo) )\n"
				."try( CairoFonts(\n"
				."	regular    =\"$f:style=Regular\",\n"
				."	bold       =\"$f:style=Regular,Bold\",\n"
				."	italic     =\"$f:style=Regular,Italic\",\n"
				."	bolditalic =\"$f:style=Regular,Bold Italic,BoldItalic\"\n"
				."))"
			);
		}
		$::config_obj->R->output_chk(1);
		$kh_r_plot::if_font = 1;
	}

	# Windows用の設定
	if ( ($::config_obj->os eq 'win32') and ($kh_r_plot::if_font == 0) ){
		print "kh_r_plot: Loading Cairo...\n";
		$::config_obj->R->output_chk(0);
		$::config_obj->R->send( "try( library(Cairo) )" );
		$::config_obj->R->output_chk(1);
		$kh_r_plot::if_font = 1;
		
		# no good effect: trying to allocate more memory on 32 bit Windows  
		#require Devel::Platform::Info::Win32;
		#my $os_info = Devel::Platform::Info::Win32->new->get_info();
		#if ( ($os_info->{wow64} == 0) && ($os_info->{is64bit} == 0) ){
		#	print "kh_r_plot: sending: memory.limit(size=4095)...\n";
		#	$::config_obj->R->send( "try( memory.limit(size=4095) )" );
		#}
	}

	# Rのバージョンが2.5.0より小さい場合の対処
	unless ($if_lt25){
		if ($::config_obj->R_version > 205){
			$if_lt25 = 1;
		} else {
			$::config_obj->R->output_chk(0);
			$::config_obj->R->send(
				'as.graphicsAnnot <- function(x) if (is.language(x) || !is.object(x)) x else as.character(x)'
			);
			$::config_obj->R->output_chk(1);
			$if_lt25 = 2;
			#print "as.graphicsAnnot defined.\n";
		}
	}

	# width・heightのチェック
	$self->{width}  = $::config_obj->plot_size_codes unless defined($self->{width});
	$self->{height} = $::config_obj->plot_size_codes unless defined($self->{height});
	
	unless (
		   (length($self->{width} ) == 0 || $self->{width}  =~ /^[0-9]+$/)
		&& (length($self->{height}) == 0 || $self->{height} =~ /^[0-9]+$/)
	){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('illegal_plot_size') # プロットサイズの指定が不正です
		);
		return 0;
	}

	$self->{font_size} = $::config_obj->plot_font_size / 100 unless $self->{font_size};

	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	$::config_obj->R->send("the_warning <<- \"\"\n");
	print "kh_r_plot::new lock ok.\n" if $debug;
	$self->{path} = $self->R_device(
		$self->{path},
		$self->{width},
		$self->{height},
	);
	print "kh_r_plot::new R.device ok.\n" if $debug;
	$self->set_par;
	print "kh_r_plot::new set_par ok.\n" if $debug;
	$::config_obj->R->send("saving_file <- 0\n");
	$::config_obj->R->send("image_width <- $self->{width} / $self->{dpi}\n");
	$::config_obj->R->send($command);
	print "kh_r_plot::new send ok.\n" if $debug;
	$self->{r_msg} = $::config_obj->R->read;
	print "kh_r_plot::new read ok.\n" if $debug;
	$::config_obj->R->send('dev.off()');
	print "kh_r_plot::new dev.off ok.\n" if $debug;
	$::config_obj->R->unlock;
	print "kh_r_plot::new unlock ok.\n" if $debug;
	$::config_obj->R->output_chk(1);

	# Reading text output from R
	my $loc = 'console_out';
	unless ( Encode::find_encoding('console_out') ){
		$loc = 'ascii';
	}
	
	if (
		   ( $::config_obj->os eq 'win32' )
		&& $::project_obj->morpho_analyzer_lang eq 'cn')
	{
		$loc = 'cp936'
	}
	$self->{r_msg} = Encode::decode($loc, $self->{r_msg});

	# 結果のチェック
	if (
		not (-e $self->{path})
		or ( $self->{r_msg} =~ /error/i )
		or ( index($self->{r_msg},'エラー') > -1 )
		or ( index($self->{r_msg},Jcode->new('エラー','euc')->utf8) > -1 )
	) {
		my $msg = kh_msg->get('faliled_in_plotting');
		$msg .= $self->{r_msg}."\n\n";
		
		$msg .= "No output file." if not -e $self->{path};
		
		print "output file: $self->{path}\n";
		
		gui_errormsg->open(
			type   => 'msg',
			window => \$::main_gui->mw,
			msg    => $msg,
		);
		return 0;
	}
	
	return $self;
}

### From Encode::Escape::Unicode
sub chr2hex {
    my($c) = @_;
    if ( ord($c) < 65536 ) {
        return sprintf("%04x", ord($c));
    }
    else {
        require Carp;
        Carp::croak (
            "'unicode-escape' codec can't encode character: ordinal " . ord($c)
        );
    }
}

sub escape_unicode{
	my $self = shift;
	my $input = shift;
	
	if ($::config_obj->os eq 'win32') {
		# Delete characters outside of the current locale (Win32)
		# if ($::project_obj) {
		if (0) {
			my %loc = (
				'jp' => 'cp932',
				'en' => 'cp1252',
				'cn' => 'cp936',
				'de' => 'cp1252',
				'es' => 'cp1252',
				'fr' => 'cp1252',
				'it' => 'cp1252',
				'nl' => 'cp1252',
				'pt' => 'cp1252',
				'kr' => 'cp949',
				'ca' => 'cp1252',
				'ru' => 'cp1251',
				'sl' => 'cp1251',
			);
			my $lang = $::project_obj->morpho_analyzer_lang;
			if ($lang eq 'en') {
				$lang = $::config_obj->msg_lang;
			}
			
			$lang = $loc{$lang};
			my $encoded = Encode::encode($lang, $input, Encode::FB_HTMLCREF );
			$input = Encode::decode($lang, $encoded);
		}
		
		# Escape Unicode characaters
		#my $utf8 = Encode::encode('UTF-8', $input);
		#use Unicode::Escape;
		#return Unicode::Escape::escape($utf8);
		
		$input =~ s/([\x{7f}-\x{ffff}])/'\u'.chr2hex($1)/gse;
		return $input;
	} else {
		return $input;
	}
}

sub clear_env{
	#$::config_obj->R->send('print( ls() )');
	#print "before: ", $::config_obj->R->read, "\n";

	return 1 if $::config_obj->web_if;
	
	$::config_obj->R->output_chk(0);
	$::config_obj->R->send("
		the_list <- ls()
		the_list <- the_list[substring(the_list,0,4) != \"PERL\"]
		if ( length(the_list) > 0 ){
			rm(list=the_list)
		}
		rm(the_list)
	");

	if ( $if_lt25 == 2 ){
		$::config_obj->R->send(
			'as.graphicsAnnot <- function(x) if (is.language(x) || !is.object(x)) x else as.character(x)'
		);
	}
	$::config_obj->R->output_chk(1);

	#$::config_obj->R->send('print( ls() )');
	#print "after: ", $::config_obj->R->read, "\n";

	#print "R env has been cleared.\n";
}

sub set_par{
	my $self = shift;
	my $opt  = shift;
	$opt = '' unless defined($opt);

	$::config_obj->R->output_chk(0);
	$::config_obj->R->send(
		'par(mai=c(0,0,0,0), mar=c(4,4,1,1), omi=c(0,0,0,0), oma =c(0,0,0,0) )'
	);

	my $font;
	if ($opt eq 'ps_font') {
		$font = $::config_obj->font_pdf_current;
	} else {
		$font = $::config_obj->font_plot_current;
	}
	$::config_obj->R->send( "par(family=\"$font\")" );
	$::config_obj->R->send( "PERL_font_family <- \"$font\"" );

	# Windowsではロケールを設定する
	if ($::config_obj->os eq 'win32') {
		my %loc = (
			'jp' => 'Japanese',
			'en' => 'English',
			'cn' => 'Chinese',
			'de' => 'German',
			'es' => 'Spanish',
			'fr' => 'French',
			'it' => 'Italian',
			'nl' => 'Dutch',
			'pt' => 'Portuguese',
			'kr' => 'Korean',
			'ca' => 'Catalan',
			'ru' => 'Russian',
			'sl' => 'Slovenian',
		);
		
		my $lang = $::project_obj->morpho_analyzer_lang;
		if ($lang eq 'en') {
			$lang = $::config_obj->msg_lang;
		}
		$lang = $loc{$lang};
		if ($lang) {
			$::config_obj->{R}->send("Sys.setlocale(category=\"LC_ALL\",locale=\"$lang\")");
		}
	}
	
	$::config_obj->R->output_chk(1);

	return $self;
}

sub rotate_cls{
	my $self = shift;
	
	unless (eval 'require Image::Magick;'){
		print "Could not rotate the dendrogram: No Image-Magick.\n";
		return $self;
	}
	
	# tempファイルの名前
	my $type = '';
	if ($self->{path} =~ /\.bmp$/){
		$type = 'bmp';
	} else {
		$type = 'png';
	}
	
	# tempファイルにリネーム
	my $temp = "hoge";
	my $n = 0;
	while (-e "$temp$n.$type"){
		++$n;
	}
	$temp = $::config_obj->cwd.'/'."$temp$n.$type";
	use File::Copy;
	copy($self->{path}, $temp);
	#print "$temp, $self->{path}\n";

	# 画像操作
	my $p = Image::Magick->new;
	$p->Read( $::config_obj->uni_path( $temp ) );
	unless ($p->[0]){
		warn("Could not rotate the dendrogram: $!");
		unlink($temp);
		return $self;
	}
	$p->Rotate( degrees=>90 );
	
	if ($self->{width} > 1000){
		# スケール部分切り出し
		my $scale_height = int( 41 * $self->{dpi} / 72 );
		$p->Crop(geometry=> "$self->{height}x$scale_height+0+0");
		
		# 本体切り出し
		#print "$temp\n";
		$p->Read( $::config_obj->uni_path( $temp ) );
		unless ($p->[1]){
			warn("Could not rotate the dendrogram: $!");
			unlink($temp);
			return $self;
		}
		$p->[1]->Rotate(degrees=>90);
		my $start = int( $self->{width} * 0.033 + 33 - 10 );
		my $height = int( $self->{width} - $self->{width} * 0.033 +10)-$start;
		$p->[1]->Crop(geometry=> "$self->{height}x$height+0+$start");
		
		# 貼り合わせ
		$p = $p->append(stack => "true");
	}
	
	if ($type eq 'bmp'){ 
		$p->Write(filename=>"$temp", compression=>'None');
	} else {
		$p->Write($temp);
	}
	
	unlink($self->{path});
	rename($temp, $self->{path});

	return $self;
}

sub save{
	my $self = shift;
	my $target_os_path = shift;
	$self->{target_os_path} = $target_os_path;
	
	my $path;
	$path =
		$::config_obj->cwd
		.'/config/R-bridge/'
		.$::project_obj->dbname
		.'_'
		.$self->{name}
		.'_save'
	;
	
	if (-e $path){
		unlink $path or die("could not delete file: $path");
	}
	#my $temp_os_path = $path;
	
	$path = $::config_obj->uni_path($path);
	$path =~ tr/\\/\//;
	
	$self->clear_env;
	
	$::config_obj->R->send("saving_file <- 1\n");
	if ($target_os_path =~ /\.r$/i){
		$path .= ".r";
		$self->_save_r($path);
	}
	elsif ($target_os_path =~ /\.png$/i){
		$path .= ".png";
		$self->_save_png($path);
	}
	elsif ($target_os_path =~ /\.eps$/i){
		$path .= ".eps";
		$self->_save_eps($path);
	}
	elsif ($target_os_path =~ /\.pdf$/i){
		$path .= ".pdf";
		$self->_save_pdf($path);
	}
	elsif ($target_os_path =~ /\.emf$/i){
		$path .= ".emf";
		$self->_save_emf($path);
	}
	elsif ($target_os_path =~ /\.svg$/i){
		$path .= ".svg";
		$self->_save_svg($path);
	}
	elsif ($target_os_path =~ /\.graphml$/i){
		$path .= ".graphml";
		$self->_save_graphml($path);
	}
	elsif ($target_os_path =~ /\.net$/i){
		$path .= ".net";
		$self->_save_net($path);
	}
	elsif ($target_os_path =~ /\.csv$/i){
		$path .= ".csv";
		$self->_save_csv($path);
	}
	elsif ($target_os_path =~ /\.html$/i){
		$path .= ".html";
		$self->_save_html($path);
	}
	else {
		warn "The file type is not supported yet:\n$target_os_path\n";
	}

	my $temp_os_path = $::config_obj->os_path($path);
	unless ( -e $temp_os_path ){
		warn "failed to save the plot: ".$::config_obj->R->read;
		return 0;
	}
	
	use File::Copy;
	copy($temp_os_path, $target_os_path) or die("failed to copy the file: $temp_os_path, $target_os_path");
}

sub R_device{
	my $self  = shift;
	my $path  = shift;
	my $width = shift;
	my $height = shift;
	
	$path .= '.png';
	unlink($path) if -e $path;
	
	$width  = $::config_obj->plot_size_words unless $width;
	$height = $::config_obj->plot_size_words unless $height;

	# Setup the dpi value
	my $dpi = 72;
	use Statistics::Lite qw(min);
	if (
		(
			   $self->{command_f} =~ /ggdendro/
			|| $self->{command_f} =~ /rect\.hclust/
		)
		and not ( $self->{command_f} =~ /pp_type/ )
	) {                         # dendrogram
		$dpi = int( 72 * ($::config_obj->plot_size_codes / 480) );
	}
	elsif ( $self->{command_f} =~ /pheatmap/){
		$dpi = int( 72 * ($width / 640) );
		# print "pheatmap! width: $width\n";
	}
	elsif ($self->{command_f} =~ /# dpi: short based\n/){ # short based (codes, mainly)
		$dpi = int( 72 * ( min($width,$height) / 480) );
	}
	elsif ($height == $width) { # square
		$dpi = int( 72 * ($height / 640) ) if $height > 640;
	}
	elsif (
		   $height == $::config_obj->plot_size_codes
		&& $width  == $::config_obj->plot_size_words
	){                          # default rectangle
		$dpi = int( 72 * ($::config_obj->plot_size_words / 640) );
	}
	elsif ( min($width,$height) > 640 ) { # unknown
		$dpi = int( 72 * ( min($width,$height) / 640 ) )
	}

	#$dpi = int( $dpi * $self->{font_size} );

	return 0 unless $::config_obj->R;
	$self->{dpi} = $dpi;
	
	my $p = 12 * $dpi / 72;
	#print "point size: $p\n";
	#print "dpi: $dpi\n";
	
	my $uni_path = $::config_obj->uni_path($path);
	$::config_obj->R->send("
		if ( exists(\"Cairo\") ){
			Cairo(width=$width, height=$height, unit=\"px\", file=\"$uni_path\", bg = \"white\", type=\"png\", dpi=$dpi)
		} else {
			png(\"$uni_path\", width=$width, height=$height, unit=\"px\", res=$dpi ) # pointsize=$p
		}
	");
	return $path;
}

sub _save_emf{
	my $self = shift;
	my $path = shift;
	
	my $w = 8;
	if ($self->{width} > $self->{height}){
		$w = sprintf("%.5f", 8 * $self->{width} / $self->{height} );
	}
	my $h = 8;
	if ($self->{height} > $self->{width}){
		$h = sprintf("%.5f", 8 * $self->{height} / $self->{width} );
	}
	
	# Font configuration for R's built in "win.metafile" function
	# comment out "$self->set_par;" below to use this config
	#my $font = $::config_obj->font_plot_current;
	#$::config_obj->R->send( "windowsFonts(serif=windowsFont(\"TT $font\"))" );
	#$::config_obj->R->send( "PERL_font_family <- \"serif\"" );

	# devEMF package or default win.metafile
	my $emf_command = '';
	if ( $::config_obj->devEMF ){
		$emf_command = "library(devEMF)\n emf(file=\"$path\", width = $w, height = $h, pointsize=12, emfPlus=F)"
	} else {
		$emf_command = "win.metafile(filename=\"$path\", width = $w, height = $h, pointsize=12, family=\"serif\")";
	}
	
	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	$::config_obj->R->send( "saving_emf <- 1" );
	$::config_obj->R->send( $emf_command );
	$self->set_par;
	if ( length($self->{command_s}) ) {
		$::config_obj->R->send( $self->{command_s} );
	} else {
		$::config_obj->R->send( $self->{command_f} );
	}
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	return 1;
}

sub _save_pdf{
	my $self = shift;
	my $path = shift;

	my $w = 8;
	if ($self->{width} > $self->{height}){
		$w = sprintf("%.5f", 8 * $self->{width} / $self->{height} );
	}
	my $h = 8;
	if ($self->{height} > $self->{width}){
		$h = sprintf("%.5f", 8 * $self->{height} / $self->{width} );
	}

	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	
	# Use "cairo_pdf" when the prject language is Russian
	my $lang = '';
	if ( $::project_obj ) {
		$lang = $::project_obj->morpho_analyzer_lang;
	}
	if ($lang eq 'ru') {
		$::config_obj->R->send(
			 "cairo_pdf(file=\"$path\", height = $h, width = $w, "
			."pointsize=12)"
		);
	} else {
		$::config_obj->R->send(
			 "pdf(file=\"$path\", height = $h, width = $w, useDingbats=F, "
			."family=\"".$::config_obj->font_pdf_current."\", pointsize=12)"
		);
	}

	$self->set_par('ps_font');
	if ( length($self->{command_s}) ) {
		$::config_obj->R->send( $self->{command_s} );
	} else {
		$::config_obj->R->send( $self->{command_f} );
	}
	$::config_obj->R->send('dev.off()');

	if (
		$lang eq 'ru'
		&& $^O =~ /darwin/
		&& $::config_obj->all_in_one_pack
		&& 0
	) {
		#$::config_obj->R->send(
		#	"embedFonts(\"$path\", fontpaths=\"".$::config_obj->cwd."/deps/fonts\")"
		#);
		$::config_obj->R->send("Sys.setlocale(category=\"LC_ALL\",locale=\"ja_JP.UTF-8\")");
	}
	
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	return 1;
}


sub _save_eps{
	my $self = shift;
	my $path = shift;

	my $w = 8;
	if ($self->{width} > $self->{height}){
		$w = sprintf("%.5f", 8 * $self->{width} / $self->{height} );
	}
	my $h = 8;
	if ($self->{height} > $self->{width}){
		$h = sprintf("%.5f", 8 * $self->{height} / $self->{width} );
	}

	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	$::config_obj->R->send( "saving_eps <- 1" );
	
	# Use "cairo_ps" when the prject language is Russian or Korean
	my $lang = '';
	if ( $::project_obj ) {
		$lang = $::project_obj->morpho_analyzer_lang;
	}
	if ($lang eq 'ru' || $lang eq 'kr' || $^O =~ /darwin/i ) {
		$::config_obj->R->send(
			"cairo_ps(\"$path\", height = $h, width = $w, pointsize=12)"
		);
	} else {
		$::config_obj->R->send(
			 "postscript(\"$path\", horizontal = FALSE, onefile = FALSE,"
			."paper = \"special\", height = $h, width = $w,"
			."family=\"".$::config_obj->font_pdf_current."\",pointsize=12)"
		);
	}

	$self->set_par('ps_font');
	if ( length($self->{command_s}) ) {
		$::config_obj->R->send( $self->{command_s} );
	} else {
		$::config_obj->R->send( $self->{command_f} );
	}
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	return 1;
}

sub _save_png{
	my $self = shift;
	my $path = shift;
	
	if (-e $self->{path}) {
		use File::Copy qw/copy/;
		copy($self->{path}, $path) or warn("File copy failed: $path\n");
		return 1;
	}
	
	my $width = $self->{width};
	my $height = $self->{height};

	$width  = $::config_obj->plot_size_words unless $width;
	$height = $::config_obj->plot_size_words unless $height;

	# Setup the dpi value
	my $dpi = 72;
	use Statistics::Lite qw(min);
	if (
		(
			   $self->{command_f} =~ /ggdendro/
			|| $self->{command_f} =~ /rect\.hclust/
		)
		and not ( $self->{command_f} =~ /pp_type/ )
	) {                         # dendrogram
		$dpi = int( 72 * ($::config_obj->plot_size_codes / 480) );
	}
	elsif ( $self->{command_f} =~ /pheatmap/){
		$dpi = int( 72 * ($width / 640) );
		# print "pheatmap! width: $width\n";
	}
	elsif ($self->{command_f} =~ /# dpi: short based\n/){ # short based (codes, mainly)
		$dpi = int( 72 * ( min($width,$height) / 480) );
	}
	elsif ($height == $width) { # square
		$dpi = int( 72 * ($height / 640) ) if $height > 640;
	}
	elsif (
		   $height == $::config_obj->plot_size_codes
		&& $width  == $::config_obj->plot_size_words
	){                          # default rectangle
		$dpi = int( 72 * ($::config_obj->plot_size_words / 640) );
	}
	elsif ( min($width,$height) > 640 ) { # unknown
		$dpi = int( 72 * ( min($width,$height) / 640 ) )
	}

	#$dpi = int( $dpi * $self->{font_size} );
	$self->{dpi} = $dpi;
	
	my $p = 12 * $dpi / 72;

	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;

	$::config_obj->R->send("
		if ( exists(\"Cairo\") ){
			Cairo(width=$width, height=$height, unit=\"px\", file=\"$path\", type=\"png\", bg=\"white\", dpi=$dpi)
		} else {
			png(\"$path\", width=$self->{width}, height=$self->{height}, unit=\"px\", res=$dpi)
		}
	");


	$self->set_par;
	if ( length($self->{command_s}) ) {
		$::config_obj->R->send( $self->{command_s} );
	} else {
		$::config_obj->R->send( $self->{command_f} );
	}
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	return 1;
}

sub _save_svg{
	my $self = shift;
	my $path = shift;
	
	$self->{width}  = 480 unless $self->{width};
	$self->{height} = 480 unless $self->{height};
	
	# for darwin
	my $w = 8;
	if ($self->{width} > $self->{height}){
		$w = sprintf("%.5f", 8 * $self->{width} / $self->{height} );
	}
	my $h = 8;
	if ($self->{height} > $self->{width}){
		$h = sprintf("%.5f", 8 * $self->{height} / $self->{width} );
	}

	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;

	$::config_obj->R->send("
		if ( exists(\"Cairo\") ){
			library(Cairo)
			Cairo(
				width=$w * 80,
				height=$h * 80,
				file=\"$path\",
				type=\"svg\",
				onefile=TRUE,
				bg=\"transparent\",
				dpi=72,
				units=\"px\",
				pointsize=12
			)
		} else {
			# for darwin

			# Could not render some circle outlines
			library(RSVGTipsDevice)
			devSVGTips(
				\"$path\",
				width=$w * 1.4,
				height=$h * 1.4,
				bg=\"white\",
				fg=\"black\",
				toolTipMode=0
			)
			
			# Font rendering is ugly (same as Cairo)
			#svg(
			#	\"$path\",
			#	width=$w,
			#	height=$h
			#	family=\"".$::config_obj->font_pdf_current."\"
			#)

			# Could not install 'svglite' package for R 3.1.0
		}
	");

	$self->set_par;
	
	# for darwin
	if ($^O =~ /darwin/i){
		$::config_obj->R->send(
			'par(mai=c(0,0,0,0), mar=c(5,4,1,1), omi=c(0,0,0,0), oma =c(0,0,0,0) )'
		);
	}
	
	if ( length($self->{command_s}) ) {
		$::config_obj->R->send( $self->{command_s} );
	} else {
		$::config_obj->R->send( $self->{command_f} );
	}
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	# for darwin (No harm in Windows. But what's this?)
	#my $file_temp = $::config_obj->file_temp;
	#open my $fhi, '<:encoding(eucJP-ms)', $path      or die("file: $path");
	#open my $fho, '>:encoding(utf8)',     $file_temp or die("file: $file_temp");
	#while (<$fhi>){
	#	print $fho $_;
	#}
	#close $fhi;
	#close $fho;
	#unlink $path;
	#rename($file_temp, $path) or die("rename $file_temp, $path");
	
	return 1;
}

sub _save_r{
	my $self = shift;
	my $path = shift;
	$path = $::config_obj->os_path($path);
	
	# 日本語データでOSの文字コードがcp932の場合のみcp932で出力
	my $out_code = 'utf8';
	if (
		   ( $::config_obj->os_code eq 'cp932' )
		&& ( $::project_obj->morpho_analyzer_lang eq 'jp' )
	) {
		$out_code = 'cp932';
	}
	
	my $t = $self->{command_f};
	
	# SOMのための特殊処理
	if ($t =~ /\nload\(\"(.+)\"\)/){
		my $file = $1;
		$file = $::config_obj->os_path($file);
		$file .= '_s';
		if ( -e $file ){
			#print "file: $file\n";
			open (my $fh, '<:encoding(utf8)', $file)
				or gui_errormsg->open(
					type    => 'file',
					thefile => $file,
				)
			;
			my $t0 = '';
			while (<$fh>){
				$t0 .= $_;
			}
			close $fh;
			$t =~ s/\nload\(\"(.+)\"\)\n/\n/;
			$t = $t0."\n".$t;
		}
	}
	
	open (OUTF, ">:encoding($out_code)", $path) or 
		gui_errormsg->open(
			type    => 'file',
			thefile => $path,
		);
	
	# データをファイル内に記述
	if ( $t =~ /source\(\"(.+)\", encoding=\"UTF-8\"\)/ ){
		my $file_data = $1;
		$file_data = $::config_obj->os_path($file_data);
		open my $fhr, '<:encoding(utf8)', $file_data or 
			gui_errormsg->open(
				type    => 'file',
				thefile => $file_data,
			);
		while (<$fhr>){
			print OUTF $_;
		}
		close $fhr;
		$t =~ s/source\(\"(.+)\", encoding=\"UTF-8\"\)//;
	}
	if ( $t =~ /source\(\"(.+)\"\)/ ){
		my $file_data = $1;
		$file_data = $::config_obj->os_path($file_data);
		open my $fhr, '<:encoding(cp1251)', $file_data or 
			gui_errormsg->open(
				type    => 'file',
				thefile => $file_data,
			);
		while (<$fhr>){
			print OUTF $_;
		}
		close $fhr;
		$t =~ s/source\(\"(.+)\"\)//;
	}
	
	#$t = $self->escape_unicode($t);
	print OUTF $t,"\n";
	close (OUTF);
	
	return 1;
}

sub command_f{
	my $self = shift;
	return $self->{command_f};
}

sub r_msg{
	my $self = shift;
	return $self->{r_msg};
}

sub path{
	my $self = shift;
	return $self->{path};
}

sub quote{
	my $class = shift;
	my $t     = shift;
	
	$t =~ s/"/\\"/g;
	return '"'.$t.'"';
}

#sub DESTROY{
#	my $self = shift;
#	print "DESTROYed: $self->{name}\n";
#}

1;
