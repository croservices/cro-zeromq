use Cro::Connector;
use Cro::Transform;
use Cro::ZeroMQ::Message;
use Net::ZMQ4::Constants;
use Net::ZMQ4::Util;
use Net::ZMQ4;

class Cro::ZeroMQ::Socket::Dealer does Cro::Connector {
    class Transform does Cro::Transform {
        has $.socket;
        has $.ctx;

        method consumes() { Cro::ZeroMQ::Message }
        method produces() { Cro::ZeroMQ::Message }

        method transformer(Supply $incoming --> Supply) {
            my $closer = False;
            supply {
                whenever $incoming {
                    $!socket.sendmore(|@(.parts));
                }
                my $messages = Channel.new;
                start {
                    loop {
                        last if $closer;
                        my @res = $!socket.receivemore;
                        $messages.send(Cro::ZeroMQ::Message.new(parts => @res));
                        CATCH {
                            when X::ZMQ {
                                $closer = True;
                                next;
                            }
                        }
                    }
                }
                whenever $messages { .emit }
                CLOSE {
                    $closer = True;
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
        my $socket = Net::ZMQ4::Socket.new($ctx, ZMQ_DEALER);
        $socket.connect($connect) if $connect;
        $socket.bind($bind) if $bind;
        Promise.start({ Transform.new(:$ctx, :$socket)} );
    }
}
