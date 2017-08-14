use Cro;
use Cro::ZeroMQ::Message;
use Cro::ZeroMQ::Component;
use Net::ZMQ4;
use Net::ZMQ4::Constants;

class Cro::ZeroMQ::Socket::Pub does Cro::Sink does Cro::ZeroMQ::Component {
    method consumes() { Cro::ZeroMQ::Message }

    method sinker(Supply:D $incoming) {
        my Net::ZMQ4::Context $ctx .= new();
        my Net::ZMQ4::Socket  $pub .= new($ctx, ZMQ_PUB);
        $pub.setopt(ZMQ_SNDHWM, $!high-water-mark) if $!high-water-mark;
        $pub.bind($!bind) if $!bind;
        $pub.connect($!connect) if $!connect;
        supply {
            whenever $incoming -> Cro::ZeroMQ::Message $_ {
                $pub.sendmore(|(.parts));
            }
            CLOSE {
                $pub.close;
                $ctx.term;
            }
        }
    }
}
