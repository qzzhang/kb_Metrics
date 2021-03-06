package kb_Metrics::kb_MetricsClient;

use JSON::RPC::Client;
use POSIX;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;
my $get_time = sub { time, 0 };
eval {
    require Time::HiRes;
    $get_time = sub { Time::HiRes::gettimeofday() };
};

use Bio::KBase::AuthToken;

# Client version should match Impl version
# This is a Semantic Version number,
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME

kb_Metrics::kb_MetricsClient

=head1 DESCRIPTION


A KBase module: kb_Metrics
This KBase SDK module implements methods for generating various KBase metrics.


=cut

sub new
{
    my($class, $url, @args) = @_;
    

    my $self = {
	client => kb_Metrics::kb_MetricsClient::RpcClient->new,
	url => $url,
	headers => [],
    };

    chomp($self->{hostname} = `hostname`);
    $self->{hostname} ||= 'unknown-host';

    #
    # Set up for propagating KBRPC_TAG and KBRPC_METADATA environment variables through
    # to invoked services. If these values are not set, we create a new tag
    # and a metadata field with basic information about the invoking script.
    #
    if ($ENV{KBRPC_TAG})
    {
	$self->{kbrpc_tag} = $ENV{KBRPC_TAG};
    }
    else
    {
	my ($t, $us) = &$get_time();
	$us = sprintf("%06d", $us);
	my $ts = strftime("%Y-%m-%dT%H:%M:%S.${us}Z", gmtime $t);
	$self->{kbrpc_tag} = "C:$0:$self->{hostname}:$$:$ts";
    }
    push(@{$self->{headers}}, 'Kbrpc-Tag', $self->{kbrpc_tag});

    if ($ENV{KBRPC_METADATA})
    {
	$self->{kbrpc_metadata} = $ENV{KBRPC_METADATA};
	push(@{$self->{headers}}, 'Kbrpc-Metadata', $self->{kbrpc_metadata});
    }

    if ($ENV{KBRPC_ERROR_DEST})
    {
	$self->{kbrpc_error_dest} = $ENV{KBRPC_ERROR_DEST};
	push(@{$self->{headers}}, 'Kbrpc-Errordest', $self->{kbrpc_error_dest});
    }

    #
    # This module requires authentication.
    #
    # We create an auth token, passing through the arguments that we were (hopefully) given.

    {
	my %arg_hash2 = @args;
	if (exists $arg_hash2{"token"}) {
	    $self->{token} = $arg_hash2{"token"};
	} elsif (exists $arg_hash2{"user_id"}) {
	    my $token = Bio::KBase::AuthToken->new(@args);
	    if (!$token->error_message) {
	        $self->{token} = $token->token;
	    }
	}
	
	if (exists $self->{token})
	{
	    $self->{client}->{token} = $self->{token};
	}
    }

    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);
    bless $self, $class;
    #    $self->_validate_version();
    return $self;
}




=head2 get_app_metrics

  $return_records = $obj->get_app_metrics($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_Metrics.AppMetricsParams
$return_records is a kb_Metrics.AppMetricsResult
AppMetricsParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
AppMetricsResult is a reference to a hash where the following keys are defined:
	job_states has a value which is an UnspecifiedObject, which can hold any non-null object

</pre>

=end html

=begin text

$params is a kb_Metrics.AppMetricsParams
$return_records is a kb_Metrics.AppMetricsResult
AppMetricsParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
AppMetricsResult is a reference to a hash where the following keys are defined:
	job_states has a value which is an UnspecifiedObject, which can hold any non-null object


=end text

=item Description



=back

=cut

 sub get_app_metrics
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_app_metrics (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_app_metrics:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_app_metrics');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_Metrics.get_app_metrics",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_app_metrics',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_app_metrics",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_app_metrics',
				       );
    }
}
 


=head2 map_ws_narrative_names

  $return_records = $obj->map_ws_narrative_names($ws_ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$ws_ids is a reference to a list where each element is an int
$return_records is a reference to a list where each element is a kb_Metrics.MapWsNarrNamesResult
MapWsNarrNamesResult is a reference to a hash where the following keys are defined:
	ws_id has a value which is an int
	narr_name_map has a value which is a kb_Metrics.narrative_name_map
narrative_name_map is a reference to a list containing 3 items:
	0: (ws_name) a string
	1: (narrative_name) a string
	2: (narrative_version) an int

</pre>

=end html

=begin text

$ws_ids is a reference to a list where each element is an int
$return_records is a reference to a list where each element is a kb_Metrics.MapWsNarrNamesResult
MapWsNarrNamesResult is a reference to a hash where the following keys are defined:
	ws_id has a value which is an int
	narr_name_map has a value which is a kb_Metrics.narrative_name_map
narrative_name_map is a reference to a list containing 3 items:
	0: (ws_name) a string
	1: (narrative_name) a string
	2: (narrative_version) an int


=end text

=item Description



=back

=cut

 sub map_ws_narrative_names
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function map_ws_narrative_names (received $n, expecting 1)");
    }
    {
	my($ws_ids) = @args;

	my @_bad_arguments;
        (ref($ws_ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ws_ids\" (value was \"$ws_ids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to map_ws_narrative_names:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'map_ws_narrative_names');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_Metrics.map_ws_narrative_names",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'map_ws_narrative_names',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method map_ws_narrative_names",
					    status_line => $self->{client}->status_line,
					    method_name => 'map_ws_narrative_names',
				       );
    }
}
 


=head2 update_metrics

  $return_records = $obj->update_metrics($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object

</pre>

=end html

=begin text

$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object


=end text

=item Description

For writing to mongodb metrics *

=back

=cut

 sub update_metrics
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function update_metrics (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to update_metrics:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'update_metrics');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_Metrics.update_metrics",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'update_metrics',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method update_metrics",
					    status_line => $self->{client}->status_line,
					    method_name => 'update_metrics',
				       );
    }
}
 


=head2 get_user_details

  $return_records = $obj->get_user_details($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object

</pre>

=end html

=begin text

$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object


=end text

=item Description

For retrieving from mongodb metrics *

=back

=cut

 sub get_user_details
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_user_details (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_user_details:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_user_details');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_Metrics.get_user_details",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_user_details',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_user_details",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_user_details',
				       );
    }
}
 


=head2 get_nonkbuser_details

  $return_records = $obj->get_nonkbuser_details($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object

</pre>

=end html

=begin text

$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object


=end text

=item Description



=back

=cut

 sub get_nonkbuser_details
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_nonkbuser_details (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_nonkbuser_details:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_nonkbuser_details');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_Metrics.get_nonkbuser_details",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_nonkbuser_details',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_nonkbuser_details",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_nonkbuser_details',
				       );
    }
}
 


=head2 get_signup_returning_users

  $return_records = $obj->get_signup_returning_users($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object

</pre>

=end html

=begin text

$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object


=end text

=item Description



=back

=cut

 sub get_signup_returning_users
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_signup_returning_users (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_signup_returning_users:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_signup_returning_users');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_Metrics.get_signup_returning_users",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_signup_returning_users',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_signup_returning_users",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_signup_returning_users',
				       );
    }
}
 


=head2 get_signup_returning_nonkbusers

  $return_records = $obj->get_signup_returning_nonkbusers($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object

</pre>

=end html

=begin text

$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object


=end text

=item Description



=back

=cut

 sub get_signup_returning_nonkbusers
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_signup_returning_nonkbusers (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_signup_returning_nonkbusers:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_signup_returning_nonkbusers');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_Metrics.get_signup_returning_nonkbusers",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_signup_returning_nonkbusers',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_signup_returning_nonkbusers",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_signup_returning_nonkbusers',
				       );
    }
}
 


=head2 get_user_counts_per_day

  $return_records = $obj->get_user_counts_per_day($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object

</pre>

=end html

=begin text

$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object


=end text

=item Description



=back

=cut

 sub get_user_counts_per_day
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_user_counts_per_day (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_user_counts_per_day:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_user_counts_per_day');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_Metrics.get_user_counts_per_day",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_user_counts_per_day',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_user_counts_per_day",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_user_counts_per_day',
				       );
    }
}
 


=head2 get_total_logins

  $return_records = $obj->get_total_logins($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object

</pre>

=end html

=begin text

$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object


=end text

=item Description



=back

=cut

 sub get_total_logins
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_total_logins (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_total_logins:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_total_logins');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_Metrics.get_total_logins",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_total_logins',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_total_logins",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_total_logins',
				       );
    }
}
 


=head2 get_nonkb_total_logins

  $return_records = $obj->get_nonkb_total_logins($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object

</pre>

=end html

=begin text

$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object


=end text

=item Description



=back

=cut

 sub get_nonkb_total_logins
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_nonkb_total_logins (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_nonkb_total_logins:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_nonkb_total_logins');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_Metrics.get_nonkb_total_logins",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_nonkb_total_logins',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_nonkb_total_logins",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_nonkb_total_logins',
				       );
    }
}
 


=head2 get_user_logins

  $return_records = $obj->get_user_logins($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object

</pre>

=end html

=begin text

$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object


=end text

=item Description



=back

=cut

 sub get_user_logins
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_user_logins (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_user_logins:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_user_logins');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_Metrics.get_user_logins",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_user_logins',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_user_logins",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_user_logins',
				       );
    }
}
 


=head2 get_user_numObjs

  $return_records = $obj->get_user_numObjs($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object

</pre>

=end html

=begin text

$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object


=end text

=item Description



=back

=cut

 sub get_user_numObjs
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_user_numObjs (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_user_numObjs:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_user_numObjs');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_Metrics.get_user_numObjs",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_user_numObjs',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_user_numObjs",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_user_numObjs',
				       );
    }
}
 


=head2 get_narrative_stats

  $return_records = $obj->get_narrative_stats($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object

</pre>

=end html

=begin text

$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object


=end text

=item Description



=back

=cut

 sub get_narrative_stats
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_narrative_stats (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_narrative_stats:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_narrative_stats');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_Metrics.get_narrative_stats",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_narrative_stats',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_narrative_stats",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_narrative_stats',
				       );
    }
}
 


=head2 get_all_narrative_stats

  $return_records = $obj->get_all_narrative_stats($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object

</pre>

=end html

=begin text

$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object


=end text

=item Description



=back

=cut

 sub get_all_narrative_stats
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_all_narrative_stats (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_all_narrative_stats:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_all_narrative_stats');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_Metrics.get_all_narrative_stats",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_all_narrative_stats',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_all_narrative_stats",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_all_narrative_stats',
				       );
    }
}
 


=head2 get_user_ws_stats

  $return_records = $obj->get_user_ws_stats($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object

</pre>

=end html

=begin text

$params is a kb_Metrics.MetricsInputParams
$return_records is a kb_Metrics.MetricsOutput
MetricsInputParams is a reference to a hash where the following keys are defined:
	user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
	epoch_range has a value which is a kb_Metrics.epoch_range
user_id is a string
epoch_range is a reference to a list containing 2 items:
	0: (e_lowerbound) a kb_Metrics.epoch
	1: (e_upperbound) a kb_Metrics.epoch
epoch is an int
MetricsOutput is a reference to a hash where the following keys are defined:
	metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object


=end text

=item Description



=back

=cut

 sub get_user_ws_stats
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_user_ws_stats (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_user_ws_stats:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_user_ws_stats');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "kb_Metrics.get_user_ws_stats",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_user_ws_stats',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_user_ws_stats",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_user_ws_stats',
				       );
    }
}
 
  
sub status
{
    my($self, @args) = @_;
    if ((my $n = @args) != 0) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function status (received $n, expecting 0)");
    }
    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
        method => "kb_Metrics.status",
        params => \@args,
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => 'status',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
                          );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method status",
                        status_line => $self->{client}->status_line,
                        method_name => 'status',
                       );
    }
}
   

sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "kb_Metrics.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'get_user_ws_stats',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method get_user_ws_stats",
            status_line => $self->{client}->status_line,
            method_name => 'get_user_ws_stats',
        );
    }
}

sub _validate_version {
    my ($self) = @_;
    my $svr_version = $self->version();
    my $client_version = $VERSION;
    my ($cMajor, $cMinor) = split(/\./, $client_version);
    my ($sMajor, $sMinor) = split(/\./, $svr_version);
    if ($sMajor != $cMajor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Major version numbers differ.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor < $cMinor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Client minor version greater than Server minor version.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor > $cMinor) {
        warn "New client version available for kb_Metrics::kb_MetricsClient\n";
    }
    if ($sMajor == 0) {
        warn "kb_Metrics::kb_MetricsClient version is $svr_version. API subject to change.\n";
    }
}

=head1 TYPES



=head2 user_id

=over 4



=item Description

A string for the user id


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 timestamp

=over 4



=item Description

A time in the format YYYY-MM-DDThh:mm:ssZ, where Z is the difference
in time to UTC in the format +/-HHMM, eg:
        2012-12-17T23:24:06-0500 (EST time)
        2013-04-03T08:56:32+0000 (UTC time)


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 epoch

=over 4



=item Description

A Unix epoch (the time since 00:00:00 1/1/1970 UTC) in milliseconds.


=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 time_range

=over 4



=item Description

A time range defined by its lower and upper bound.


=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: (t_lowerbound) a kb_Metrics.timestamp
1: (t_upperbound) a kb_Metrics.timestamp

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: (t_lowerbound) a kb_Metrics.timestamp
1: (t_upperbound) a kb_Metrics.timestamp


=end text

=back



=head2 epoch_range

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 2 items:
0: (e_lowerbound) a kb_Metrics.epoch
1: (e_upperbound) a kb_Metrics.epoch

</pre>

=end html

=begin text

a reference to a list containing 2 items:
0: (e_lowerbound) a kb_Metrics.epoch
1: (e_upperbound) a kb_Metrics.epoch


=end text

=back



=head2 narrative_name_map

=over 4



=item Definition

=begin html

<pre>
a reference to a list containing 3 items:
0: (ws_name) a string
1: (narrative_name) a string
2: (narrative_version) an int

</pre>

=end html

=begin text

a reference to a list containing 3 items:
0: (ws_name) a string
1: (narrative_name) a string
2: (narrative_version) an int


=end text

=back



=head2 AppMetricsParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
epoch_range has a value which is a kb_Metrics.epoch_range

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
epoch_range has a value which is a kb_Metrics.epoch_range


=end text

=back



=head2 AppMetricsResult

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
job_states has a value which is an UnspecifiedObject, which can hold any non-null object

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
job_states has a value which is an UnspecifiedObject, which can hold any non-null object


=end text

=back



=head2 MapWsNarrNamesResult

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ws_id has a value which is an int
narr_name_map has a value which is a kb_Metrics.narrative_name_map

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ws_id has a value which is an int
narr_name_map has a value which is a kb_Metrics.narrative_name_map


=end text

=back



=head2 MetricsInputParams

=over 4



=item Description

unified input/output parameters


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
epoch_range has a value which is a kb_Metrics.epoch_range

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
user_ids has a value which is a reference to a list where each element is a kb_Metrics.user_id
epoch_range has a value which is a kb_Metrics.epoch_range


=end text

=back



=head2 MetricsOutput

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
metrics_result has a value which is an UnspecifiedObject, which can hold any non-null object


=end text

=back



=cut

package kb_Metrics::kb_MetricsClient::RpcClient;
use base 'JSON::RPC::Client';
use POSIX;
use strict;

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ($self, $uri, $headers, $obj) = @_;
    my $result;


    {
	if ($uri =~ /\?/) {
	    $result = $self->_get($uri);
	}
	else {
	    Carp::croak "not hashref." unless (ref $obj eq 'HASH');
	    $result = $self->_post($uri, $headers, $obj);
	}

    }

    my $service = $obj->{method} =~ /^system\./ if ( $obj );

    $self->status_line($result->status_line);

    if ($result->is_success) {

        return unless($result->content); # notification?

        if ($service) {
            return JSON::RPC::ServiceObject->new($result, $self->json);
        }

        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    elsif ($result->content_type eq 'application/json')
    {
        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    else {
        return;
    }
}


sub _post {
    my ($self, $uri, $headers, $obj) = @_;
    my $json = $self->json;

    $obj->{version} ||= $self->{version} || '1.1';

    if ($obj->{version} eq '1.0') {
        delete $obj->{version};
        if (exists $obj->{id}) {
            $self->id($obj->{id}) if ($obj->{id}); # if undef, it is notification.
        }
        else {
            $obj->{id} = $self->id || ($self->id('JSON::RPC::Client'));
        }
    }
    else {
        # $obj->{id} = $self->id if (defined $self->id);
	# Assign a random number to the id if one hasn't been set
	$obj->{id} = (defined $self->id) ? $self->id : substr(rand(),2);
    }

    my $content = $json->encode($obj);

    $self->ua->post(
        $uri,
        Content_Type   => $self->{content_type},
        Content        => $content,
        Accept         => 'application/json',
	@$headers,
	($self->{token} ? (Authorization => $self->{token}) : ()),
    );
}



1;
