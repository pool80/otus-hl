resource "local_file" "ansible_inventory" {
  filename        = "ansible/inventory.ini"
  file_permission = 0644
  content = templatefile("./inventory.tftpl",
    {
      vm_ip_address_list = yandex_compute_instance.vm[*].network_interface[0].nat_ip_address
      vm_names        = yandex_compute_instance.vm[*].name
    }
  )
}
