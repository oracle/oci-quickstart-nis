data "template_file" "nis_server_script" {
  template = "${file("${path.module}/../scripts/bootstrap-server.sh")}"

  vars {
    nis_domain_name             = "${var.nis_domain_name}"
    nis_server_sercure_net_list = "${join(" ", var.nis_server_sercure_net_list)}"
    nis_sudo_group_name         = "${var.nis_sudo_group_name}"
  }
}

data "template_file" "nis_client_script" {
  template = "${file("${path.module}/../scripts/bootstrap-client.sh")}"

  vars {
    server_host_name    = "${var.nis_server_hostname}"
    server_domain_name  = "${var.nis_server_domainname}"
    nis_domain_name     = "${var.nis_domain_name}"
    nis_sudo_group_name = "${var.nis_sudo_group_name}"
  }
}

resource "null_resource" "configure_nis_server" {
  connection = {
    host        = "${var.nis_server_private_ip}"
    agent       = false
    timeout     = "5m"
    user        = "${var.nis_server_user}"
    private_key = "${file("${var.nis_server_ssh_private_key}")}"

    bastion_host        = "${var.nis_login_host_public_ip}"
    bastion_user        = "${var.nis_login_user}"
    bastion_private_key = "${file("${var.nis_login_host_ssh_private_key}")}"
  }

  provisioner "file" {
    content     = "${data.template_file.nis_server_script.rendered}"
    destination = "~/configure-server.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ~/configure-server.sh",
      "sudo sh ~/configure-server.sh",
    ]
  }
}

resource "null_resource" "configure_nis_client" {
  count = "${length(var.nis_client_private_ip_list)}"

  connection = {
    host        = "${var.nis_client_private_ip_list[count.index]}"
    agent       = false
    timeout     = "5m"
    user        = "${var.nis_client_private_user_list[count.index]}"
    private_key = "${file("${var.nis_client_ssh_private_key_list[count.index]}")}"

    bastion_host        = "${var.nis_login_host_public_ip}"
    bastion_user        = "${var.nis_login_user}"
    bastion_private_key = "${file("${var.nis_login_host_ssh_private_key}")}"
  }

  provisioner "file" {
    content     = "${data.template_file.nis_client_script.rendered}"
    destination = "~/bootstrap-client.sh"
  }

  provisioner "remote-exec" {

    inline = [
      "chmod +x ~/bootstrap-client.sh",
      "sudo ~/bootstrap-client.sh",
    ]
  }

  depends_on = ["null_resource.configure_nis_server"]
}
