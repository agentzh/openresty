package OpenAPI::Cache;

use strict;
use warnings;
use FindBin;

# This is a hack...

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    my $params = shift;
    my $type = $OpenAPI::Config{'cache.type'} or
        die "No cache.type specified in the config files.\n";
    my $obj;
    my $self = bless {}, $class;
    if ($type eq 'filecache') {
        require Cache::FileCache;
        $obj = Cache::FileCache->new(
            { namespace => 'OpenAPI', default_expires_in => 60 * 60 * 24 }
        );
    } elsif ($type eq 'memcached') {
        my $list = $OpenAPI::Config{'cache.servers'} or
            die "No cache.servers specified in the config files.\n";
        require Cache::Memcached::Fast;
        my @addr = split /\s*,\s*|\s+/, $list;
        if (!@addr) {
            die "No memcached server found: $list.\n";
        }
        $obj = Cache::Memcached::Fast->new({
            servers => [@addr],
        });
        #$obj->set(dog => 32);
        #die "Dog value: ", $obj->get('dog');
        #die $obj;
    } else {
        die "Invalid cache.type value: $type\n";
    }
    $self->{obj} = $obj;
    return $self;
}

# expire_in is in seconds...
sub set {
    my ($self, $key, $val, $expire_in) = @_;
    $self->{obj}->set($key, $val, $expire_in);
}

sub get {
    $_[0]->{obj}->get($_[1]);
}

sub remove {
    my $self = shift;
    my $obj = $self->{obj};
    if ($obj->can('remove')) {
        $obj->remove(@_);
    } else {
        $obj->delete(@_);
    }
}

1;

