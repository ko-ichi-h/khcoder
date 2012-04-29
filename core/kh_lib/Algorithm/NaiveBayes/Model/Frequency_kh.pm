package Algorithm::NaiveBayes::Model::Frequency;

use strict;
use Algorithm::NaiveBayes::Util qw(sum_hash add_hash max rescale);
use base qw(Algorithm::NaiveBayes);

no warnings 'redefine';

sub new {
  my $self = shift()->SUPER::new(@_);
  $self->training_data->{attributes} = {};
  $self->training_data->{labels} = {};
  return $self;
}

sub do_add_instance {
  my ($self, $attributes, $labels, $training_data) = @_;
  add_hash($training_data->{attributes}, $attributes);
  
  my $mylabels = $training_data->{labels};
  foreach my $label ( @$labels ) {
    $mylabels->{$label}{count}++;
    add_hash($mylabels->{$label}{attributes} ||= {}, $attributes);
  }
}

sub do_train {
  my ($self, $training_data) = @_;
  my $m = {};
  
  my $instances = $self->instances;
  my $labels = $training_data->{labels};
  $m->{attributes} = $training_data->{attributes};
  my $vocab_size = keys %{ $m->{attributes} };
  
  # Calculate the log-probabilities for each category
  foreach my $label ($self->labels) {
    $m->{prior_probs}{$label} = log($labels->{$label}{count} / $instances);
    
    # Count the number of tokens in this cat
    my $label_tokens = sum_hash($labels->{$label}{attributes});
    
    # Compute a smoothing term so P(word|cat)==0 can be avoided
    $m->{smoother}{$label} = -log($label_tokens + $vocab_size);
    
    # P(attr|label) = $count/$label_tokens                         (simple)
    # P(attr|label) = ($count + 1)/($label_tokens + $vocab_size)   (with smoothing)
    # log P(attr|label) = log($count + 1) - log($label_tokens + $vocab_size)
    
    my $denominator = log($label_tokens + $vocab_size);
    
    while (my ($attribute, $count) = each %{ $labels->{$label}{attributes} }) {
      $m->{probs}{$label}{$attribute} = log($count + 1) - $denominator;
    }
  }
  return $m;
}

sub do_predict {
  my ($self, $m, $newattrs) = @_;
  
  # Note that we're using the log(prob) here.  That's why we add instead of multiply.

  # 分類プロセスの保存用
  my $spd = $self->save_prediction_detail;
  my $kh_process if $spd;
  
  my %scores = %{$m->{prior_probs}};
  while (my ($feature, $value) = each %$newattrs) {
    next unless exists $m->{attributes}{$feature};  # Ignore totally unseen features
    while (my ($label, $attributes) = each %{$m->{probs}}) {
      $scores{$label} += ($attributes->{$feature} || $m->{smoother}{$label})*$value;   # P($feature|$label)**$value
 
      # 分類プロセスの保存用
      if ($spd){
        $kh_process->{$feature}{v} = $value;
        $kh_process->{$feature}{l}{$label} = ( $attributes->{$feature} || $m->{smoother}{$label} );
      }

    }
  }

  rescale(\%scores);

  if ($spd){
    return (\%scores, $kh_process);
  } else {
    return (\%scores, undef);
  }
}

sub save_prediction_detail{
	my $self = shift;
	my $new =  shift;
	
	if ( defined($new) ){
		$self->{save_prediction_detail} = $new;
	}
	
	return $self->{save_prediction_detail};
}

1;
