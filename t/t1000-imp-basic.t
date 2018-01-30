#!/bin/sh
#

test_description='IMP basic functionality test

Ensure IMP runs and runs under sudo when SUDO is available.
Also test basic subcommands like "version".
'

# Append --logfile option if FLUX_TESTS_LOGFILE is set in environment:
test -n "$FLUX_TESTS_LOGFILE" && set -- "$@" --logfile
. `dirname $0`/sharness.sh

flux_imp=${SHARNESS_BUILD_DIRECTORY}/src/imp/flux-imp

echo "# Using ${flux_imp}"

test_expect_success 'flux-imp is built and is executable' '
	test -x $flux_imp
'
test_expect_success 'flux-imp returns error when run with no args' '
	test_must_fail $flux_imp 
'
test_expect_success 'flux-imp version works' '
	$flux_imp version | grep "flux-imp v"
'
test_expect_success SUDO 'flux-imp version works under sudo' '
	sudo $flux_imp version | grep "flux-imp v"
'
test_expect_success SUDO 'flux-imp generates error if SUDO_USER is invalid' '
	test_expect_code 1 sudo SUDO_USER=invalid $flux_imp version
'
test_expect_success 'flux-imp whoami works' '
	$flux_imp whoami | sort -k2,2 > output.whoami &&
	test_debug cat output.whoami &&
	cat <<-EOF > expected.whoami &&
	flux-imp: unprivileged: uid=$(id -ru) euid=$(id -u) gid=$(id -rg) egid=$(id -g)
EOF
	test_cmp expected.whoami output.whoami
'
test_expect_success SUDO 'flux-imp whoami works under sudo' '
	sudo $flux_imp whoami | sort -k2,2 > output.whoami.sudo &&
	test_debug cat output.whoami.sudo &&
	cat <<-EOF > expected.whoami.sudo &&
	flux-imp: privileged: uid=$(id -ru) euid=0 gid=$(id -rg) egid=0
	flux-imp: unprivileged: uid=$(id -ru) euid=$(id -u) gid=$(id -rg) egid=$(id -g)
EOF
	test_cmp expected.whoami.sudo output.whoami.sudo
'
test_expect_success SUDO 'create setuid copy of flux-imp for testing' '
	sudo cp $flux_imp . &&
	sudo chmod 4755 ./flux-imp
'
test_expect_success SUDO 'setuid copy of flux-imp works' '
	./flux-imp whoami | sort -k2,2 > output.whoami.setuid &&
	test_debug cat output.whoami.setuid &&
	cat <<-EOF >expected.whoami.setuid &&
	flux-imp: privileged: uid=$(id -ru) euid=0 gid=$(id -rg) egid=$(id -g)
	flux-imp: unprivileged: uid=$(id -ru) euid=$(id -u) gid=$(id -rg) egid=$(id -g)
	EOF
	test_cmp expected.whoami.setuid output.whoami.setuid
'
test_expect_success SUDO 'flux-imp setuid ignores SUDO_USER' '
	SUDO_USER=nobody ./flux-imp whoami | sort -k2,2 > output.whoami.no &&
	test_debug cat output.whoami.no &&
	cat <<-EOF >expected.whoami.no &&
	flux-imp: privileged: uid=$(id -ru) euid=0 gid=$(id -rg) egid=$(id -g)
	flux-imp: unprivileged: uid=$(id -ru) euid=$(id -u) gid=$(id -rg) egid=$(id -g)
	EOF
	test_cmp expected.whoami.no output.whoami.no
'
test_done
