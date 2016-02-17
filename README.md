# hardlink-deduplication
Tiny Perl program to deduplicate files using hardlinks

Written for personal use, not configurable.

Usage:

    $ ./dedup.pl dir1 dir2 dir3 ...

Duplicate files will be substituted by hardlinks to files in `dir1`. Useful for
saving space with directory trees consisting of hardlinked backups (as for
instance created by rsync) where you suspect that the chain of hardlinks was
broken.

This program requires the Perl module `Path::Class`, which can be installed by
the following command.

    $ cpanm Path::Class
