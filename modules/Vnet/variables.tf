variable "vnet_name" { type = string }
variable "address_space" { type = list(string) }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "subnets" {
  type = map(string)
}
variable "tags" { type = map(string) }