use Cro::Message;

class Cro::ZeroMQ::Message does Cro::Message {
    has Blob @.parts;

    method parts(--> List) { @!parts.List }
    method body-blob(--> Blob) { @!parts[*-1] }
    method body-text(:$enc = 'utf-8') { @!parts[*-1].decode($enc) }

    multi method new(Str $part)  { self.bless(parts => [$part.encode]) }
    multi method new(Blob $part) { self.bless(parts => [$part]) }
    multi method new(:$parts)    { self.bless(parts => @$parts) }
    multi method new(*@rest) {
        my @res;
        for @rest {
            die "Message part can be only Blob or Str, encountered $_.WHAT" if $_ !~~ Blob|Str;
            @res.push: $_ ~~ Str ?? Blob.new($_.encode) !! $_;
        }
        return self.bless(parts => @res);
    }
}
