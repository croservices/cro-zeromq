use Cro::ZeroMQ::Internal;
use Net::ZMQ4::Constants;

class Cro::ZeroMQ::Socket::Pull does Cro::ZeroMQ::Source {
    method !type() { ZMQ_PULL }

    method incoming() {
        my ($socket, $ctx) = self!initial;
        $socket.setopt(ZMQ_SNDHWM, $!high-water-mark) if $!high-water-mark;
        $socket.connect($!connect) if $!connect;
        $socket.bind($!bind) if $!bind;
        self!source-supply($socket, $ctx);
    }
}
