variable "yc_zones" {
  type    = list(string)
  default = ["ru-central1-a", "ru-central1-b", "ru-central1-c"]
}
variable "alma9" {
  type    = string
  default = "fd87ihr5mbkcrv7mrvtp"
}
variable "vm_user" {
  type    = string
  default = "almalinux"
}
variable "ssh_key_private" {
  type    = string
  default = "~/.ssh/id_rsa_yc"
}
variable "ssh_key_public" {
  type    = string
  default = "~/.ssh/id_rsa_yc.pub"
}
variable "instances" {
  type    = number
  default = 3
}
