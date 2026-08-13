moved {
  from = google_container_cluster.this
  to   = google_container_cluster.this[0]
}
