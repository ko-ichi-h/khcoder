package gui_OtherWin::linux;
use base qw (gui_OtherWin);
use strict;

sub _open{
	my $self = shift;
	my $t = $self->target;

	my $cmd;
	if ($t =~ /^http/ or $t =~ /\.htm$/ or $t =~ /\.html$/ ){
		$cmd = $::config_obj->app_html;
	}
	elsif($t =~ /\.csv$/){
		$cmd = $::config_obj->app_csv;
	}
	elsif($t =~ /\.pdf$/){
		$cmd = $::config_obj->app_pdf;
	}

	$cmd =~ s/%s/$t/;
	print "$cmd\n";

	system "$cmd";
	print "hoge\n";
}


1;