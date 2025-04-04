packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }

    windows-update = {
      version = "0.15.0"
      source  = "github.com/rgl/windows-update"
    }
  }
}

variable "accelerator" {
  type    = string
  default = "tcg"
  descripton "TCG is used for macOS Hypervisor Framework, so use if building on macOS"
}

variable "autounattend" {
  type    = string
  default = "./answer_files/11/Autounattend.xml"
}

variable "cpus" {
  type    = string
  default = "4"
}

variable "disk_size" {
  type    = string
  default = "61440"
}

variable "headless" {
  type    = string
  default = "true"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:c8dbc96b61d04c8b01faf6ce0794fdf33965c7b350eaa3eb1e6697019902945c"
}

variable "iso_url" {
 type    = string
 default = "./isos/WIN_11_23H2.iso"
}

#variable "iso_url" {
#  type    = string
#  default = "https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/22631.2428.231001-0608.23H2_NI_RELEASE_SVC_REFRESH_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
#}

variable "memory_size" {
  type    = string
  default = "4096"
}

variable "shutdown_command" {
  type    = string
  default = "%WINDIR%/system32/sysprep/sysprep.exe /generalize /oobe /shutdown /unattend:C:/Windows/Temp/Autounattend.xml"
}

variable "vm_name" {
  type    = string
  default = "windows_11"
}

source "qemu" "win11_23h2" {
  accelerator      = "${var.accelerator}"
  boot_wait        = "20s"
  communicator     = "winrm"
  cpus             = "${var.cpus}"
  disk_compression = "true"
  disk_interface   = "virtio"
  disk_size        = "${var.disk_size}"
  floppy_files     = ["${var.autounattend}", "./scripts/0-firstlogin.bat", "./scripts/1-fixnetwork.ps1", "./scripts/70-install-misc.bat", "./scripts/50-enable-winrm.ps1", "./answer_files/Firstboot/Firstboot-Autounattend.xml", "./drivers/"]
  format           = "qcow2"
  headless         = "${var.headless}"
  iso_checksum     = "${var.iso_checksum}"
  iso_url          = "${var.iso_url}"
  memory           = "${var.memory_size}"
  net_device       = "virtio-net"
  #qemuargs         = [["-vga", "qxl"]]
  shutdown_command = "${var.shutdown_command}"
  winrm_insecure   = "true"
  winrm_password   = "vagrant"
  winrm_timeout    = "180m"
  winrm_use_ssl    = "true"
  winrm_username   = "vagrant"
  output_directory = "output-${var.vm_name}"
}

build {
  sources = ["source.qemu.win11_23h2"]

  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c C:/Windows/Temp/script.bat"
    remote_path     = "c:/Windows/Temp/script.bat"
    scripts         = ["./scripts/70-install-misc.bat", "./scripts/80-compile-dotnet-assemblies.bat"]
  }

  # Reboot after doing our first stages
  # This is to give the windows-update provisioner a chance
  # As it will seemingly hang on TiWorker.exe siting around idling
  # (This is due to registry changes in the first stage seemignly not having
  # efect until a reboot has happened)
  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'restarted.'}\""
  }

  provisioner "windows-update" {
  }

  # Without this step, your images will be ~12-15GB
  # With this step, roughly ~8-9GB
  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c C:/Windows/Temp/script.bat"
    remote_path     = "c:/Windows/Temp/script.bat"
    scripts         = ["./scripts/90-compact.bat"]
  }
}
