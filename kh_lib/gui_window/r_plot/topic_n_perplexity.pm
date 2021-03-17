package gui_window::r_plot::topic_n_perplexity;
use base qw(gui_window::r_plot);

sub start{
	my $self = shift;
	$self->{button_config}->configure(-state => 'disabled');
}

sub option1_options{
	return [ 'nothing' ];
}

sub option1_name{
	return '';
}

sub win_title{
	return kh_msg->get('win_title');
}

sub win_name{
	return 'w_topic_n_perplexity_plot';
}

sub base_name{
	return 'topic_n_perplexity';
}

1;