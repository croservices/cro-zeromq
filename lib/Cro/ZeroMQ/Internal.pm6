use Cro::ZeroMQ::Component;
use Cro::ZeroMQ::Message;
use Cro;
use Net::ZMQ4::Constants;
use Net::ZMQ4;

role Cro::ZeroMQ::Replyable does Cro::Replyable {
    my class ReplyHandler does Cro::Sink {
        has $!socket;
        has $!ctx;

        submethod BUILD(:$!socket!, :$!ctx!) {}

        method consumes() { Cro::ZeroMQ::Message }
        method sinker(Supply:D $messages --> Supply:D) {
            supply {
                whenever $messages -> Cro::ZeroMQ::Message $_ {
                    $!socket.sendmore(|@(.parts));
                }
                CLOSE {
                    $!socket.close;
                    $!ctx.term;
                }
            }
        }
    }

    method replier(--> Cro::Replier) {
        self!initial;
        ReplyHandler.new(|self!data);
    }
}

role Cro::ZeroMQ::Component::Internal does Cro::ZeroMQ::Component {
    has $!socket;
    has $!ctx;

    method !socket() { $!socket }
    method !ctx()    { $!ctx }

    method !type() { ... }
    method !initial() {
        return if $!socket;
        $!ctx = Net::ZMQ4::Context.new();
        $!socket = Net::ZMQ4::Socket.new($!ctx, self!type);
        $!socket.setopt(ZMQ_SNDHWM, self.high-water-mark) if self.high-water-mark;
        $!socket.connect(self.connect) if self.connect;
        $!socket.bind(self.bind) if self.bind;
    }
}

role Cro::ZeroMQ::Sink does Cro::Sink does Cro::ZeroMQ::Component::Internal {
    method consumes() { Cro::ZeroMQ::Message }
    method sinker(Supply:D $incoming) {
        self!initial;
        supply {
            whenever $incoming -> Cro::ZeroMQ::Message $_ {
                self!socket.sendmore(|@(.parts));
            }
            CLOSE {
                self!socket.close;
                self!ctx.term;
            }
        }
    }
}

role Cro::ZeroMQ::Source does Cro::Source does Cro::ZeroMQ::Component::Internal {
    method produces() { Cro::ZeroMQ::Message }
    method !data() { {socket => self!socket, ctx => self!ctx} }
    method incoming() {
        self!initial;
        self!source-supply;
    }

    method !source-supply() {
        supply {
            my $closer = False;
            my $messages = Supplier.new;
            start {
                loop {
                    last if $closer;
                    $messages.emit: Cro::ZeroMQ::Message.new(parts => self!socket.receivemore);
                }
            }
            whenever $messages { emit $_ }
            CLOSE {
                $closer = True;
                self!socket.close;
                self!ctx.term;
            }
        }
    }
}

role Cro::ZeroMQ::Connector does Cro::Connector does Cro::ZeroMQ::Component {
    method consumes() { Cro::ZeroMQ::Message }
    method produces() { Cro::ZeroMQ::Message }

    method connect(:$connect, :$bind, :$high-water-mark --> Promise) {
        my $ctx = Net::ZMQ4::Context.new();
        my $socket = Net::ZMQ4::Socket.new($ctx, self!type);
        $socket.setopt(ZMQ_SNDHWM, $high-water-mark) if $high-water-mark;
        $socket.connect($connect) if $connect;
        $socket.bind($bind) if $bind;
        self!promise($ctx, $socket);
    }
}
