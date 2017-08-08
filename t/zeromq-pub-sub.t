use Cro::ZeroMQ::Message;
use Cro::ZeroMQ::Pub;
use Cro::ZeroMQ::Sub;
use Test;

my $pub = Cro::ZeroMQ::Pub.new(connect => 'tcp://127.0.0.1:2910');
my $sub = Cro::ZeroMQ::Sub.new(bind => 'tcp://127.0.0.1:2910', subscribe => Blob.new('A'.encode));

my %h = :!first, :!second, :!third, :!fourth;
my $complete = Promise.new;

$sub.incoming.tap: -> $_ {
    %h{$_.body-text} = True;
    $complete.keep if so %h<first>&%h<second>&%h<third>&!%h<fourth>;
}

$pub.sinker(
    supply {
        emit Cro::ZeroMQ::Message.new: parts => ('A'.encode, 'first'.encode);
        emit Cro::ZeroMQ::Message.new: parts => ('A'.encode, 'second'.encode);
        emit Cro::ZeroMQ::Message.new: parts => ('B'.encode, 'fourth'.encode);
        emit Cro::ZeroMQ::Message.new: parts => ('A'.encode, 'third'.encode);
    }
).tap;

await Promise.anyof($complete, Promise.in(1));

if $complete.status == Kept {
    pass "PUB/SUB socket pair is working"
} else {
    flunk "PUB/SUB socket pair is working"
}

done-testing;
