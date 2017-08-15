use Cro::Replyable;
use Cro::ZeroMQ::Internal;
use Net::ZMQ4::Constants;

class Cro::ZeroMQ::Socket::Rep does Cro::ZeroMQ::Source does Cro::Replyable {
    has $!socket;
    has $!ctx;

    method !type() { ZMQ_REP }

    method !init() {
        ($!socket, $!ctx) = self!initial;
        $!socket.setopt(ZMQ_SNDHWM, $!high-water-mark) if $!high-water-mark;
        $!socket.connect($!connect) if $!connect;
        $!socket.bind($!bind) if $!bind;
    }

    method incoming() {
        self!init unless $!socket;
        self!source-supply($!socket, $!ctx);
    }

    method replier(--> Cro::Replier) {
        self!init unless $!socket;
        ReplyHandler.new(socket => $!socket, ctx => $!ctx);
    }
}
