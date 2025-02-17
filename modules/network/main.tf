# Copyright (c) 2022 Cisco Systems, Inc. and its affiliates
# All rights reserved.

resource "aws_vpc" "ftd_vpc" {
  count                = var.vpc_cidr != "" ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  #enable_classiclink   = false
  instance_tenancy     = "default"
  tags = merge({
    Name = var.vpc_name
  }, var.tags)
}

resource "aws_subnet" "mgmt_subnet" {
  count                   = length(var.mgmt_subnet_cidr) != 0 ? length(var.mgmt_subnet_cidr) : 0
  vpc_id                  = local.con
  cidr_block              = var.mgmt_subnet_cidr[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = merge({
    Name = "${var.mgmt_subnet_name[count.index]}"
  }, var.tags)
}

resource "aws_subnet" "outside_subnet" {
  count             = length(var.outside_subnet_cidr) != 0 ? length(var.outside_subnet_cidr) : 0
  vpc_id            = local.con
  cidr_block        = var.outside_subnet_cidr[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge({
    Name = var.outside_subnet_name[count.index]
  }, var.tags)
}

resource "aws_subnet" "inside_subnet" {
  count             = length(var.inside_subnet_cidr) != 0 ? length(var.inside_subnet_cidr) : 0
  vpc_id            = local.con
  cidr_block        = var.inside_subnet_cidr[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge({
    Name = var.inside_subnet_name[count.index]
  }, var.tags)
}

resource "aws_subnet" "diag_subnet" {
  count             = length(var.diag_subnet_cidr) != 0 ? length(var.diag_subnet_cidr) : 0
  vpc_id            = local.con
  cidr_block        = var.diag_subnet_cidr[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge({
    Name = var.diag_subnet_name[count.index]
  }, var.tags)
}

# # #################################################################################################################################
# # # Security Group
# # #################################################################################################################################

resource "aws_security_group" "outside_sg" {
  name        = "Outside Interface SG"
  vpc_id      = local.con
  description = "Secure Firewall Outside SG"
}

# tfsec:ignore:aws-vpc-add-description-to-security-group-rule
# tfsec:ignore:aws-vpc-no-public-ingress-sgr
resource "aws_security_group_rule" "outside_sg_ingress" {
  count       = length(var.outside_interface_sg)
  type        = "ingress"
  from_port   = lookup(var.outside_interface_sg[count.index], "from_port", null)
  to_port     = lookup(var.outside_interface_sg[count.index], "to_port", null)
  protocol    = lookup(var.outside_interface_sg[count.index], "protocol", null)
  cidr_blocks = lookup(var.outside_interface_sg[count.index], "cidr_blocks", null)
  #description = var.outside_interface_sg[count.index].description
  security_group_id = aws_security_group.outside_sg.id
}

# tfsec:ignore:aws-vpc-no-public-egress-sgr
resource "aws_security_group_rule" "outside_sg_egress" {
  type              = "egress"
  description       = "Secure Firewall Outside SG"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.outside_sg.id
}

resource "aws_security_group" "inside_sg" {
  name        = "Inside Interface SG"
  vpc_id      = local.con
  description = "Secure Firewall Inside SG"
}

# tfsec:ignore:aws-vpc-add-description-to-security-group-rule
# tfsec:ignore:aws-vpc-no-public-ingress-sgr
resource "aws_security_group_rule" "inside_sg_ingress" {
  count       = length(var.inside_interface_sg)
  type        = "ingress"
  from_port   = lookup(var.inside_interface_sg[count.index], "from_port", null)
  to_port     = lookup(var.inside_interface_sg[count.index], "to_port", null)
  protocol    = lookup(var.inside_interface_sg[count.index], "protocol", null)
  cidr_blocks = lookup(var.inside_interface_sg[count.index], "cidr_blocks", null)
  #description = var.outside_interface_sg[count.index].description
  security_group_id = aws_security_group.inside_sg.id
}

# tfsec:ignore:aws-vpc-no-public-egress-sgr
resource "aws_security_group_rule" "inside_sg_egress" {
  type              = "egress"
  description       = "Secure Firewall Inside SG"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.inside_sg.id
}

resource "aws_security_group" "mgmt_sg" {
  name        = "FTD Management Interface SG"
  vpc_id      = local.con
  description = "Secure Firewall MGMT SG"
}

# tfsec:ignore:aws-vpc-add-description-to-security-group-rule
# tfsec:ignore:aws-vpc-no-public-ingress-sgr
resource "aws_security_group_rule" "mgmt_sg_ingress" {
  count       = length(var.mgmt_interface_sg)
  type        = "ingress"
  from_port   = lookup(var.mgmt_interface_sg[count.index], "from_port", null)
  to_port     = lookup(var.mgmt_interface_sg[count.index], "to_port", null)
  protocol    = lookup(var.mgmt_interface_sg[count.index], "protocol", null)
  cidr_blocks = lookup(var.mgmt_interface_sg[count.index], "cidr_blocks", null)
  #description = var.outside_interface_sg[count.index].description
  security_group_id = aws_security_group.mgmt_sg.id
}

# tfsec:ignore:aws-vpc-no-public-egress-sgr
resource "aws_security_group_rule" "mgmt_sg_egress" {
  type              = "egress"
  description       = "Secure Firewall MGMT SG"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mgmt_sg.id
}

resource "aws_security_group" "fmc_mgmt_sg" {
  name        = "FMC Management Interface SG"
  vpc_id      = local.con
  description = "Secure Firewall FMC MGMT SG"
}

# tfsec:ignore:aws-vpc-add-description-to-security-group-rule
# tfsec:ignore:aws-vpc-no-public-ingress-sgr
resource "aws_security_group_rule" "fmc_mgmt_sg_ingress" {
  count       = length(var.fmc_mgmt_interface_sg)
  type        = "ingress"
  from_port   = lookup(var.fmc_mgmt_interface_sg[count.index], "from_port", null)
  to_port     = lookup(var.fmc_mgmt_interface_sg[count.index], "to_port", null)
  protocol    = lookup(var.fmc_mgmt_interface_sg[count.index], "protocol", null)
  cidr_blocks = lookup(var.fmc_mgmt_interface_sg[count.index], "cidr_blocks", null)
  #description = var.outside_interface_sg[count.index].description
  security_group_id = aws_security_group.fmc_mgmt_sg.id
}

# tfsec:ignore:aws-vpc-no-public-egress-sgr
resource "aws_security_group_rule" "fmc_mgmt_sg_egress" {
  type              = "egress"
  description       = "Secure Firewall FMC MGMT SG"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.fmc_mgmt_sg.id
}

resource "aws_security_group" "no_access" {
  name        = "No Access"
  vpc_id      = local.con
  description = "No Access SG"
}

# # ##################################################################################################################################
# # # Network Interfaces
# # ##################################################################################################################################
resource "aws_network_interface" "ftd_mgmt" {
  count             = length(var.mgmt_interface) != 0 ? length(var.mgmt_interface) : length(var.ftd_mgmt_ip)
  description       = "asa${count.index}-mgmt"
  subnet_id         = local.mgmt_subnet[local.azs[count.index] - 1].id
  source_dest_check = false
  private_ips       = [var.ftd_mgmt_ip[count.index]]
  security_groups   = [aws_security_group.mgmt_sg.id]
}

resource "aws_network_interface" "ftd_outside" {
  count             = length(var.outside_interface) != 0 ? length(var.outside_interface) : length(var.ftd_outside_ip)
  description       = "asa${count.index}-outside"
  subnet_id         = local.outside_subnet[local.azs[count.index] - 1].id
  source_dest_check = false
  private_ips       = [var.ftd_outside_ip[count.index]]
  security_groups   = [aws_security_group.outside_sg.id]
}

resource "aws_network_interface" "ftd_inside" {
  count             = length(var.inside_interface) != 0 ? length(var.inside_interface) : length(var.ftd_inside_ip)
  description       = "asa${count.index}-inside"
  subnet_id         = local.inside_subnet[local.azs[count.index] - 1].id
  source_dest_check = false
  private_ips       = [var.ftd_inside_ip[count.index]]
  security_groups   = [aws_security_group.inside_sg.id]
}

resource "aws_network_interface" "ftd_diag" {
  count             = length(var.diag_interface) != 0 ? length(var.diag_interface) : length(var.ftd_diag_ip)
  description       = "asa{count.index}-diag"
  subnet_id         = local.diag_subnet[local.azs[count.index] - 1].id
  source_dest_check = false
  private_ips       = [var.ftd_diag_ip[count.index]]
  security_groups   = [aws_security_group.no_access.id]
}

resource "aws_network_interface" "fmcmgmt" {
  count             = length(var.fmc_interface) != 0 ? 0 : 1
  description       = "Fmc_Management"
  subnet_id         = local.mgmt_subnet[local.azs[0] - 1].id
  source_dest_check = false
  private_ips       = [var.fmc_ip]
  security_groups   = [aws_security_group.fmc_mgmt_sg.id]
}

# # ##################################################################################################################################
# # #Internet Gateway and Routing Tables
# # ##################################################################################################################################

# //define the internet gateway
resource "aws_internet_gateway" "int_gw" {
  count  = var.create_igw ? 1 : 0
  vpc_id = local.con
  tags = merge({
    Name = "Internet Gateway"
  }, var.tags)
}

resource "aws_route_table" "ftd_mgmt_route" {
  count  = var.create_igw ? (var.mgmt_subnet_cidr != [] ? length(var.mgmt_subnet_cidr) : length(var.mgmt_subnet_name)) : 0
  vpc_id = local.con
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.int_gw[0].id
  }

  tags = merge({
    Name = "Management network Routing table"
  }, var.tags)
}

resource "aws_route_table" "ftd_outside_route" {
  count  = length(var.outside_subnet_cidr) != 0 ? length(var.outside_subnet_cidr) : length(var.outside_subnet_name)
  vpc_id = local.con
  tags = merge({
    Name = "outside network Routing table"
  }, var.tags)
}

resource "aws_route_table" "ftd_inside_route" {
  count  = length(var.inside_subnet_cidr) != 0 ? length(var.inside_subnet_cidr) : length(var.inside_subnet_name)
  vpc_id = local.con
  tags = merge({
    Name = "inside network Routing table"
  }, var.tags)
}

resource "aws_route_table" "ftd_diag_route" {
  count  = length(var.diag_subnet_cidr) != 0 ? length(var.diag_subnet_cidr) : length(var.diag_subnet_name)
  vpc_id = local.con
  tags = merge({
    Name = "diag network Routing table"
  }, var.tags)
}

resource "aws_route_table_association" "outside_association" {
  count          = length(var.outside_subnet_cidr) != 0 ? length(var.outside_subnet_cidr) : length(var.outside_subnet_name)
  subnet_id      = length(var.outside_subnet_cidr) != 0 ? aws_subnet.outside_subnet[count.index].id : data.aws_subnet.outsideftd[count.index].id
  route_table_id = aws_route_table.ftd_outside_route[count.index].id
}

resource "aws_route_table_association" "mgmt_association" {
  count          = var.create_igw ? (var.mgmt_subnet_cidr != [] ? length(var.mgmt_subnet_cidr) : length(var.mgmt_subnet_name)) : 0
  subnet_id      = length(var.mgmt_subnet_cidr) != 0 ? aws_subnet.mgmt_subnet[count.index].id : data.aws_subnet.mgmt[count.index].id
  route_table_id = aws_route_table.ftd_mgmt_route[count.index].id
}

resource "aws_route_table_association" "inside_association" {
  count          = length(var.inside_subnet_cidr) != 0 ? length(var.inside_subnet_cidr) : length(var.inside_subnet_name)
  subnet_id      = length(var.inside_subnet_cidr) != 0 ? aws_subnet.inside_subnet[count.index].id : data.aws_subnet.insideftd[count.index].id
  route_table_id = aws_route_table.ftd_inside_route[count.index].id
}

resource "aws_route_table_association" "diag_association" {
  count          = length(var.diag_subnet_cidr) != 0 ? length(var.diag_subnet_cidr) : length(var.diag_subnet_name)
  subnet_id      = length(var.diag_subnet_cidr) != 0 ? aws_subnet.diag_subnet[count.index].id : data.aws_subnet.diagftd[count.index].id
  route_table_id = aws_route_table.ftd_diag_route[count.index].id
}

# # ##################################################################################################################################
# # # AWS External IP address creation and associating it to the mgmt interface. 
# # ##################################################################################################################################

resource "aws_eip" "ftd_mgmt_eip" {
  count = var.use_ftd_eip ? (length(var.mgmt_interface) != 0 ? length(var.mgmt_interface) : length(var.ftd_mgmt_ip)) : 0
  vpc   = true
  tags = merge({
    "Name" = "ftd-${count.index} Management IP"
  }, var.tags)
}

resource "aws_eip_association" "ftd_mgmt_ip_assocation" {
  count                = length(aws_eip.ftd_mgmt_eip)
  network_interface_id = length(var.mgmt_interface) != 0 ? var.mgmt_interface[count.index] : aws_network_interface.ftd_mgmt[count.index].id
  allocation_id        = aws_eip.ftd_mgmt_eip[count.index].id
}

resource "aws_eip" "fmcmgmt_eip" {
  count = var.use_fmc_eip ? 1 : 0
  vpc   = true
  tags = {
    "Name" = "FMCv Management IP"
  }
}
resource "aws_eip_association" "fmc_mgmt_ip_assocation" {
  count                = var.use_fmc_eip ? 1 : 0
  network_interface_id = aws_network_interface.fmcmgmt[0].id
  allocation_id        = aws_eip.fmcmgmt_eip[0].id
}