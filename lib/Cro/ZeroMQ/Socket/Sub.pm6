use Cro::Source;
use Cro::ZeroMQ::Component;
use Cro::ZeroMQ::Message;
use Net::ZMQ4;
use Net::ZMQ4::Constants;

class Cro::ZeroMQ::Sub does Cro::Source does Cro::ZeroMQ::Component {
    has $.subscribe;
    has $.unsubscribe;

    method produces() { Cro::ZeroMQ::Message }

    method new(:$connect = Nil, :$bind = Nil,
               :$high-water-mark,
               :$subscribe = Nil, :$unsubscribe) {
        die "You need to specify subscribe parameter for a SUB socket" if $subscribe ~~ Nil;
        die Cro::ZeroMQ::IllegalBind.new(:reason<you need to specify connect or bind>) unless so $connect^$bind;
        self.bless(:$connect, :$bind, :$high-water-mark, :$subscribe, :$unsubscribe);
    }

    method incoming(--> Supply:D) {
        my Net::ZMQ4::Context $ctx .= new();
        my Net::ZMQ4::Socket  $sub .= new($ctx, ZMQ_SUB);
        $sub.setopt(ZMQ_SNDHWM, $!high-water-mark) if $!high-water-mark;
        $sub.connect($!connect) if $!connect;
        $sub.bind($!bind) if $!bind;

        given $!subscribe {
            when Blob { $sub.setopt(ZMQ_SUBSCRIBE, $_) }
            when Str  { $sub.setopt(ZMQ_SUBSCRIBE, Blob.new: $_.encode) }
            when Iterable {
                for @$_ {
                    $_ ~~ Blob ??
                    $sub.setopt(ZMQ_SUBSCRIBE, $_) !!
                        $_ ~~ Str ??
                        $sub.setopt(ZMQ_SUBSCRIBE, Blob.new: $_.encode) !!
                        die "Envelope part must be a Str or a Blob, {$_.WHAT} passed";
                }
            }
            when Whatever { $sub.setopt(ZMQ_SUBSCRIBE, Blob.new) }
            when Supply {
                $_.tap: -> $_ {
                    die "Envelope part must be a Str or a Blob, {$_.WHAT} passed" if $_ !~~ Blob|Str;
                    $sub.setopt(
                        ZMQ_SUBSCRIBE,
                        $_ ~~ Blob ?? $_ !! Blob.new: $_.encode
                    )
                }
            }
        }

        if $!unsubscribe {
            $!unsubscribe.tap: -> $_ {
                my $topic = $_ ~~ Blob ?? $_ !! $_.encode;
                $sub.setopt(ZMQ_UNSUBSCRIBE, $topic);
            }
        }

        supply {
            my $closer = False;
            my $messages = Supplier.new;
            start {
                loop {
                    last if $closer;
                    $messages.emit: Cro::ZeroMQ::Message.new(parts => $sub.receivemore[1..*]);
                }
            }
            whenever $messages { emit $_ }
            CLOSE {
                $closer = True;
                $sub.close;
                $ctx.term;
            }
        }
    }
}
