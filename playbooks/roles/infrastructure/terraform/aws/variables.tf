variable "cluster_name" {
  type = string
}

variable "base_domain" {
  type = string
}

variable "cluster_domain" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "172.31.0.0/16"
}

variable "rhcos_ami" {
  type = string
}

variable "keypair_name" {
  type = string
}
