resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_compute_instance" "vm" {
  count = var.instances
  name  = "pcs-${count.index + 1}"
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = var.alma9
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "${var.vm_user}:${file("${var.ssh_key_public}")}"
  }

  connection {
    type        = "ssh"
    user        = var.vm_user
    private_key = file("${var.ssh_key_private}")
    host        = self.network_interface[0].nat_ip_address
  }

  provisioner "remote-exec" {
    inline = [
      <<EOT
sudo setenforce 0
sudo sed -i "s/SELINUX=enforcing/SELINUX=permissive/" /etc/selinux/config
EOT
    ]
  }

  # provisioner "local-exec" {
  #   command = "ansible-playbook -u ${var.vm_user} -i '${self.network_interface[0].nat_ip_address},' --private-key ${var.ssh_key_private} provision.yml"
  # }
}
