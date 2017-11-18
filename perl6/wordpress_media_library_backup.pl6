use v6;
use LWP::Simple;

my $medialib = @*ARGS[0] // 'medialib';
my $dest = $medialib;
my $xml = slurp @*ARGS[1] // 'export.xml';
my @matches = $xml ~~ m:g/ '<wp:attachment_url>' (\N+) '</wp:attachment_url>' /;
if @matches.elems == 0 { die 'No URLs found.' }

say 'Downloading...';

for @matches {
    $dest = $medialib;
    my $url = $_[0].Str;
    print "-> $url";
    $url ~~ m/ http[s?] '://' .+? '/' (.+ '/')? (.+) /;
    my ($dirs, $file) = $/.values;
    if $dirs.defined == False { $dirs = '' };
    if $dirs ne '' { mkdir "$dest/$dirs" }

    $dest = "$dest/$dirs/$file".subst(/'//'/, '/');
    my $file_content = LWP::Simple.get($url);

    if $file_content.isa('Buf') {
        spurt $dest, $file_content, :bin;
        put '';
    }
    else { put ' : Error' }
}

say 'Finished.';