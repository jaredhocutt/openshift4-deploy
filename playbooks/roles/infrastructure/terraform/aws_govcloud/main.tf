provider "aws" {}

###############################################################################
# Data
###############################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

# https://access.redhat.com/solutions/15356
data "aws_ami" "rhel7" {
  most_recent = true
  owners      = ["219670896067"]

  filter {
    name   = "name"
    values = ["RHEL-7.7?*Hourly*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

###############################################################################
# Locals
###############################################################################

locals {
  kubernetes_cluster_shared_tag = map(
    "kubernetes.io/cluster/${var.cluster_id}", "shared",
    "OpenShiftCluster", var.cluster_domain
  )

  kubernetes_cluster_owned_tag = map(
    "kubernetes.io/cluster/${var.cluster_id}", "owned",
    "OpenShiftCluster", var.cluster_domain
  )

  public_subnets = [
    aws_subnet.public0,
    aws_subnet.public1,
    aws_subnet.public2
  ]

  private_subnets = [
    aws_subnet.private0,
    aws_subnet.private1,
    aws_subnet.private2
  ]
}

###############################################################################
# VPC
###############################################################################

resource "aws_vpc" "openshift" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.cluster_id
  }
}

resource "aws_vpc_dhcp_options" "openshift" {
  domain_name_servers = ["AmazonProvidedDNS"]
}

resource "aws_vpc_dhcp_options_association" "openshift" {
  vpc_id          = aws_vpc.openshift.id
  dhcp_options_id = aws_vpc_dhcp_options.openshift.id
}

resource "aws_internet_gateway" "openshift" {
  vpc_id = aws_vpc.openshift.id

  tags = {
    Name = var.cluster_id
  }
}

resource "aws_subnet" "public0" {
  vpc_id                  = aws_vpc.openshift.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 0)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-public-${data.aws_availability_zones.available.names[0]}"
    )
  )
}

resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.openshift.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 1)
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-public-${data.aws_availability_zones.available.names[1]}"
    )
  )
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.openshift.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 2)
  availability_zone       = data.aws_availability_zones.available.names[2]
  map_public_ip_on_launch = true

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-public-${data.aws_availability_zones.available.names[2]}"
    )
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.openshift.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.openshift.id
  }

  tags = {
    Name = "${var.cluster_id}-public"
  }
}

resource "aws_route_table_association" "public0" {
  subnet_id      = aws_subnet.public0.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "natgw_public0" {
  vpc = true

  tags = {
    Name = "${var.cluster_id}-natgw-${data.aws_availability_zones.available.names[0]}"
  }

  depends_on = [aws_internet_gateway.openshift]
}

resource "aws_eip" "natgw_public1" {
  vpc = true

  tags = {
    Name = "${var.cluster_id}-natgw-${data.aws_availability_zones.available.names[1]}"
  }

  depends_on = [aws_internet_gateway.openshift]
}

resource "aws_eip" "natgw_public2" {
  vpc = true

  tags = {
    Name = "${var.cluster_id}-natgw-${data.aws_availability_zones.available.names[2]}"
  }

  depends_on = [aws_internet_gateway.openshift]
}

resource "aws_nat_gateway" "public0" {
  subnet_id     = aws_subnet.public0.id
  allocation_id = aws_eip.natgw_public0.id

  tags = {
    Name = "${var.cluster_id}-${data.aws_availability_zones.available.names[0]}"
  }

  depends_on = [aws_internet_gateway.openshift]
}

resource "aws_nat_gateway" "public1" {
  subnet_id     = aws_subnet.public1.id
  allocation_id = aws_eip.natgw_public1.id

  tags = {
    Name = "${var.cluster_id}-${data.aws_availability_zones.available.names[1]}"
  }

  depends_on = [aws_internet_gateway.openshift]
}

resource "aws_nat_gateway" "public2" {
  subnet_id     = aws_subnet.public2.id
  allocation_id = aws_eip.natgw_public2.id

  tags = {
    Name = "${var.cluster_id}-${data.aws_availability_zones.available.names[2]}"
  }

  depends_on = [aws_internet_gateway.openshift]
}

resource "aws_subnet" "private0" {
  vpc_id                  = aws_vpc.openshift.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 3)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-private-${data.aws_availability_zones.available.names[0]}"
    )
  )
}

resource "aws_subnet" "private1" {
  vpc_id                  = aws_vpc.openshift.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 4)
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-private-${data.aws_availability_zones.available.names[1]}"
    )
  )
}

resource "aws_subnet" "private2" {
  vpc_id                  = aws_vpc.openshift.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 5)
  availability_zone       = data.aws_availability_zones.available.names[2]
  map_public_ip_on_launch = false

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-private-${data.aws_availability_zones.available.names[2]}"
    )
  )
}

resource "aws_route_table" "private0" {
  vpc_id = aws_vpc.openshift.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.public0.id
  }

  tags = {
    Name = "${var.cluster_id}-private-${data.aws_availability_zones.available.names[0]}"
  }
}

resource "aws_route_table" "private1" {
  vpc_id = aws_vpc.openshift.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.public1.id
  }

  tags = {
    Name = "${var.cluster_id}-private-${data.aws_availability_zones.available.names[1]}"
  }
}

resource "aws_route_table" "private2" {
  vpc_id = aws_vpc.openshift.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.public2.id
  }

  tags = {
    Name = "${var.cluster_id}-private-${data.aws_availability_zones.available.names[2]}"
  }
}

resource "aws_route_table_association" "private0" {
  subnet_id      = aws_subnet.private0.id
  route_table_id = aws_route_table.private0.id
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private1.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private2.id
}

###############################################################################
# Load Balancing
###############################################################################

resource "aws_lb" "masters_ext" {
  name               = "${substr(var.cluster_id, 0, 28)}-ext"
  load_balancer_type = "network"

  subnets = [
    aws_subnet.public0.id,
    aws_subnet.public1.id,
    aws_subnet.public2.id
  ]

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-ext"
    )
  )
}

resource "aws_lb" "masters_int" {
  name               = "${substr(var.cluster_id, 0, 28)}-int"
  internal           = true
  load_balancer_type = "network"

  subnets = [
    aws_subnet.private0.id,
    aws_subnet.private1.id,
    aws_subnet.private2.id
  ]

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-int"
    )
  )
}

resource "aws_lb" "ingress" {
  name               = "${substr(var.cluster_id, 0, 24)}-ingress"
  load_balancer_type = "network"

  subnets = [
    aws_subnet.public0.id,
    aws_subnet.public1.id,
    aws_subnet.public2.id
  ]

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-ingress"
    )
  )
}

resource "aws_lb_target_group" "api" {
  name     = "${substr(var.cluster_id, 0, 28)}-api"
  vpc_id   = aws_vpc.openshift.id
  port     = 6443
  protocol = "TCP"

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-api"
    )
  )
}

resource "aws_lb_target_group" "api_int" {
  name     = "${substr(var.cluster_id, 0, 24)}-api-int"
  vpc_id   = aws_vpc.openshift.id
  port     = 6443
  protocol = "TCP"

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-api-int"
    )
  )
}

resource "aws_lb_target_group" "machine_config" {
  name     = "${substr(var.cluster_id, 0, 17)}-machine-config"
  vpc_id   = aws_vpc.openshift.id
  port     = 22623
  protocol = "TCP"

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-machine-config"
    )
  )
}

resource "aws_lb_target_group" "http" {
  name     = "${substr(var.cluster_id, 0, 27)}-http"
  vpc_id   = aws_vpc.openshift.id
  port     = 80
  protocol = "TCP"

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-http"
    )
  )
}

resource "aws_lb_target_group" "https" {
  name     = "${substr(var.cluster_id, 0, 26)}-https"
  vpc_id   = aws_vpc.openshift.id
  port     = 443
  protocol = "TCP"

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-https"
    )
  )
}

resource "aws_lb_listener" "api" {
  load_balancer_arn = aws_lb.masters_ext.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

resource "aws_lb_listener" "api_int" {
  load_balancer_arn = aws_lb.masters_int.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_int.arn
  }
}

resource "aws_lb_listener" "machine_config" {
  load_balancer_arn = aws_lb.masters_int.arn
  port              = 22623
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.machine_config.arn
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ingress.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.ingress.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.https.arn
  }
}

resource "aws_lb_target_group_attachment" "api_masters" {
  count = 3

  target_group_arn = aws_lb_target_group.api.arn
  target_id        = aws_instance.masters[count.index].id
  port             = 6443
}

resource "aws_lb_target_group_attachment" "api_int_masters" {
  count = 3

  target_group_arn = aws_lb_target_group.api_int.arn
  target_id        = aws_instance.masters[count.index].id
  port             = 6443
}

resource "aws_lb_target_group_attachment" "api_int_bootstrap" {
  target_group_arn = aws_lb_target_group.api_int.arn
  target_id        = aws_instance.bootstrap.id
  port             = 6443
}

resource "aws_lb_target_group_attachment" "machine_config_masters" {
  count = 3

  target_group_arn = aws_lb_target_group.machine_config.arn
  target_id        = aws_instance.masters[count.index].id
  port             = 22623
}

resource "aws_lb_target_group_attachment" "machine_config_bootstrap" {
  target_group_arn = aws_lb_target_group.machine_config.arn
  target_id        = aws_instance.bootstrap.id
  port             = 22623
}

resource "aws_lb_target_group_attachment" "ingress_http_workers" {
  count = 3

  target_group_arn = aws_lb_target_group.http.arn
  target_id        = aws_instance.workers[count.index].id
  port             = 80
}

resource "aws_lb_target_group_attachment" "ingress_https_workers" {
  count = 3

  target_group_arn = aws_lb_target_group.https.arn
  target_id        = aws_instance.workers[count.index].id
  port             = 443
}

###############################################################################
# Security Groups
###############################################################################

resource "aws_security_group" "bastion" {
  name        = "${var.cluster_id}-bastion"
  description = "${var.cluster_id} bastion security group"
  vpc_id      = aws_vpc.openshift.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-bastion"
    )
  )
}

resource "aws_security_group" "bootstrap" {
  name        = "${var.cluster_id}-bootstrap"
  description = "${var.cluster_id} bootstrap security group"
  vpc_id      = aws_vpc.openshift.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-bootstrap"
    )
  )
}

resource "aws_security_group" "master" {
  name        = "${var.cluster_id}-master"
  description = "${var.cluster_id} master security group"
  vpc_id      = aws_vpc.openshift.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-master"
    )
  )
}

resource "aws_security_group" "worker" {
  name        = "${var.cluster_id}-worker"
  description = "${var.cluster_id} worker security group"
  vpc_id      = aws_vpc.openshift.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-worker"
    )
  )
}

###############################################################################
# EC2
###############################################################################

resource "aws_instance" "bastion" {
  instance_type = "t3.small"
  ami           = data.aws_ami.rhel7.id
  subnet_id     = local.public_subnets[0].id
  key_name      = var.keypair_name

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

  vpc_security_group_ids      = [aws_security_group.bastion.id, aws_security_group.master.id]
  associate_public_ip_address = true

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-bastion",
      "OpenShiftRole", "bastion"
    )
  )
}

resource "aws_eip" "bastion" {
  vpc      = true
  instance = aws_instance.bastion.id

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-bastion"
    )
  )

  depends_on = [aws_internet_gateway.openshift]
}

resource "aws_instance" "bootstrap" {
  instance_type = "i3.large"
  ami           = var.rhcos_ami
  subnet_id     = local.private_subnets[0].id

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 120
    delete_on_termination = true
  }

  vpc_security_group_ids      = [aws_security_group.bootstrap.id, aws_security_group.master.id]
  associate_public_ip_address = false

  user_data = <<-EOF
  {"ignition":{"config":{"replace":{"source":"http://${aws_instance.bastion.private_ip}/bootstrap.ign","verification":{}}},"timeouts":{},"version":"2.1.0"},"networkd":{},"passwd":{},"storage":{},"systemd":{}}
  EOF

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-bootstrap",
      "OpenShiftRole", "bootstrap"
    )
  )

  lifecycle {
    ignore_changes = all
  }

  depends_on = [aws_instance.bastion]
}

resource "aws_instance" "masters" {
  count = 3

  instance_type = "m5.xlarge"
  ami           = var.rhcos_ami
  subnet_id     = local.private_subnets[count.index].id

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 120
    delete_on_termination = true
  }

  vpc_security_group_ids      = [aws_security_group.master.id]
  associate_public_ip_address = false

  user_data = <<-EOF
  {"ignition":{"config":{"replace":{"source":"http://${aws_instance.bastion.private_ip}/master.ign","verification":{}}},"timeouts":{},"version":"2.1.0"},"networkd":{},"passwd":{},"storage":{},"systemd":{}}
  EOF

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-master-${count.index}",
      "OpenShiftRole", "master"
    )
  )

  depends_on = [aws_instance.bastion]
}

resource "aws_instance" "workers" {
  count = 3

  instance_type = "m5.xlarge"
  ami           = var.rhcos_ami
  subnet_id     = local.private_subnets[count.index].id

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 120
    delete_on_termination = true
  }

  vpc_security_group_ids      = [aws_security_group.worker.id]
  associate_public_ip_address = false

  user_data = <<-EOF
  {"ignition":{"config":{"replace":{"source":"http://${aws_instance.bastion.private_ip}/worker.ign","verification":{}}},"timeouts":{},"version":"2.1.0"},"networkd":{},"passwd":{},"storage":{},"systemd":{}}
  EOF

  tags = merge(
    local.kubernetes_cluster_shared_tag,
    map(
      "Name", "${var.cluster_id}-worker-${count.index}",
      "OpenShiftRole", "worker"
    )
  )

  depends_on = [aws_instance.bastion]
}

###############################################################################
# Route53
###############################################################################

resource "aws_route53_zone" "private" {
  name = var.cluster_domain

  vpc {
    vpc_id = aws_vpc.openshift.id
  }

  tags = merge(
    local.kubernetes_cluster_owned_tag,
    map(
      "Name", "${var.cluster_id}-int"
    )
  )
}

resource "aws_route53_record" "api_private" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "api"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.masters_int.dns_name]
}

resource "aws_route53_record" "apps_private" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "*.apps"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.ingress.dns_name]
}

resource "aws_route53_record" "api_int" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "api-int"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.masters_int.dns_name]
}

resource "aws_route53_record" "etcd" {
  count = 3

  zone_id = aws_route53_zone.private.zone_id
  name    = "etcd-${count.index}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.masters[count.index].private_ip]
}

resource "aws_route53_record" "etcd_srv" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "_etcd-server-ssl._tcp"
  type    = "SRV"
  ttl     = "300"
  records = [
    "0 10 2380 etcd-0.${var.cluster_domain}.",
    "0 10 2380 etcd-1.${var.cluster_domain}.",
    "0 10 2380 etcd-2.${var.cluster_domain}."
  ]
}
