terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.2-rc04"
    }
  }
}

provider "proxmox" {
  pm_api_url           = "https://xxx.xxx.xxx.xxx:8006/api2/json"
  pm_api_token_id      = "user@pam!gui-token"
  pm_api_token_secret  = "xxxxxxxxx"
  pm_tls_insecure      = true
}

resource "proxmox_vm_qemu" "vm" {
  name        = var.machine_name
  target_node = var.node        
  machine     = var.machine
  memory      = var.memory
  scsihw      = "virtio-scsi-pci"
  agent       = 1
  balloon     = var.memory
  vm_state    = "running"
  description = local.description

  cpu {
    cores   = var.cores
  }

  disk {
    slot      = "virtio0"
    size      = var.disk_size
    storage   = var.disk_storage
    iothread  = "1"
  }
  
  disk {
    slot    = "ide2"
    type    = "cdrom"
    iso     = var.disk_iso               
  }              

  network {
    id     = 0
    model  = "virtio"
    bridge = var.bridge
    tag    = var.vlan                  
  }
}
