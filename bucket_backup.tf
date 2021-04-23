provider "google" {
  region  = "europe-west2"
  project = var.project
}

data "google_storage_transfer_project_service_account" "default" {
  project = var.project
}

resource "google_storage_bucket" "tfe-backup-bucket" {
  name          = "tfe-active-backup-test"
  storage_class = "NEARLINE"
  project       = var.project
}

resource "google_storage_bucket_iam_member" "backup-bucket" {
  bucket     = google_storage_bucket.tfe-backup-bucket.name
  role       = "roles/storage.admin"
  member     = "serviceAccount:${data.google_storage_transfer_project_service_account.default.email}"
  depends_on = [google_storage_bucket.tfe-backup-bucket]
}


resource "google_storage_transfer_job" "nightly-backup" {
  description = "Nightly backup of cloud storage bucket"
  project     = var.project

  transfer_spec {
    transfer_options {
      delete_objects_unique_in_sink = false
    }
    gcs_data_source {
      bucket_name = var.tfe_bucket
    }
    gcs_data_sink {
      bucket_name = google_storage_bucket.tfe-backup-bucket.name
    }
  }

  schedule {
    schedule_start_date {
      year  = 2020
      month = 4
      day   = 22
    }
    start_time_of_day {
      hours   = 11
      minutes = 45
      seconds = 0
      nanos   = 0
    }
  }
  depends_on = [google_storage_bucket_iam_member.backup-bucket]
}