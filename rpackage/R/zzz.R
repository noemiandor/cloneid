module3Banner <- function(libname, pkgname){
# Get the package version
version <- utils::packageDescription(pkgname, fields = "Version")

# Create a large-font style message
msg <- paste0(
    "\n",
    "##############################################\n",
    "##                                          ##\n",
    "##   ", pkgname, " version ", version, strrep(" ", max(0, 24 - nchar(version))), "##\n",
    "##                                          ##\n",
    "##############################################\n"
)

cat(msg)

}
