use Cro::ZeroMQ::Internal;
use Net::ZMQ4::Constants;

class Cro::ZeroMQ::Socket::XPub does Cro::ZeroMQ::Source::Impure does Cro::ZeroMQ::Replyable {
    method !type() { ZMQ_XPUB }

    method !source-supply() {
        supply {
            my $closer = False;
            my $messages = Supplier.new;
            start {
                loop {
                    last if $closer;
                    with self!socket.receivemore {
                        if .parts[0][0] == 0 {
                            $messages.emit: Cro::ZeroMQ::Message.new(|@(.parts))
                        }
                    }
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
