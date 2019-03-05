#!/bin/bash

sudo su <<"END"

## PATH
export PATH="$PATH:/usr/local/bin:/usr/sbin:/sbin/"

# yum section
echo "starting yum update"
yum update -y

## reinstall policy kit
echo "starting reinstall polkit"
yum reinstall -y polkit*

# Common tools
echo "starting common tools"
yum install -y wget
yum install -y lsof
yum groupinstall -y 'Development Tools'

echo "starting jenkins user setup"
groupadd jenkins && useradd -d /var/lib/jenkins jenkins -u 451 -g jenkins
echo "jenkins ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Java
echo "starting java install"
yum erase -y java
yum install -y java-1.8.0-openjdk-devel

# Ruby
echo "starting ruby install"
echo "y" | yum install ruby-devel

## rvm
echo "starting rvm install"
gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys XXX YYY
curl -sSL https://get.rvm.io | bash -s stable
usermod -a -G rvm jenkins
source /etc/profile.d/rvm.sh
rvm install ruby-2.4.1

## gem installs
gem install fpm --no-rdoc --no-ri

# newrelic
echo "starting newrelic install"
wget -qO /tmp/newrelic.zip https://oss.sonatype.org/content/repositories/releases/com/newrelic/agent/java/newrelic-java/3.46.0/newrelic-java-3.46.0.zip
unzip /tmp/newrelic.zip -d /var/lib/
mv /var/lib/newrelic /var/lib/newrelic.new
rm -f /tmp/newrelic.zip
cd /var/lib/newrelic.new
cp newrelic.yml newrelic.yml.bak
#these are just defaults (for QA) as the name and key for each account is changed in the CF template
sed -i 's/app_name:.*/app_name: jenkins master/g' newrelic.yml
sed -i 's/license_key:.*/license_key: XYZ/g' newrelic.yml

# Jenkins
echo "starting jenkins install"
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
yum install -y jenkins
service jenkins stop && chkconfig jenkins off
rm -rf /var/lib/jenkins

## Installation for cloudwatch metrics
echo "starting cloudwatch install"
yum install -y perl-DateTime perl-Sys-Syslog perl-Digest-SHA perl-CPAN perl-Crypt-SSLeay perl-Net-SSLeay perl-libwww-perl.noarch perl-LWP-Protocol-https
curl -sSL http://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.1.zip --output /tmp/CloudWatchMonitoringScripts-1.2.1.zip
/bin/unzip /tmp/CloudWatchMonitoringScripts-1.2.1.zip -d /usr/sbin
rm -f /tmp/CloudWatchMonitoringScripts-1.2.1.zip

## create the cron to send metrics to CloudWatch
cat >> /var/spool/cron/root << __EOF__
*/5 * * * * /usr/sbin/aws-scripts-mon/mon-put-instance-data.pl --mem-util --disk-space-util --disk-path=/ --from-cron
__EOF__

# make sure rc.local is executable
chmod 744 /etc/rc.local

# install jenkinsapi (python libs)
echo "starting jenkinsapi install"
pip3 install jenkinsapi

# # install NTP
# echo "starting NTP install"
# # # first erase chrony service
# # yum erase -y chrony
# # # install ntp
# # yum install -y ntp
# # sync ntp with external time service
# ntpdate pool.ntp.org
# # start ntpd now
# service ntpd start
# # run ntp on startup
# chkconfig ntpd on

#  Reset Image
# AWS seems to preserve any values that we set
echo "starting reset image"
sh /usr/local/bin/reset_image_for_ami.sh
END
