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
  depends_on = [yandex_compute_instance.db]
  count      = var.instances
  name       = "cms-${count.index + 1}"
  hostname   = "cms-${count.index + 1}"
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
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
sudo mkdir -p /opt/docker/xwiki
sudo docker run -d --name xwiki -p ${self.network_interface[0].ip_address}:8080:8080 -v /opt/docker/xwiki:/usr/local/xwiki -e DB_USER=${var.db_user} -e DB_PASSWORD=${var.db_password} -e DB_DATABASE=${var.db_name} -e DB_HOST=${yandex_compute_instance.db.fqdn} xwiki:stable-postgres-tomcat
EOT
    ]
  }
}

resource "yandex_compute_instance" "nginx" {
  depends_on = [yandex_compute_instance.vm]
  name       = "nginx"
  hostname   = "nginx"
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

  provisioner "local-exec" {
    command = "ansible-playbook -u ${var.vm_user} -i '${self.network_interface[0].nat_ip_address},' --private-key ${var.ssh_key_private} provision/nginx.yml"
  }
}

resource "yandex_compute_instance" "db" {
  name     = "db"
  hostname = "db"
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
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
sudo mkdir -p /opt/docker/postgres
sudo docker run -d --name postgres -p 0.0.0.0:5432:5432 -v /opt/docker/postgres:/var/lib/postgresql/data -e POSTGRES_ROOT_PASSWORD=${var.db_password} -e POSTGRES_USER=${var.db_user}  -e POSTGRES_PASSWORD=${var.db_password} -e POSTGRES_DB=${var.db_name} -e POSTGRES_INITDB_ARGS="--encoding=UTF8" -e POSTGRES_HOST_AUTH_METHOD=scram-sha-256 postgres:16
EOT
    ]
  }
}