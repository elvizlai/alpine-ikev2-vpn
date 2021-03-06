#!/bin/bash
# File desc: onekey install ikev2 vpn server on docker
# Requirements: ubuntu 16.04+ / Centos7+
# Time: 2018-05-06

install_docker(){
  if python -mplatform | grep -qi ubuntu ; then
    export os_type=ubuntu
  elif python -mplatform | grep -qi centos ; then
    export os_type=centos
  else
    echo -e 'Unknow system platform\n'
  fi

  case $os_type in
    ubuntu)
      echo -e "*************** Install Docker... *******************\n"
      sudo apt-get update
      sudo apt-get install apt-transport-https ca-certificates ca-certificates software-properties-common dnsutils
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
      sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
      sudo apt-get update
      sudo apt-get install -y docker-ce
      sudo systemctl enable docker -q
      sudo systemctl start docker
      echo -e "\n*************** Install docker on ubuntu. "
      ;;
    centos)
      echo -e "\n*************** Install Docker... *******************"
      sudo yum install -y yum-utils device-mapper-persistent-data lvm2 bind-utils
      sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
      sudo yum install -y docker-ce-17.12.1.ce-1.el7.centos
      sudo systemctl enable docker -q
      sudo systemctl start docker
      echo -e "\n*************** install docker on centos ***************"
      ;;
    *)
      echo -e "\n*************** please check os platform"
      ;;
  esac

}

# ensure docker is running
running_docker(){
  sudo systemctl start docker
}

# pull image command
pull_image(){
  echo -e "\n*************** Pull ikev2 vpn image from docker hub... ***************"
  sudo docker pull sdrzlyz/ikev2
}

# run command
run_docker(){
    sudo docker run --restart=always -itd --privileged -v /lib/modules:/lib/modules \
-e HOST_IP=$PUBLIC_IP -e VPNUSER=$VPNUSER -e VPNPASS="$VPNPASS" \
-p 500:500/udp -p 4500:4500/udp --name=ikev2-vpn sdrzlyz/ikev2
}

# Run ikev2 server
run_vpnserver(){
  export PUBLIC_IP=`dig +short myip.opendns.com @resolver1.opendns.com`
  export VPNUSER=$1
  export VPNPASS=$2
  CONTAINER_NAME=`sudo docker ps -f name=ikev2-vpn --format '{{.Names}}'`

  echo -e "\n*************** Start vpn server...***************"

  if [ "$CONTAINER_NAME" = 'ikev2-vpn' ]; then
    echo -e "\n*************** Delete old vpn server. "
    sudo docker rm -f $CONTAINER_NAME
    run_docker
  else
    run_docker
  fi

  echo -e "\n*************** Vpn Server is up, just a moment... ***************"
  sleep 3
}

# Generate certificate
generate_cert(){
  echo -e "\n*************** Generate certificate ***************"
  sudo docker exec -it ikev2-vpn sh /usr/bin/vpn
  echo -e "\n*************** Congratulations. 42. *************** "
  echo "Note: Don't forget to set the cloud host's firewall to allow udp port 500 and port 4500 traffic ! ^_^"
}


# ensure installed docker engine
command -v docker >/dev/null 2>&1

if [ $? -eq 0 ] ; then
  running_docker
  pull_image
  run_vpnserver $@
  generate_cert
else
  install_docker
  running_docker
  pull_image
  run_vpnserver $@
  generate_cert
fi