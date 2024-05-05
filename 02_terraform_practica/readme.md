# 02 Практическое занятие по использованию Terraform

- реализовать терраформ для разворачивания одной виртуалки в yandex-cloud
- запровиженить nginx с помощью ansible

## Terraform cli
```
terraform init
terraform validate
terraform fmt
terraform plan
terraform apply
terraform destroy
```

## Install Ansible
```
sudo apt install python3-pip
python3 -m pip install --user ansible
```
в ~/.bashrc
```
PATH=$PATH:~/.local/bin
```
в ~/.ansible.cfg
```
[defaults]
host_key_checking = False
```

## Как это работает?
Терраформ разворачивает виртуалку с предустановленной ОС. 
Использовал Almalinux 9. С помощью `provisioner "remote-exec"` переводим selinux в режим permissive. Далее с помощью `provisioner "local-exec"` разворачиваем сценарий Ансибл и устанавливаем нжинкс.