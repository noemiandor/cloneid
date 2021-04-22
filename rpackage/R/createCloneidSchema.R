createCloneidSchema = function(forceCreateSchema = FALSE) {
    
    STDERR_PREFIX = '^JAVADB: '
    jarFile = paste0(system.file(package='cloneid'), '/java/cloneid.jar')

    if (forceCreateSchema) {
        std = system2('java', args=paste0('-jar ', jarFile, ' -f'), stdout=TRUE, stderr=TRUE)
    } else {
        std = system2('java', args=paste0('-jar ', jarFile, ' -c'), stdout=TRUE, stderr=TRUE)
    }

    for (warning in std) {
        
        if (grepl(STDERR_PREFIX, warning)) {
            warning = gsub(STDERR_PREFIX, '', warning)
            cat(warning, '\n')
        }
        
    }

}
