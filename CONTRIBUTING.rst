Bifrost is a part of Ironic, which is an OpenStack project and
thus follows OpenStack development procedures.

For a full (and official) description of the development workflow, see:

    http://docs.openstack.org/infra/manual/developers.html#development-workflow

For a highly abridged version, read on.

-------------
Communicating
-------------

Before you file a ticket or submit a pull request, its often helpful to chat
with other developers.  The #openstack-ironic channel is a good place to start,
and if you don't have IRC (or would prefer email), openstack-dev@lists.openstack.org
is the mailing list for all OpenStack projects.  As the name implies, that mailing
list is for all OpenStack development, so it's often harder to get attention on
your particular issue.

-----------
Filing Bugs
-----------

Bugs should be filed on Launchpad, not GitHub:

    https://bugs.launchpad.net/bifrost

-----------------
Contributing Code
-----------------

Bifrost requires a valid OpenStack contributor agreement to be signed before
code can be accepted.  Details can be found in the development workflow link
above.

Code isn't committed directly (so pull requests won't work); instead, the
code is submitted for review through Gerrit via git review, and once its
been sufficiently reviewed it will be merged from there.

Once that's done, the development workflow is, roughly::

   $ git clone https://git.openstack.org/openstack/bifrost
   $ cd bifrost
   $ git checkout -b some-branch-name
   ... hack hack hack ...
   $ git commit
   $ git review
   ... The configuration details for this are in .gitreview.
   ... When the command runs, it will add a ChangeId to your commit
   ... message and print out a link for your reference
   ...
   ... If you need to fix something in that commit, you can do:
   $ git commit --amend
   $ git review

From that point on, the link the git review command generated is
the place to do final tweaks.  When its approved, the code
will be merged in automatically.
