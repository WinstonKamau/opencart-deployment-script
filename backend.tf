
terraform {
  backend "gcs" {
    credentials = "./account-folder/account.json"
  }
}
