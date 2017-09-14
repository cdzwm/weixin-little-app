use utf8;
use Modern::Perl;
use Encode qw(decode encode);
use Mojo::UserAgent;
use IO::Uncompress::Unzip qw(unzip $UnzipError) ;
use Data::Dump qw(dump);

my $ua=Mojo::UserAgent->new;
$ua->connect_timeout(600);
$ua->request_timeout(600);
$ua->proxy->https("socks://123.57.10.224:1096");

# get update urls
sub get_update_file_urls{
	my ($start, $count)=@_;

	my $url="https://groups.yahoo.com/api/v1/groups/xys/messages?start=$start&count=$count&sortOrder=desc&direction=-1&chrome=raw&tz=America%2FLos_Angeles&ts=1505281553760";

	my $messages;
	for(1..3){
		my $res=$ua->get($url)->res;
		$messages=$res->json->{ygData}{messages}, last if $res->code == 200;
	}

	my @urls;
	for ( @$messages ){
		if( defined ( my $type = $_->{attachments}[0]{fileType}) ){
			if( $type eq 'application/zip'){
				push @urls, $_->{attachments}[0]{link};
			}
		}
	}
	@urls;
}

sub get_update_file{
	my $update_file_url=shift;
	for(1..3){
		my $tx=$ua->get($update_file_url);

		my $res=$tx->res;
		if($res->code == 200){
			return $res->body;
		}
		else{
			say STDERR sprintf "Code: %d", $res->code;
			say STDERR $tx->error;
		}
	}
}

sub parse_update_file{
	my $file_data=shift;
	my $r=quotemeta('◇◇新语丝(www.xys.org)') . '(?:.*?)' .  quotemeta('◇◇');
	my $re ="(.*?)$r";
	my $text = decode('cp936', $file_data);
	my @articles = ($text =~ /$re/sg);
	@articles;
}

my @urls =&get_update_file_urls(6016, 10000);

for( @urls ){
	my $update_file_url=$_;
	say STDERR $update_file_url;
	my $input=get_update_file $update_file_url;
	my $output;
	my $status = unzip \$input => \$output;
	my @arc=&parse_update_file($output);
	say STDERR $#arc;
}

