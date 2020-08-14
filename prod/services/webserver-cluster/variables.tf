variable "matrix_heroes" {
  description = "They gr8 m8"
  type        = map(string)
  default = {
    Neo      = "hero"
    Morpheus = "mentor"
    Trinity  = "love interest"
  }
}