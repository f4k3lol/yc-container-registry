variable "name" {
  type = string
}

variable "repos" {
  default = []
}

variable "rules" {
  default = {
    #rule01 = { description = "", expire_period = 11, tag_regexp = "", untagged = "", retained_top = "" }
  }

}
