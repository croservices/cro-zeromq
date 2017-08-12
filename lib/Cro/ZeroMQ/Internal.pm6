use Cro::ZeroMQ::Component;
use Cro::ZeroMQ::Message;
use Cro;
use Net::ZMQ4::Constants;
use Net::ZMQ4;

role Cro::ZeroMQ::Sink does Cro::Sink does Cro::ZeroMQ::Component {
    method consumes() { Cro::ZeroMQ::Message }
    method !type() { ... }
    method !connection($socket) { ... }

    method sinker(Supply:D $incoming) {
        my Net::ZMQ4::Context $ctx    .= new();
        my Net::ZMQ4::Socket  $socket .= new($ctx, self!type);
        self!connection($socket);
        supply {
            whenever $incoming -> Cro::ZeroMQ::Message $_ {
                $socket.sendmore(|@(.parts));
            }
            CLOSE {
                $socket.close;
                $ctx.term;
            }
        }
    }
}

role Cro::ZeroMQ::Source does Cro::Source does Cro::ZeroMQ::Component {
    method produces() { Cro::ZeroMQ::Message }
    method !type() { ... }
    method !initial() {
        my Net::ZMQ4::Context $ctx .= new();
        my Net::ZMQ4::Socket  $socket .= new($ctx, self!type);
        ($socket, $ctx);
    }

    method !source-supply($socket, $ctx) {
        supply {
            my $closer = False;
            my $messages = Supplier.new;
            start {
                loop {
                    last if $closer;
                    $messages.emit: Cro::ZeroMQ::Message.new(parts => $socket.receivemore);
                }
            }
            whenever $messages { emit $_ }
            CLOSE {
                $closer = True;
                $socket.close;
                $ctx.term;
            }
        }
    }

}
