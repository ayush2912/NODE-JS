provider "mongodbatlas" {
  access_key = vikvqvrh
  secret_key = fee8edd1-014f-47e0-a9da-ca17967d4014
}
resource "mongodbatlas_function" "my_function" {
  name = "ayush_function"
  code = file("App.js")
}
resource "mongodbatlas_function_source" "my_function_source" {
  function_id = mongodbatlas_function.my_function.id
  source_type = "github"
  repository = "NODE-JS"
  branch = "main"
}
