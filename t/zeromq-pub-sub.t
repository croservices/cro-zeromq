use Cro::ZeroMQ::Message;
use Cro::ZeroMQ::Pub;
use Cro::ZeroMQ::Sub;
use Test;

sub test($desc, @messages, $subscribe,
         %init, %finish,
         :$unsubscribe) {
    my $pub = Cro::ZeroMQ::Pub.new(connect => 'tcp://127.0.0.1:2910');
    my $sub = Cro::ZeroMQ::Sub.new(bind => 'tcp://127.0.0.1:2910', :$subscribe, :$unsubscribe);

    my $complete = Promise.new;

    my $tap = $sub.incoming.tap: -> $_ {
        %init{$_.body-text} = True;
        $complete.keep if %init eqv %finish;
    }

    $pub.sinker(
        supply {
            for @messages {
                emit Cro::ZeroMQ::Message.new($_)
            }
        }
    ).tap;

    await Promise.anyof($complete, Promise.in(1));

    if $complete.status ~~ Kept {
        $tap.close;
        pass $desc;
    } else {
        flunk $desc;
    }
}

test 'Subscriber is a Blob',
     (('A', 'first'), ('A', 'second'),
      ('A', 'third'), ('B', 'fourth')),
     Blob.new('A'.encode),
     {:!first, :!second, :!third, :!fourth},
     {:first, :second, :third, :!fourth};

test 'Subscriber is a String',
     (('A', 'first'), ('A', 'second'),
      ('A', 'third'), ('B', 'fourth')),
     'A',
     {:!first, :!second, :!third, :!fourth},
     {:first, :second, :third, :!fourth};

test 'Subscriber is a Supply',
     (('A', 'first'), ('A', 'second'),
      ('A', 'third'), ('B', 'fourth')),
     supply { emit 'A' },
     {:!first, :!second, :!third, :!fourth},
     {:first, :second, :third, :!fourth};

test 'Subscriber is a Whatever',
     (('A', 'first'), ('A', 'second'),
      ('A', 'third'), ('B', 'fourth')),
     *,
     {:!first, :!second, :!third, :!fourth},
     {:first, :second, :third, :fourth};

test 'Unsubscribe',
     (('A', 'first'), ('A', 'second'),
      ('A', 'third'), ('B', 'fourth')),
     <A B>,
     {:!first, :!second, :!third, :!fourth},
     {:!first, :!second, :!third, :fourth},
     unsubscribe => supply { emit 'A' };

done-testing;
