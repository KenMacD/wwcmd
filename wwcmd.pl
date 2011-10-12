use strict;
use vars qw($VERSION %IRSSI);

use Irssi;
$VERSION = '20111011';
%IRSSI = (
    authors     => 'Kenny MacDermid',
    contact     => 'kenny.macdermid@gmail.com',
    name        => 'wwcmd',
    description => 'doesn\'t send common mistake messages to people/channels',
    license     => 'Public Domain',
);

my @last_sig;
my $have_last = 0;
my $ignore_once = 0;
my @cmds;

push(@cmds, qr/^\s+\//);
push(@cmds, qr/^\s*win /);
push(@cmds, qr/^\s*win$/);
push(@cmds, qr/^\s*ls/);
push(@cmds, qr/^\s*:q/);
push(@cmds, qr/^\s*:wq/);
for my $cmd (Irssi::commands()) {
    my $c = $cmd->{cmd};
    push(@cmds, qr/^\s*$c$/);
    push(@cmds, qr/^\s*$c /);
}

sub send_text {

    #"send text", char *line, SERVER_REC, WI_ITEM_REC
    my ( $data, $server, $witem ) = @_;

    return if not $witem;
    return if $witem->{type} ne "CHANNEL" and $witem->{type} ne "QUERY";
         
    if ($ignore_once != 0) {
        $have_last = 0;
        $ignore_once = 0;
        # Do not clear @last_sig here, bad things happen.
        return;
    }

    my $matched = 0;
    foreach my $cmd( @cmds) {
        if ( $data =~/$cmd/ ) {
            $matched = 1;
            last;
        }
    }
    if ( $matched ) {
        $witem->print("Accidental command? Ctrl+K to send anyway.");
        @last_sig = ($data, $server, $witem);
        $have_last = 1;
        Irssi::signal_stop();
    } elsif ( $witem && @last_sig) {
        $have_last = 0;
        @last_sig = undef;
    }
}

Irssi::signal_add_first('send text' => \&send_text);

sub sig_cmd_override {
    my ($key) = @_;
    if ($key == 11 && $have_last) {
        $ignore_once = 1;
        Irssi::signal_emit("send text", @last_sig);
        @last_sig = undef;
    }
}

Irssi::signal_add_first('gui key pressed' => \&sig_cmd_override);

