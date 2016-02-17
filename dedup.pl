#!/usr/bin/perl
# Usage: dedup.pl dir1 dir2 ...
# Duplicate files will be substituted by hardlinks to files in dir1.

use warnings;
use strict;

use Path::Class;

use constant CHECK_SIZE_ONLY => 0;
use constant MINIMUM_SIZE    => 20 * 1024 * 1024;
use constant MAXIMUM_SIZE    => 50 * 1024 * 1024;

if(CHECK_SIZE_ONLY) {
    warn "*** Checking size only; please confirm.\n";
    <STDIN>;
}

my $base   = shift @ARGV;
my @copies = @ARGV;

my $num_hardlinks = 0;
my $savings       = 0;

exit unless @copies;

dir($base)->recurse(callback => sub {
    my $file  = shift;
    my @stat  = stat $file;
    my $size  = $stat[7];
    my $inode = $stat[1];
    return Path::Class::Entity::PRUNE() if -l $file;
    return unless -f $file;
    return unless $size;
    return unless $size >= MINIMUM_SIZE;
    return unless $size <  MAXIMUM_SIZE;
    print STDERR "$file... ";

    my %same_inodes;
    my $num_weak_duplicates   = 0;
    my $num_strong_duplicates = 0;

    my $postfix = $file;
    $postfix =~ s/^\Q$base\E\///m;
    for my $copy (@copies) {
        my $file_  = "$copy/$postfix";
        my @stat_  = stat $file_;
        my $size_  = $stat_[7];
        my $inode_ = $stat_[1];
        next unless $size_;
        next unless $size  == $size_;
        next if     $inode == $inode_;
        if(not CHECK_SIZE_ONLY and not $same_inodes{$inode_}) {
            next unless system("cmp", "-s", "--", $file, $file_) == 0;
	}

        system("ln", "-f", "--", $file, $file_) == 0 or die "ln -f $file $file_ not successful!";
        $num_hardlinks++;
        $savings += $size        unless $same_inodes{$inode_};
	$num_strong_duplicates++ unless $same_inodes{$inode_};
	$num_weak_duplicates++;

	$same_inodes{$inode_} = 1;
    }

    print STDERR "$num_strong_duplicates/$num_weak_duplicates duplicates.\n";
});

END {
    printf STDERR "Created %d hardlinks, saving %s bytes (%.1f MiB).\n",
	$num_hardlinks, $savings, $savings / 1024 / 1024;
}
