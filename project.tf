provider "google" {
    credentials = "${file("./account-folder/account.json")}"
    region = "${var.region}"
    project = "${var.project}"
}
