packer {
  required_plugins {
    docker = {
      version = ">= 0.0.7"
      source  = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "percona-mongodb-server" {
  image  = "ubuntu:jammy"  # Adjust the base image according to your requirements
  commit = true
  volumes = {
    "/var/run/docker.sock" = "/var/run/docker.sock"
  }
}
variable "docker_username" {
  type    = string
  default = ""
}
variable "docker_password" {
  type    = string
  default = ""
}
variable "tag" {
  type    = string
  default = ""
}
variable "git_token" {
  type    = string
  default = ""
}
variable "mongodb_version" {
  type    = string
  default = ""
}
build {
  name = "Percona-MongoDB-server-Image"
  sources = [
    "source.docker.percona-mongodb-server"
  ]


  provisioner "shell" {
    inline = [
      "apt-get update",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget jq ca-certificates git gnupg lsb-release sudo software-properties-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "sudo apt install docker-buildx",
      "rm -rf percona-docker",
      "git clone https://avnshrai:${var.git_token}@github.com/coredgeio/percona-server-mongodb.git",
      "cd percona-server-mongodb/percona-server-mongodb-${var.mongodb_version}",
      "docker build -t coredgeio/mongodb-server:${var.tag} ." ,
      "docker tag coredgeio/mongodb-server:${var.tag} coredgeio/mongodb-server:latest",
      "docker login -u ${var.docker_username} -p ${var.docker_password}",
      "docker push coredgeio/mongodb-server:${var.tag}",
      "docker push coredgeio/mongodb-server:latest",
    ]
  }

  post-processor "docker-tag" {
    repository = "coredgeio/server-mongodb"  # Adjust repository name as needed
    tags       = ["latest"]
  }
}
