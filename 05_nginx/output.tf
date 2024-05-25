output "internal_ip_address_vm" {
  value = yandex_compute_instance.vm[*].network_interface.0.ip_address
}
output "external_ip_address_vm" {
  value = yandex_compute_instance.vm[*].network_interface.0.nat_ip_address
}
output "internal_ip_address_nginx" {
  value = yandex_compute_instance.nginx[*].network_interface.0.ip_address
}
output "external_ip_address_nginx" {
  value = yandex_compute_instance.nginx[*].network_interface.0.nat_ip_address
}
output "internal_ip_address_db" {
  value = yandex_compute_instance.db[*].network_interface.0.ip_address
}
output "external_ip_address_db" {
  value = yandex_compute_instance.db[*].network_interface.0.nat_ip_address
}