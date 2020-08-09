package Net::EtcDv2::EntryStat {
    use v5.30;
    use strictures;
    use utf8;
    use English;

    use feature ":5.30";
    use feature 'lexical_subs';
    use feature 'signatures';
    use feature 'switch';
    no warnings "experimental::signatures";
    no warnings "experimental::smartmatch";

    use boolean;
    use Data::Dumper;
    use Errno qw(:POSIX);
    use HTTP::Request;
    use HTTP::Status qw(:constants);
    use JSON;
    use LWP::UserAgent;
    use Throw qw(throw classify);
    use Try::Tiny qw(try catch);

    my $debug = false;
    my $host = undef;
    my $port = undef;
    my $user = undef;
    my $password = undef;

    sub new ($class, %args) {
        if (exists $args{'debug'} && $args{'debug'} eq true) {
            $debug = true;
        }

        my $sub = (caller(0))[3];
        if ($debug eq true) {
            say "DEBUG: Sub: $sub";
            say "DEBUG: Constructing object";
        }

        $host     = $args{'host'};
        $port     = $args{'port'};

        if (exists $args{'user'}) {
            $user     = $args{'user'};
        }
        if (exists $args{'password'}) {
            $password = $args{'password'};
        }

        my $self = {};
        bless $self, $class;
    }

    our sub stat ($self, $path) {
        my $sub = (caller(0))[3];
        say "DEBUG: debug == $debug" if $debug;
        say "DEBUG: Sub: $sub" if $debug;

        my $stat_struct = undef;
        my $response    = undef;
        try {
            my $ua = LWP::UserAgent->new();
            unless (defined $user && defined $password) {
                $response = $ua->get("$host:$port/v2/keys${path}");
                say "DEBUG: " . Dumper $response;
                my $rc = $response->code();
                if ($rc ne HTTP_OK) {
                    throw(
                        "HTTP I/O error", {
                            'type' => $rc,
                            'uri'  => $response->base,
                            'info' => "Attempt to stat entry from etcd cluster"
                        }
                    );
                } else {
                    my $content = decode_json($response->content);
                    my $uri = $response->base->as_string;
                    my $cluster_id = $response->header('x-etcd-cluster-id');
                    my $ace_allow_origin = $response->header('access-control-allow-origin');
                    my $ace_allow_methods = $response->header('access-control-allow-methods');
                    my $heirarchy_index = $response->header('x-etcd-index');
                    my $type = 'key';
                    if (exists $content->{'node'}->{'dir'} && $content->{'node'}->{'dir'} eq true) {
                        $type = 'dir';
                    }
                    $stat_struct = {
                        'uri'  => $uri,
                        'type' => $type,
                        'entryId' => "$cluster_id:$heirarchy_index",
                        'ace'     => "$ace_allow_origin:$ace_allow_methods"
                    };
                }
            } else {
                $response = $ua->credentials("$host:$port", 'Basic', $user, $password);
                $response = $ua->get("$host:$port");
            }
        } catch {
            say "DEBUG: catch args: $_" if $debug;
            classify $_, {
                404 => sub {
                    # rethrow
                    throw("$_->{'error'}",
                        {
                            'type' => $_->{'type'},
                            'info' => $_->{'info'}
                        }
                    );
                },
                default => sub {
                    # Dunno what this is, so be fatal
                    exit EPERM;
                }
            };
        };

        say "DEBUG: Stat struct: " . Dumper($stat_struct);
        return $stat_struct;
    }

    true;
}

=head1 NAME

Net::EtcDv2::EntryStat - A object oriented Perl module to stat entries in an EtcD v2 API key/value store

=head1 VERSION

Version 0.0.1

=head1 SYNOPSIS

    use feature say;
    use Data::Dumper;
    use Net::EtcDv2::EntryStat;

    # create an un-authenticated object for an etcd running on localhost on
    # port 2379
    my $foo = Net::EtcDv2::EntryStat->new(
        'host' => "http://localhost",
        'port' => 2379
    );
    
    my $stat_struct = $foo->stat('/myDir');
    say Dumper $stat_struct;

    # outputs the following if '/myDir' exists and is a directory
    # $VAR1 = {
    #   'type' => 'dir',
    #   'uri' => 'http://localhost:2379/myDir',
    #   'ace' => '*:POST, GET, OPTIONS, PUT, DELETE',
    #   'entryId' => 'cdf818194f3b8d32:23'
    # };
    #
    # The ACE is the access allowed methods and and origin for that path, and
    # the 'entryId' is made up from the cluster ID and the etcd item index ID

=head1 DESCRIPTION

The Net::EtcDv2::EntryStat module is an internal module to the Net::EtcDv2
distribution. It allows code to stat key/value entries in an etcd cluster.

=head1 METHODS

=head2 new

The constructor for the class. For now, we only support HTTP basic 
authentication.

If the DEBUG environment variable is set, the class will emit debugging
output on STDERR.

B<Parameters:>

  - class, SCALAR: The class name
  - args,  HASH:   A hash of named parameters:
    - host:        the hostname of the etcd endpoint
    - port:        the port number of the etcd endpoint
    - user:        the username authorized for the etcd environment
    - password:    the password for the user authorized for the etcd
                   environment

=head2 stat

This method takes a path and gathers information about the etcd object. If the
item doesn't exist, it throws an exception (error code 6).

B<Parameters:>

  - self, SCALAR REF: the object reference
  - path, SCALAR:     the path segment of the URI to get info for

B<Return type:>

  - stat_struct: HASH: the stat information for the path

B<Exceptions:>

If the object is not found (HTTP 404), the method will emit error ENXIO

