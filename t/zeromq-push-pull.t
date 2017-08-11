use Cro::ZeroMQ::Message;
use Cro::ZeroMQ::Pull;
use Cro::ZeroMQ::Push;
use Test;

my $pusher = Cro::ZeroMQ::Push.new(connect => 'tcp://127.0.0.1:2910', high-water-mark => 1000);
my $receiver = Cro::ZeroMQ::Pull.new(bind => 'tcp://127.0.0.1:2910');

my %h = :!first, :!second, :!third;
my $complete = Promise.new;

my $tap = $receiver.incoming.tap: -> $_ {
    %h{$_.body-text} = True;
    {$complete.keep; $tap.close} if so %h<first>&%h<second>&%h<third>;
}

$pusher.sinker(
    supply {
        emit Cro::ZeroMQ::Message.new: "first";
        emit Cro::ZeroMQ::Message.new: "second";
        emit Cro::ZeroMQ::Message.new: "third"
    }
).tap;

await Promise.anyof($complete, Promise.in(1));

if $complete.status == Kept {
    pass "PUSH/PULL socket pair is working"
} else {
    flunk "PUSH/PULL socket pair is working"
}

done-testing;
