use Cro::Connector;
use Cro::Transform;
use Net::ZMQ4::Constants;

class Cro::ZeroMQ::Socket::Dealer does Cro::Connector {
    class Transform does Cro::Transform {
        has $.socket;
        has $.ctx;

        method consumes() { Cro::ZeroMQ::Message }
        method produces() { Cro::ZeroMQ::Message }

        method transformer(Supply $incoming --> Supply) {
            supply {
                $incoming.tap: -> $_ {
                    # XXX Figure out second value
                    $!socket.sendmore('', '');
                    emit $!socket.receivemore[1..*];
                }
                CLOSE {
                    $!socket.close;
                    $!ctx.term;
                }
            }
        }

    }

    method consumes() { Cro::ZeroMQ::Message }
    method produces() { Cro::ZeroMQ::Message }

    method connect(:$connect, :$bind, :$high-water-mark --> Promise) {
        my $ctx = Net::ZMQ4::Context.new();
        my $socket = Net::ZMQ4::socket.new($ctx, ZMQ_DEALER);
        $socket.connect($connect) if $connect;
        $socket.bind($bind) if $bind;
        Promise.start({ Transform.new(:$ctx, :$socket)} );
    }
}
