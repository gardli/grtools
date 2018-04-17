#case 1:
#ec2_server exist, on eip 
#s3 exist(no_dots)
#role attached-ec2 fullaccess to s3
#ec2 security group ports opened: 990/tcp, 15390:15690/tcp

#input bucket name
bucket_name=
#input EIP
elastic_IP=

#[S3FS-FUSE]
sudo yum -y update
sudo yum -y install git automake make gcc libstdc++-devel gcc-c++ fuse fuse-devel libcurl-devel curl-devel libxml2-devel mailcap openssl-devel

mkdir ~/misc && cd ~/misc
git clone https://github.com/s3fs-fuse/s3fs-fuse.git
cd s3fs-fuse
./autogen.sh
./configure
make
sudo make install

#[VSFTPD]
sudo yum -y install vsftpd
#[FTPS]
sudo mkdir -p /etc/ssl/private
sudo openssl req -x509 -nodes -days 730 -newkey rsa:2048 \
 -keyout /etc/ssl/private/vsftpd.pem \
 -out /etc/ssl/private/vsftpd.pem \
 -subj "/C=cc/ST=Default/L=Default/O=Default/CN=carla.grtools.cc"
sudo vi /etc/vsftpd/vsftpd.conf
sudo cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.origin
sudo vi /etc/vsftpd/vsftpd.conf
------------------------------------------
anonymous_enable=NO
local_enable=YES
chroot_local_user=YES
tcp_wrappers=YES
write_enable=YES
allow_writeable_chroot=YES

userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO

pasv_enable=yes
pasv_min_port=15390 
pasv_max_port=15690 
pasv_address=18.197.127.113
listen_port=15400

rsa_cert_file=/etc/ssl/private/vsftpd.pem
rsa_private_key_file=/etc/ssl/private/vsftpd.pem

ssl_enable=YES
allow_anon_ssl=NO
force_local_data_ssl=YES
force_local_logins_ssl=YES

ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO

require_ssl_reuse=NO
ssl_ciphers=HIGH
-------------------------------------

#[S3 MOUNT]
sudo mkdir -p /mnt/$bucket_name
sudo vi /etc/fuse.conf
#uncomment user_allow_other

sudo /usr/local/bin/s3fs $bucket_name /mnt/$bucket_name -o iam_role -o allow_other
#[S3-FSTAB]
sudo vi /etc/fstab
$bucket_name /mnt/$bucket_name fuse.s3fs _netdev,allow_other,iam_role 0 0

#[VSFTPD: USER]
sudo useradd -d /mnt/$bucket_name -s /sbin/nologin ftpuser1
sudo passwd ftpuser1
sudo vi /etc/vsftpd.userlist
#add ftpuser1

#[RESTART, ENABLE VSFTPD]
sudo systemctl restart vsftpd
sudo systemctl enable vsftpd