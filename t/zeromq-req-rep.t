use Cro;
use Cro::ZeroMQ::Socket::Rep;
use Cro::ZeroMQ::Socket::Req;
use Test;

my $rep = Cro::ZeroMQ::Socket::Rep.new(bind => "tcp://127.0.0.1:5555");

my $s = Supplier::Preserving.new;

$rep.incoming.tap: -> $_ {
    $s.emit: $_
}

$rep.replier.sinker($s.Supply).tap;

my $req = Cro.compose(Cro::ZeroMQ::Socket::Req);

my $s1 = Supplier::Preserving.new;
my $responses = $req.establish($s1.Supply, connect => "tcp://127.0.0.1:5555");

my %f = :!first, :!second, :!third;
my $completion = Promise.new;

$responses.tap: -> $_ {
    %f{$_.body-text} = True;
    $completion.keep if %f<first> && %f<second> && %f<third>;
}

$s1.emit(Cro::ZeroMQ::Message.new('first'));
$s1.emit(Cro::ZeroMQ::Message.new('second'));
$s1.emit(Cro::ZeroMQ::Message.new('third'));

await Promise.anyof($completion, Promise.in(2));

if $completion.status == Kept {
    pass "REQ/REP pair is working";
} else {
    flunk "REQ/REP pair is working";
}

done-testing;
