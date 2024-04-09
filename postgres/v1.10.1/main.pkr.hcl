packer {
  required_plugins {
    docker = {
      version = ">= 0.0.7"
      source  = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "percona-postgres-server" {
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
variable "postgres_version" {
  type    = string
  default = ""
}
build {
  name = "Percona-postgres-server-Image"
  sources = [
    "source.docker.percona-postgres-server"
  ]


  provisioner "shell" {
    environment_vars = [
      "GOPATH=/home/core/go",
    ]
    inline = [
      "apt-get update",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget jq ca-certificates git gnupg lsb-release sudo software-properties-common",
      "wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz",
      "sudo tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz",
      "export PATH=$PATH:/usr/local/go/bin",
      "source /home/core/.bashrc",
      "go version",
      "export GOPATH=/home/core/go",
      "mkdir -p ${GOPATH}/src/github.com/zalando/",
      "cd ${GOPATH}/src/github.com/zalando/",
      "git clone https://github.com/zalando/postgres-operator.git",
      "make deps",
      "export TAG=postgres-operator${var.tag}",
      "make docker",
      "docker tag avnshrai/postgres-operator:${var.tag} avnshrai/postgres-operator:latest",
      "docker login -u ${var.docker_username} -p ${var.docker_password}",
      "docker push avnshrai/postgres-operator:${var.tag}",
      "docker push avnshrai/postgres-operator:latest",
    ]
  }

  post-processor "docker-tag" {
    repository = "avnshrai/postgres-operator"  # Adjust repository name as needed
    tags       = ["latest"]
  }
}