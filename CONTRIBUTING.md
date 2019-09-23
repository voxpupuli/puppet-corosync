This module has grown over time based on a range of contributions from
people using it. If you follow these contributing guidelines your patch
will likely make it into a release a little quicker.


## Contributing

Please note that this project is released with a Contributor Code of Conduct. By participating in this project you agree to abide by its terms. [Contributor Code of Conduct](https://voxpupuli.org/coc/).

1. Fork the repo.

1. Create a separate branch for your change.

1. Run the tests. We only take pull requests with passing tests, and
   documentation.

1. Add a test for your change. Only refactoring and documentation
   changes require no new tests. If you are adding functionality
   or fixing a bug, please add a test.

1. Squash your commits down into logical components. Make sure to rebase
   against the current master.

1. Push the branch to your fork and submit a pull request.

Please be prepared to repeat some of these steps as our contributors review
your code.

## Dependencies

The testing and development tools have a bunch of dependencies,
all managed by [bundler](http://bundler.io/) according to the
[Puppet support matrix](http://docs.puppetlabs.com/guides/platforms.html#ruby-versions).

By default the tests use a baseline version of Puppet.

If you have Ruby 2.x or want a specific version of Puppet,
you must set an environment variable such as:

    export PUPPET_VERSION="~> 4.2.0"

Install the dependencies like so...

    bundle install

## Syntax and style

The test suite will run [Puppet Lint](http://puppet-lint.com/) and
[Puppet Syntax](https://github.com/gds-operations/puppet-syntax) to
check various syntax and style things. You can run these locally with:

    ```bash
    # Ensure the correct version of puppet is selected
    export PUPPET_VERSION="~> 5.0"
    bundle exec rake lint
    bundle exec rake validate
    bundle exec rake rubocop 
    ```

## Running the unit tests

The unit test suite covers most of the code, as mentioned above please
add tests if you're adding new functionality. If you've not used
[rspec-puppet](http://rspec-puppet.com/) before then feel free to ask
about how best to test your new feature.

To run your all the unit tests

    bundle exec rake spec SPEC_OPTS='--format documentation'

To run a specific spec test set the `SPEC` variable:

    bundle exec rake spec SPEC=spec/foo_spec.rb

To run the linter, the syntax checker and the unit tests:

    bundle exec rake test


## Integration tests

The unit tests just check the code runs, not that it does exactly what
we want on a real machine. For that we're using
[beaker](https://github.com/puppetlabs/beaker).

This fires up a new virtual machine (using vagrant) and runs a series of
simple tests against it after applying the module. You can run this
with:

    bundle exec rake acceptance

This will run the tests on an Ubuntu 12.04 virtual machine. You can also
run the integration tests against Centos 6.5 with.

    BEAKER_set=centos-64-x64 bundle exec rake acceptances

If you don't want to have to recreate the virtual machine every time you
can use `BEAKER_DESTROY=no` and `BEAKER_PROVISION=no`. On the first run you will
at least need `BEAKER_PROVISION` set to yes (the default). The Vagrantfile
for the created virtual machines will be in `.vagrant/beaker_vagrant_fies`.

### Vagrant

If you are using vagrant instead of docker for local testing you will need to
ensure that the beaker-vagrant is installed.

1. Add `gem 'beaker-vagrant',                     :require => false` to the Gemfile.
1. Re-run `bundle install` to add all relevant packages.

Once this is in-place, you can execute a test on an CentOS 7 VM with puppet5 as follows:

```bash
BEAKER_PUPPET_COLLECTION=puppet5 bundle exec rake beaker:centos-7-x64 SPEC=spec/acceptance/cs_primitive_spec.rb
```

When troubleshooting adding `BEAKER_destroy=no` will ensure that the VM is not
removed after the test completes. To connect via ssh, perform the following:

1. Determine the vagrant ID of your test node

    ```bash
    vagrant global-status
    ```
    Something similar to the following should print:

    ```bash
    id       name         provider   state   directory                                                                                                            
    -------------------------------------------------------------------------------------------------------------------------------
    e86d327  centos-7-x64 virtualbox running /home/me/puppet-corosync/.vagrant/beaker_vagrant_files/centos-7-x64.ym
    ```
1. Connect to the ID

    ```bash
    vagrant ssh e86d327
    ```

From there you should be able to become root via `sudo -i` without a password
and do whatever. Likely, you'll try running a puppet apply similar to the
example below to troubleshoot your code.
```bash
puppet apply --verbose --trace --detailed-exitcodes /tmp/apply_manifest.pp.<some_garbage>`
```

It might also be necessary to specify **PUPPET_VERSION** explicitly via
something like `PUPPET_VERSION=5.5.16` for some versions of beaker-puppet.
This can come up if you see package manager errors which attempt to use
`~>5.0` as the version of the package.

# vim: syntax=markdown
