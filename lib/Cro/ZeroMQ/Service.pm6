use Cro::ZeroMQ::Socket::Rep;
use Cro::Service;

class Cro::ZeroMQ::Service does Cro::Service {
    method rep(:$bind, :$connect, *@components) {
        my %args = $bind ?? :$bind !! Nil;
        %args<connect> = $connect ?? :$connect !! Nil;
        Cro.compose(
            service-type => self.WHAT,
            Cro::ZeroMQ::Socket::Rep.new(|%args),
            |@components
        )
    }
}
