Bifrost is a part of Ironic, which is an OpenStack project and
thus follows OpenStack development procedures.

For a full (and official) description of the development workflow, see:

    https://docs.openstack.org/infra/manual/developers.html#development-workflow

For a highly abridged version, read on.

-------------
Communicating
-------------

Before you file a bug or new review set, it's often helpful to chat with other
developers. The #openstack-ironic channel is a good place to start, and if
you don't have IRC (or would prefer email),
openstack-discuss@lists.openstack.org is the mailing list for all OpenStack
projects. As the name implies, that mailing list is for all OpenStack
development, so it's often harder to get attention on your particular issue.

-----------
Filing Bugs
-----------

Bugs should be filed in StoryBoard, not GitHub:

    https://storyboard.openstack.org/#!/project/941

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

   $ git clone https://opendev.org/openstack/bifrost
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

If you propose a new feature and are unable to complete it, please
let the community know by commenting in the review set indicating
that someone else is free to carry on your change.  If the core
reviewers observe reviews that are not being actively worked on,
we are likely to inquire with you. If a review is untouched and the
owner of the review is unreachable for a lengthy period of time,
such as three to six months, the core reviewers may abandon the
change as we do not utilize auto-abandon.

----------
Code Style
----------

Bifrost is a mix of Python, YaML, and bash thrown in for good measure.

The overall intent is to keep features, and changes simple to permit a user
to easily understand and extend bifrost to meet their operational needs as
we recognize needs may vary.

With this, we have a list of things that we would like people to keep in mind
when contributing code.

1. Try to limit YaML to 79 characters per row, we understand this is not
   always possible, but please make an effort.
2. Try to keep change sets as short and to the point as possible.
3. Rather than pass key-value pair strings to Ansible modules, try to utilize
   key-value pair lists on a module command line.  Example::

      - name: "Stat file for x reason"
        stat:
          file: '/path/to/file'
          get_md5: no

4. Playbook conditionals utilizing variables intended as booleans,
   should make use of the ``| bool`` casting feature.  This is due
   to command line overrides are typically interpreted as strings
   instead of booleans.  Example::

      - name: "Something something something"
        module:
          parameter: "value"
        when: boolean_value | bool == true

5. Be clear and explicit with actions in playbooks and comments.
6. Simplicity is favored over magic.
7. Documentation should generally be paired with code changes as we feel
   that it is important for us to be able to release the master branch
   at any time.
8. Documentation should always be limited to 79 characters per row.
9. If you have any questions, please ask in #openstack-ironic.
