.onLoad <- function(libname, pkgname) {
  module3Banner(libname, pkgname)
  .jpackage(pkgname, lib.loc = libname)
}
