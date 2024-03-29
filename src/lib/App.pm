package App;
use v5.16;
use warnings;

my $HELP = <<'EOF';
Usage: goenv download [options] [version]

Options:
  -l, --list      show available versions (latest stable 10)
  -L, --list-all  show available versions (all)
  -g, --global    execute `goenv globa` after installation
  -r, --rehash    execute `goenv rehash` after installation
  -h, --help      show this help

Examples:
 $ goenv download -l
 $ goenv download latest
 $ goenv download 1.17.3
 $ goenv download HEAD              # download golang source code, and build HEAD
 $ goenv download source@6f42be78bb # download golang source code, and build commit 6f42be78bb
EOF

use File::Basename qw(basename);
use File::Path qw(mkpath);
use File::Spec::Functions qw(catfile);
use File::pushd qw(pushd);
use Getopt::Long ();
use HTTP::Tinyish;
use POSIX qw(uname strftime);
use JSON::PP ();

sub new {
    my ($class, %argv) = @_;
    my $home = $argv{home};
    my $cache_dir = catfile $home, "cache";
    my $root = $ENV{GOENV_ROOT} || catfile($ENV{HOME}, ".goenv");
    my $versions_dir = catfile $root, "versions";
    mkpath $_ for grep { !-d } $versions_dir, $cache_dir;
    my $os = $^O =~ /linux/i ? "linux" : $^O =~ /darwin/i ? "darwin" : die;
    my $_arch = (uname)[4];
    my $arch = $_arch eq "x86_64"  ? "amd64"
             : $_arch eq "arm64"   ? "arm64"
             : $_arch eq "aarch64" ? "arm64" : die;
    bless {
        os => $os,
        arch => $arch,
        home => $home,
        cache_dir => $cache_dir,
        root => $root,
        versions_dir => $versions_dir,
        http => HTTP::Tinyish->new(verify_SSL => 1),
    }, $class;
}

sub run {
    my ($self, @argv) = @_;

    my $parser = Getopt::Long::Parser->new(
        config => [qw(no_auto_abbrev no_ignore_case bundling)],
    );
    $parser->getoptionsfromarray(
        \@argv,
        "h|help" => sub { die $HELP },
        "l|list" => \my $list,
        "g|global" => \my $global,
        "r|rehash" => \my $rehash,
        "L|list-all" => \my $list_all,
        "complete" => sub { print $_, "\n" for "-l", "-L", "latest"; exit 0 },
    ) or return 1;

    if ($list || $list_all) {
        my @available = $self->available;
        if ($list) {
            @available = (map { $_->{version} } grep { $_->{stable} } @available)[0..9];
        } else {
            @available = map { $_->{version} } @available;
        }
        print $_, "\n" for @available;
        return 0;
    }

    my $version = shift @argv or die "Need version, try `goenv download --help`\n";

    if ($version eq "HEAD" || $version =~ s/source@//) {
        $self->build_from_source($version);
        return 0;
    }

    my @available = $self->available;
    if ($version eq "latest") {
        $version = (map { $_->{version} } grep { $_->{stable} } @available)[0];
    } else {
        my %available = map { $_ => 1 } map { $_->{version} } $self->available;
        if (!$available{$version}) {
            die "Unknown version '$version', try `goenv download -L`\n";
        }
    }
    my $target = catfile $self->{versions_dir}, $version;
    if (-e $target) {
        die "Already exists $target\n";
    }
    my $tarball = $self->download($version);
    $self->unpack($tarball => $target);
    $self->log("Successfully installed $target");
    if ($global) {
        $self->log("Executing `goenv global $version`");
        !system "goenv", "global", $version or die;
    }
    if ($rehash) {
        $self->log("Executing `goenv rehash`");
        !system "goenv", "rehash" or die;
    }
    return 0;
}

sub log { my $self = shift; warn "@_\n" }

sub available {
    my $self = shift;
    my $url = 'https://go.dev/dl/?mode=json&include=all';
    my $res = $self->{http}->get($url);
    if (!$res->{success}) {
        warn $res->{content} if $res->{status} == 599;
        die "$res->{status} $res->{reason}, $url\n";
    }
    my $releases = JSON::PP::decode_json $res->{content};
    my @release;
    for my $r (@$releases) {
        (my $version = $r->{version}) =~ s/^go//;
        my $stable = $r->{stable} ? 1 : 0;
        push @release, { version => $version, stable => $stable };
    }
    @release;
}

sub download {
    my ($self, $version) = @_;
    my $url = sprintf "https://dl.google.com/go/go%s.%s-%s.tar.gz",
        $version, $self->{os}, $self->{arch};
    my $cache_file = catfile $self->{cache_dir}, basename($url);
    if (-f $cache_file) {
        $self->log("Using cache $cache_file");
        return $cache_file;
    }
    $self->log("Downloading $url");
    my $res = $self->{http}->mirror($url => $cache_file);
    if (!$res->{success}) {
        unlink $cache_file;
        warn $res->{content} if $res->{status} == 599;
        die "$res->{status} $res->{reason}, $url\n";
    }
    $cache_file;
}

sub unpack {
    my ($self, $tarball, $target) = @_;
    mkpath $target;
    $self->log("Unpacking $tarball");
    !system "tar", "xf", $tarball, "--strip-components=1", "-C", $target or die;
}

sub build_from_source {
    my ($self, $commitish) = @_;

    my $url = "https://github.com/golang/go";

    my $reference = catfile $self->{cache_dir}, "reference";
    if (-d $reference) {
        my $guard = pushd $reference;
        my @cmd = ("git", "pull");
        $self->log("Updating $reference");
        !system @cmd or die;
    } else {
        my @cmd = ("git", "clone", "-q", $url, $reference);
        $self->log("Executing @cmd");
        !system @cmd or die;
    }

    if ($commitish eq "HEAD") {
        my $guard = pushd $reference;
        $commitish = `git rev-parse --short HEAD`;
        chomp $commitish;
    }
    my $target = catfile $self->{versions_dir}, strftime("%Y%m%d-", localtime) . $commitish;

    my @cmd = ("git", "clone", "-q", "--reference", $reference, $url, $target);
    $self->log("Executing @cmd");
    !system @cmd or die;

    my $guard = pushd $target;
    @cmd = ("git", "checkout", "-q", $commitish);
    $self->log("Executing @cmd");
    !system @cmd or die;

    {
        my $guard = pushd "src";
        my @cmd = ("bash", "make.bash");
        $self->log("Executing @cmd");
        !system @cmd or die;
    }

    @cmd = ("bin/go", "install", "-race", "std");
    $self->log("Executing @cmd");
    !system @cmd or die;
}

1;
