package kh_docx;
use strict;

sub new{
	my $class = shift;
	
	my $self;
	$self->{original} = shift;

	bless $self, $class;
	return $self;
}

sub conv{
	my $self = shift;
	
	# check the file type
	my $type;
	my $base;
	if ($self->{original} =~ /(.+)\.docx$/i) {
		$type = 'docx';
		$base = $1;
	}
	elsif ($self->{original} =~ /(.+)\.doc$/i) {
		$type = 'doc';
		$base = $1;
	}
	elsif ($self->{original} =~ /(.+)\.rtf$/i) {
		$type = 'rtf';
		$base = $1;
	}
	elsif ($self->{original} =~ /(.+)\.odt$/i) {
		$type = 'odt';
		$base = $1;
	}
	else {
		print "kh_docx: not intended file type (docx/doc/rtf).\n";
		return undef;
	}
	
	# output file name
	unless ($self->{converted}){
		my $n = 0;
		while (-e $base."_txt$n.txt"){
			++$n;
		}
		$self->{converted} = $base."_txt$n.txt";
	}

	# exec conv
	use Cwd;
	my $cwd = cwd;
	chdir( $::config_obj->cwd );
	#print "moved cwd: ", cwd, "\n";
	
	my $os = $::config_obj->os;
	my $exe = "_$type"."_$os";
	$self->$exe;

	# check the result
	unless (-e $::config_obj->os_path( $self->{converted} )){
		print "failed to convert: $exe\n";
		return undef;
	}
	
	chdir( $cwd );
	#print "returned cwd: ", cwd, "\n";
	return $self->{converted};
}

sub _rtf_linux{
	my $self = shift;

	unless ($^O =~ /darwin/i){
		return undef;
	}
	
	my $o = $::config_obj->os_path( $self->{converted} );
	my $i = $::config_obj->os_path( $self->{original}  );
	
	system("textutil \"$i\" -convert txt -output \"$o\"");
	return 1;
}

sub _doc_linux{
	return undef;
}

sub _doc_win32{
	my $self = shift;
	
	if ( $^O eq 'MSWin32' ){
		require Win32::OLE;
	} else {
		return undef;
	}

	my $word = Win32::OLE->GetActiveObject('Word.Application')
		|| Win32::OLE->new('Word.Application', 'Quit')
		|| return undef
	;

	# https://docs.microsoft.com/ja-jp/office/vba/api/Word.WdSaveFormat
	# https://docs.microsoft.com/ja-jp/office/vba/api/office.msoencoding
	use constant wdFormatUnicodeText => 7;
	use constant msoEncodingUTF8 => 65001;

	my $o = $::config_obj->os_path( $self->{converted} );
	my $i = $::config_obj->os_path( $self->{original}  );

	my $doc = $word->Documents->Open($i) || return undef;
	$doc->SaveAs2({
		Filename   => $o,
		FileFormat => wdFormatUnicodeText,
		Encoding   => msoEncodingUTF8,
	});
	$doc->Close;

	return 1;
}

*_rtf_win32 = \&_doc_win32;

sub _docx_linux{
	my $self = shift;

	my $o = $::config_obj->os_path( $self->{converted} );
	my $i = $::config_obj->os_path( $self->{original}  );
	my $cmd = "pandoc --from=docx --to=plain --output=\"$o\" \"$i\"";
	
	system "$cmd";
	
	return 1;
}

sub _odt_linux{
	my $self = shift;

	my $o = $::config_obj->os_path( $self->{converted} );
	my $i = $::config_obj->os_path( $self->{original}  );
	my $cmd = "pandoc --from=odt --to=plain --output=\"$o\" \"$i\"";
	
	system "$cmd";
	
	return 1;
}

sub _odt_win32{
	my $self = shift;
	
	# pandoc path
	require Win32::SearchPath;
	my $path = Win32::SearchPath::SearchPath('pandoc');
	#print "path: $path\n";
	unless (-e $path && length($path) ) {
		print "kh_docx: could not find pandoc.\n";
		return undef;
	}

	# convert
	my $o = $::config_obj->os_path( $self->{converted} );
	my $i = $::config_obj->os_path( $self->{original}  );
	my $cmd = "pandoc --from=odt --to=plain --output=\"$o\" \"$i\"";
	
		require Win32::Process;
	my $process;
	Win32::Process::Create(
		$process,
		$path,
		$cmd,
		0,
		undef,
		$::config_obj->cwd,
	) || return undef;
	$process->Wait( Win32::Process->INFINITE );
	
	return 1;
}

sub _docx_win32{
	my $self = shift;
	
	# pandoc path
	require Win32::SearchPath;
	my $path = Win32::SearchPath::SearchPath('pandoc');
	#print "path: $path\n";
	unless (-e $path && length($path) ) {
		print "kh_docx: could not find pandoc.\n";
		return undef;
	}

	# convert
	my $o = $::config_obj->os_path( $self->{converted} );
	my $i = $::config_obj->os_path( $self->{original}  );
	my $cmd = "pandoc --from=docx --to=plain --output=\"$o\" \"$i\"";
	
	require Win32::Process;
	my $process;
	Win32::Process::Create(
		$process,
		$path,
		$cmd,
		0,
		undef,
		$::config_obj->cwd,
	) || return undef;
	$process->Wait( Win32::Process->INFINITE );
	
	return 1;
}


1;
