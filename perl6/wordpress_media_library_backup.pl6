use v6;
use Terminal::ANSIColor;

my $medialib = @*ARGS[0] // 'medialib';
my $dest = $medialib;
my $xml = slurp @*ARGS[1] // 'export.xml';
my @matches = $xml ~~ m:g/ '<wp:attachment_url>' (\N+) '</wp:attachment_url>' /;
if @matches.elems == 0 { die 'No URLs found.' }

enum States <CHCK DOWN SKIP ERR>;
sub colorize(States $state) {
    given $state {
        when CHCK { colored(sprintf('%-10s', 'CHECKING'), 'bold yellow') }
        when DOWN { colored(sprintf('%-10s', 'DOWNLOADED'), 'bold green') }
        when SKIP { colored(sprintf('%-10s', 'SKIPPED'), 'bold cyan') }
        default   { colored(sprintf('%-10s', 'ERROR'), 'bold red') }
    }
}

sub download() {
  say q:to/END/;
      -----------------------------------
      Wordpress media library backup tool
      -----------------------------------

      Downloading...
      END

  for @matches {
      $dest = $medialib;
      my $url = $_[0].Str;
      print colorize(CHCK) ~ " -> $url";
      $url ~~ m/ http[s?] '://' .+? '/' (.+ '/')? (.+) /;
      my ($dirs, $file) = $/.values;
      if $dirs.defined == False { $dirs = '' };
      mkdir "$dest/$dirs";

      $dest = "$dest/$dirs/$file".subst(/'//'/, '/');

      my $msg = '';
      given qq:x/curl -s -z $dest -w "%\{http_code}" $url --output $dest/ {
          when '200' { $msg = colorize(DOWN) }
          when '304' { $msg = colorize(SKIP) }
          default    { $msg = colorize(ERR); unlink $dest; }
      }
      say "\r$msg -> $url";
  }
  say "\nFinished.";
}

download();
