variable "bucket_name" {
  description = "The name of the s3 bucket"
  default     = "my-website-bucket-2026-05-07"
}
variable "website_index_document" {
  description = "The index document for the website"
  default     = "index.html"
}
variable "website_error_document" {
  description = "The error document for the website"
  default     = "error.html"
}