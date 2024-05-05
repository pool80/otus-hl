terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-a"
}

resource "yandex_compute_disk" "boot-disk-1" {
  name     = "boot-disk-1"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  size     = "20"
  image_id = "fd87ihr5mbkcrv7mrvtp"
}

resource "yandex_compute_instance" "vm-1" {
  name = "nginx1"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk-1.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    user-data = "${file("./users.yml")}"
  }

  connection {
    type        = "ssh"
    user        = "${var.vm_user}"
    private_key = file("~/.ssh/id_rsa_yc")
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

  provisioner "local-exec" {
    command = "ansible-playbook -u ${var.vm_user} -i '${self.network_interface[0].nat_ip_address},' --private-key ${var.ssh_key_private} provision.yml" 
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.ip_address
}

output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}
