use Cro::Replyable;
use Cro::ZeroMQ::Internal;
use Net::ZMQ4::Constants;

class Cro::ZeroMQ::Socket::Rep does Cro::ZeroMQ::Source does Cro::Replyable {
    has $!socket;

    method !type() { ZMQ_REP }

    method incoming() {
        ($!socket, my $ctx) = self!initial;
        $!socket.setopt(ZMQ_SNDHWM, $!high-water-mark) if $!high-water-mark;
        $!socket.connect($!connect) if $!connect;
        $!socket.bind($!bind) if $!bind;
        self!source-supply($!socket, $ctx);
    }

    method replier(--> Cro::Replier) {
        ReplyHandler.new(socket => $!socket);
    }
}
