package gui_errormsg;
use strict;

use gui_errormsg::msg;
use gui_errormsg::file;
use gui_errormsg::mysql;

use gui_errormsg::print;

# usege: gui_errormsg->open
# options: 
#	msg
#	*window
#	type [msg,file,mysql]
#	*thefile
#   *sql
#	*icon

sub open{
	my $class = shift;
	my %args = @_;
	my $self = \%args;
	bless $self, "$class"."::"."$args{type}";
	
	$self->notify;
	
	$self->{msg} = $self->get_msg;
	$self->print;
	unless ($self->{type} eq 'msg'){
		exit;
	}
}

sub print{
	my $self = shift;
	my %args = %{$self};
	gui_errormsg::print->new(%args);
}

# 前処理中でメール通知がONの場合はメールを送信

sub notify{
	
	unless ($::config_obj->mail_if && $::config_obj->in_preprocessing){
		return 0;
	}

	my $user = $ENV{USERNAME};
	unless ($user){ $user = $ENV{USER}; }
	
	my $host = $ENV{USERDOMAIN};
	unless ($host){ $host = $ENV{HOSTNAME}; }
	
	use Net::SMTP;
	my $smtp = Net::SMTP->new($::config_obj->mail_smtp);
	$smtp->mail($::config_obj->mail_from);
	$smtp->to($::config_obj->mail_to);
	$smtp->data();
	$smtp->datasend("From:KH Coder<".$::config_obj->mail_from.">\n");
	$smtp->datasend("To:a_User_of_KH_Coder\n");
	$smtp->datasend("Subject:Failure in Pre-processing.\n");
	# 本文
	
	$smtp->datasend("Hello $user.\nI am KH Coder v. $::kh_version.\n\n");
	$smtp->datasend("I am sorry that I encountered a problem during the pre-processing and could not finish it.\n\n");
	
	$smtp->datasend("computer used: $host\n");
	$smtp->datasend("target file: ".$::project_obj->file_target."\n");
	$smtp->datasend("project comment: ".$::project_obj->comment."\n");
	
	$smtp->dataend();
	$smtp->quit;

}

1;
