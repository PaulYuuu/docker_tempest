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
    pip install -r ./requirements.txt && \
    pip install -r ./test-requirements.txt && \
    python setup.py install && \
    pip install nose tox && \
    tox -egenconfig && \
    cp etc/{tempest.conf.sample,tempest.conf} && \
    cp etc/{accounts.yaml.sample,accounts.yaml}

# Running tempest setup
RUN cd /root/tempest/source/tempest && \
    for i in designate-tempest-plugin magnum-tempest-plugin neutron-tempest-plugin manila-tempest-plugin \
             keystone-tempest-plugin murano-tempest-plugin heat-tempest-plugin tempest-horizon \
             ironic-tempest-plugin octavia-tempest-plugin barbican-tempest-plugin; \
          do git clone https://github.com/openstack/"$i" && \
             pip install -e ./"$i" && \
             pip install -r ./"$i"/test-requirements.txt; \
        done && \
    tempest init /root/tempest/workdir && \
    cd /root/tempest/workdir && \
    testr init

WORKDIR /root/tempest/workdir

CMD ["/bin/bash"]
