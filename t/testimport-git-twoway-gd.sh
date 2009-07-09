. lib.sh

create_darcs test

rm -rf test.git
mkdir test.git
cd test.git
git init
git darcs add upstream ../test
git darcs pull upstream
cd ..
diff_git test || die "initial fetch differs"
upd_file_darcs test file2 upd_contents
cd test.git
git darcs pull upstream
cd ..
diff_git test || die "fetch #1 differs"
upd_file_git test.git file2 upd_contents2
cd test.git
git darcs push upstream
cd ..
diff_git test || die "push #1 difers"
upd_file_darcs test file2 upd_contents3
upd_file_darcs test file2 upd_contents32
cd test.git
git darcs pull upstream
# --working now has [..file2=upd_contents2,=upd_contents3,=upd_contents32]]
cd ..
diff_git test || die "fetch #2 (multiple commits) differs"
upd_file_git test.git file2 upd_contents4
upd_file_git test.git file2 upd_contents42
cd test.git
git darcs push upstream
cd ..
diff_git test || die "push #2 (multiple commits) differs"

# the --working repo will get everything that was added to darcs [during
# darcs-to-git pull], but only the last 'git commit' patch before a
# git-to-darcs push (plus files that patch depends upon, from darcs' point of
# view) [during the subsequent darcs-to-git pull].

# so at this point, the --working repo does not have upd_contents4 or
# upd_contents42

# push two non-interdependent changes from git to darcs
cd test.git
echo "file3" > file3
echo "file4" > file4
git add file3
git commit -a -m "added file3"
git add file4
git commit -a -m "added file4"
git darcs push upstream
# that "added file4" was the last thing pushed git-to-darcs, so it will be
# recorded in import_marks[-1], and will be pulled into the working repo by
# the next darcs-to-git. However, due to the bug, that working repo will
# still be missing "added file3", "update file2 to upd_contents42", and
# "update file2 to upd_contents4".
cd ..
diff_git test || die "push #3 (multiple non-dependent commits) differs"
# then add something to darcs and pull it back
cd test
echo "file5" > file5
darcs add file5
_drrec -a -m "added file5"
cd ..

cd test.git
git darcs pull upstream
# this pull will see that import_marks[-1] is "added file4", and will try to
# drag everything after that (i.e. "added file5") to --working. This is the
# only patch that is not yet in git. However, because the --working repo is
# missing those other patches, DFE will record a tree state without them,
# making the git "added file5" patch actually revert the missing ones (i.e.
# it will delete file3 and reset file2 back to upd_content32"
cd ..
diff_git test || die "fetch #3 (multiple non-dependent commits) differs"
