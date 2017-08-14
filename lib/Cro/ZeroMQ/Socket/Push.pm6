use Cro::ZeroMQ::Internal;
use Net::ZMQ4::Constants;

class Cro::ZeroMQ::Socket::Push does Cro::ZeroMQ::Sink {
    method !type() { ZMQ_PUSH }
    method !connection($socket) {
        $socket.setopt(ZMQ_SNDHWM, $!high-water-mark) if $!high-water-mark;
        $socket.connect($!connect) if $!connect;
        $socket.bind($!bind) if $!bind;
    }
}
