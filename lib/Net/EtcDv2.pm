package Net::EtcDv2 v0.0.1 {
    use v5.30;
    use strict;
    use warnings;
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
    use HTTP::Status qw(:constants);
    use JSON;
    use LWP::UserAgent;
    use Throw qw(throw classify);
    use Try::Tiny qw(try catch);

    my $debug    = false;
    my $host     = undef;
    my $port     = undef;
    my $user     = undef;
    my $password = undef;

    sub new ($class, %args) {
        if (exists $ENV{'DEBUG'}) {
            $debug = true;
        }
        my $sub = (caller(0))[3];
        if ($debug eq true) {
            say STDERR "DEBUG: Sub: $sub";
            say STDERR "DEBUG: Constructing object";
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
        say STDERR "DEBUG: Sub: $sub" if $debug;

        my $stat_struct = undef;
        my $response    = undef;
        try {
            my $ua = LWP::UserAgent->new();
            unless (defined $user && defined $password) {
                $response = $ua->get("$host:$port/v2/keys${path}");
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
            classify $_, {
                404 => sub {
                    exit ENXIO;
                },
                default => sub {
                    exit EPERM;
                }
            };
        };

        say STDERR "DEBUG: Stat struct: " . Dumper($stat_struct) if $debug;
        return $stat_struct;
    }

    our sub mkdir ($self, $path) {
        my $sub = (caller(0))[3];
        say STDERR "DEBUG: Sub: $sub" if $debug;

        my $stat_struct = undef;
        my $response    = undef;
        # we cannot create a directory if it already exists
        try {
            my $response = $self->stat('/myTestDir');
            my $rc = $response->code();
            # unconditionally throw
            throw "HTTP error", { 'type' => $rc };
        } catch {
            classify $_, {
                200 => sub {
                    exit EEXIST;
                },
                404 => sub {
                    # now we can actually create the directory
                    my $ua = LWP::UserAgent->new();
                    unless {

                    } else {

                    }
                },
                default = sub {

                }
            };
        };

        return $path;
    }

    true; # End of Net::EtcDv2
}

=head1 NAME

Net::EtcDv2 - A object oriented Perl module to interact with the EtcD version 2 API

=head1 VERSION

Version 0.0.1

=head1 SYNOPSIS

    use feature say;
    use Data::Dumper;
    use Net::EtcDv2;

    # create an un-authenticated object for an etcd running on localhost on
    # port 2379
    my $foo = Net::EtcDv2->new(
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

The Net::EtcDv2 module allows code to create, read, update, and delete
key/value data in an etcd cluster. Additionally, using the v2 API, this
module can create, list, and delete directories in the key store to
organize the data.

Additionally, this module can manage users and roles, which govern the
access rights to the key/value heirarchy.

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

=head2 mkdir

This method creates a directory if the named object does not already exist
at that level of the heirarchy. If it already exists, no matter if it is a
key or directory, it emits an exception.

B<Parameters:>

  - self, SCALAR REF: the object reference
  - path, SCALAR:     the full path to create

B<Return type:>

  - path, SCALAR:     the full path that was created

B<Exceptions:>

If the named entry, irregardless of the type, exists, the method will emit
error EEXIST

=head1 AUTHOR

Gary L. Greene, Jr., C<< <greeneg at tolharadys.net> >>

=head1 BUGS

Please report any bugs or feature requests via this module's GitHub Issues tracker, here: 
L<https://github.com/greeneg/Net-EtcDv2>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::EtcDv2

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-EtcDv2>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Net-EtcDv2>

=item * Search CPAN

L<https://metacpan.org/release/Net-EtcDv2>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Gary L. Greene, Jr.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
