use Cro::Connector;
use Cro::Transform;
use Cro::ZeroMQ::Message;
use Cro::ZeroMQ::Component;
use Net::ZMQ4;
use Net::ZMQ4::Constants;

class Cro::ZeroMQ::Socket::Req does Cro::Connector does Cro::ZeroMQ::Component {
    class Transform does Cro::Transform {
        has $.socket;
        has $.ctx;

        method consumes() { Cro::ZeroMQ::Message }
        method produces() { Cro::ZeroMQ::Message }

        method transformer(Supply $incoming --> Supply) {
            supply {
                $incoming.tap: -> $_ {
                    $!socket.sendmore(|@(.parts));
                    my @res = $!socket.receivemore;
                    emit Cro::ZeroMQ::Message.new(|@res);
                }, done => {
                    $!socket.close;
                    $!ctx.term;
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
        my $socket = Net::ZMQ4::Socket.new($ctx, ZMQ_REQ);
        $socket.connect($connect) if $connect;
        $socket.bind($bind) if $bind;
        Promise.start({ Transform.new(:$ctx, :$socket)} );
    }
}
