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
variable "gopath" {
  type    = string
  default = ""
}
variable "branch" {
  type    = string
  default = ""
}
build {
  name = "Percona-postgres-server-Image"
  sources = [
    "source.docker.percona-postgres-server"
  ]
  provisioner "shell" {
    inline = [
      "apt-get update",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y make curl wget jq ca-certificates git gnupg lsb-release sudo software-properties-common",
      "sudo apt-get install -y docker.io",
      "sudo apt install docker-buildx",
      "wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz",
      "sudo tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz",
      "export PATH=$PATH:/usr/local/go/bin",
      "go version",
      "export GOPATH=~/go",
      "mkdir -p ${var.gopath}/src/github.com/zalando/",
      "cd ${var.gopath}/src/github.com/zalando/",
      "git clone https://github.com/zalando/postgres-operator.git",
      "cd postgres-operator && git checkout tags/${var.branch}",
      "make deps",
      "export TAG=${var.tag}",
      "export IMAGE=avnshrai/postgres-operator",
      "make docker",
      "[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64",
      "chmod +x ./kind && sudo cp ./kind /usr/local/bin/kind",
      "if kind get clusters | grep -qw 'postgres-test'; then echo \"Cluster 'postgres-test' already exists.\"; else kind create cluster --name postgres-test; fi",
      "kind load docker-image avnshrai/postgres-operator:${var.tag} --name postgres-test",
      "curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3",
      "chmod 700 get_helm.sh",
      "./get_helm.sh",
      "helm install postgres-operator ./charts/postgres-operator --namespace zalando-operator --set image.registry=docker.io --set image.repository=avnshrai/postgres-operator --set image.tag=${var.tag} --set image.pullPolicy=Never",
      "kubectl get pods -l name=postgres-operator",
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
