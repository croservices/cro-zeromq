use Cro::ZeroMQ::Socket::Req;
use Cro::ZeroMQ::Service;
use Test;

my Cro::Service $rep = Cro::ZeroMQ::Service.rep(
    bind => 'tcp://127.0.0.1:5555'
);

$rep.start;

my $req = Cro.compose(Cro::ZeroMQ::Socket::Req);
my $input = Supplier::Preserving.new;
my $responses = $req.establish($input.Supply, connect => "tcp://127.0.0.1:5555");
my $completion = Promise.new;
$responses.tap: -> $_ {
    $completion.keep if $_.body-text eq 'test';
}
$input.emit(Cro::ZeroMQ::Message.new('test'));

await Promise.anyof($completion, Promise.in(2));

if $completion.status == Kept {
    pass "REP service works";
} else {
    flunk "REP service works";
}

done-testing;
