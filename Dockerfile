FROM ubuntu:16.04
MAINTAINER AnanasYuu <yuyihuang0702@163.com>

# Pre-installation
RUN sed -i s/^deb-src.*// /etc/apt/sources.list && \
    apt-get update && apt-get install --yes bash-completion apt-utils vim git wget curl gcc \
    python-dev python-libxml2 python-setuptools \
    libxml2-dev libxslt-dev lib32z1-dev libssl-dev libxslt1-dev libsasl2-dev libsqlite3-dev libldap2-dev libffi-dev && \
    easy_install pip && \
    pip install --upgrade setuptools && \
    pip install xunit2testrail junitxml ipdb virtualenv python-openstackclient && \
    sed -i "32,38s/^#//g" /etc/bash.bashrc && \
    mkdir -p /root/tempest/source

# Clone and install tempest
RUN cd /root/tempest/source && \
    git clone -b 18.0.0 https://git.openstack.org/openstack/tempest ./ && \
    pip install ./ && \
    pip install -r ./test-requirements.txt && \
    pip install nose tox

# Configuration tempest
RUN cd /root/tempest/source && \
    tox -egenconfig && \
    cp etc/accounts.yaml.sample etc/accounts.yaml && \
    cp etc/tempest.conf.sample etc/tempest.conf

# Running tempest setup
RUN tempest init /root/tempest/workdir && \
    cd /root/tempest/workdir && \
    echo "[DEFAULT]" > .testr.conf && \
    echo "test_command=OS_STDOUT_CAPTURE=${OS_STDOUT_CAPTURE:-1} \" >> .testr.conf && \
    echo "             OS_STDERR_CAPTURE=${OS_STDERR_CAPTURE:-1} \" >> .testr.conf && \
    echo "             OS_TEST_TIMEOUT=${OS_TEST_TIMEOUT:-500} \" >> .testr.conf && \
    echo "             OS_TEST_LOCK_PATH=${OS_TEST_LOCK_PATH:-${TMPDIR:-'/tmp'}} \" .testr.conf && \
    echo "             ${PYTHON:-python} -m subunit.run discover -t ${OS_TOP_LEVEL:-./} ${OS_TEST_PATH:-./tempest/test_discover} $LISTOPT $IDOPTION" >> .testr.conf && \
    echo "test_id_option=--load-list $IDFILE" >> .testr.conf && \
    echo "test_list_option=--list" >> .testr.conf && \
    echo "group_regex=([^\.]*\.)*" >> .testr.conf && \
    testr init

WORKDIR /root/tempest/workdir

CMD ["/bin/bash"]
