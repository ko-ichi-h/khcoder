# 前処理の成功・失敗をメールで通知

package kh_mailif;
use strict;
use Net::SMTP;

sub success{
	unless ($::config_obj->mail_if){
		return 0;
	}

	# ユーザー名とホスト名の取得
	my $user = $ENV{USERNAME};
	unless ($user){ $user = $ENV{USER}; }
	my $host = $ENV{USERDOMAIN};
	unless ($host){ $host = $ENV{HOSTNAME}; }
	
	
	my $smtp = Net::SMTP->new($::config_obj->mail_smtp);
	$smtp->mail($::config_obj->mail_from);
	$smtp->to($::config_obj->mail_to);
	$smtp->data();
	$smtp->datasend("From:KH Coder<".$::config_obj->mail_from.">\n");
	$smtp->datasend("To:The User<".$::config_obj->mail_to.">\n");
	$smtp->datasend("Subject:Pre-processing is successfully complete.\n");
	
	# 本文
	$smtp->datasend("Hello $user.\nI am KH Coder v. $::kh_version.\n\n");
	$smtp->datasend("It is my honor to notify you that I have successfully comleted pre-processing of your data.\n\n");
	$smtp->datasend("Here is some info.\n");
	$smtp->datasend("  Computer used:    $host\n");
	$smtp->datasend("  Target File:      ".$::project_obj->file_target."\n");
	$smtp->datasend("  Project comment:  ".$::project_obj->comment."\n");
	
	$smtp->datasend("\nBest regards.");
	$smtp->dataend();
	$smtp->quit;
}

sub failure{
	unless ($::config_obj->mail_if && $::config_obj->in_preprocessing){
		return 0;
	}

	# ユーザー名とホスト名の取得
	my $user = $ENV{USERNAME};
	unless ($user){ $user = $ENV{USER}; }
	my $host = $ENV{USERDOMAIN};
	unless ($host){ $host = $ENV{HOSTNAME}; }

	my $smtp = Net::SMTP->new($::config_obj->mail_smtp);
	$smtp->mail($::config_obj->mail_from);
	$smtp->to($::config_obj->mail_to);
	$smtp->data();
	$smtp->datasend("From:KH Coder<".$::config_obj->mail_from.">\n");
	$smtp->datasend("To:The User<".$::config_obj->mail_to.">\n");
	$smtp->datasend("Subject:Failure in Pre-processing.\n");
	# 本文
	
	$smtp->datasend("Hello $user.\nI am KH Coder v. $::kh_version.\n\n");
	$smtp->datasend("I am sorry that I encountered a problem during the pre-processing and could not finish it.\n\n");
	
	$smtp->datasend("  computer used: $host\n");
	$smtp->datasend("  target file: ".$::project_obj->file_target."\n");
	$smtp->datasend("  project comment: ".$::project_obj->comment."\n");
	
	$smtp->datasend("\nBest regards.");
	$smtp->dataend();
	$smtp->quit;
}

1;