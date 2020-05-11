use 5.30.0;
use strict;
use warnings;

use HTTP::Status qw(:constants);
use Try::Tiny qw(try catch);
use Throw qw(throw classify);
use Test::More 'no_plan';

BEGIN {
    use_ok('Net::EtcDv2');
}

SKIP: {
    skip "missing env vars(ETCD_HOST, ETCD_PORT)", 3,
        unless (exists $ENV{'ETCD_HOST'} && exists $ENV{'ETCD_PORT'});

    # a little prettier debug output
    say STDERR "" if $ENV{DEBUG};
    my $o = Net::EtcDv2->new(
        'host' => $ENV{'ETCD_HOST'},
        'port' => $ENV{'ETCD_PORT'}
    );
    try {
        my $r = $o->stat('/myTestDir');
        my $rc = $r->code();
        if ($r->code ne HTTP_OK) {
            throw "HTTP error", {
                'type' => $r,

            };
        }
    } catch {}

    ok(defined $r);
}
